//! WebSocket contract: a state change broadcasts a delta to a connected client.
//! The delta is awaited deterministically (the next message on the socket) — no
//! sleeps, no polling.

use std::sync::Arc;

use crate::api::build_router;
use crate::auth::Token;
use crate::store::Store;

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
            crate::domain::ItemId::new("a").unwrap(),
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
            &crate::domain::ItemId::new("a").unwrap(),
            crate::domain::Status::Doing,
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
async fn client_drop_completes_the_server_stream() {
    let dir = tempdir();
    let store = Arc::new(Store::open(&dir).await.unwrap());
    store
        .upsert_item(
            crate::domain::ItemId::new("a").unwrap(),
            "A".into(),
            "claude-sonnet-4-6".into(),
        )
        .await
        .unwrap();

    let token = Token::new("tok");
    let router = build_router(Arc::clone(&store), token, dir.join("static"));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let server = tokio::spawn(async move {
        axum::serve(listener, router).await.unwrap();
    });

    // Connect, prove a delta flows, then drop the client to simulate the browser
    // closing the tab.
    let url = format!("ws://{addr}/ws?token=tok");
    let (mut ws, _resp) = tokio_tungstenite::connect_async(&url).await.unwrap();
    store
        .post_status(
            &crate::domain::ItemId::new("a").unwrap(),
            crate::domain::Status::Doing,
        )
        .await
        .unwrap();
    // Drain the first delta.
    loop {
        match ws.next().await {
            Some(Ok(Message::Text(_))) => break,
            Some(Ok(_)) => continue,
            other => panic!("expected a delta, got {other:?}"),
        }
    }
    drop(ws); // client gone

    // Pump deltas until the server-side stream observes the dropped client and
    // exits its loop (its broadcast receiver is dropped, so the count returns to
    // zero). No sleeps: yield between attempts and bound the iterations.
    let mut completed = false;
    for _ in 0..10_000 {
        store
            .append_spend(&crate::domain::ItemId::new("a").unwrap(), 1)
            .await
            .unwrap();
        if store.subscriber_count() == 0 {
            completed = true;
            break;
        }
        tokio::task::yield_now().await;
    }
    assert!(
        completed,
        "server stream_deltas must finish after the client drops"
    );

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
