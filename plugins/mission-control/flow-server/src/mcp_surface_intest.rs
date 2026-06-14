//! Exhaustive MCP JSON-RPC surface contract: tools/list, every one of the
//! thirteen `tools/call` verbs (happy + error/abuse/malformed-params), the
//! unknown-tool and unknown-method envelopes, and the 401/no-token gate. Drives
//! the real axum router via `oneshot`.

use std::sync::Arc;

use crate::api::build_router;
use crate::auth::Token;
use crate::domain::ItemId;
use crate::store::Store;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use serde_json::{json, Value};
use tower::ServiceExt;

const TOK: &str = "tok";

fn tempdir(tag: &str) -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-mcps-{tag}-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

async fn seeded(tag: &str) -> (axum::Router, Arc<Store>) {
    let dir = tempdir(tag);
    let store = Arc::new(Store::open(&dir).await.unwrap());
    for s in ["a", "b"] {
        store
            .upsert_item(
                ItemId::new(s).unwrap(),
                s.to_uppercase(),
                "claude-sonnet-4-6".into(),
            )
            .await
            .unwrap();
    }
    let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));
    (router, store)
}

async fn rpc(router: &axum::Router, body: Value) -> (StatusCode, Value) {
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/mcp")
                .header("Authorization", format!("Bearer {TOK}"))
                .header("content-type", "application/json")
                .body(Body::from(body.to_string()))
                .unwrap(),
        )
        .await
        .unwrap();
    let status = resp.status();
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let v: Value = serde_json::from_slice(&bytes).unwrap_or(Value::Null);
    (status, v)
}

/// Build a `tools/call` envelope for `name` with `arguments`.
fn call(id: i64, name: &str, args: Value) -> Value {
    json!({
        "jsonrpc":"2.0","id":id,
        "method":"tools/call",
        "params":{"name":name,"arguments":args}
    })
}

// --- envelopes ------------------------------------------------------------

#[tokio::test]
async fn tools_list_enumerates_the_thirteen_verbs() {
    let (router, _store) = seeded("list").await;
    let (status, v) = rpc(
        &router,
        json!({"jsonrpc":"2.0","id":1,"method":"tools/list"}),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    let tools = v["result"]["tools"].as_array().unwrap();
    // Nine original verbs plus roadmap #15 (render_roadmap), roadmap #4
    // (annotate, request_rewrite), and the event-log reader (list_events).
    assert_eq!(tools.len(), 13);
    assert!(tools.iter().any(|t| t == "append_sysmsg"));
    assert!(tools.iter().any(|t| t == "render_roadmap"));
    assert!(tools.iter().any(|t| t == "annotate"));
    assert!(tools.iter().any(|t| t == "request_rewrite"));
    assert!(tools.iter().any(|t| t == "list_events"));
}

// --- list_events ----------------------------------------------------------

#[tokio::test]
async fn list_events_returns_the_log_newest_last() {
    let (router, store) = seeded("le-ok").await;
    let (_s, _) = rpc(&router, call(1, "append_sysmsg", json!({"text":"go"}))).await;
    let (_s, v) = rpc(&router, call(2, "list_events", json!({}))).await;
    let events = v["result"]["events"].as_array().unwrap();
    // Two seed upserts plus the sysmsg, in append order.
    let logged = store.read_events().await.unwrap();
    assert_eq!(events.len(), logged.len());
    assert_eq!(events[0]["kind"], "item_upserted");
    assert_eq!(events[events.len() - 1]["kind"], "sys_msg");
    assert_eq!(events[events.len() - 1]["text"], "go");
}

#[tokio::test]
async fn list_events_read_error_is_internal() {
    // A malformed JSONL line makes `read_events` fail; the verb surfaces it as the
    // -32603 internal store error (the only non-happy arm of `list_events`).
    let dir = tempdir("le-err");
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(
            ItemId::new("a").unwrap(),
            "A".into(),
            "claude-sonnet-4-6".into(),
        )
        .await
        .unwrap();
    let mut log = std::fs::read_to_string(dir.join("events.jsonl")).unwrap();
    log.push_str("{not valid json}\n");
    std::fs::write(dir.join("events.jsonl"), log).unwrap();

    let router = build_router(Arc::clone(&store), Token::new(TOK), dir.join("static"));
    let (_s, v) = rpc(&router, call(1, "list_events", json!({}))).await;
    assert_eq!(v["error"]["code"], -32603);
    assert_eq!(v["error"]["data"]["error"], "io");
}

#[tokio::test]
async fn list_events_filters_by_kind() {
    let (router, _store) = seeded("le-filter").await;
    let (_s, _) = rpc(&router, call(1, "append_sysmsg", json!({"text":"x"}))).await;
    let (_s, v) = rpc(&router, call(2, "list_events", json!({"kind":"sys_msg"}))).await;
    let events = v["result"]["events"].as_array().unwrap();
    assert_eq!(events.len(), 1);
    assert_eq!(events[0]["kind"], "sys_msg");

    // A non-string `kind` is ignored (returns the full log), not an error.
    let (_s, v) = rpc(&router, call(3, "list_events", json!({"kind":42}))).await;
    let events = v["result"]["events"].as_array().unwrap();
    assert_eq!(events.len(), 3);
}

#[tokio::test]
async fn unknown_method_is_method_not_found() {
    let (router, _store) = seeded("unknown-method").await;
    let (status, v) = rpc(
        &router,
        json!({"jsonrpc":"2.0","id":9,"method":"resources/read"}),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["error"]["code"], -32601);
    assert_eq!(v["id"], 9);
}

#[tokio::test]
async fn missing_method_field_is_method_not_found() {
    let (router, _store) = seeded("no-method").await;
    // No `method`, no `id`: method defaults to "" (unknown) and id to null.
    let (status, v) = rpc(&router, json!({"jsonrpc":"2.0"})).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["error"]["code"], -32601);
    assert_eq!(v["id"], Value::Null);
}

