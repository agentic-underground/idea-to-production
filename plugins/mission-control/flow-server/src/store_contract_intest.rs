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
        // An annotation (no-op on flow state replay) and two rewrites (each
        // replays the draft bump) so apply_event's new arms are exercised.
        store.annotate(&id("a"), "note".into()).await.unwrap();
        store
            .request_rewrite(&id("a"), "redo".into())
            .await
            .unwrap();
        store
            .request_rewrite(&id("a"), "again".into())
            .await
            .unwrap();
    }

    // Reopen: every event replays through apply_event into the same state.
    let reopened = Store::open(&dir).await.unwrap();
    let snap = reopened.snapshot().await;
    let a = snap.get(&id("a")).unwrap();
    assert_eq!(a.status, Status::Doing);
    assert_eq!(a.gate, WaitGate::Go);
    assert_eq!(a.tokens, 5);
    assert_eq!(a.model, "claude-opus-4-8");
    // Two rewrites replayed: the draft count survives the reopen.
    assert_eq!(a.draft, 2);
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

#[tokio::test]
async fn spend_on_child_rolls_up_to_ancestor_and_writes_telemetry() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    // epic depends on nothing; parent depends on epic; child depends on parent.
    // Edge direction is `from -> to` = "from depends on to", so child's
    // ancestors are parent and epic.
    for s in ["epic", "parent", "child"] {
        store
            .upsert_item(id(s), s.into(), "claude-sonnet-4-6".into())
            .await
            .unwrap();
    }
    store
        .mutate_connection(crate::domain::Mutation::Add, id("child"), id("parent"))
        .await
        .unwrap();
    store
        .mutate_connection(crate::domain::Mutation::Add, id("parent"), id("epic"))
        .await
        .unwrap();

    // 1000 tokens on the atomic child.
    let total = store
        .append_spend_as(&id("child"), 1000, "carriage-agent", "implement")
        .await
        .unwrap();
    assert_eq!(total, 1000);

    let snap = store.snapshot().await;
    // The child's own tally…
    assert_eq!(snap.get(&id("child")).unwrap().tokens, 1000);
    // …and every ancestor composite's rolled-up tally rose by 1000.
    assert_eq!(snap.get(&id("parent")).unwrap().tokens, 1000);
    assert_eq!(snap.get(&id("epic")).unwrap().tokens, 1000);

    // A telemetry line was appended carrying the schema + the ancestors.
    let tev = store.read_telemetry().await.unwrap();
    assert_eq!(tev.len(), 1);
    assert_eq!(tev[0].item_id, id("child"));
    assert_eq!(tev[0].agent, "carriage-agent");
    assert_eq!(tev[0].activity, "implement");
    assert_eq!(tev[0].tokens_delta, 1000);
    assert_eq!(tev[0].tokens_total, 1000);
    assert_eq!(tev[0].ancestors, vec![id("epic"), id("parent")]);
}

#[tokio::test]
async fn default_append_spend_still_works_and_records_telemetry() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    // The legacy verb keeps its signature and now also leaves a telemetry line.
    assert_eq!(store.append_spend(&id("a"), 42).await.unwrap(), 42);
    let tev = store.read_telemetry().await.unwrap();
    assert_eq!(tev.len(), 1);
    assert_eq!(tev[0].agent, "carriage-agent");
    assert_eq!(tev[0].activity, "spend");
    assert_eq!(tev[0].tokens_delta, 42);
    assert!(tev[0].ancestors.is_empty());
}

