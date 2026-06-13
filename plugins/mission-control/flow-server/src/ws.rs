//! WebSocket delta fan-out. The handshake carries the token as `?token=` (a
//! browser cannot set the `Authorization` header on a WS upgrade); a
//! missing/invalid token is rejected before the upgrade. Each broadcast [`Event`]
//! is serialized and pushed to every connected client as a text frame.

use std::collections::HashMap;

use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};

use crate::api::AppState;

/// Handle `GET /ws?token=...`: authenticate, then upgrade and stream deltas.
pub async fn upgrade(
    State(state): State<AppState>,
    Query(params): Query<HashMap<String, String>>,
    upgrade: WebSocketUpgrade,
) -> Response {
    let presented = params.get("token").map(String::as_str).unwrap_or("");
    if !state.token.matches(presented) {
        return (StatusCode::UNAUTHORIZED, "missing or invalid token").into_response();
    }
    let store = state.store.clone();
    upgrade.on_upgrade(move |socket| stream_deltas(socket, store))
}

async fn stream_deltas(mut socket: WebSocket, store: std::sync::Arc<crate::store::Store>) {
    let mut rx = store.subscribe();
    loop {
        match rx.recv().await {
            Ok(event) => {
                let Ok(text) = event.to_jsonl() else {
                    continue;
                };
                if socket.send(Message::Text(text)).await.is_err() {
                    break; // client gone
                }
            }
            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                // Dropped some deltas under load; keep streaming the rest.
                continue;
            }
            Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
        }
    }
}
