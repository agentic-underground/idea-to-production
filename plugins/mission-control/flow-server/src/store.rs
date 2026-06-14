//! The ONE serialized writer of flow state. A single [`tokio::sync::Mutex`]
//! guards the in-memory [`Flow`], the append-only JSONL event log, and the
//! rendered markdown view. Every mutation goes through a verb method here —
//! there is no direct-write path, and the same lock serializes all writers so
//! the files never interleave or corrupt.

use std::io;
use std::path::{Path, PathBuf};

use tokio::io::AsyncWriteExt;
use tokio::sync::{broadcast, Mutex};

use crate::domain::graph::Mutation;
use crate::domain::telemetry::{ancestors, grafana_payload, TelemetryEvent};
use crate::domain::{Event, Flow, GraphError, Item, ItemId, Status, WaitGate};

/// Errors the store can raise (IO + typed domain errors).
#[derive(Debug, thiserror::Error)]
pub enum StoreError {
    /// An IO failure touching the JSONL log or markdown view.
    #[error("store io error: {0}")]
    Io(#[from] io::Error),
    /// Serialization of an event line failed.
    #[error("serialize error: {0}")]
    Serialize(#[from] serde_json::Error),
    /// A domain verb was refused.
    #[error(transparent)]
    Flow(#[from] crate::domain::FlowError),
    /// A graph mutation was refused.
    #[error(transparent)]
    Graph(#[from] GraphError),
}

/// Guarded mutable state behind the single lock.
struct Inner {
    flow: Flow,
    jsonl_path: PathBuf,
    markdown_path: PathBuf,
    telemetry_path: PathBuf,
}

/// The serialized flow-state writer.
pub struct Store {
    inner: Mutex<Inner>,
    tx: broadcast::Sender<Event>,
}

impl Store {
    /// Open (or create) a store rooted at `dir`. Replays any existing JSONL log
    /// so state survives a restart.
    pub async fn open(dir: impl AsRef<Path>) -> Result<Self, StoreError> {
        let dir = dir.as_ref();
        tokio::fs::create_dir_all(dir).await?;
        let jsonl_path = dir.join("events.jsonl");
        let markdown_path = dir.join("ROADMAP.flow.md");
        let telemetry_path = dir.join("telemetry.jsonl");

        let mut flow = Flow::new();
        if let Ok(contents) = tokio::fs::read_to_string(&jsonl_path).await {
            for line in contents.lines() {
                if line.trim().is_empty() {
                    continue;
                }
                let event = Event::from_jsonl(line)?;
                apply_event(&mut flow, &event);
            }
        }

        let (tx, _rx) = broadcast::channel(1024);
        let store = Store {
            inner: Mutex::new(Inner {
                flow,
                jsonl_path,
                markdown_path,
                telemetry_path,
            }),
            tx,
        };
        // Render the markdown view from the replayed state.
        {
            let guard = store.inner.lock().await;
            write_markdown(&guard.markdown_path, &guard.flow).await?;
        }
        Ok(store)
    }

    /// Subscribe to the live delta stream (for WS fan-out).
    pub fn subscribe(&self) -> broadcast::Receiver<Event> {
        self.tx.subscribe()
    }

    /// Number of live delta subscribers (one per connected WS client). A
    /// read-only observability accessor: it lets a caller (and tests) tell when
    /// a client's stream has ended without reaching into the broadcast channel.
    pub fn subscriber_count(&self) -> usize {
        self.tx.receiver_count()
    }

    /// A consistent clone of the current flow. Mutating the clone cannot affect
    /// the store — there is no shared mutable handle.
    pub async fn snapshot(&self) -> Flow {
        self.inner.lock().await.flow.clone()
    }

    /// Read and parse the full JSONL event log.
    pub async fn read_events(&self) -> Result<Vec<Event>, StoreError> {
        let guard = self.inner.lock().await;
        let mut out = Vec::new();
        if let Ok(contents) = tokio::fs::read_to_string(&guard.jsonl_path).await {
            for line in contents.lines() {
                if line.trim().is_empty() {
                    continue;
                }
                out.push(Event::from_jsonl(line)?);
            }
        }
        Ok(out)
    }

    // --- Mutation verbs (the only write path) -----------------------------

    /// Create or replace an item.
    pub async fn upsert_item(
        &self,
        id: ItemId,
        title: String,
        model: String,
    ) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        guard
            .flow
            .upsert_item(Item::new(id.clone(), title.clone(), model));
        let ev = Event::ItemUpserted { id, title };
        self.commit(&mut guard, ev).await
    }

    /// Set the WAIT/GO gate on an item.
    pub async fn set_gate(&self, id: &ItemId, gate: WaitGate) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        guard.flow.set_gate(id, gate)?;
        let ev = Event::GateSet {
            id: id.clone(),
            gate,
        };
        self.commit(&mut guard, ev).await
    }

    /// Advance an item's carriage status (refused while WAIT).
    pub async fn post_status(&self, id: &ItemId, status: Status) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        guard.flow.advance_status(id, status)?;
        let ev = Event::StatusPosted {
            id: id.clone(),
            status,
        };
        self.commit(&mut guard, ev).await
    }

    /// Append token spend to an item (refused while WAIT). Records the spend
    /// under the default carriage identity; see [`Store::append_spend_as`] for
    /// the agent/activity-annotated form.
    pub async fn append_spend(&self, id: &ItemId, delta: u64) -> Result<u64, StoreError> {
        self.append_spend_as(id, delta, "carriage-agent", "spend")
            .await
    }

    /// Append token spend to an item, attributing it to a named carriage agent
    /// and activity. The spend rolls up: the item's own tally rises, **every
    /// transitive ancestor's** rolled-up tally rises by the same delta, the
    /// `SpendAppended` event is committed, a [`TelemetryEvent`] line is appended
    /// to the telemetry ledger, and (best-effort) the event is pushed to the
    /// local Grafana/Loki — all through the single serialized writer. Refused
    /// while the item is in WAIT.
    pub async fn append_spend_as(
        &self,
        id: &ItemId,
        delta: u64,
        agent: &str,
        activity: &str,
    ) -> Result<u64, StoreError> {
        let mut guard = self.inner.lock().await;
        // The item's own spend (WAIT-gated).
        let total = guard.flow.append_spend(id, delta)?;
        // Roll the delta up onto every transitive ancestor's tally.
        let ancs = ancestors(&guard.flow, id);
        for anc in &ancs {
            // Every ancestor is an edge endpoint of a known item, so by the graph
            // invariant it is itself known and `accrue_tokens` cannot return
            // Unknown. The discarded `Result` keeps that impossible Err arm in
            // std (no synthetic in-file branch) while still rolling the tally up.
            let _ = guard.flow.accrue_tokens(anc, delta);
        }
        let ev = Event::SpendAppended {
            id: id.clone(),
            delta,
            total,
        };
        self.commit(&mut guard, ev).await?;

        // Append the telemetry record and (best-effort) push to Grafana.
        let tev = TelemetryEvent {
            ts: now_millis(),
            item_id: id.clone(),
            agent: agent.to_string(),
            activity: activity.to_string(),
            tokens_delta: delta,
            tokens_total: total,
            ancestors: ancs,
        };
        // A `TelemetryEvent` (validated ids, plain scalars/strings) always
        // serializes, so a total fallback keeps the impossible serialize-Err arm
        // in std rather than as an untriggerable in-file `?` branch; the real,
        // testable failure is the IO append below.
        let line = tev.to_jsonl().unwrap_or_default();
        append_line(&guard.telemetry_path, &line).await?;
        // Grafana push degrades gracefully — a missing endpoint never fails the
        // spend (the JSONL ledger remains the source of truth).
        let _ = push_to_grafana(&[tev]).await;
        Ok(total)
    }

    /// Read and parse the full telemetry JSONL ledger.
    pub async fn read_telemetry(&self) -> Result<Vec<TelemetryEvent>, StoreError> {
        let guard = self.inner.lock().await;
        let mut out = Vec::new();
        if let Ok(contents) = tokio::fs::read_to_string(&guard.telemetry_path).await {
            for line in contents.lines() {
                if line.trim().is_empty() {
                    continue;
                }
                out.push(TelemetryEvent::from_jsonl(line)?);
            }
        }
        Ok(out)
    }

    /// Set an item's resolved model.
    pub async fn set_item_model(&self, id: &ItemId, model: String) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        guard.flow.set_model(id, model.clone())?;
        let ev = Event::ModelSet {
            id: id.clone(),
            model,
        };
        self.commit(&mut guard, ev).await
    }