#[tokio::test]
async fn reopen_replays_rolled_up_ancestor_tallies() {
    let dir = tempdir();
    {
        let store = Store::open(&dir).await.unwrap();
        for s in ["parent", "child"] {
            store
                .upsert_item(id(s), s.into(), "claude-sonnet-4-6".into())
                .await
                .unwrap();
        }
        store
            .mutate_connection(crate::domain::Mutation::Add, id("child"), id("parent"))
            .await
            .unwrap();
        store.append_spend(&id("child"), 250).await.unwrap();
    }
    // Reopen: the event-log replay must reconstruct the roll-up onto `parent`.
    let reopened = Store::open(&dir).await.unwrap();
    let snap = reopened.snapshot().await;
    assert_eq!(snap.get(&id("child")).unwrap().tokens, 250);
    assert_eq!(snap.get(&id("parent")).unwrap().tokens, 250);
}

#[tokio::test]
async fn read_telemetry_on_missing_ledger_is_empty() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    assert!(store.read_telemetry().await.unwrap().is_empty());
}

#[tokio::test]
async fn read_telemetry_surfaces_malformed_line() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    store.append_spend(&id("a"), 1).await.unwrap();
    let path = dir.join("telemetry.jsonl");
    let mut contents = std::fs::read_to_string(&path).unwrap();
    // A trailing blank line is skipped (the trim().is_empty() guard)…
    contents.push('\n');
    std::fs::write(&path, &contents).unwrap();
    assert_eq!(store.read_telemetry().await.unwrap().len(), 1);
    // …a malformed line surfaces the Serialize error.
    contents.push_str("not telemetry json\n");
    std::fs::write(&path, contents).unwrap();
    assert!(store.read_telemetry().await.is_err());
}

#[tokio::test]
async fn spend_commit_fails_when_telemetry_path_is_a_directory() {
    // Replace telemetry.jsonl with a directory so the append-open faults after
    // the spend commit, exercising the telemetry append `?` propagation.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    std::fs::create_dir_all(dir.join("telemetry.jsonl")).unwrap();
    assert!(store.append_spend(&id("a"), 1).await.is_err());
}

#[tokio::test]
async fn grafana_push_no_endpoint_when_unset() {
    // With GRAFANA_URL unset, the push is a graceful no-op carrying the reason.
    // (Serialized: this test mutates a process-global env var.)
    let _g = ENV_LOCK.lock().await;
    std::env::remove_var("GRAFANA_URL");
    assert_eq!(
        crate::store::push_to_grafana_for_test(&[]).await,
        crate::store::GrafanaPush::NoEndpoint
    );
}

#[tokio::test]
async fn grafana_push_attempted_when_endpoint_present() {
    let _g = ENV_LOCK.lock().await;
    std::env::set_var("GRAFANA_URL", "http://localhost:3100/");
    let got = crate::store::push_to_grafana_for_test(&[]).await;
    std::env::remove_var("GRAFANA_URL");
    assert_eq!(
        got,
        crate::store::GrafanaPush::Attempted {
            endpoint: "http://localhost:3100/loki/api/v1/push".into()
        }
    );
}

/// Serializes the two tests that mutate the process-global `GRAFANA_URL`.
static ENV_LOCK: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

/// Minimal unique temp dir (no external crate); cleaned by the OS on reboot.
#[tokio::test]
async fn annotate_appends_to_plan_doc_when_present() {
    // Use a test-owned root so `doc/` resolution (data_dir.parent()/doc) is
    // isolated; the store data dir is a child of that root.
    let root = tempdir();
    let data = root.join(".flow");
    let doc = root.join("doc");
    std::fs::create_dir_all(&doc).unwrap();
    // The item title "Flow server" → plan doc FLOW_SERVER_PLAN.md.
    let plan = doc.join("FLOW_SERVER_PLAN.md");
    std::fs::write(&plan, "# Flow server plan\n").unwrap();

    let store = Store::open(&data).await.unwrap();
    store
        .upsert_item(id("flow-server"), "Flow server".into(), "m".into())
        .await
        .unwrap();
    store
        .annotate(&id("flow-server"), "tighten the auth gate".into())
        .await
        .unwrap();

    // The annotation block was appended to the existing plan doc.
    let contents = std::fs::read_to_string(&plan).unwrap();
    assert!(contents.starts_with("# Flow server plan\n"));
    assert!(contents.contains("### Annotation on `flow-server`"));
    assert!(contents.contains("tighten the auth gate"));
    // The per-item ledger was NOT used (the plan doc took precedence).
    assert!(!data.join("annotations").join("flow-server.md").exists());
}

