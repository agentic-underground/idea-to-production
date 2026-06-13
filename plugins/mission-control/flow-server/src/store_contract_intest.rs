//! Store contract: the ONE serialized writer. Concurrent writes serialize
//! without corruption; the JSONL event log round-trips; the only way to mutate
//! is a store method (there is no direct-write path).

use std::sync::Arc;

use crate::domain::{Event, ItemId, Status, WaitGate};
use crate::store::Store;

fn id(s: &str) -> ItemId {
    ItemId::new(s).unwrap()
}

#[tokio::test]
async fn concurrent_writes_serialize() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());

    // Seed one item.
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();

    // Fan out 100 concurrent spend appends through the single writer.
    let mut handles = Vec::new();
    for _ in 0..100 {
        let s = Arc::clone(&store);
        handles.push(tokio::spawn(async move {
            s.append_spend(&id("a"), 1).await.unwrap();
        }));
    }
    for h in handles {
        h.await.unwrap();
    }

    // Exactly 100 accrued, no lost updates or corruption.
    let snap = store.snapshot().await;
    assert_eq!(snap.get(&id("a")).unwrap().tokens, 100);

    // The JSONL log has the upsert + 100 spend events, every line parseable.
    let events = store.read_events().await.unwrap();
    let spend = events
        .iter()
        .filter(|e| matches!(e, Event::SpendAppended { .. }))
        .count();
    assert_eq!(spend, 100);
}

#[tokio::test]
async fn jsonl_round_trips() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    store.set_gate(&id("a"), WaitGate::Wait).await.unwrap();
    store.set_gate(&id("a"), WaitGate::Go).await.unwrap();
    store.post_status(&id("a"), Status::Doing).await.unwrap();

    let events = store.read_events().await.unwrap();
    // First event is the upsert; the rest replay deterministically. Assert on the
    // whole value (Event derives PartialEq) rather than a `matches!`, whose dead
    // non-match arm would read as an uncovered region.
    assert_eq!(
        events.first().unwrap(),
        &Event::ItemUpserted {
            id: id("a"),
            title: "A".into(),
        }
    );
    assert!(events.contains(&Event::StatusPosted {
        id: id("a"),
        status: Status::Doing,
    }));

    // Re-opening the store replays the JSONL into the same state.
    drop(store);
    let reopened = Store::open(&dir).await.unwrap();
    let snap = reopened.snapshot().await;
    assert_eq!(snap.get(&id("a")).unwrap().status, Status::Doing);
}

#[tokio::test]
async fn markdown_is_written_and_only_methods_mutate() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(
            id("flow-server"),
            "Flow server".into(),
            "claude-opus-4-8".into(),
        )
        .await
        .unwrap();

    // The markdown view exists and references the item by slug + title.
    let md = std::fs::read_to_string(dir.join("ROADMAP.flow.md")).unwrap();
    assert!(md.contains("flow-server"));
    assert!(md.contains("Flow server"));

    // There is no public direct-write method on Store: the only entry points are
    // the verbs. (Compile-time guarantee — this asserts the snapshot is a clone,
    // so mutating it cannot affect the store.)
    let mut snap = store.snapshot().await;
    snap.set_gate(&id("flow-server"), WaitGate::Wait).ok();
    let fresh = store.snapshot().await;
    assert_eq!(fresh.get(&id("flow-server")).unwrap().gate, WaitGate::Go);
}

#[tokio::test]
async fn subscriber_count_reflects_live_subscribers() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    assert_eq!(store.subscriber_count(), 0);
    let rx1 = store.subscribe();
    assert_eq!(store.subscriber_count(), 1);
    let rx2 = store.subscribe();
    assert_eq!(store.subscriber_count(), 2);
    drop(rx1);
    drop(rx2);
    assert_eq!(store.subscriber_count(), 0);
}

#[tokio::test]
async fn reopen_replays_every_event_kind() {
    let dir = tempdir();
    // Write a state covering every event variant the apply_event replay handles.
    {
        let store = Store::open(&dir).await.unwrap();
        store
            .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
            .await
            .unwrap();
        store
            .upsert_item(id("b"), "B".into(), "claude-sonnet-4-6".into())
            .await
            .unwrap();
        store.set_gate(&id("a"), WaitGate::Wait).await.unwrap();
        store.set_gate(&id("a"), WaitGate::Go).await.unwrap();
        store.post_status(&id("a"), Status::Doing).await.unwrap();
        store.append_spend(&id("a"), 5).await.unwrap();
        store
            .set_item_model(&id("a"), "claude-opus-4-8".into())
            .await
            .unwrap();
        store
            .mutate_connection(crate::domain::Mutation::Add, id("a"), id("b"))
            .await
            .unwrap();
        store
            .mutate_connection(crate::domain::Mutation::Remove, id("a"), id("b"))
            .await
            .unwrap();
        store.append_sysmsg("hello".into()).await.unwrap();
    }

    // Reopen: every event replays through apply_event into the same state.
    let reopened = Store::open(&dir).await.unwrap();
    let snap = reopened.snapshot().await;
    let a = snap.get(&id("a")).unwrap();
    assert_eq!(a.status, Status::Doing);
    assert_eq!(a.gate, WaitGate::Go);
    assert_eq!(a.tokens, 5);
    assert_eq!(a.model, "claude-opus-4-8");
    // The add+remove cancel out: no edges survive.
    assert_eq!(snap.edges().len(), 0);
}

