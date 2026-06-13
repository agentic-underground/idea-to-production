//! Exhaustive HTTP REST surface contract: every verb's happy path and every
//! error branch (bad id, unknown item, bad body, bad op, cycle, WAIT-guard),
//! plus the static-serve fallback. Drives the real axum router via `oneshot`.

use std::sync::Arc;

use crate::api::build_router;
use crate::auth::Token;
use crate::domain::{ItemId, Status, WaitGate};
use crate::store::Store;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use serde_json::{json, Value};
use tower::ServiceExt;

const TOK: &str = "test-token";

fn tempdir(tag: &str) -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-surface-{tag}-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

async fn seeded(tag: &str) -> (axum::Router, Arc<Store>, std::path::PathBuf) {
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
    let static_dir = dir.join("static");
    let router = build_router(Arc::clone(&store), Token::new(TOK), static_dir.clone());
    (router, store, static_dir)
}

/// Issue an authenticated request and return (status, parsed-json-or-null).
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

#[tokio::test]
async fn get_item_happy() {
    let (router, _store, _) = seeded("get-ok").await;
    let (status, v) = req(&router, "GET", "/api/items/a", None).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["id"], "a");
    assert_eq!(v["title"], "A");
    assert_eq!(v["status"], "do");
    assert_eq!(v["gate"], "go");
    assert_eq!(v["tokens"], 0);
}

#[tokio::test]
async fn get_item_unknown_is_404() {
    let (router, _store, _) = seeded("get-404").await;
    let (status, v) = req(&router, "GET", "/api/items/zzz", None).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(v["error"], "unknown");
}

