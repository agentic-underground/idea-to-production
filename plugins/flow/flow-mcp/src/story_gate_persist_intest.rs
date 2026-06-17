//! Story tests for item [36]: gate state persists across restarts and surfaces
//! in list_items MCP grouping.
//!
//! These are end-to-end stories that exercise the full stack (store + the MCP
//! dispatch surface) and simulate restart by reopening the store from the same
//! `.flow/` directory with a fresh `Store::open()` call. This is the closest
//! possible simulation to an actual server restart within the test binary
//! without spawning a separate process.
//!
//! The web UI was removed in roadmap #39, so the gate is set and read through the
//! MCP verbs (`set_wait_go`, `list_items`) via `mcp::dispatch` rather than the
//! removed HTTP REST surface.
//!
//! Story tests are mandatory per the FOUNDRY orchestration rules and must emit
//! `STORY_PROVEN` before the pipeline can advance to sync/commit.

use std::sync::Arc;

use serde_json::{json, Value};

use crate::api::AppState;
use crate::auth::Token;
use crate::domain::ItemId;
use crate::mcp;
use crate::store::Store;

const TOK: &str = "story-tok";

fn tempdir(tag: &str) -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir =
        std::env::temp_dir().join(format!("flow-story-gate-{tag}-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

/// Build an AppState over a store (the stdio dispatch surface takes no auth).
fn state(store: Arc<Store>) -> AppState {
    AppState {
        store,
        token: Token::new(TOK),
    }
}

/// Issue a JSON-RPC `tools/call` through `mcp::dispatch` and return the response.
async fn mcp_call(state: &AppState, name: &str, args: Value) -> Value {
    let body = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {"name": name, "arguments": args}
    });
    mcp::dispatch(state, body).await
}

// ---------------------------------------------------------------------------
// STORY-G36-01: Persist and restore gate state across a simulated restart
// ---------------------------------------------------------------------------
//
// Steps:
//   1. Start store with a temp .flow/ dir, seed item "item-a"
//   2. set_wait_go {"id":"item-a","gate":"wait"}
//   3. "Restart": drop the store, reopen from same dir, call restore_gates()
//   4. list_items — pending.wait must contain item-a; item-a's gate is "wait"

#[tokio::test]
async fn story_g36_01_gate_wait_survives_restart() {
    let dir = tempdir("restart");

    // --- Phase 1: set gate to wait ---
    {
        let store = Arc::new(Store::open(&dir).await.unwrap());
        store
            .upsert_item(ItemId::new("item-a").unwrap(), "Alpha".into(), "m".into())
            .await
            .unwrap();
        let st = state(Arc::clone(&store));

        let v = mcp_call(&st, "set_wait_go", json!({"id":"item-a","gate":"wait"})).await;
        assert_eq!(v["result"]["ok"], true, "set_wait_go must succeed");

        // Verify gates.json was written
        assert!(
            dir.join("gates.json").exists(),
            "gates.json must exist after set_gate"
        );
    }

    // --- Phase 2: simulated restart --- reopen store, ingest "roadmap", restore gates ---
    {
        // A real restart calls: Store::open → ingest_roadmap → restore_gates.
        // We simulate by: Store::open (replays JSONL) → upsert item (simulating ingest resets gate) → restore_gates
        let store2 = Arc::new(Store::open(&dir).await.unwrap());
        // Simulate ingest_roadmap resetting gate (upsert uses Item::new default = Go)
        store2
            .upsert_item(ItemId::new("item-a").unwrap(), "Alpha".into(), "m".into())
            .await
            .unwrap();
        // restore_gates re-applies gates from gates.json (AFTER upsert)
        store2.restore_gates().await;

        let st = state(Arc::clone(&store2));

        // list_items — item-a must be in pending.wait with gate "wait"
        let v = mcp_call(&st, "list_items", json!({})).await;
        let wait = v["result"]["pending"]["wait"].as_array().unwrap();
        let item_a = wait
            .iter()
            .find(|i| i["id"] == "item-a")
            .expect("STORY-G36-01: item-a must be in pending.wait after restart");
        assert_eq!(
            item_a["gate"], "wait",
            "STORY-G36-01: gate must be 'wait' after restart"
        );
        let go = v["result"]["pending"]["go"].as_array().unwrap();
        assert!(
            !go.iter().any(|i| i["id"] == "item-a"),
            "STORY-G36-01: item-a must NOT be in pending.go after restart"
        );
    }
}