#[tokio::test]
async fn unknown_tool_is_invalid_params() {
    let (router, _store) = seeded("unknown-tool").await;
    let (status, v) = rpc(&router, call(2, "delete_everything", json!({}))).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"]
        .as_str()
        .unwrap()
        .contains("unknown tool"));
}

#[tokio::test]
async fn call_with_no_params_defaults_to_empty_unknown_tool() {
    let (router, _store) = seeded("no-params").await;
    // tools/call with no params object: name defaults to "" → unknown tool.
    let (status, v) = rpc(
        &router,
        json!({"jsonrpc":"2.0","id":3,"method":"tools/call"}),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn rejects_without_token() {
    let (router, _store) = seeded("no-token").await;
    let resp = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/mcp")
                .header("content-type", "application/json")
                .body(Body::from(
                    json!({"jsonrpc":"2.0","id":1,"method":"tools/list"}).to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

// --- list_items / get_item ------------------------------------------------

#[tokio::test]
async fn list_items_returns_seeded() {
    let (router, _store) = seeded("li").await;
    let (status, v) = rpc(&router, call(1, "list_items", json!({}))).await;
    assert_eq!(status, StatusCode::OK);
    // Response shape is now grouped; both seeded items are PENDING/GO.
    assert_eq!(v["result"]["pending"]["go"].as_array().unwrap().len(), 2);
}

#[tokio::test]
async fn get_item_happy() {
    let (router, _store) = seeded("gi-ok").await;
    let (_s, v) = rpc(&router, call(1, "get_item", json!({"id":"a"}))).await;
    assert_eq!(v["result"]["item"]["id"], "a");
}

#[tokio::test]
async fn get_item_unknown_is_typed_error() {
    let (router, _store) = seeded("gi-unknown").await;
    let (_s, v) = rpc(&router, call(1, "get_item", json!({"id":"zzz"}))).await;
    assert_eq!(v["error"]["code"], -32004);
    assert_eq!(v["error"]["data"]["error"], "unknown");
}

#[tokio::test]
async fn get_item_missing_id_arg_is_invalid_params() {
    let (router, _store) = seeded("gi-noarg").await;
    let (_s, v) = rpc(&router, call(1, "get_item", json!({}))).await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("id"));
}

#[tokio::test]
async fn get_item_bad_slug_is_invalid_params() {
    let (router, _store) = seeded("gi-badslug").await;
    // A non-empty but invalid slug fails ItemId::new, not the "must be a string" path.
    let (_s, v) = rpc(&router, call(1, "get_item", json!({"id":"BAD"}))).await;
    assert_eq!(v["error"]["code"], -32602);
}

// --- set_wait_go ----------------------------------------------------------

#[tokio::test]
async fn set_wait_go_happy() {
    let (router, _store) = seeded("swg-ok").await;
    let (_s, v) = rpc(
        &router,
        call(1, "set_wait_go", json!({"id":"a","gate":"wait"})),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
}

#[tokio::test]
async fn set_wait_go_bad_id_is_invalid_params() {
    let (router, _store) = seeded("swg-badid").await;
    let (_s, v) = rpc(
        &router,
        call(1, "set_wait_go", json!({"id":123,"gate":"go"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn set_wait_go_missing_gate_is_invalid_params() {
    let (router, _store) = seeded("swg-nogate").await;
    let (_s, v) = rpc(&router, call(1, "set_wait_go", json!({"id":"a"}))).await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("gate"));
}

#[tokio::test]
async fn set_wait_go_bad_gate_value_is_invalid_params() {
    let (router, _store) = seeded("swg-badgate").await;
    let (_s, v) = rpc(
        &router,
        call(1, "set_wait_go", json!({"id":"a","gate":"halt"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn set_wait_go_unknown_item_is_store_error() {
    let (router, _store) = seeded("swg-unknown").await;
    let (_s, v) = rpc(
        &router,
        call(1, "set_wait_go", json!({"id":"zzz","gate":"go"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32000);
    assert_eq!(v["error"]["data"]["error"], "unknown");
}

// --- post_status ----------------------------------------------------------

#[tokio::test]
async fn post_status_happy() {
    let (router, _store) = seeded("ps-ok").await;
    let (_s, v) = rpc(
        &router,
        call(1, "post_status", json!({"id":"a","status":"doing"})),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
}

#[tokio::test]
async fn post_status_bad_id_is_invalid_params() {
    let (router, _store) = seeded("ps-badid").await;
    let (_s, v) = rpc(
        &router,
        call(1, "post_status", json!({"id":42,"status":"do"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn post_status_missing_status_is_invalid_params() {
    let (router, _store) = seeded("ps-nostatus").await;
    let (_s, v) = rpc(&router, call(1, "post_status", json!({"id":"a"}))).await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("status"));
}

#[tokio::test]
async fn post_status_blocked_while_wait_is_store_error() {
    let (router, _store) = seeded("ps-wait").await;
    let (_s, _) = rpc(
        &router,
        call(1, "set_wait_go", json!({"id":"a","gate":"wait"})),
    )
    .await;
    let (_s, v) = rpc(
        &router,
        call(2, "post_status", json!({"id":"a","status":"doing"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32000);
    assert_eq!(v["error"]["data"]["error"], "waiting");
}

// --- append_spend ---------------------------------------------------------

#[tokio::test]
async fn append_spend_happy_returns_total() {
    let (router, _store) = seeded("as-ok").await;
    let (_s, v) = rpc(
        &router,
        call(1, "append_spend", json!({"id":"a","delta":17})),
    )
    .await;
    assert_eq!(v["result"]["total"], 17);
}

#[tokio::test]
async fn append_spend_bad_id_is_invalid_params() {
    let (router, _store) = seeded("as-badid").await;
    let (_s, v) = rpc(
        &router,
        call(1, "append_spend", json!({"id":true,"delta":1})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn append_spend_non_numeric_delta_is_invalid_params() {
    let (router, _store) = seeded("as-baddelta").await;
    let (_s, v) = rpc(
        &router,
        call(1, "append_spend", json!({"id":"a","delta":"lots"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("delta"));
}

#[tokio::test]
async fn append_spend_unknown_item_is_store_error() {
    let (router, _store) = seeded("as-unknown").await;
    let (_s, v) = rpc(
        &router,
        call(1, "append_spend", json!({"id":"zzz","delta":1})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32000);
    assert_eq!(v["error"]["data"]["error"], "unknown");
}

// --- set_item_model -------------------------------------------------------

#[tokio::test]
async fn set_item_model_happy() {
    let (router, _store) = seeded("sim-ok").await;
    let (_s, v) = rpc(
        &router,
        call(
            1,
            "set_item_model",
            json!({"id":"a","model":"claude-opus-4-8"}),
        ),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
}

#[tokio::test]
async fn set_item_model_bad_id_is_invalid_params() {
    let (router, _store) = seeded("sim-badid").await;
    let (_s, v) = rpc(
        &router,
        call(1, "set_item_model", json!({"id":1,"model":"x"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn set_item_model_missing_model_is_invalid_params() {
    let (router, _store) = seeded("sim-nomodel").await;
    let (_s, v) = rpc(&router, call(1, "set_item_model", json!({"id":"a"}))).await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("model"));
}

// --- validate_connection --------------------------------------------------

#[tokio::test]
async fn validate_connection_ok() {
    let (router, _store) = seeded("vc-ok").await;
    let (_s, v) = rpc(
        &router,
        call(1, "validate_connection", json!({"from":"a","to":"b"})),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
}

#[tokio::test]
async fn validate_connection_bad_from_id_is_invalid_params() {
    let (router, _store) = seeded("vc-badfrom").await;
    let (_s, v) = rpc(
        &router,
        call(1, "validate_connection", json!({"from":99,"to":"b"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn validate_connection_bad_to_id_is_invalid_params() {
    let (router, _store) = seeded("vc-badto").await;
    // from is a valid slug; to is a valid string but an invalid slug, exercising
    // arg_pair's second `?`.
    let (_s, v) = rpc(
        &router,
        call(1, "validate_connection", json!({"from":"a","to":"BAD"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn validate_connection_unknown_is_graph_error() {
    let (router, _store) = seeded("vc-unknown").await;
    let (_s, v) = rpc(
        &router,
        call(1, "validate_connection", json!({"from":"a","to":"zzz"})),
    )
    .await;
    assert_eq!(v["error"]["code"], -32000);
    assert_eq!(v["error"]["data"]["error"], "unknown");
}

// --- mutate_connection ----------------------------------------------------

#[tokio::test]
async fn mutate_connection_add_then_remove() {
    let (router, store) = seeded("mc-ok").await;
    let (_s, v) = rpc(
        &router,
        call(
            1,
            "mutate_connection",
            json!({"op":"add","from":"a","to":"b"}),
        ),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
    assert_eq!(store.snapshot().await.edges().len(), 1);
    let (_s, v) = rpc(
        &router,
        call(
            2,
            "mutate_connection",
            json!({"op":"remove","from":"a","to":"b"}),
        ),
    )
    .await;
    assert_eq!(v["result"]["ok"], true);
    assert_eq!(store.snapshot().await.edges().len(), 0);
}

#[tokio::test]
async fn mutate_connection_bad_op_is_invalid_params() {
    let (router, _store) = seeded("mc-badop").await;
    let (_s, v) = rpc(
        &router,
        call(
            1,
            "mutate_connection",
            json!({"op":"sideways","from":"a","to":"b"}),
        ),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("op"));
}

#[tokio::test]
async fn mutate_connection_bad_id_is_invalid_params() {
    let (router, _store) = seeded("mc-badid").await;
    let (_s, v) = rpc(
        &router,
        call(
            1,
            "mutate_connection",
            json!({"op":"add","from":"a","to":7}),
        ),
    )
    .await;
    assert_eq!(v["error"]["code"], -32602);
}

#[tokio::test]
async fn mutate_connection_remove_missing_is_broken_dep() {
    let (router, _store) = seeded("mc-broken").await;
    let (_s, v) = rpc(
        &router,
        call(
            1,
            "mutate_connection",
            json!({"op":"remove","from":"a","to":"b"}),
        ),
    )
    .await;
    assert_eq!(v["error"]["code"], -32000);
    assert_eq!(v["error"]["data"]["error"], "broken_dep");
}

#[tokio::test]
async fn mutate_connection_cycle_is_graph_error() {
    let (router, _store) = seeded("mc-cycle").await;
    let (_s, _) = rpc(
        &router,
        call(
            1,
            "mutate_connection",
            json!({"op":"add","from":"a","to":"b"}),
        ),
    )
    .await;
    let (_s, v) = rpc(
        &router,
        call(
            2,
            "mutate_connection",
            json!({"op":"add","from":"b","to":"a"}),
        ),
    )
    .await;
    assert_eq!(v["error"]["data"]["error"], "cycle");
}

// --- append_sysmsg --------------------------------------------------------

#[tokio::test]
async fn append_sysmsg_happy() {
    let (router, _store) = seeded("sm-ok").await;
    let (_s, v) = rpc(&router, call(1, "append_sysmsg", json!({"text":"go"}))).await;
    assert_eq!(v["result"]["ok"], true);
}

#[tokio::test]
async fn append_sysmsg_missing_text_is_invalid_params() {
    let (router, _store) = seeded("sm-notext").await;
    let (_s, v) = rpc(&router, call(1, "append_sysmsg", json!({}))).await;
    assert_eq!(v["error"]["code"], -32602);
    assert!(v["error"]["message"].as_str().unwrap().contains("text"));
}
