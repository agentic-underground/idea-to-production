//! Unit tests for `mcp::dispatch` — calls the dispatch function directly
//! (not through the HTTP router), providing coverage for the stdio code path
//! that the existing HTTP-routed tests cannot reach.
//!
//! These tests are WRITTEN FIRST (step 3) before the implementation (step 5),
//! per TDD discipline. They will fail to compile until T37-1 (mcp::dispatch
//! extraction) is complete.
//!
//! Traces to: EVT-37-6, EVT-37-2 (dispatch correctness)

use std::sync::Arc;

use serde_json::{json, Value};

use crate::api::AppState;
use crate::auth::Token;
use crate::domain::ItemId;
use crate::mcp;
use crate::store::Store;

fn tempdir(tag: &str) -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-dispatch-{tag}-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

/// Build an AppState suitable for dispatch unit tests — uses a dummy token
/// (never verified in the dispatch path, only in the HTTP auth middleware).
async fn make_state(tag: &str) -> AppState {
    let dir = tempdir(tag);
    let store = Arc::new(Store::open(&dir).await.unwrap());
    AppState {
        store,
        token: Token::new("stdio-noop"),
    }
}

/// Build a state with a single item pre-seeded.
async fn make_state_with_item(tag: &str) -> (AppState, ItemId) {
    let state = make_state(tag).await;
    let id = ItemId::new("i1").unwrap();
    state
        .store
        .upsert_item(id.clone(), "Item One".into(), "claude-sonnet-4-6".into())
        .await
        .unwrap();
    (state, id)
}

// ---------------------------------------------------------------------------
// T37-5: Test all five primary tools + error paths through mcp::dispatch
// ---------------------------------------------------------------------------

#[tokio::test]
async fn dispatch_list_items_returns_grouped_shape() {
    let state = make_state("list").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": { "name": "list_items", "arguments": {} }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0", "must be JSON-RPC 2.0");
    assert_eq!(resp["id"], 1, "id must echo the request id");
    let result = &resp["result"];
    assert!(result.is_object(), "result must be an object");
    assert!(result["pending"].is_object(), "pending must be an object");
    assert!(
        result["pending"]["wait"].is_array(),
        "pending.wait must be array"
    );
    assert!(
        result["pending"]["go"].is_array(),
        "pending.go must be array"
    );
    assert!(
        result["in_progress"].is_array(),
        "in_progress must be array"
    );
    assert!(result["done"].is_array(), "done must be array");
}

#[tokio::test]
async fn dispatch_render_roadmap_returns_rendered_string() {
    let state = make_state("render").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": { "name": "render_roadmap", "arguments": {} }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 2);
    assert!(
        resp["result"]["rendered"].is_string(),
        "result.rendered must be a string, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_post_status_updates_item() {
    let (state, id) = make_state_with_item("post-status").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "post_status",
            "arguments": { "id": id.as_str(), "status": "doing" }
        }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 3);
    assert_eq!(
        resp["result"]["ok"],
        json!(true),
        "post_status should return ok:true, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_set_gate_updates_gate() {
    let (state, id) = make_state_with_item("set-gate").await;
    // set_wait_go is the MCP tool name for gate control
    let req = json!({
        "jsonrpc": "2.0",
        "id": 4,
        "method": "tools/call",
        "params": {
            "name": "set_wait_go",
            "arguments": { "id": id.as_str(), "gate": "go" }
        }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 4);
    assert_eq!(
        resp["result"]["ok"],
        json!(true),
        "set_wait_go should return ok:true, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_append_spend_records_total() {
    let (state, id) = make_state_with_item("append-spend").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 5,
        "method": "tools/call",
        "params": {
            "name": "append_spend",
            "arguments": { "id": id.as_str(), "delta": 100 }
        }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 5);
    assert_eq!(
        resp["result"]["total"],
        json!(100),
        "append_spend should return total:100, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_unknown_tool_returns_32602() {
    let state = make_state("unknown-tool").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 6,
        "method": "tools/call",
        "params": { "name": "no_such_tool", "arguments": {} }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 6);
    assert_eq!(
        resp["error"]["code"],
        json!(-32602),
        "unknown tool must return -32602, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_unknown_method_returns_32601() {
    let state = make_state("unknown-method").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 7,
        "method": "unknown/method",
        "params": {}
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 7);
    assert_eq!(
        resp["error"]["code"],
        json!(-32601),
        "unknown method must return -32601, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_initialize_completes_handshake() {
    let state = make_state("initialize").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": { "name": "probe", "version": "0" }
        }
    });
    let resp = mcp::dispatch(&state, req).await;
    assert!(
        resp.get("error").is_none(),
        "initialize must not error, got: {resp:?}"
    );
    assert_eq!(resp["result"]["protocolVersion"], "2024-11-05");
    assert!(
        resp["result"]["capabilities"]["tools"].is_object(),
        "must advertise the tools capability, got: {resp:?}"
    );
    assert_eq!(resp["result"]["serverInfo"]["name"], "flow-server");
}

#[tokio::test]
async fn dispatch_initialized_notification_yields_no_response() {
    let state = make_state("initialized-notif").await;
    let req = json!({ "jsonrpc": "2.0", "method": "notifications/initialized" });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(
        resp,
        Value::Null,
        "the initialized notification must produce no JSON-RPC response"
    );
}

#[tokio::test]
async fn dispatch_tools_list_returns_descriptor_objects() {
    let state = make_state("tools-list-objects").await;
    let req = json!({ "jsonrpc": "2.0", "id": 1, "method": "tools/list" });
    let resp = mcp::dispatch(&state, req).await;
    let tools = resp["result"]["tools"].as_array().unwrap();
    assert_eq!(tools.len(), 13);
    for t in tools {
        assert!(t["name"].is_string(), "descriptor missing name: {t:?}");
        assert!(
            t["inputSchema"].is_object(),
            "descriptor missing inputSchema: {t:?}"
        );
    }
}

#[tokio::test]
async fn dispatch_tools_list_returns_tool_array() {
    let state = make_state("tools-list").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": 8,
        "method": "tools/list",
        "params": {}
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["jsonrpc"], "2.0");
    assert_eq!(resp["id"], 8);
    assert!(
        resp["result"]["tools"].is_array(),
        "tools/list result.tools must be array, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn dispatch_id_echoed_correctly_for_string_id() {
    let state = make_state("string-id").await;
    let req = json!({
        "jsonrpc": "2.0",
        "id": "abc-123",
        "method": "tools/list",
        "params": {}
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["id"], json!("abc-123"), "string ids must be echoed");
}

#[tokio::test]
async fn dispatch_missing_id_uses_null() {
    let state = make_state("no-id").await;
    let req = json!({
        "jsonrpc": "2.0",
        "method": "tools/list"
    });
    let resp = mcp::dispatch(&state, req).await;
    assert_eq!(resp["id"], Value::Null, "absent id must echo as null");
}
