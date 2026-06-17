//! MCP contract: the JSON-RPC verb surface driven directly through
//! `mcp::dispatch` (the stdio transport's entry point — the HTTP `/mcp` route was
//! removed in roadmap #39). A `validate_connection` that would cycle is rejected
//! with a typed error and the graph is unchanged; `list_items` returns the items.

use std::sync::Arc;

use crate::api::AppState;
use crate::auth::Token;
use crate::mcp;
use crate::store::Store;

use serde_json::Value;

fn tempdir() -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-mcp-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

async fn seeded() -> (AppState, Arc<Store>) {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());
    for s in ["a", "b"] {
        store
            .upsert_item(
                crate::domain::ItemId::new(s).unwrap(),
                s.to_uppercase(),
                "claude-sonnet-4-6".into(),
            )
            .await
            .unwrap();
    }
    let state = AppState {
        store: Arc::clone(&store),
        token: Token::new("tok"),
    };
    (state, store)
}

/// Dispatch a JSON-RPC request `Value` and return the response `Value`.
async fn rpc(state: &AppState, body: Value) -> Value {
    mcp::dispatch(state, body).await
}

#[tokio::test]
async fn mcp_list_items() {
    // The response shape is grouped:
    // {"pending":{"wait":[...],"go":[...]},"in_progress":[...],"done":[...]}
    // Both seeded items are PENDING/GO, so they appear in pending.go.
    let (state, _store) = seeded().await;
    let v = rpc(
        &state,
        serde_json::json!({
            "jsonrpc":"2.0","id":1,
            "method":"tools/call",
            "params":{"name":"list_items","arguments":{}}
        }),
    )
    .await;
    let pending_go = v["result"]["pending"]["go"].as_array().unwrap();
    assert_eq!(pending_go.len(), 2);
    // The old "items" flat array must not be present.
    assert!(
        v["result"]["items"].is_null(),
        "old flat 'items' key must not be present"
    );
}

/// EARS-G36-06: list_items groups PENDING items by gate.
#[tokio::test]
async fn list_items_groups_pending_by_gate() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());

    // Seed four items: pending/wait, pending/go, doing/go, done/go.
    for (slug, title) in [
        ("pw", "PendWait"),
        ("pg", "PendGo"),
        ("dg", "Doing"),
        ("dn", "Done"),
    ] {
        store
            .upsert_item(
                crate::domain::ItemId::new(slug).unwrap(),
                title.to_string(),
                "claude-sonnet-4-6".into(),
            )
            .await
            .unwrap();
    }
    // Set pw to Wait
    store
        .set_gate(
            &crate::domain::ItemId::new("pw").unwrap(),
            crate::domain::WaitGate::Wait,
        )
        .await
        .unwrap();
    // Advance dg to Doing
    store
        .post_status(
            &crate::domain::ItemId::new("dg").unwrap(),
            crate::domain::Status::Doing,
        )
        .await
        .unwrap();
    // Advance dn to Done
    store
        .post_status(
            &crate::domain::ItemId::new("dn").unwrap(),
            crate::domain::Status::Done,
        )
        .await
        .unwrap();

    let state = AppState {
        store: Arc::clone(&store),
        token: Token::new("tok"),
    };
    let v = call(&state, "list_items", serde_json::json!({})).await;

    let wait = v["result"]["pending"]["wait"].as_array().unwrap();
    assert_eq!(wait.len(), 1);
    assert_eq!(wait[0]["id"], "pw");

    let go = v["result"]["pending"]["go"].as_array().unwrap();
    assert_eq!(go.len(), 1);
    assert_eq!(go[0]["id"], "pg");

    let in_progress = v["result"]["in_progress"].as_array().unwrap();
    assert_eq!(in_progress.len(), 1);
    assert_eq!(in_progress[0]["id"], "dg");

    let done = v["result"]["done"].as_array().unwrap();
    assert_eq!(done.len(), 1);
    assert_eq!(done[0]["id"], "dn");
}

/// EARS-G36-06: Empty store returns all groups as empty arrays.
#[tokio::test]
async fn list_items_empty_store_returns_empty_groups() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());
    let state = AppState {
        store,
        token: Token::new("tok"),
    };
    let v = call(&state, "list_items", serde_json::json!({})).await;

    assert_eq!(v["result"]["pending"]["wait"].as_array().unwrap().len(), 0);
    assert_eq!(v["result"]["pending"]["go"].as_array().unwrap().len(), 0);
    assert_eq!(v["result"]["in_progress"].as_array().unwrap().len(), 0);
    assert_eq!(v["result"]["done"].as_array().unwrap().len(), 0);
}