// ---------------------------------------------------------------------------
// STORY-G36-02: Resilient cold start with corrupt gates.json
// ---------------------------------------------------------------------------
//
// Steps:
//   1. Write corrupt JSON to .flow/gates.json
//   2. Open a new Store (simulating server start)
//   3. Seed an item, call restore_gates
//   4. Verify the surface is healthy (list_items returns a grouped result)
//   5. Verify all items have gate: "go"

#[tokio::test]
async fn story_g36_02_corrupt_gates_json_cold_start() {
    let dir = tempdir("corrupt");

    // Write corrupt gates.json before starting
    std::fs::write(dir.join("gates.json"), b"{not valid json at all}").unwrap();

    // Open the store (restore_gates will be called after seeding)
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(ItemId::new("item-a").unwrap(), "Alpha".into(), "m".into())
        .await
        .unwrap();
    store
        .upsert_item(ItemId::new("item-b").unwrap(), "Beta".into(), "m".into())
        .await
        .unwrap();

    // restore_gates with corrupt file: must not crash, all gates default to go
    store.restore_gates().await; // infallible

    let st = state(Arc::clone(&store));

    // Surface is healthy: list_items returns a grouped result, all items in go.
    let v = mcp_call(&st, "list_items", json!({})).await;
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert_eq!(
        go.len(),
        2,
        "STORY-G36-02: both items must default to 'go' when gates.json is corrupt"
    );
    let wait = v["result"]["pending"]["wait"].as_array().unwrap();
    assert!(
        wait.is_empty(),
        "STORY-G36-02: no item must be in wait after a corrupt gates.json"
    );
    for item in go {
        assert_eq!(
            item["gate"], "go",
            "STORY-G36-02: all items must default to 'go' when gates.json is corrupt"
        );
    }
}

// ---------------------------------------------------------------------------
// STORY-G36-03: Missing gates.json cold start
// ---------------------------------------------------------------------------

#[tokio::test]
async fn story_g36_03_missing_gates_json_cold_start() {
    let dir = tempdir("missing");

    // No gates.json in dir (fresh directory)
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(ItemId::new("item-x").unwrap(), "X".into(), "m".into())
        .await
        .unwrap();
    store.restore_gates().await; // must not crash

    let st = state(Arc::clone(&store));

    let v = mcp_call(&st, "list_items", json!({})).await;
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert!(
        go.iter().all(|i| i["gate"] == "go"),
        "STORY-G36-03: all gates must be 'go'"
    );
    assert!(
        go.iter().any(|i| i["id"] == "item-x"),
        "STORY-G36-03: item-x must be present and in go"
    );
}

// ---------------------------------------------------------------------------
// STORY-G36-04: list_items grouping story
// ---------------------------------------------------------------------------
//
// Steps:
//   1. Seed items: one pending/wait, one pending/go, one doing/go, one done/go
//   2. Call list_items MCP
//   3. Verify grouped shape with correct membership

