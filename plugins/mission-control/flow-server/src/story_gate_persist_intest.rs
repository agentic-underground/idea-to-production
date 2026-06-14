//! Story tests for item [36]: gate state persists across restarts and surfaces
//! in list_items MCP grouping.
//!
//! These are end-to-end stories that exercise the full request stack (store +
//! router + HTTP handler) and simulate restart by reopening the store from the
//! same `.flow/` directory with a fresh `Store::open()` call. This is the
//! closest possible simulation to an actual server restart within the test
//! binary without spawning a separate process.
//!
//! Story tests are mandatory per the FOUNDRY orchestration rules and must emit
//! `STORY_PROVEN` before the pipeline can advance to sync/commit.

use std::sync::Arc;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use serde_json::{json, Value};
use tower::ServiceExt;

use crate::api::build_router;
use crate::auth::Token;
use crate::domain::ItemId;
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

/// Issue an authenticated request on a one-shot router, return (status, body).
async fn req(
    router: &axum::Router,
    method: &str,
    uri: &str,
    body: Option<Value>,
) -> (StatusCode, Value) {
    let mut builder = Request::builder()
        .method(method)
        .uri(uri)
        .header("Authorization", format!("Bearer {TOK}"));
    let body = match body {
        Some(v) => {
            builder = builder.header("content-type", "application/json");
            Body::from(v.to_string())
        }
        None => Body::empty(),
    };
    let resp = router
        .clone()
        .oneshot(builder.body(body).unwrap())
        .await
        .unwrap();
    let status = resp.status();
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let v: Value = serde_json::from_slice(&bytes).unwrap_or(Value::Null);
    (status, v)
}

/// Issue a JSON-RPC call and return the parsed body.
async fn mcp_call(router: &axum::Router, name: &str, args: Value) -> Value {
    let body = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {"name": name, "arguments": args}
    });
    let (_, v) = req(router, "POST", "/mcp", Some(body)).await;
    v
}

// ---------------------------------------------------------------------------
// STORY-G36-01: Persist and restore gate state across a simulated restart
// ---------------------------------------------------------------------------
//
// Steps:
//   1. Start store with a temp .flow/ dir, seed item "item-a"
//   2. POST /api/items/item-a/gate {"gate": "wait"}
//   3. "Restart": drop the store, reopen from same dir, call restore_gates()
//   4. GET /api/items — item-a must have gate: "wait"
//   5. MCP list_items — pending.wait must contain item-a

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
        let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));

        let (status, _) = req(
            &router,
            "POST",
            "/api/items/item-a/gate",
            Some(json!({"gate": "wait"})),
        )
        .await;
        assert_eq!(status, StatusCode::OK, "POST gate must succeed");

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

        let router2 = build_router(Arc::clone(&store2), Token::new(TOK), dir.join("static"));

        // GET /api/items — item-a must be "wait"
        let (status, body) = req(&router2, "GET", "/api/items", None).await;
        assert_eq!(status, StatusCode::OK);
        let items = body.as_array().unwrap();
        let item_a = items.iter().find(|i| i["id"] == "item-a").unwrap();
        assert_eq!(
            item_a["gate"], "wait",
            "STORY-G36-01: gate must be 'wait' after restart"
        );

        // MCP list_items — pending.wait must contain item-a
        let v = mcp_call(&router2, "list_items", json!({})).await;
        let wait = v["result"]["pending"]["wait"].as_array().unwrap();
        assert!(
            wait.iter().any(|i| i["id"] == "item-a"),
            "STORY-G36-01: item-a must be in pending.wait after restart"
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
//   4. Verify server is healthy (GET /api/items returns 200)
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

    let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));

    // Server is healthy
    let (status, body) = req(&router, "GET", "/api/items", None).await;
    assert_eq!(
        status,
        StatusCode::OK,
        "STORY-G36-02: server must be healthy despite corrupt gates.json"
    );

    // All items have gate: "go"
    let items = body.as_array().unwrap();
    assert!(!items.is_empty(), "STORY-G36-02: items must be present");
    for item in items {
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

    let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));

    let (status, body) = req(&router, "GET", "/api/items", None).await;
    assert_eq!(
        status,
        StatusCode::OK,
        "STORY-G36-03: server must be healthy with no gates.json"
    );
    let items = body.as_array().unwrap();
    assert!(
        items.iter().all(|i| i["gate"] == "go"),
        "STORY-G36-03: all gates must be 'go'"
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

    let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));
    let v = mcp_call(&router, "list_items", json!({})).await;

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

    let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));

    // Initially GO → in pending.go
    let v = mcp_call(&router, "list_items", json!({})).await;
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert!(
        go.iter().any(|i| i["id"] == "item-a"),
        "initially in pending.go"
    );

    // Toggle to WAIT
    let (status, _) = req(
        &router,
        "POST",
        "/api/items/item-a/gate",
        Some(json!({"gate": "wait"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);

    // Now in pending.wait
    let v = mcp_call(&router, "list_items", json!({})).await;
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
    let (status, _) = req(
        &router,
        "POST",
        "/api/items/item-a/gate",
        Some(json!({"gate": "go"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);

    // Back in pending.go
    let v = mcp_call(&router, "list_items", json!({})).await;
    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert!(
        go.iter().any(|i| i["id"] == "item-a"),
        "STORY-G36-05: after toggle back, item in pending.go"
    );
}