#[tokio::test]
async fn annotate_falls_back_to_ledger_without_plan_doc() {
    let root = tempdir();
    let data = root.join(".flow");
    let store = Store::open(&data).await.unwrap();
    store
        .upsert_item(id("flow-server"), "Flow server".into(), "m".into())
        .await
        .unwrap();
    store
        .annotate(&id("flow-server"), "first note".into())
        .await
        .unwrap();
    store
        .annotate(&id("flow-server"), "second note".into())
        .await
        .unwrap();
    // The per-item ledger holds both annotations, in order.
    let ledger = data.join("annotations").join("flow-server.md");
    let contents = std::fs::read_to_string(&ledger).unwrap();
    assert!(contents.contains("first note"));
    assert!(contents.contains("second note"));
    let first = contents.find("first note").unwrap();
    let second = contents.find("second note").unwrap();
    assert!(first < second);
}

#[tokio::test]
async fn annotate_unknown_item_is_error() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    let err = store.annotate(&id("nope"), "x".into()).await;
    assert!(err.is_err());
}

#[tokio::test]
async fn request_rewrite_unknown_item_is_error() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    let err = store.request_rewrite(&id("nope"), "x".into()).await;
    assert!(err.is_err());
}

#[tokio::test]
async fn annotate_fails_when_ledger_dir_cannot_be_created() {
    // Put a FILE where the annotations dir would go, so create_dir_all faults —
    // exercising annotate's create_dir `?`.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "m".into())
        .await
        .unwrap();
    std::fs::write(dir.join("annotations"), "not a dir").unwrap();
    assert!(store.annotate(&id("a"), "x".into()).await.is_err());
}

#[tokio::test]
async fn annotate_fails_when_ledger_target_is_a_directory() {
    // Make the per-item ledger file path a directory so append_raw's open faults —
    // exercising annotate's append `?` after the dir is created.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "m".into())
        .await
        .unwrap();
    std::fs::create_dir_all(dir.join("annotations").join("a.md")).unwrap();
    assert!(store.annotate(&id("a"), "x".into()).await.is_err());
}

#[tokio::test]
async fn request_rewrite_commit_failure_propagates() {
    // Replace events.jsonl with a directory so the commit append faults inside
    // request_rewrite — exercising its `commit(...).await?`.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "m".into())
        .await
        .unwrap();
    std::fs::remove_file(dir.join("events.jsonl")).unwrap();
    std::fs::create_dir_all(dir.join("events.jsonl")).unwrap();
    assert!(store
        .request_rewrite(&id("a"), "redo".into())
        .await
        .is_err());
}

#[tokio::test]
async fn annotate_commit_failure_propagates() {
    // The annotation append to the ledger succeeds, but the event commit's JSONL
    // append faults — exercising annotate's trailing `commit(...).await`.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("a"), "A".into(), "m".into())
        .await
        .unwrap();
    std::fs::remove_file(dir.join("events.jsonl")).unwrap();
    std::fs::create_dir_all(dir.join("events.jsonl")).unwrap();
    assert!(store.annotate(&id("a"), "note".into()).await.is_err());
}

