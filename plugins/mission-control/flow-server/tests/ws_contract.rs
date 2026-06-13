//! WebSocket contract: a state change broadcasts a delta to a connected client.
//! The delta is awaited deterministically (the next message on the socket) — no
//! sleeps, no polling.

use std::sync::Arc;

use flow_server::api::build_router;
use flow_server::auth::Token;
use flow_server::store::Store;

use futures_util::StreamExt;
use tokio_tungstenite::tungstenite::Message;

fn tempdir() -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!("flow-ws-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

#[tokio::test]
async fn state_change_broadcasts() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(
            flow_server::domain::ItemId::new("a").unwrap(),
            "A".into(),
            "claude-sonnet-4-6".into(),
        )
        .await
        .unwrap();

    let token = Token::new("tok");
    let router = build_router(Arc::clone(&store), token, dir.join("static"));

    // Bind to an ephemeral port and serve in the background.
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let server = tokio::spawn(async move {
        axum::serve(listener, router).await.unwrap();
    });

    // Connect a WS client with the token on the handshake URL.
    let url = format!("ws://{addr}/ws?token=tok");
    let (mut ws, _resp) = tokio_tungstenite::connect_async(&url).await.unwrap();

    // Trigger a state change AFTER the socket is established so the broadcast is
    // guaranteed to reach this subscriber.
    store
        .post_status(
            &flow_server::domain::ItemId::new("a").unwrap(),
            flow_server::domain::Status::Doing,
        )
        .await
        .unwrap();

    // Await the next text frame deterministically (no sleep).
    let msg = loop {
        match ws.next().await {
            Some(Ok(Message::Text(t))) => break t,
            Some(Ok(_)) => continue, // skip ping/pong/binary
            other => panic!("expected a text delta, got {other:?}"),
        }
    };

    let v: serde_json::Value = serde_json::from_str(&msg).unwrap();
    assert_eq!(v["kind"], "status_posted");
    assert_eq!(v["id"], "a");
    assert_eq!(v["status"], "doing");

    server.abort();
}

#[tokio::test]
async fn ws_rejects_without_token() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());
    let token = Token::new("tok");
    let router = build_router(Arc::clone(&store), token, dir.join("static"));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let server = tokio::spawn(async move {
        axum::serve(listener, router).await.unwrap();
    });

    // No token on the handshake → the upgrade is rejected (handshake fails).
    let url = format!("ws://{addr}/ws");
    let result = tokio_tungstenite::connect_async(&url).await;
    assert!(result.is_err(), "handshake without token must be rejected");

    server.abort();
}
