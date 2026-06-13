//! WebSocket delta fan-out. The handshake carries the token as `?token=` (a
//! browser cannot set the `Authorization` header on a WS upgrade); a
//! missing/invalid token is rejected before the upgrade. Each broadcast [`Event`]
//! is serialized and pushed to every connected client as a text frame.

use std::collections::HashMap;

use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use tokio::sync::broadcast::error::RecvError;

use crate::api::AppState;
use crate::domain::Event;

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

/// The next action the delta loop should take for one received broadcast result.
#[derive(Debug, PartialEq, Eq)]
enum Step {
    /// Push this serialized delta to the client.
    Send(String),
    /// Skip this result and keep streaming (lagged, or unserializable).
    Skip,
    /// The broadcast channel closed; stop streaming.
    Stop,
}

/// Map one `recv()` outcome to a [`Step`], using `render` to serialize a
/// delivered event. Pure: no IO, so every branch is directly testable —
/// including the `render`-returned-`None` skip, which production never hits
/// (an `Event` always serializes) but a test double can force.
fn step_with<F>(received: Result<Event, RecvError>, render: F) -> Step
where
    F: FnOnce(&Event) -> Option<String>,
{
    match received {
        Ok(event) => match render(&event) {
            Some(text) => Step::Send(text),
            None => Step::Skip,
        },
        // Dropped some deltas under load; keep streaming the rest.
        Err(RecvError::Lagged(_)) => Step::Skip,
        Err(RecvError::Closed) => Step::Stop,
    }
}

/// Production rendering: serialize the event to its JSONL frame. The `Result`
/// from `serde_json` cannot fail for this enum, so this is total.
fn render_event(event: &Event) -> Option<String> {
    event.to_jsonl().ok()
}

/// Map one `recv()` outcome to a [`Step`] using the production renderer.
fn step(received: Result<Event, RecvError>) -> Step {
    step_with(received, render_event)
}

/// A text-frame sink the delta loop writes to. `WebSocket` is the production
/// implementor; tests supply a double to exercise the client-drop path.
trait TextSink {
    /// Send one text frame; `Err` means the client is gone.
    async fn send_text(&mut self, text: String) -> Result<(), ()>;
}

impl TextSink for WebSocket {
    async fn send_text(&mut self, text: String) -> Result<(), ()> {
        self.send(Message::Text(text)).await.map_err(|_| ())
    }
}

/// Drive the streaming loop over any [`TextSink`]. Returns when the channel
/// closes or the client drops.
async fn run_loop<S: TextSink>(sink: &mut S, mut rx: tokio::sync::broadcast::Receiver<Event>) {
    loop {
        match step(rx.recv().await) {
            Step::Send(text) => {
                if sink.send_text(text).await.is_err() {
                    break; // client gone
                }
            }
            Step::Skip => continue,
            Step::Stop => break,
        }
    }
}

async fn stream_deltas(mut socket: WebSocket, store: std::sync::Arc<crate::store::Store>) {
    let rx = store.subscribe();
    run_loop(&mut socket, rx).await;
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::ItemId;
    use tokio::sync::broadcast;

    fn sample_event() -> Event {
        Event::StatusPosted {
            id: ItemId::new("a").unwrap(),
            status: crate::domain::Status::Doing,
        }
    }

    #[test]
    fn render_event_serializes_to_jsonl() {
        let ev = sample_event();
        assert_eq!(render_event(&ev), Some(ev.to_jsonl().unwrap()));
    }

    #[test]
    fn step_sends_serialized_delta_on_ok() {
        let ev = sample_event();
        let expected = ev.to_jsonl().unwrap();
        assert_eq!(step(Ok(ev)), Step::Send(expected));
    }

    #[test]
    fn step_with_skips_when_render_yields_none() {
        // The production path never returns None, so force it with a renderer
        // that declines to serialize — this pins the Skip arm as a coordinate.
        assert_eq!(step_with(Ok(sample_event()), |_| None), Step::Skip);
    }

    #[test]
    fn step_skips_on_lagged() {
        assert_eq!(step(Err(RecvError::Lagged(7))), Step::Skip);
    }

    #[test]
    fn step_stops_on_closed() {
        assert_eq!(step(Err(RecvError::Closed)), Step::Stop);
    }

    /// A sink that records sends and can be told to report the client gone after
    /// a given number of successful frames.
    struct FakeSink {
        sent: Vec<String>,
        fail_after: usize,
    }

    impl TextSink for FakeSink {
        async fn send_text(&mut self, text: String) -> Result<(), ()> {
            if self.sent.len() >= self.fail_after {
                return Err(());
            }
            self.sent.push(text);
            Ok(())
        }
    }

    #[tokio::test]
    async fn run_loop_streams_until_channel_closes() {
        let (tx, rx) = broadcast::channel::<Event>(8);
        let ev = sample_event();
        tx.send(ev.clone()).unwrap();
        // Drop the only sender after queueing one event: the loop sends it, then
        // sees `Closed` and stops.
        drop(tx);
        let mut sink = FakeSink {
            sent: Vec::new(),
            fail_after: usize::MAX,
        };
        run_loop(&mut sink, rx).await;
        assert_eq!(sink.sent, vec![ev.to_jsonl().unwrap()]);
    }

    #[tokio::test]
    async fn run_loop_breaks_when_client_drops() {
        let (tx, rx) = broadcast::channel::<Event>(8);
        tx.send(sample_event()).unwrap();
        tx.send(sample_event()).unwrap();
        // The sink reports the client gone on the very first send.
        let mut sink = FakeSink {
            sent: Vec::new(),
            fail_after: 0,
        };
        run_loop(&mut sink, rx).await;
        // Loop broke immediately; nothing was recorded, channel never drained.
        assert!(sink.sent.is_empty());
    }

    #[tokio::test]
    async fn run_loop_skips_lagged_then_continues() {
        let (tx, rx) = broadcast::channel::<Event>(2);
        // Overflow the capacity-2 channel so the first recv reports Lagged.
        for _ in 0..5 {
            tx.send(sample_event()).unwrap();
        }
        drop(tx);
        let mut sink = FakeSink {
            sent: Vec::new(),
            fail_after: usize::MAX,
        };
        run_loop(&mut sink, rx).await;
        // After the Lagged skip, the still-buffered events stream through.
        assert!(!sink.sent.is_empty());
        assert!(sink.sent.iter().all(|t| t.contains("status_posted")));
    }
}