#[tokio::test]
async fn ingest_roadmap_loads_items_with_statuses_and_edges() {
    // The startup ingest fills an empty store from the roadmap markdown so the
    // board is not blank: every parsed item appears (with its parsed status) and
    // every valid edge is added, all through the single serialized writer.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    let md = "\
## [1] Flow server
> STATUS: IN PROGRESS
> DEPENDS ON: —

## [5] Roadmap history
> STATUS: COMPLETE
> DEPENDS ON: #1

## [2] Canvas
> STATUS: PENDING
> DEPENDS ON: #1, #5
";
    let loaded = store.ingest_roadmap(md).await.unwrap();
    assert_eq!(loaded, 3);

    let snap = store.snapshot().await;
    // Items present in display order with their parsed statuses.
    let items: Vec<_> = snap
        .items_in_order()
        .iter()
        .map(|i| (i.id.as_str().to_string(), i.title.clone(), i.status))
        .collect();
    assert_eq!(
        items,
        vec![
            (
                "item-1".to_string(),
                "Flow server".to_string(),
                Status::Doing
            ),
            (
                "item-5".to_string(),
                "Roadmap history".to_string(),
                Status::Done
            ),
            ("item-2".to_string(), "Canvas".to_string(), Status::Do),
        ]
    );

    // Edges added: 5->1, 2->1, 2->5.
    let mut edges: Vec<_> = snap
        .edges()
        .iter()
        .map(|e| (e.from.as_str().to_string(), e.to.as_str().to_string()))
        .collect();
    edges.sort();
    assert_eq!(
        edges,
        vec![
            ("item-2".to_string(), "item-1".to_string()),
            ("item-2".to_string(), "item-5".to_string()),
            ("item-5".to_string(), "item-1".to_string()),
        ]
    );
}

#[tokio::test]
async fn ingest_roadmap_skips_rejected_edges_but_keeps_items() {
    // A cyclic dependency is faithfully kept by the parser, but the graph
    // validator refuses the edge that would close the cycle. Ingest must skip
    // that edge gracefully (count it, proceed) rather than aborting — the
    // markdown is the source of truth and a malformed dep must not blank the
    // board. Both items still land, and the one acyclic edge survives.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    let md = "\
## [1] A
> STATUS: PENDING
> DEPENDS ON: #2
## [2] B
> STATUS: PENDING
> DEPENDS ON: #1
";
    let loaded = store.ingest_roadmap(md).await.unwrap();
    assert_eq!(loaded, 2);

    let snap = store.snapshot().await;
    assert!(snap.get(&id("item-1")).is_some());
    assert!(snap.get(&id("item-2")).is_some());
    // Exactly one of the two cyclic edges is accepted; the other is skipped.
    assert_eq!(snap.edges().len(), 1);
}

#[tokio::test]
async fn ingest_empty_roadmap_loads_nothing() {
    // Empty markdown parses to no items: ingest reports zero and the board stays
    // empty (the graceful "nothing to load" path).
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    assert_eq!(store.ingest_roadmap("").await.unwrap(), 0);
    assert!(store.snapshot().await.items_in_order().is_empty());
}

#[tokio::test]
async fn ingest_roadmap_commit_failure_propagates() {
    // The first upsert's commit append faults (events.jsonl is a directory), so
    // ingest surfaces the StoreError rather than swallowing a real IO failure.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    // A fresh store has not written events.jsonl yet; put a directory in its
    // place so the first upsert's commit append faults.
    std::fs::create_dir_all(dir.join("events.jsonl")).unwrap();
    let md = "## [1] A\n> STATUS: PENDING\n";
    assert!(store.ingest_roadmap(md).await.is_err());
}

// ---- .i2p/roadmap/ tree ingest + post_status write-back (roadmap [42]) ----

/// Build a fixture roadmap tree under a fresh temp dir and return its root.
fn tree_fixture() -> std::path::PathBuf {
    let root = tempdir().join("roadmap");
    for (folder, name, body) in [
        (
            "backlog",
            "16-epic.md",
            "---\nid: 16\ntitle: Epic\nstatus: PENDING\ndepends_on: \"—\"\n---\nbody\n",
        ),
        (
            "doing",
            "42-tree.md",
            "---\nid: 42\ntitle: Tree\nstatus: IN PROGRESS\ndepends_on: \"#16\"\n---\nbody\n",
        ),
        (
            "done",
            "01-first.md",
            "---\nid: 1\ntitle: First\nstatus: COMPLETE\n---\nbody\n",
        ),
    ] {
        let dir = root.join(folder);
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join(name), body).unwrap();
    }
    root
}