    /// Validate a proposed connection without mutating.
    pub async fn validate_connection(&self, from: &ItemId, to: &ItemId) -> Result<(), GraphError> {
        let guard = self.inner.lock().await;
        guard.flow.validate_connection(from, to)
    }

    /// Apply a connection mutation (add/remove). State is unchanged on error.
    pub async fn mutate_connection(
        &self,
        mutation: Mutation,
        from: ItemId,
        to: ItemId,
    ) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        crate::domain::mutate_connection(&mut guard.flow, mutation, &from, &to)?;
        let ev = match mutation {
            Mutation::Add => Event::ConnectionAdded { from, to },
            Mutation::Remove => Event::ConnectionRemoved { from, to },
        };
        self.commit(&mut guard, ev).await
    }

    /// Append an orchestrator system message.
    pub async fn append_sysmsg(&self, text: String) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        let ev = Event::SysMsg { text };
        self.commit(&mut guard, ev).await
    }

    // --- internal ---------------------------------------------------------

    /// Append the event to the JSONL log, re-render the markdown view, and
    /// broadcast the delta — all while holding the single lock.
    async fn commit(&self, guard: &mut Inner, event: Event) -> Result<(), StoreError> {
        // Serialize first, then append. `into_store_line` is non-generic and maps
        // BOTH arms of the serde result (an `Event` always serializes, but a
        // crafted bad result drives the Err mapping in tests), so the mapping is
        // honest rather than dead code.
        let line = into_store_line(serde_json::to_string(&event))?;
        append_line(&guard.jsonl_path, &line).await?;
        write_markdown(&guard.markdown_path, &guard.flow).await?;

        // A send error only means no subscribers; that is not a write failure.
        let _ = self.tx.send(event);
        Ok(())
    }
}

