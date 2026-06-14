//! HTTP contract through the real axum router: token gate (401), list_items,
//! and a cycle-rejecting validate_connection that leaves the graph unchanged.

use std::sync::Arc;

use crate::api::build_router;
use crate::auth::Token;
use crate::store::Store;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use tower::ServiceExt; // oneshot

fn tempdir(tag: &str) -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-http-{tag}-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

async fn seeded() -> (axum::Router, Arc<Store>) {
    let dir = tempdir("seed");
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(
            crate::domain::ItemId::new("a").unwrap(),
            "A".into(),
            "claude-sonnet-4-6".into(),
        )
        .await
        .unwrap();
    store
        .upsert_item(
            crate::domain::ItemId::new("b").unwrap(),
            "B".into(),
            "claude-sonnet-4-6".into(),
        )
        .await
        .unwrap();
    let token = Token::new("test-token");
    let router = build_router(Arc::clone(&store), token, dir.join("static"));
    (router, store)
}

#[tokio::test]
async fn rejects_without_token() {
    let (router, store) = seeded().await;
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/items")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);

    // And a wrong token is also 401.
    let resp = router
        .oneshot(
            Request::builder()
                .uri("/api/items")
                .header("Authorization", "Bearer wrong")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);

    // No mutation happened (the store is untouched).
    assert_eq!(store.snapshot().await.items_in_order().len(), 2);
}

#[tokio::test]
async fn list_items_ok() {
    let (router, _store) = seeded().await;
    let resp = router
        .oneshot(
            Request::builder()
                .uri("/api/items")
                .header("Authorization", "Bearer test-token")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    let items = v.as_array().unwrap();
    assert_eq!(items.len(), 2);
    assert_eq!(items[0]["id"], "a");
}

#[tokio::test]
async fn validate_connection_cycle_rejected_unchanged() {
    let (router, store) = seeded().await;
    // a -> b first.
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/connection/mutate")
                .header("Authorization", "Bearer test-token")
                .header("content-type", "application/json")
                .body(Body::from(
                    serde_json::json!({"op":"add","from":"a","to":"b"}).to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // Now validate b -> a, which would cycle.
    let resp = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/connection/validate")
                .header("Authorization", "Bearer test-token")
                .header("content-type", "application/json")
                .body(Body::from(
                    serde_json::json!({"from":"b","to":"a"}).to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CONFLICT);
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(v["error"], "cycle");

    // Graph unchanged: exactly the one a->b edge remains.
    assert_eq!(store.snapshot().await.edges().len(), 1);
}

#[tokio::test]
async fn wait_state_refuses_carriage_advance() {
    let (router, store) = seeded().await;
    // Put `a` into WAIT.
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/items/a/gate")
                .header("Authorization", "Bearer test-token")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::json!({"gate":"wait"}).to_string()))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // A status post (carriage-advance) is refused while WAIT.
    let resp = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/items/a/status")
                .header("Authorization", "Bearer test-token")
                .header("content-type", "application/json")
                .body(Body::from(
                    serde_json::json!({"status":"doing"}).to_string(),
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CONFLICT);

    // Status unchanged.
    assert_eq!(
        store
            .snapshot()
            .await
            .get(&crate::domain::ItemId::new("a").unwrap())
            .unwrap()
            .status,
        crate::domain::Status::Do
    );
}

/// Helper: POST a JSON body to `uri` with the valid bearer token.
async fn post_json(
    router: &axum::Router,
    uri: &str,
    body: serde_json::Value,
) -> (StatusCode, serde_json::Value) {
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri(uri)
                .header("Authorization", "Bearer test-token")
                .header("content-type", "application/json")
                .body(Body::from(body.to_string()))
                .unwrap(),
        )
        .await
        .unwrap();
    let status = resp.status();
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    // Some bodies (e.g. 422 from the extractor) are not JSON; default to null.
    let v: serde_json::Value = serde_json::from_slice(&bytes).unwrap_or(serde_json::Value::Null);
    (status, v)
}

#[tokio::test]
async fn roadmap_rendered_is_token_gated_and_returns_the_view() {
    let (router, _store) = seeded().await;
    // Token-gated: no token → 401.
    let resp = router
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/roadmap/rendered")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);

    // With the token, the rendered text view comes back.
    let resp = router
        .oneshot(
            Request::builder()
                .uri("/api/roadmap/rendered")
                .header("Authorization", "Bearer test-token")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let text = String::from_utf8(bytes.to_vec()).unwrap();
    assert!(text.starts_with("ROADMAP\n2 item(s)\n"));
    assert!(text.contains("· a · A · DO · GO · 0 tok · d0"));
}

#[tokio::test]
async fn annotate_happy_unknown_and_bad_body() {
    let (router, store) = seeded().await;
    // Happy: annotate a known item.
    let (status, v) = post_json(
        &router,
        "/api/items/a/annotate",
        serde_json::json!({"text":"please tighten the error path"}),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["ok"], true);
    // The annotation was recorded as an event.
    let events = store.read_events().await.unwrap();
    assert!(events
        .iter()
        .any(|e| matches!(e, crate::domain::Event::Annotated { text, .. } if text == "please tighten the error path")));

    // Unknown item → 404.
    let (status, v) = post_json(
        &router,
        "/api/items/nope/annotate",
        serde_json::json!({"text":"x"}),
    )
    .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(v["error"], "unknown");

    // Bad body (missing `text`) → 422 from the JSON extractor.
    let (status, _v) = post_json(&router, "/api/items/a/annotate", serde_json::json!({})).await;
    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn rewrite_happy_unknown_and_bad_body() {
    let (router, store) = seeded().await;
    // Happy: request a rewrite → draft increments to 1.
    let (status, v) = post_json(
        &router,
        "/api/items/a/rewrite",
        serde_json::json!({"comment":"redo with the new contract"}),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["draft"], 1);
    // A second rewrite increments again.
    let (status, v) = post_json(
        &router,
        "/api/items/a/rewrite",
        serde_json::json!({"comment":"again"}),
    )
    .await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(v["draft"], 2);
    assert_eq!(
        store
            .snapshot()
            .await
            .get(&crate::domain::ItemId::new("a").unwrap())
            .unwrap()
            .draft,
        2
    );

    // Unknown item → 404.
    let (status, v) = post_json(
        &router,
        "/api/items/nope/rewrite",
        serde_json::json!({"comment":"x"}),
    )
    .await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(v["error"], "unknown");

    // Bad body (missing `comment`) → 422.
    let (status, _v) = post_json(&router, "/api/items/a/rewrite", serde_json::json!({})).await;
    assert_eq!(status, StatusCode::UNPROCESSABLE_ENTITY);
}