#[tokio::test]
async fn story_g36_04_list_items_grouping() {
    let dir = tempdir("grouping");
    let store = Arc::new(Store::open(&dir).await.unwrap());

    // Seed items
    for (slug, title) in [
        ("pw", "PendWait"),
        ("pg", "PendGo"),
        ("dg", "Doing"),
        ("dn", "Done"),
    ] {
        store
            .upsert_item(ItemId::new(slug).unwrap(), title.into(), "m".into())
            .await
            .unwrap();
    }
    // Set pw to Wait
    store
        .set_gate(&ItemId::new("pw").unwrap(), crate::domain::WaitGate::Wait)
        .await
        .unwrap();
    // Advance dg to Doing (must set gate to Go first — pg is already Go by default)
    store
        .post_status(&ItemId::new("dg").unwrap(), crate::domain::Status::Doing)
        .await
        .unwrap();
    // Advance dn to Done
    store
        .post_status(&ItemId::new("dn").unwrap(), crate::domain::Status::Done)
        .await
        .unwrap();

    let st = state(Arc::clone(&store));
    let v = mcp_call(&st, "list_items", json!({})).await;

    // pending.wait: only "pw"
    let wait = v["result"]["pending"]["wait"].as_array().unwrap();
    assert_eq!(
        wait.len(),
        1,
        "STORY-G36-04: exactly 1 item in pending.wait"
    );
    assert_eq!(wait[0]["id"], "pw");

    // pending.go: only "pg"
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert_eq!(go.len(), 1, "STORY-G36-04: exactly 1 item in pending.go");
    assert_eq!(go[0]["id"], "pg");

    // in_progress: only "dg"
    let in_prog = v["result"]["in_progress"].as_array().unwrap();
    assert_eq!(
        in_prog.len(),
        1,
        "STORY-G36-04: exactly 1 item in in_progress"
    );
    assert_eq!(in_prog[0]["id"], "dg");

    // done: only "dn"
    let done = v["result"]["done"].as_array().unwrap();
    assert_eq!(done.len(), 1, "STORY-G36-04: exactly 1 item in done");
    assert_eq!(done[0]["id"], "dn");

    // No top-level "items" key (old shape)
    assert!(
        v["result"]["items"].is_null(),
        "STORY-G36-04: old flat 'items' key must not be present"
    );

    // Item objects include required fields
    assert!(wait[0]["id"].is_string(), "id field present");
    assert!(wait[0]["title"].is_string(), "title field present");
    assert!(wait[0]["gate"].is_string(), "gate field present");
    assert_eq!(wait[0]["gate"], "wait", "gate value correct");
}

// ---------------------------------------------------------------------------
// STORY-G36-05: Gate toggle affects list_items grouping in real-time
// ---------------------------------------------------------------------------

#[tokio::test]
async fn story_g36_05_gate_toggle_updates_list_items_grouping() {
    let dir = tempdir("toggle");
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(ItemId::new("item-a").unwrap(), "Alpha".into(), "m".into())
        .await
        .unwrap();

    let st = state(Arc::clone(&store));

    // Initially GO → in pending.go
    let v = mcp_call(&st, "list_items", json!({})).await;
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert!(
        go.iter().any(|i| i["id"] == "item-a"),
        "initially in pending.go"
    );

    // Toggle to WAIT via the set_wait_go verb
    let v = mcp_call(&st, "set_wait_go", json!({"id":"item-a","gate":"wait"})).await;
    assert_eq!(v["result"]["ok"], true);

    // Now in pending.wait
    let v = mcp_call(&st, "list_items", json!({})).await;
    let wait = v["result"]["pending"]["wait"].as_array().unwrap();
    assert!(
        wait.iter().any(|i| i["id"] == "item-a"),
        "STORY-G36-05: after toggle, item in pending.wait"
    );
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert!(
        !go.iter().any(|i| i["id"] == "item-a"),
        "STORY-G36-05: item not in pending.go after toggle"
    );

    // Toggle back to GO
    let v = mcp_call(&st, "set_wait_go", json!({"id":"item-a","gate":"go"})).await;
    assert_eq!(v["result"]["ok"], true);

    // Back in pending.go
    let v = mcp_call(&st, "list_items", json!({})).await;
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert!(
        go.iter().any(|i| i["id"] == "item-a"),
        "STORY-G36-05: after toggle back, item in pending.go"
    );
}
