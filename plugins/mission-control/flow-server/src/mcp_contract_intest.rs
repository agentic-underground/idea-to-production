//! MCP contract: the JSON-RPC verb surface on the same router, behind the same
//! token gate. A `validate_connection` that would cycle is rejected with a typed
//! error and the graph is unchanged; `list_items` returns the items.

use std::sync::Arc;

use crate::api::build_router;
use crate::auth::Token;
use crate::store::Store;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use tower::ServiceExt;

fn tempdir() -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-mcp-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

async fn seeded() -> (axum::Router, Arc<Store>) {
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
    let router = build_router(Arc::clone(&store), Token::new("tok"), dir.join("static"));
    (router, store)
}

async fn rpc(router: &axum::Router, body: serde_json::Value) -> (StatusCode, serde_json::Value) {
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/mcp")
                .header("Authorization", "Bearer tok")
                .header("content-type", "application/json")
                .body(Body::from(body.to_string()))
                .unwrap(),
        )
        .await
        .unwrap();
    let status = resp.status();
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    (status, v)
}

#[tokio::test]
async fn mcp_rejects_without_token() {
    let (router, _store) = seeded().await;
    let resp = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/mcp")
                .header("content-type", "application/json")
                .body(Body::from(
                    serde_json::json!({"jsonrpc":"2.0","id":1,"method":"tools/list"}).to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn mcp_list_items() {
    let (router, _store) = seeded().await;
    let (status, v) = rpc(
        &router,
        serde_json::json!({
            "jsonrpc":"2.0","id":1,
            "method":"tools/call",
            "params":{"name":"list_items","arguments":{}}
        }),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    let items = v["result"]["items"].as_array().unwrap();
    assert_eq!(items.len(), 2);
}

#[tokio::test]
async fn mcp_cycle_rejected() {
    let (router, store) = seeded().await;
    // add a->b
    let (status, _) = rpc(
        &router,
        serde_json::json!({
            "jsonrpc":"2.0","id":1,
            "method":"tools/call",
            "params":{"name":"mutate_connection","arguments":{"op":"add","from":"a","to":"b"}}
        }),
    )
    .await;
    assert_eq!(status, StatusCode::OK);

    // validate b->a would cycle: typed JSON-RPC error, graph unchanged.
    let (status, v) = rpc(
        &router,
        serde_json::json!({
            "jsonrpc":"2.0","id":2,
            "method":"tools/call",
            "params":{"name":"validate_connection","arguments":{"from":"b","to":"a"}}
        }),
    )
    .await;
    assert_eq!(status, StatusCode::OK); // JSON-RPC carries the error in-band
    assert_eq!(v["error"]["data"]["error"], "cycle");
    assert_eq!(store.snapshot().await.edges().len(), 1);
}