#[tokio::test]
async fn ingest_roadmap_tree_loads_items_grouped_by_folder() {
    let dir = tempdir();
    let tree = tree_fixture();
    let store = Store::open(&dir).await.unwrap();

    let n = store.ingest_roadmap_tree(&tree).await.unwrap();
    assert_eq!(n, 3);

    let flow = store.snapshot().await;
    let status = |s: &str| {
        flow.items_in_order()
            .iter()
            .find(|i| i.id == id(s))
            .unwrap()
            .status
    };
    assert_eq!(status("item-16"), Status::Do); // backlog → Do
    assert_eq!(status("item-42"), Status::Doing); // doing → Doing
    assert_eq!(status("item-1"), Status::Done); // done → Done
}

#[tokio::test]
async fn post_status_moves_tree_file_and_rewrites_frontmatter() {
    // AC#2: `post_status 42 doing` → 42's file in doing/ with status IN PROGRESS.
    let dir = tempdir();
    let tree = tree_fixture();
    let store = Store::open(&dir).await.unwrap();
    store.ingest_roadmap_tree(&tree).await.unwrap();

    // 16 starts in backlog/. Advance it to Doing.
    store
        .post_status(&id("item-16"), Status::Doing)
        .await
        .unwrap();

    assert!(
        !tree.join("backlog/16-epic.md").exists(),
        "source file must be gone"
    );
    let moved = tree.join("doing/16-epic.md");
    assert!(moved.exists(), "file must move into doing/");
    let contents = std::fs::read_to_string(&moved).unwrap();
    assert!(
        contents.contains("status: IN PROGRESS"),
        "front-matter status must be rewritten, got:\n{contents}"
    );
    assert!(
        contents.contains("id: 16") && contents.contains("body"),
        "rest of the file is preserved"
    );

    // And Done → done/ with COMPLETE.
    store
        .post_status(&id("item-16"), Status::Done)
        .await
        .unwrap();
    assert!(tree.join("done/16-epic.md").exists());
    assert!(std::fs::read_to_string(tree.join("done/16-epic.md"))
        .unwrap()
        .contains("status: COMPLETE"));
}

#[tokio::test]
async fn post_status_without_tree_leaves_disk_untouched() {
    // A non-tree store (single-file/test): post_status mutates memory only.
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .ingest_roadmap("## [9] Nine\n> STATUS: PENDING\n")
        .await
        .unwrap();
    // No roadmap_tree was recorded, so this must not error trying to move a file.
    store
        .post_status(&id("item-9"), Status::Doing)
        .await
        .unwrap();
    let flow = store.snapshot().await;
    assert_eq!(
        flow.items_in_order()
            .iter()
            .find(|i| i.id == id("item-9"))
            .unwrap()
            .status,
        Status::Doing
    );
}

#[tokio::test]
async fn ingest_roadmap_tree_absent_is_empty_not_error() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    let n = store
        .ingest_roadmap_tree(std::path::Path::new("/no/such/tree/at/all"))
        .await
        .unwrap();
    assert_eq!(n, 0);
}

fn tempdir() -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let pid = std::process::id();
    let dir = std::env::temp_dir().join(format!("flow-store-test-{pid}-{n}"));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

// ---------------------------------------------------------------------------
// Gate persistence tests (item [36] — EARS-G36-01 through EARS-G36-08)
// ---------------------------------------------------------------------------