#[tokio::test]
async fn open_skips_blank_lines_and_rejects_malformed() {
    let dir = tempdir();
    {
        let store = Store::open(&dir).await.unwrap();
        store
            .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
            .await
            .unwrap();
    }
    let jsonl = dir.join("events.jsonl");
    let mut contents = std::fs::read_to_string(&jsonl).unwrap();
    // A blank line is skipped on replay (the trim().is_empty() guard).
    contents.push_str("\n   \n");
    std::fs::write(&jsonl, &contents).unwrap();
    // With only valid + blank lines, reopen succeeds.
    let reopened = Store::open(&dir).await.unwrap();
    assert!(reopened.snapshot().await.get(&id("a")).is_some());

    // Now append a malformed line: reopen must surface a Serialize error.
    let mut bad = std::fs::read_to_string(&jsonl).unwrap();
    bad.push_str("{not valid json}\n");
    std::fs::write(&jsonl, bad).unwrap();
    let err = Store::open(&dir).await;
    assert!(err.is_err(), "a malformed JSONL line must fail replay");
}

#[tokio::test]
async fn read_events_surfaces_malformed_line() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    // Valid log reads back cleanly (the Ok content + skip-blank path).
    let jsonl = dir.join("events.jsonl");
    let mut contents = std::fs::read_to_string(&jsonl).unwrap();
    contents.push('\n'); // trailing blank line, skipped
    std::fs::write(&jsonl, &contents).unwrap();
    assert_eq!(store.read_events().await.unwrap().len(), 1);

    // A malformed line makes read_events return the Serialize error.
    contents.push_str("totally not json\n");
    std::fs::write(&jsonl, contents).unwrap();
    assert!(store.read_events().await.is_err());
}

#[tokio::test]
async fn read_events_on_missing_log_is_empty() {
    // A fresh store dir with no writes: events.jsonl does not exist, so the
    // read_to_string Err branch yields an empty event list (not an error).
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    assert!(store.read_events().await.unwrap().is_empty());
}

#[tokio::test]
async fn open_fails_when_data_dir_path_runs_through_a_file() {
    // create_dir_all must fail when an ancestor of the data dir is a file.
    let base = std::env::temp_dir().join(format!("flow-openfail-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&base);
    std::fs::create_dir_all(&base).unwrap();
    let file = base.join("a-file");
    std::fs::write(&file, "x").unwrap();
    let bad_dir = file.join("nested"); // ancestor `a-file` is a regular file
    assert!(Store::open(&bad_dir).await.is_err());
}

#[tokio::test]
async fn open_fails_when_markdown_path_is_a_directory() {
    // If ROADMAP.flow.md is already a directory, the open-time markdown render
    // (tokio::fs::write) fails and propagates out of Store::open.
    let dir = tempdir();
    std::fs::create_dir_all(dir.join("ROADMAP.flow.md")).unwrap();
    assert!(Store::open(&dir).await.is_err());
}

#[tokio::test]
async fn set_item_model_on_unknown_item_is_flow_error() {
    // The domain `set_model` `?` propagates an Unknown flow error before commit.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    let err = store
        .set_item_model(&id("ghost"), "m".into())
        .await
        .unwrap_err();
    // StoreError has no PartialEq; pin the variant via its Display (the
    // transparent FlowError::Unknown message) rather than a `matches!`.
    assert_eq!(err.to_string(), "unknown item ghost");
}

#[tokio::test]
async fn commit_fails_when_markdown_becomes_a_directory() {
    // A successful set_model then a commit whose markdown render faults: the
    // verb's `commit(...).await?` propagation is exercised on a real IO fault.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    // Replace the markdown file with a directory so the next render fails.
    std::fs::remove_file(dir.join("ROADMAP.flow.md")).unwrap();
    std::fs::create_dir_all(dir.join("ROADMAP.flow.md")).unwrap();
    let err = store
        .set_item_model(&id("a"), "claude-opus-4-8".into())
        .await;
    assert!(
        err.is_err(),
        "commit must fail when the markdown render faults"
    );
}

#[tokio::test]
async fn commit_fails_when_jsonl_becomes_a_directory() {
    // Replace events.jsonl with a directory so the append-open faults inside
    // commit, exercising the JSONL open `?`.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    std::fs::remove_file(dir.join("events.jsonl")).unwrap();
    std::fs::create_dir_all(dir.join("events.jsonl")).unwrap();
    // append_spend mutates in-memory, then its `commit(...).await?` faults on the
    // JSONL append — exercising that verb's commit error propagation.
    let err = store.append_spend(&id("a"), 1).await;
    assert!(
        err.is_err(),
        "commit must fail when the JSONL append faults"
    );
}

/// Minimal unique temp dir (no external crate); cleaned by the OS on reboot.
fn tempdir() -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let pid = std::process::id();
    let dir = std::env::temp_dir().join(format!("flow-store-test-{pid}-{n}"));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}