#[tokio::test]
async fn get_item_bad_id_is_400() {
    let (router, _store, _) = seeded("get-badid").await;
    // Uppercase is not a valid slug → parse_id fails → 400 bad_id.
    let (status, v) = req(&router, "GET", "/api/items/BAD", None).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn set_wait_go_bad_id_is_400() {
    let (router, _store, _) = seeded("gate-badid").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/BAD/gate",
        Some(json!({"gate":"wait"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn set_wait_go_happy() {
    let (router, store, _) = seeded("gate-ok").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/a/gate",
        Some(json!({"gate":"wait"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["ok"], true);
    assert_eq!(
        store
            .snapshot()
            .await
            .get(&ItemId::new("a").unwrap())
            .unwrap()
            .gate,
        WaitGate::Wait
    );
}

#[tokio::test]
async fn set_wait_go_unknown_item_is_404() {
    let (router, _store, _) = seeded("gate-unknown").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/zzz/gate",
        Some(json!({"gate":"go"})),
    )
    .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(v["error"], "unknown");
}

#[tokio::test]
async fn post_status_bad_id_is_400() {
    let (router, _store, _) = seeded("status-badid").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/BAD/status",
        Some(json!({"status":"doing"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn post_status_happy_advances() {
    let (router, store, _) = seeded("status-ok").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/a/status",
        Some(json!({"status":"doing"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["ok"], true);
    assert_eq!(
        store
            .snapshot()
            .await
            .get(&ItemId::new("a").unwrap())
            .unwrap()
            .status,
        Status::Doing
    );
}

#[tokio::test]
async fn post_status_bad_body_is_422() {
    let (router, _store, _) = seeded("status-badbody").await;
    // "nope" is not a valid Status → axum Json rejection.
    let (status, _v) = req(
        &router,
        "POST",
        "/api/items/a/status",
        Some(json!({"status":"nope"})),
    )
    .await;
    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn append_spend_happy_returns_total() {
    let (router, _store, _) = seeded("spend-ok").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/a/spend",
        Some(json!({"delta":42})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["total"], 42);
}

#[tokio::test]
async fn append_spend_bad_id_is_400() {
    let (router, _store, _) = seeded("spend-badid").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/BAD/spend",
        Some(json!({"delta":1})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn append_spend_unknown_item_is_404() {
    let (router, _store, _) = seeded("spend-unknown").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/zzz/spend",
        Some(json!({"delta":1})),
    )
    .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(v["error"], "unknown");
}

#[tokio::test]
async fn append_spend_blocked_while_wait_is_409() {
    let (router, _store, _) = seeded("spend-wait").await;
    let (s1, _) = req(
        &router,
        "POST",
        "/api/items/a/gate",
        Some(json!({"gate":"wait"})),
    )
    .await;
    assert_eq!(s1, StatusCode::OK);
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/a/spend",
        Some(json!({"delta":1})),
    )
    .await;
    assert_eq!(status, StatusCode::CONFLICT);
    assert_eq!(v["error"], "waiting");
}

#[tokio::test]
async fn set_item_model_happy() {
    let (router, store, _) = seeded("model-ok").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/a/model",
        Some(json!({"model":"claude-opus-4-8"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["ok"], true);
    assert_eq!(
        store
            .snapshot()
            .await
            .get(&ItemId::new("a").unwrap())
            .unwrap()
            .model,
        "claude-opus-4-8"
    );
}

#[tokio::test]
async fn set_item_model_bad_id_is_400() {
    let (router, _store, _) = seeded("model-badid").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/items/BAD/model",
        Some(json!({"model":"x"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn validate_connection_ok() {
    let (router, _store, _) = seeded("validate-ok").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/validate",
        Some(json!({"from":"a","to":"b"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["ok"], true);
}

#[tokio::test]
async fn validate_connection_bad_from_id_is_400() {
    let (router, _store, _) = seeded("validate-badfrom").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/validate",
        Some(json!({"from":"BAD","to":"b"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn validate_connection_bad_to_id_is_400() {
    let (router, _store, _) = seeded("validate-badto").await;
    // from is a valid slug, to is a valid string but an invalid slug: this
    // exercises the second arm of the (Err, _) | (_, Err) match.
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/validate",
        Some(json!({"from":"a","to":"BAD"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn validate_connection_unknown_endpoint_is_404() {
    let (router, _store, _) = seeded("validate-unknown").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/validate",
        Some(json!({"from":"a","to":"zzz"})),
    )
    .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(v["error"], "unknown");
}

#[tokio::test]
async fn mutate_connection_add_then_remove() {
    let (router, store, _) = seeded("mutate-ok").await;
    let (s_add, _) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"add","from":"a","to":"b"})),
    )
    .await;
    assert_eq!(s_add, StatusCode::OK);
    assert_eq!(store.snapshot().await.edges().len(), 1);

    let (s_rm, v) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"remove","from":"a","to":"b"})),
    )
    .await;
    assert_eq!(s_rm, StatusCode::OK);
    assert_eq!(v["ok"], true);
    assert_eq!(store.snapshot().await.edges().len(), 0);
}

#[tokio::test]
async fn mutate_connection_bad_op_is_400() {
    let (router, _store, _) = seeded("mutate-badop").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"frobnicate","from":"a","to":"b"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_op");
}

#[tokio::test]
async fn mutate_connection_bad_from_id_is_400() {
    let (router, _store, _) = seeded("mutate-badfrom").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"add","from":"BAD","to":"b"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn mutate_connection_bad_to_id_is_400() {
    let (router, _store, _) = seeded("mutate-badto").await;
    // Valid from, invalid-slug to: the second arm of the id-parse match.
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"add","from":"a","to":"BAD"})),
    )
    .await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(v["error"], "bad_id");
}

#[tokio::test]
async fn mutate_connection_remove_missing_is_broken_dep_409() {
    let (router, _store, _) = seeded("mutate-broken").await;
    // Removing an edge that was never added is a broken-dep graph error.
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"remove","from":"a","to":"b"})),
    )
    .await;
    assert_eq!(status, StatusCode::CONFLICT);
    assert_eq!(v["error"], "broken_dep");
}

#[tokio::test]
async fn mutate_connection_cycle_is_409() {
    let (router, _store, _) = seeded("mutate-cycle").await;
    let (s_add, _) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"add","from":"a","to":"b"})),
    )
    .await;
    assert_eq!(s_add, StatusCode::OK);
    // a->b exists; adding b->a would cycle.
    let (status, v) = req(
        &router,
        "POST",
        "/api/connection/mutate",
        Some(json!({"op":"add","from":"b","to":"a"})),
    )
    .await;
    assert_eq!(status, StatusCode::CONFLICT);
    assert_eq!(v["error"], "cycle");
}

#[tokio::test]
async fn append_sysmsg_happy() {
    let (router, store, _) = seeded("sysmsg-ok").await;
    let (status, v) = req(
        &router,
        "POST",
        "/api/sysmsg",
        Some(json!({"text":"hello orchestrator"})),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["ok"], true);
    // The sysmsg was logged as an event.
    let events = store.read_events().await.unwrap();
    assert!(events.iter().any(
        |e| matches!(e, crate::domain::Event::SysMsg { text } if text == "hello orchestrator")
    ));
}

#[tokio::test]
async fn static_fallback_serves_index() {
    let (router, _store, static_dir) = seeded("static").await;
    std::fs::create_dir_all(&static_dir).unwrap();
    std::fs::write(static_dir.join("index.html"), "<h1>flow</h1>").unwrap();
    // The fallback ServeDir is unauthenticated and resolves the static asset.
    let resp = router
        .oneshot(
            Request::builder()
                .uri("/index.html")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    assert_eq!(&bytes[..], b"<h1>flow</h1>");
}