/// EARS-G36-01: After set_gate(wait), gates.json exists and maps the id to "wait".
#[tokio::test]
async fn gates_json_written_on_set_gate_wait() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store.set_gate(&id("item-a"), WaitGate::Wait).await.unwrap();

    let gates_path = dir.join("gates.json");
    assert!(gates_path.exists(), "gates.json must exist after set_gate");
    let raw = std::fs::read_to_string(&gates_path).unwrap();
    let map: std::collections::BTreeMap<String, String> =
        serde_json::from_str(&raw).expect("gates.json must be valid JSON");
    assert_eq!(map.get("item-a").map(|s| s.as_str()), Some("wait"));
}

/// EARS-G36-01: After set_gate(go), gates.json maps the id to "go".
#[tokio::test]
async fn gates_json_updated_on_toggle_to_go() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store.set_gate(&id("item-a"), WaitGate::Wait).await.unwrap();
    store.set_gate(&id("item-a"), WaitGate::Go).await.unwrap();

    let raw = std::fs::read_to_string(dir.join("gates.json")).unwrap();
    let map: std::collections::BTreeMap<String, String> = serde_json::from_str(&raw).unwrap();
    assert_eq!(map.get("item-a").map(|s| s.as_str()), Some("go"));
}

/// EARS-G36-01: gates.json.tmp does not persist after atomic rename.
#[tokio::test]
async fn gates_json_tmp_does_not_linger() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store.set_gate(&id("item-a"), WaitGate::Wait).await.unwrap();
    assert!(
        !dir.join("gates.json.tmp").exists(),
        "gates.json.tmp must not linger after atomic rename"
    );
}

/// EARS-G36-01: gates.json is valid JSON after write (atomic write is complete).
#[tokio::test]
async fn gates_json_atomic_write_is_not_corrupted() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store.set_gate(&id("item-a"), WaitGate::Wait).await.unwrap();
    let raw = std::fs::read_to_string(dir.join("gates.json")).unwrap();
    assert!(
        serde_json::from_str::<serde_json::Value>(&raw).is_ok(),
        "gates.json must be valid JSON"
    );
}

/// EARS-G36-02 + EARS-G36-07: restore_gates after ingest_roadmap restores WAIT.
#[tokio::test]
async fn restore_gates_survives_restart() {
    let dir = tempdir();
    // First store: set gate to wait
    {
        let store = Store::open(&dir).await.unwrap();
        store
            .upsert_item(id("item-a"), "Alpha".into(), "m".into())
            .await
            .unwrap();
        store.set_gate(&id("item-a"), WaitGate::Wait).await.unwrap();
    }
    // Second store: open fresh, ingest roadmap (which resets gate to Go), then restore_gates
    let store2 = Store::open(&dir).await.unwrap();
    // Simulate ingest_roadmap resetting gates by upserting (which uses Item::new → Go default)
    store2
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    // After upsert, gate is Go (reset by upsert). Now restore_gates should re-apply Wait.
    store2.restore_gates().await;
    let snap = store2.snapshot().await;
    assert_eq!(
        snap.get(&id("item-a")).unwrap().gate,
        WaitGate::Wait,
        "restore_gates must re-apply Wait gate after ingest resets it"
    );
}

/// EARS-G36-03: Missing gates.json does not crash; all gates default to go.
#[tokio::test]
async fn missing_gates_json_does_not_prevent_restore() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    // No gates.json written. restore_gates must succeed silently.
    store.restore_gates().await;
    let snap = store.snapshot().await;
    assert_eq!(snap.get(&id("item-a")).unwrap().gate, WaitGate::Go);
}

/// EARS-G36-04: Corrupt gates.json does not crash; all gates default to go.
#[tokio::test]
async fn corrupt_gates_json_does_not_prevent_restore() {
    let dir = tempdir();
    std::fs::write(dir.join("gates.json"), b"{not valid json}").unwrap();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store.restore_gates().await;
    let snap = store.snapshot().await;
    assert_eq!(snap.get(&id("item-a")).unwrap().gate, WaitGate::Go);
}