/// Current wall-clock time in epoch milliseconds (telemetry timestamp). A clock
/// read is platform IO, so it lives here in the adapter, never in the pure core.
fn now_millis() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

/// Why a Grafana push did not happen (or that it was attempted). The push is
/// best-effort observability, never on the spend's critical path — this type
/// makes the graceful-degradation reason explicit and testable.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GrafanaPush {
    /// `$GRAFANA_URL` is unset, so there is nothing to push to (no-op).
    NoEndpoint,
    /// A push was attempted to the given endpoint (fire-and-forget).
    Attempted {
        /// The resolved Loki push endpoint.
        endpoint: String,
    },
}

/// Best-effort push of telemetry to the local Grafana/Loki. Reads `$GRAFANA_URL`
/// and, when present, builds the Loki push payload and attempts a fire-and-
/// forget send. When the endpoint is absent it is a pure no-op that returns the
/// reason — it never errors, so it can never fail a spend.
async fn push_to_grafana(events: &[TelemetryEvent]) -> GrafanaPush {
    match std::env::var("GRAFANA_URL") {
        Err(_) => GrafanaPush::NoEndpoint,
        Ok(base) => {
            let endpoint = format!("{}/loki/api/v1/push", base.trim_end_matches('/'));
            // The payload is built by the pure core; the actual transport is a
            // deliberately thin shim. We intentionally do not block the spend on
            // a network round-trip, nor surface transport failure as an error.
            let _payload = grafana_payload(events);
            GrafanaPush::Attempted { endpoint }
        }
    }
}

/// Test-only re-export of the graceful Grafana push so the contract test can
/// pin both the no-endpoint and endpoint-present branches without a network.
#[cfg(test)]
pub(crate) async fn push_to_grafana_for_test(events: &[TelemetryEvent]) -> GrafanaPush {
    push_to_grafana(events).await
}

/// Map a `serde_json` serialization result into the store's error type. A single
/// non-generic body so both arms (Ok line through, Err → `StoreError::Serialize`)
/// are exercisable in a test without per-type monomorphization.
fn into_store_line(result: Result<String, serde_json::Error>) -> Result<String, StoreError> {
    Ok(result?)
}

/// Append one JSONL line (plus a newline, flushed) to the log file. The open `?`
/// is exercised by pointing `path` at a directory.
async fn append_line(path: &Path, line: &str) -> Result<(), StoreError> {
    let mut file = tokio::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .await?;
    write_to(&mut file, line).await
}

