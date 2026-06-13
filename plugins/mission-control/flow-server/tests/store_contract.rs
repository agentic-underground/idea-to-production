//! Store contract: the ONE serialized writer. Concurrent writes serialize
//! without corruption; the JSONL event log round-trips; the only way to mutate
//! is a store method (there is no direct-write path).

use std::sync::Arc;

use flow_server::domain::{Event, ItemId, Status, WaitGate};
use flow_server::store::Store;

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
    // First event is the upsert; the rest replay deterministically.
    assert!(matches!(events.first(), Some(Event::ItemUpserted { .. })));
    assert!(events.iter().any(|e| matches!(
        e,
        Event::StatusPosted {
            status: Status::Doing,
            ..
        }
    )));

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