/// EARS-G36-04: Empty gates.json does not crash; all gates default to go.
#[tokio::test]
async fn empty_gates_json_does_not_prevent_restore() {
    let dir = tempdir();
    std::fs::write(dir.join("gates.json"), b"").unwrap();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store.restore_gates().await;
    let snap = store.snapshot().await;
    assert_eq!(snap.get(&id("item-a")).unwrap().gate, WaitGate::Go);
}

/// EARS-G36-05: Stale item ID in gates.json is silently discarded; known items restored.
#[tokio::test]
async fn stale_item_in_gates_json_is_silently_discarded() {
    let dir = tempdir();
    // gates.json has a ghost item (not in store) and a real item.
    std::fs::write(
        dir.join("gates.json"),
        br#"{"ghost-item": "wait", "item-a": "wait"}"#,
    )
    .unwrap();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    // No crash, no error.
    store.restore_gates().await;
    let snap = store.snapshot().await;
    // Known item is restored.
    assert_eq!(snap.get(&id("item-a")).unwrap().gate, WaitGate::Wait);
    // Ghost item has no effect (absent from store).
    assert!(snap.get(&id("ghost-item")).is_none());
}

/// EARS-G36-07: ingest_roadmap resets gates; restore_gates after ingest re-applies them.
/// This is the sequencing test: proves the correct call order in main.rs.
/// The roadmap parser derives item IDs as "item-N" from "[N] Title" headers.
#[tokio::test]
async fn restore_gates_after_ingest_roadmap_preserves_wait() {
    let dir = tempdir();
    // Write a gates.json showing item-1 (the ID the roadmap parser assigns to "[1] Alpha") as Wait.
    std::fs::write(dir.join("gates.json"), br#"{"item-1": "wait"}"#).unwrap();

    let store = Store::open(&dir).await.unwrap();
    // ingest_roadmap: upserts items (resets gate to Go via Item::new default).
    // The "[1] Alpha" header generates id "item-1".
    let md = "## [1] Alpha\n> STATUS: PENDING\n> DEPENDS ON: —\n";
    store.ingest_roadmap(md).await.unwrap();

    // After ingest, gate is Go (reset by upsert).
    {
        let snap = store.snapshot().await;
        assert_eq!(
            snap.get(&id("item-1")).unwrap().gate,
            WaitGate::Go,
            "gate should be Go after ingest (before restore)"
        );
    }

    // Now restore_gates — this is what main.rs does after ingest_roadmap.
    store.restore_gates().await;

    let snap = store.snapshot().await;
    assert_eq!(
        snap.get(&id("item-1")).unwrap().gate,
        WaitGate::Wait,
        "restore_gates after ingest must re-apply Wait"
    );
}

/// EARS-G36-08: set_gate succeeds even when the sidecar write faults (warn-and-continue).
/// We simulate a write fault by replacing the .flow/ dir with a path where the tmp file
/// cannot be written (put a file where the directory would be — not applicable since
/// the directory already exists). Instead, replace gates.json with a directory so
/// the rename target is a directory (rename onto a directory is an error on Linux).
#[tokio::test]
async fn set_gate_succeeds_when_sidecar_write_faults() {
    let dir = tempdir();
    let store = Store::open(&dir).await.unwrap();
    store
        .upsert_item(id("item-a"), "Alpha".into(), "m".into())
        .await
        .unwrap();
    // Put a directory where gates.json would be so the atomic rename faults.
    std::fs::create_dir_all(dir.join("gates.json")).unwrap();
    // set_gate must still return Ok (warn-and-continue, not fail).
    let result = store.set_gate(&id("item-a"), WaitGate::Wait).await;
    assert!(
        result.is_ok(),
        "set_gate must succeed even when sidecar write faults"
    );
    // In-memory gate is updated.
    let snap = store.snapshot().await;
    assert_eq!(snap.get(&id("item-a")).unwrap().gate, WaitGate::Wait);
}