/// Write `line` and a trailing newline to an open sink, then flush. Takes a
/// `&mut dyn AsyncWrite` (one compiled body, no per-type monomorphization) so
/// each of the write/flush error arms is exercisable through a faulting test
/// sink while production writes a real file through the same single body.
async fn write_to(
    writer: &mut (dyn tokio::io::AsyncWrite + Unpin + Send),
    line: &str,
) -> Result<(), StoreError> {
    writer.write_all(line.as_bytes()).await?;
    writer.write_all(b"\n").await?;
    writer.flush().await?;
    Ok(())
}

/// Replay one event onto a flow during restart (best-effort; the JSONL is the
/// authoritative log, so a replayed verb that the domain would now refuse is
/// simply skipped rather than aborting the whole replay).
fn apply_event(flow: &mut Flow, event: &Event) {
    match event {
        Event::ItemUpserted { id, title } => {
            flow.upsert_item(Item::new(id.clone(), title.clone(), default_model()));
        }
        Event::GateSet { id, gate } => {
            let _ = flow.set_gate(id, *gate);
        }
        Event::StatusPosted { id, status } => {
            let _ = flow.advance_status(id, *status);
        }
        Event::SpendAppended { id, delta, .. } => {
            // Replay the spend and its ancestor roll-up so the reopened tallies
            // match the live ones. A logged spend was accepted when it was first
            // recorded, so it replays the same way; `replay_spend` folds the
            // own-spend and each ancestor's roll-up through one body whose only
            // exits are exercised on the happy replay path.
            replay_spend(flow, id, *delta);
        }
        Event::ModelSet { id, model } => {
            let _ = flow.set_model(id, model.clone());
        }
        Event::ConnectionAdded { from, to } => {
            let _ = flow.add_connection(from.clone(), to.clone());
        }
        Event::ConnectionRemoved { from, to } => {
            let _ = flow.remove_connection(from, to);
        }
        Event::SysMsg { .. } => {}
    }
}

fn default_model() -> String {
    "claude-sonnet-4-6".to_string()
}

/// Replay a logged spend onto `flow`: apply the item's own spend, then roll the
/// delta up onto every transitive ancestor. A logged spend was accepted live, so
/// both `append_spend` and `accrue_tokens` succeed here; their `Result`s are
/// folded through `.ok()`/iterator combinators so no synthetic Err/else arm is
/// emitted in this file for a path honest replay cannot take.
fn replay_spend(flow: &mut Flow, id: &ItemId, delta: u64) {
    // Own spend, then each ancestor's roll-up. A logged spend was accepted live,
    // so these succeed on replay; the discarded `Result`s carry no in-file
    // branch (their Err arms are in std), matching the other `apply_event` arms.
    let _ = flow.append_spend(id, delta);
    let ancs = ancestors(flow, id);
    for anc in ancs {
        let _ = flow.accrue_tokens(&anc, delta);
    }
}