/// EARS-G36-06: All PENDING/GO items leave wait group empty.
#[tokio::test]
async fn list_items_all_pending_go_wait_empty() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());
    for slug in ["x", "y"] {
        store
            .upsert_item(
                crate::domain::ItemId::new(slug).unwrap(),
                slug.to_uppercase(),
                "claude-sonnet-4-6".into(),
            )
            .await
            .unwrap();
    }
    let state = AppState {
        store,
        token: Token::new("tok"),
    };
    let v = call(&state, "list_items", serde_json::json!({})).await;

    assert_eq!(v["result"]["pending"]["wait"].as_array().unwrap().len(), 0);
    assert_eq!(v["result"]["pending"]["go"].as_array().unwrap().len(), 2);
}

#[tokio::test]
async fn mcp_cycle_rejected() {
    let (state, store) = seeded().await;
    // add a->b
    let _ = rpc(
        &state,
        serde_json::json!({
            "jsonrpc":"2.0","id":1,
            "method":"tools/call",
            "params":{"name":"mutate_connection","arguments":{"op":"add","from":"a","to":"b"}}
        }),
    )
    .await;

    // validate b->a would cycle: typed JSON-RPC error, graph unchanged.
    let v = rpc(
        &state,
        serde_json::json!({
            "jsonrpc":"2.0","id":2,
            "method":"tools/call",
            "params":{"name":"validate_connection","arguments":{"from":"b","to":"a"}}
        }),
    )
    .await;
    assert_eq!(v["error"]["data"]["error"], "cycle");
    assert_eq!(store.snapshot().await.edges().len(), 1);
}

/// Call the `tools/call` verb `name` with `arguments`, returning the response.
async fn call(state: &AppState, name: &str, arguments: serde_json::Value) -> serde_json::Value {
    rpc(
        state,
        serde_json::json!({
            "jsonrpc":"2.0","id":1,
            "method":"tools/call",
            "params":{"name":name,"arguments":arguments}
        }),
    )
    .await
}

#[tokio::test]
async fn mcp_render_roadmap_returns_local_compute_view() {
    let (state, _store) = seeded().await;
    let v = call(&state, "render_roadmap", serde_json::json!({})).await;
    let rendered = v["result"]["rendered"].as_str().unwrap();
    assert!(rendered.starts_with("ROADMAP\n2 item(s)\n"));
    assert!(rendered.contains("· a · A · DO · GO · 0 tok · d0"));
}

#[tokio::test]
async fn mcp_annotate_happy_unknown_and_bad_body() {
    let (state, store) = seeded().await;
    // Happy.
    let v = call(
        &state,
        "annotate",
        serde_json::json!({"id":"a","text":"tighten it"}),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
    let events = store.read_events().await.unwrap();
    assert!(events
        .iter()
        .any(|e| matches!(e, crate::domain::Event::Annotated { .. })));

    // Unknown item → typed JSON-RPC error.
    let v = call(
        &state,
        "annotate",
        serde_json::json!({"id":"nope","text":"x"}),
    )
    .await;
    assert_eq!(v["error"]["data"]["error"], "unknown");

    // Bad body (missing `text`) → invalid params.
    let v = call(&state, "annotate", serde_json::json!({"id":"a"})).await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn mcp_request_rewrite_happy_unknown_and_bad_body() {
    let (state, store) = seeded().await;
    // Happy: draft increments.
    let v = call(
        &state,
        "request_rewrite",
        serde_json::json!({"id":"a","comment":"redo"}),
    )
    .await;
    assert_eq!(v["result"]["draft"], 1);
    assert_eq!(
        store
            .snapshot()
            .await
            .get(&crate::domain::ItemId::new("a").unwrap())
            .unwrap()
            .draft,
        1
    );

    // Unknown item → typed error.
    let v = call(
        &state,
        "request_rewrite",
        serde_json::json!({"id":"nope","comment":"x"}),
    )
    .await;
    assert_eq!(v["error"]["data"]["error"], "unknown");

    // Bad body (missing `comment`) → invalid params.
    let v = call(&state, "request_rewrite", serde_json::json!({"id":"a"})).await;
    assert_eq!(v["error"]["code"], -32602);
}