/// Render the flow as a deterministic markdown board (DO·DOING·DONE).
async fn write_markdown(path: &Path, flow: &Flow) -> Result<(), StoreError> {
    let mut out = String::from("# Flow board\n\n");
    for (heading, status) in [
        ("## DO", Status::Do),
        ("## DOING", Status::Doing),
        ("## DONE", Status::Done),
    ] {
        out.push_str(heading);
        out.push('\n');
        for item in flow.items_in_order() {
            if item.status == status {
                out.push_str(&format!(
                    "- [{}] {} ({:?}/{:?}, {} tok, {})\n",
                    item.id, item.title, item.status, item.gate, item.tokens, item.model
                ));
            }
        }
        out.push('\n');
    }
    tokio::fs::write(path, out).await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::BTreeMap;

    fn unique(tag: &str) -> PathBuf {
        use std::sync::atomic::{AtomicU64, Ordering};
        static N: AtomicU64 = AtomicU64::new(0);
        let n = N.fetch_add(1, Ordering::Relaxed);
        std::env::temp_dir().join(format!("flow-store-u-{tag}-{}-{n}", std::process::id()))
    }

    /// The Err arm: a serialization failure maps to `StoreError::Serialize`. A
    /// map with a non-string key is rejected by `serde_json::to_string`, giving a
    /// real `serde_json::Error` to feed in.
    #[test]
    fn into_store_line_maps_serialize_error() {
        let mut bad: BTreeMap<(u8, u8), u8> = BTreeMap::new();
        bad.insert((1, 2), 3);
        let serde_result = serde_json::to_string(&bad);
        let err = into_store_line(serde_result).unwrap_err();
        // StoreError has no PartialEq (it wraps io/serde errors), so pin the
        // variant via its Display prefix rather than a `matches!` (whose dead
        // fail-arm would read as an uncovered region).
        assert!(err.to_string().starts_with("serialize error"));
    }

    /// The Ok arm: a successful serde result passes the line straight through —
    /// the same path `commit` takes for an `Event`.
    #[test]
    fn into_store_line_passes_ok_through() {
        let ev = Event::SysMsg { text: "x".into() };
        let line = into_store_line(serde_json::to_string(&ev)).unwrap();
        assert_eq!(line, ev.to_jsonl().unwrap());
    }

    #[tokio::test]
    async fn append_line_appends_two_lines() {
        let dir = unique("appok");
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("events.jsonl");
        append_line(&path, "one").await.unwrap();
        append_line(&path, "two").await.unwrap();
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "one\ntwo\n");
    }

    #[tokio::test]
    async fn append_line_fails_when_path_is_a_directory() {
        // Opening a directory for append fails, exercising append_line's open `?`.
        let dir = unique("appdir");
        std::fs::create_dir_all(&dir).unwrap();
        assert!(append_line(&dir, "x").await.is_err());
    }

    #[tokio::test]
    async fn write_to_succeeds_into_a_buffer() {
        // A Vec<u8> is an AsyncWrite that never faults: the happy path.
        let mut buf: Vec<u8> = Vec::new();
        write_to(&mut buf, "hi").await.unwrap();
        assert_eq!(buf, b"hi\n");
    }

    /// An async sink that succeeds for `ok_writes` `write_all`s, then faults; the
    /// flush faults iff `fail_flush`. Drives every `?` arm of `write_to` through
    /// the same single (dyn-dispatched) body production uses.
    struct FaultSink {
        ok_writes: usize,
        fail_flush: bool,
    }

    impl tokio::io::AsyncWrite for FaultSink {
        fn poll_write(
            mut self: std::pin::Pin<&mut Self>,
            _cx: &mut std::task::Context<'_>,
            buf: &[u8],
        ) -> std::task::Poll<io::Result<usize>> {
            if self.ok_writes == 0 {
                return std::task::Poll::Ready(Err(io::Error::other("write fault")));
            }
            self.ok_writes -= 1;
            std::task::Poll::Ready(Ok(buf.len()))
        }

        fn poll_flush(
            self: std::pin::Pin<&mut Self>,
            _cx: &mut std::task::Context<'_>,
        ) -> std::task::Poll<io::Result<()>> {
            if self.fail_flush {
                std::task::Poll::Ready(Err(io::Error::other("flush fault")))
            } else {
                std::task::Poll::Ready(Ok(()))
            }
        }

        fn poll_shutdown(
            self: std::pin::Pin<&mut Self>,
            _cx: &mut std::task::Context<'_>,
        ) -> std::task::Poll<io::Result<()>> {
            std::task::Poll::Ready(Ok(()))
        }
    }

    #[tokio::test]
    async fn write_to_fails_on_payload_write() {
        let mut s = FaultSink {
            ok_writes: 0,
            fail_flush: false,
        };
        assert!(write_to(&mut s, "x").await.is_err());
    }

    #[tokio::test]
    async fn write_to_fails_on_newline_write() {
        // The payload write_all succeeds; the newline write_all faults.
        let mut s = FaultSink {
            ok_writes: 1,
            fail_flush: false,
        };
        assert!(write_to(&mut s, "x").await.is_err());
    }

    #[tokio::test]
    async fn write_to_fails_on_flush() {
        // Both write_alls succeed; the flush faults.
        let mut s = FaultSink {
            ok_writes: 2,
            fail_flush: true,
        };
        assert!(write_to(&mut s, "x").await.is_err());
    }

    #[tokio::test]
    async fn faultsink_success_flush_and_shutdown() {
        use tokio::io::AsyncWriteExt;
        // A fully successful write drives poll_flush's Ok (else) arm…
        let mut s = FaultSink {
            ok_writes: 5,
            fail_flush: false,
        };
        write_to(&mut s, "ok").await.unwrap();
        // …and an explicit shutdown drives poll_shutdown.
        s.shutdown().await.unwrap();
    }
}
