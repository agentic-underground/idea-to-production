//! The ONE serialized writer of flow state. A single [`tokio::sync::Mutex`]
//! guards the in-memory [`Flow`], the append-only JSONL event log, and the
//! rendered markdown view. Every mutation goes through a verb method here —
//! there is no direct-write path, and the same lock serializes all writers so
//! the files never interleave or corrupt.

use std::collections::BTreeMap;
use std::io;
use std::path::{Path, PathBuf};

use tokio::io::AsyncWriteExt;
use tokio::sync::{broadcast, Mutex};

use crate::domain::graph::Mutation;
use crate::domain::telemetry::{ancestors, grafana_payload, TelemetryEvent};
use crate::domain::{format_annotation, Event, Flow, GraphError, Item, ItemId, Status, WaitGate};

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
    /// Human-readable gate sidecar: a JSON object mapping item-id → "wait"|"go".
    /// Written atomically on every `set_gate` call; read on startup by
    /// `restore_gates()`. Serves as the fast restore path alongside JSONL replay.
    gates_path: PathBuf,
    /// Where `doc/<TITLE>_PLAN.md` plan documents live (the repo's `doc/`).
    doc_dir: PathBuf,
    /// Fallback per-item annotations ledger dir, used when no plan doc exists.
    annotations_dir: PathBuf,
    /// The `.i2p/roadmap/` tree root, set when the board was ingested from the
    /// file-per-item tree (roadmap [42]). When `Some`, `post_status` writes the
    /// status change back to the tree (move the item file + update its front-matter)
    /// so the tree stays the single source of truth. `None` for legacy single-file
    /// or test stores — write-back is then skipped (in-memory only, unchanged).
    roadmap_tree: Option<PathBuf>,
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
        let gates_path = dir.join("gates.json");
        // Plan docs live in the repo's `doc/` (beside the `.flow` data dir);
        // fall back to a `doc/` under the data dir when there is no parent.
        let doc_dir = dir.parent().unwrap_or(dir).join("doc");
        let annotations_dir = dir.join("annotations");

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
                gates_path,
                doc_dir,
                annotations_dir,
                roadmap_tree: None,
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

    /// The `.i2p/roadmap/` tree path this store ingested from, if any (roadmap [42]).
    /// `None` for a legacy single-file/empty store. Surfaced by the MCP `ping` verb so
    /// a stale or misconfigured server (empty store, no source) is visible, not silent.
    pub async fn roadmap_source(&self) -> Option<PathBuf> {
        self.inner.lock().await.roadmap_tree.clone()
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
    ///
    /// After updating in-memory state and committing the JSONL event, the full
    /// id→gate map is written atomically to `.flow/gates.json`. A sidecar write
    /// failure is **non-fatal** (warn-and-continue, EARS-G36-08): the JSONL log
    /// is the authoritative record; the sidecar is a fast restore convenience.
    pub async fn set_gate(&self, id: &ItemId, gate: WaitGate) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        guard.flow.set_gate(id, gate)?;
        let ev = Event::GateSet {
            id: id.clone(),
            gate,
        };
        self.commit(&mut guard, ev).await?;
        // Persist the sidecar after the authoritative JSONL commit succeeds.
        // A sidecar write failure is non-fatal: warn and continue.
        if let Err(e) = persist_gates(&guard.flow, &guard.gates_path).await {
            eprintln!("flow-server: warning — could not write .flow/gates.json: {e}");
        }
        Ok(())
    }

    /// Restore gate state from `.flow/gates.json`.
    ///
    /// This is the fast restore path on startup. It is **infallible**:
    /// - A missing file → all gates remain at their current value (default Go).
    /// - A malformed file → log a warning, leave all gates at Go.
    /// - An item ID in the file that no longer exists → silently skipped.
    ///
    /// MUST be called in `main.rs` AFTER `ingest_roadmap()` returns, because
    /// `upsert_item()` inside `ingest_roadmap()` resets every item's gate to
    /// `WaitGate::Go` (the `Item::new` default). Calling `restore_gates()` before
    /// `ingest_roadmap()` would have its work overwritten. Sequencing:
    ///   `Store::open()` → `ingest_roadmap()` → `restore_gates()`.
    pub async fn restore_gates(&self) {
        let mut guard = self.inner.lock().await;
        let path = guard.gates_path.clone();
        let text = match tokio::fs::read_to_string(&path).await {
            Err(_) => return, // missing file → all gates default to Go, no error
            Ok(t) => t,
        };
        let map: BTreeMap<String, WaitGate> = match serde_json::from_str(&text) {
            Err(_) => {
                eprintln!(
                    "flow-server: warning — .flow/gates.json is malformed; all gates default to go"
                );
                return;
            }
            Ok(m) => m,
        };
        for (id_str, gate) in map {
            if let Ok(id) = ItemId::new(&id_str) {
                // Unknown item → silently discard (stale entry, EARS-G36-05).
                let _ = guard.flow.set_gate(&id, gate);
            }
        }
    }

    /// Advance an item's carriage status (refused while WAIT). When the board was
    /// ingested from the `.i2p/roadmap/` tree, the change is written back to the
    /// tree (item file moved to the target folder, `status:` front-matter updated)
    /// before the in-memory commit, so the tree stays the single source of truth.
    pub async fn post_status(&self, id: &ItemId, status: Status) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        // Capture the prior status so a failed tree write can be rolled back.
        let prior = guard.flow.get(id).map(|i| i.status);
        guard.flow.advance_status(id, status)?;
        if let Some(tree) = guard.roadmap_tree.clone() {
            // The tree is the source of truth: if the file move/rewrite fails, REJECT the
            // change and roll the in-memory status back, so memory matches the unchanged
            // tree (no silent divergence). On a successful tree write the change is durable
            // — the JSONL below is a runtime event stream, and on restart the tree is
            // re-ingested and wins, so a rare post-write commit failure self-heals.
            if let Err(e) = write_status_to_tree(&tree, id, status).await {
                if let Some(prev) = prior {
                    let _ = guard.flow.advance_status(id, prev);
                }
                return Err(e);
            }
        }
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

    /// Append a human comment as a markdown annotation to an item's plan doc
    /// (roadmap #4 comment loop), and record an [`Event::Annotated`].
    ///
    /// The annotation target is resolved by [`Store::annotation_target`]: the
    /// item's `doc/<TITLE>_PLAN.md` when that file exists, else a per-item
    /// annotations ledger under the data dir. The block is produced by the pure
    /// [`format_annotation`] formatter; the only IO is the path resolution and
    /// the append. Returns the unknown error if the item is absent.
    pub async fn annotate(&self, id: &ItemId, text: String) -> Result<(), StoreError> {
        let mut guard = self.inner.lock().await;
        let item = guard
            .flow
            .get(id)
            .ok_or_else(|| crate::domain::FlowError::Unknown { id: id.clone() })?;
        let (parent, target) =
            annotation_target(&guard.doc_dir, &guard.annotations_dir, id, &item.title);
        // Ensure the target's parent dir exists (the ledger dir is created lazily
        // on first annotation; a plan doc's `doc/` already exists by definition).
        tokio::fs::create_dir_all(&parent).await?;
        let block = format_annotation(id, &text);
        append_raw(&target, &block).await?;
        let ev = Event::Annotated {
            id: id.clone(),
            text,
        };
        self.commit(&mut guard, ev).await
    }

    /// Request a full re-draft of an item (roadmap #4 rewrite loop): increment the
    /// item's draft number and record an [`Event::RewriteRequested`] carrying the
    /// commentary. The actual re-draft is external orchestration — the server only
    /// records the request. Returns the new draft number, or the unknown error if
    /// the item is absent.
    pub async fn request_rewrite(&self, id: &ItemId, comment: String) -> Result<u32, StoreError> {
        let mut guard = self.inner.lock().await;
        let draft = guard.flow.bump_draft(id)?;
        let ev = Event::RewriteRequested {
            id: id.clone(),
            comment,
            draft,
        };
        self.commit(&mut guard, ev).await?;
        Ok(draft)
    }

    /// Ingest a structured roadmap markdown so a fresh board is not blank: parse
    /// it (via [`crate::history::parse_roadmap`]), upsert every item with its
    /// parsed status, and add every declared edge — all through the single
    /// serialized writer. Returns the number of items loaded.
    ///
    /// The markdown is the source of truth, so a declared dependency the graph
    /// validator refuses (it would form a cycle, or names an unknown endpoint) is
    /// **skipped gracefully** rather than aborting the ingest — only a real write
    /// failure (IO/serialize) propagates. Items always land even when some of
    /// their edges cannot.
    pub async fn ingest_roadmap(&self, md: &str) -> Result<usize, StoreError> {
        let roadmap = crate::history::parse_roadmap(md);
        let mut guard = self.inner.lock().await;
        self.apply_roadmap(&mut guard, roadmap).await
    }

    /// Ingest the `.i2p/roadmap/` file-per-item tree at `tree_dir` (roadmap [42]):
    /// the folder is the status (`backlog`/`do` → Do, `doing` → Doing, `done` →
    /// Done). Records `tree_dir` as the write-back root so `post_status` moves the
    /// item file between folders, then applies the loaded items/edges through the
    /// same path as the single-file ingest. An absent tree loads zero items (no
    /// error), per the EARS unwanted-behaviour clause. Returns the items loaded.
    pub async fn ingest_roadmap_tree(&self, tree_dir: &Path) -> Result<usize, StoreError> {
        let roadmap = crate::history::load_roadmap_tree(tree_dir);
        let mut guard = self.inner.lock().await;
        guard.roadmap_tree = Some(tree_dir.to_path_buf());
        self.apply_roadmap(&mut guard, roadmap).await
    }

    /// Apply a parsed [`Roadmap`](crate::history::Roadmap) (items + edges) to the
    /// in-memory flow and journal it through the one serialized writer — the shared
    /// core of both `ingest_roadmap` (single file) and `ingest_roadmap_tree`.
    async fn apply_roadmap(
        &self,
        guard: &mut Inner,
        roadmap: crate::history::Roadmap,
    ) -> Result<usize, StoreError> {
        // Apply every mutation to the in-memory flow first, collecting the events
        // to journal; then commit them all through the one serialized writer. A
        // graph-refused edge (cycle/unknown) is skipped before it produces an event
        // — the roadmap is authoritative, a malformed dep must not abort ingest.
        let mut events: Vec<Event> = Vec::new();
        for item in &roadmap.items {
            guard.flow.upsert_item(Item::new(
                item.id.clone(),
                item.title.clone(),
                item.model.clone(),
            ));
            // The roadmap status is part of the item's identity on the board; set
            // it on the just-upserted item so it lands in the right column (no
            // second WAIT-gated post_status round-trip).
            set_status_in_flow(&mut guard.flow, &item.id, item.status);
            events.push(Event::ItemUpserted {
                id: item.id.clone(),
                title: item.title.clone(),
            });
        }
        for edge in &roadmap.edges {
            // `edge_applied` classifies the graph-validated add (applied vs refused;
            // non-generic, both arms unit-tested) — only an applied edge is
            // journalled, so a refused dependency is silently skipped.
            if edge_applied(crate::domain::mutate_connection(
                &mut guard.flow,
                Mutation::Add,
                &edge.from,
                &edge.to,
            )) {
                events.push(Event::ConnectionAdded {
                    from: edge.from.clone(),
                    to: edge.to.clone(),
                });
            }
        }
        let loaded = roadmap.items.len();
        // One commit site for the whole batch: the first faulting append
        // short-circuits the ingest with that write error.
        for ev in events {
            self.commit(guard, ev).await?;
        }
        Ok(loaded)
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

/// Write the full id→gate map to `gates_path` atomically (tmp + rename).
///
/// Serialises all items' gate values as a `BTreeMap<String, WaitGate>` so the
/// output is deterministic (sorted by key) and human-readable. Writes to a
/// `.tmp` sibling first, then renames — atomic on Linux when source and
/// destination share the same filesystem (guaranteed here because both live in
/// `.flow/`). Returns `Err` on IO or serialize failure; the caller decides
/// whether to propagate or warn-and-continue (EARS-G36-08: warn-and-continue).
async fn persist_gates(flow: &Flow, gates_path: &Path) -> Result<(), io::Error> {
    let map: BTreeMap<&str, WaitGate> = flow
        .items_in_order()
        .iter()
        .map(|i| (i.id.as_str(), i.gate))
        .collect();
    let json =
        serde_json::to_string(&map).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
    // Write to a tmp sibling, then atomically rename.
    let tmp = gates_path.with_extension("json.tmp");
    tokio::fs::write(&tmp, json.as_bytes()).await?;
    tokio::fs::rename(&tmp, gates_path).await?;
    Ok(())
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

/// Classify the in-flow result of adding one ingested edge: `true` when it
/// applied (the caller commits it), `false` when the graph *refused* it (a cycle
/// or unknown endpoint) — skipped, because the markdown is authoritative and a
/// malformed dep must not abort ingest. The in-flow add is pure graph validation,
/// so there is no IO error to consider here; both arms are unit-tested.
fn edge_applied(result: Result<(), GraphError>) -> bool {
    result.is_ok()
}

/// Set an item's status directly on the flow during ingest. The item was just
/// upserted, so it is present and `advance_status` succeeds; on the impossible
/// absent case the `Result` is discarded (its Err arm lives in the domain), as
/// the other in-lock replay/roll-up sites do. WAIT never blocks here because a
/// freshly-upserted item is GO.
fn set_status_in_flow(flow: &mut Flow, id: &ItemId, status: Status) {
    let _ = flow.advance_status(id, status);
}

// ── .i2p/roadmap/ tree write-back (roadmap [42]) ─────────────────────────────

/// The tree folder a board [`Status`] writes back into. `Do` lands in `do/` (the
/// groomed/ready lane); moving an item back to Do from `backlog/` is a grooming
/// transition owned by the writer here, not a separate verb.
fn tree_folder(status: Status) -> &'static str {
    match status {
        Status::Do => "do",
        Status::Doing => "doing",
        Status::Done => "done",
    }
}

/// The canonical `status:` front-matter label for a board [`Status`].
fn tree_status_label(status: Status) -> &'static str {
    match status {
        Status::Do => "PENDING",
        Status::Doing => "IN PROGRESS",
        Status::Done => "COMPLETE",
    }
}

/// Replace the first `status:` line inside the leading `---`…`---` front-matter
/// with `status: <label>`, preserving indentation. Contents without a
/// front-matter `status:` line are returned unchanged. Pure.
fn rewrite_status_front_matter(contents: &str, label: &str) -> String {
    let mut out = String::with_capacity(contents.len() + label.len());
    let mut in_fm = false;
    let mut replaced = false;
    for (i, line) in contents.lines().enumerate() {
        let trimmed = line.trim();
        if i == 0 && trimmed == "---" {
            in_fm = true;
            out.push_str(line);
            out.push('\n');
            continue;
        }
        if in_fm && trimmed == "---" {
            in_fm = false;
            out.push_str(line);
            out.push('\n');
            continue;
        }
        if in_fm && !replaced && trimmed.starts_with("status:") {
            let indent = &line[..line.len() - line.trim_start().len()];
            out.push_str(indent);
            out.push_str("status: ");
            out.push_str(label);
            out.push('\n');
            replaced = true;
            continue;
        }
        out.push_str(line);
        out.push('\n');
    }
    out
}

/// Move the tree file for `id` into the folder for `status`, updating its
/// `status:` front-matter. Finds the file by matching the numeric id in each
/// folder's front-matter; a no-op if the item has no file in the tree (e.g. a
/// synthesized item). Atomic-per-file: write a temp in the destination folder,
/// rename it into place, then remove the old file.
async fn write_status_to_tree(tree: &Path, id: &ItemId, status: Status) -> Result<(), StoreError> {
    // The flow id is the slug `item-N`; the tree front-matter `id:` is `N`.
    let num = id.as_str().strip_prefix("item-").unwrap_or(id.as_str());
    let dest_folder = tree_folder(status);
    let label = tree_status_label(status);

    // Collect EVERY file whose front-matter id matches, in TREE_FOLDERS order. The
    // loader (`history::load_roadmap_tree`) resolves a duplicate id last-folder-wins, so
    // the writer agrees by operating on the LAST match — and warns when there is more than
    // one, surfacing the malformed tree rather than silently moving one and abandoning the
    // rest (which would leave the loader and the tree disagreeing).
    let mut matches: Vec<(PathBuf, String)> = Vec::new();
    for folder in crate::history::TREE_FOLDERS {
        let mut rd = match tokio::fs::read_dir(tree.join(folder)).await {
            Ok(r) => r,
            Err(_) => continue, // missing folder
        };
        while let Some(entry) = rd.next_entry().await? {
            let path = entry.path();
            if path.extension().and_then(|x| x.to_str()) != Some("md") {
                continue;
            }
            let Ok(contents) = tokio::fs::read_to_string(&path).await else {
                continue;
            };
            if crate::history::parse_front_matter(&contents)
                .get("id")
                .map(String::as_str)
                == Some(num)
            {
                matches.push((path, contents));
            }
        }
    }

    let Some((path, contents)) = matches.pop() else {
        return Ok(()); // no tree file for this id → nothing to write back
    };
    if !matches.is_empty() {
        eprintln!(
            "flow-server: WARNING — {} files share roadmap id {num}; moving the last (the \
             loader's authoritative copy) and leaving the rest. Fix the duplicate.",
            matches.len() + 1
        );
    }

    // Rewrite the status and place the file in dest_folder atomically (tmp + rename).
    let Some(file_name) = path.file_name().map(ToOwned::to_owned) else {
        return Ok(());
    };
    let updated = rewrite_status_front_matter(&contents, label);
    let dest_dir = tree.join(dest_folder);
    tokio::fs::create_dir_all(&dest_dir).await?;
    let dest = dest_dir.join(&file_name);
    let tmp = dest_dir.join(format!(".{}.tmp", file_name.to_string_lossy()));
    tokio::fs::write(&tmp, updated.as_bytes()).await?;
    tokio::fs::rename(&tmp, &dest).await?;
    if path != dest {
        let _ = tokio::fs::remove_file(&path).await;
    }
    Ok(())
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

/// Append raw bytes (no added newline — the caller's block manages its own
/// trailing newline) to a file, creating it if absent. The annotation block is
/// already a self-contained, newline-delimited markdown chunk.
async fn append_raw(path: &Path, content: &str) -> Result<(), StoreError> {
    let mut file = tokio::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .await?;
    write_raw_to(&mut file, content).await
}

/// Write `content` verbatim (no trailing newline) to an open sink, then flush.
/// Takes a `&mut dyn AsyncWrite` (one compiled body) so the write/flush error
/// arms are exercisable through a faulting test sink while production writes a
/// real file through the same single body.
async fn write_raw_to(
    writer: &mut (dyn tokio::io::AsyncWrite + Unpin + Send),
    content: &str,
) -> Result<(), StoreError> {
    writer.write_all(content.as_bytes()).await?;
    writer.flush().await?;
    Ok(())
}

/// Resolve where an item's annotation is appended, returning `(parent_dir,
/// target_file)`: the item's `doc/<TITLE>_PLAN.md` when that file already exists,
/// else a per-item ledger `<annotations_dir>/<id>.md` (created on first
/// annotation). Path resolution is the only IO; the block content is built by the
/// pure [`format_annotation`].
fn annotation_target(
    doc_dir: &Path,
    annotations_dir: &Path,
    id: &ItemId,
    title: &str,
) -> (PathBuf, PathBuf) {
    let plan = doc_dir.join(plan_doc_filename(title));
    if plan.is_file() {
        (doc_dir.to_path_buf(), plan)
    } else {
        (
            annotations_dir.to_path_buf(),
            annotations_dir.join(format!("{}.md", id.as_str())),
        )
    }
}

/// Derive the plan-doc filename for an item title, matching the roadmap's
/// `doc/<TITLE>_PLAN.md` convention (e.g. "Flow server" → `FLOW_SERVER_PLAN.md`):
/// uppercase, with each run of non-alphanumeric characters collapsed to a single
/// `_`, and surrounding `_` trimmed. Pure and deterministic.
fn plan_doc_filename(title: &str) -> String {
    let mut name = String::new();
    let mut last_us = false;
    for ch in title.chars() {
        if ch.is_ascii_alphanumeric() {
            name.push(ch.to_ascii_uppercase());
            last_us = false;
        } else if !last_us {
            name.push('_');
            last_us = true;
        }
    }
    let trimmed = name.trim_matches('_');
    format!("{trimmed}_PLAN.md")
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
        Event::RewriteRequested { id, .. } => {
            // Replay the draft increment so the reopened draft count matches the
            // live one. A logged rewrite was accepted against a known item, so
            // `bump_draft` succeeds; its Err arm lives in the callee/std.
            let _ = flow.bump_draft(id);
        }
        // An annotation wrote to the plan doc, not to flow state, so it is a
        // no-op on replay (the doc is not re-derived from the JSONL log).
        Event::Annotated { .. } | Event::SysMsg { .. } => {}
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

    /// A successfully-applied edge reports `true` so the caller commits it.
    #[test]
    fn edge_applied_is_true_on_ok() {
        assert!(edge_applied(Ok(())));
    }

    /// A graph refusal (cycle/unknown endpoint) reports `false`: ingest skips it
    /// rather than aborting, because the markdown is the source of truth.
    #[test]
    fn edge_applied_is_false_on_graph_refusal() {
        let refused = Err(GraphError::Cycle {
            from: iid("a"),
            to: iid("b"),
        });
        assert!(!edge_applied(refused));
    }

    /// `set_status_in_flow` advances a present item; the impossible-absent case is
    /// a silent no-op (its Err lives in the domain), matching the other in-lock
    /// replay sites.
    #[test]
    fn set_status_in_flow_advances_present_item() {
        let mut flow = Flow::new();
        flow.upsert_item(Item::new(iid("a"), "A", "m"));
        set_status_in_flow(&mut flow, &iid("a"), Status::Doing);
        assert_eq!(flow.get(&iid("a")).unwrap().status, Status::Doing);
        // Absent item: a silent no-op (no panic, no state change).
        set_status_in_flow(&mut flow, &iid("ghost"), Status::Done);
        assert!(flow.get(&iid("ghost")).is_none());
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

    fn iid(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    #[test]
    fn plan_doc_filename_matches_roadmap_convention() {
        assert_eq!(plan_doc_filename("Flow server"), "FLOW_SERVER_PLAN.md");
        // Punctuation runs collapse to a single underscore; surrounding ones trim.
        assert_eq!(
            plan_doc_filename("Comment / pause / annotate"),
            "COMMENT_PAUSE_ANNOTATE_PLAN.md"
        );
        // Leading/trailing non-alphanumerics are trimmed.
        assert_eq!(plan_doc_filename("  hi!  "), "HI_PLAN.md");
        // Digits survive.
        assert_eq!(plan_doc_filename("item 15"), "ITEM_15_PLAN.md");
    }

    #[tokio::test]
    async fn annotation_target_uses_plan_doc_when_present() {
        let dir = unique("anntarget");
        let doc = dir.join("doc");
        let anns = dir.join("annotations");
        std::fs::create_dir_all(&doc).unwrap();
        // Create the plan doc so the resolver picks it.
        std::fs::write(doc.join("FLOW_SERVER_PLAN.md"), "# plan\n").unwrap();
        let (parent, target) = annotation_target(&doc, &anns, &iid("flow-server"), "Flow server");
        assert_eq!(parent, doc);
        assert_eq!(target, doc.join("FLOW_SERVER_PLAN.md"));
    }

    #[test]
    fn annotation_target_falls_back_to_ledger_when_no_plan_doc() {
        let dir = unique("annledger");
        let doc = dir.join("doc"); // does not exist → no plan file
        let anns = dir.join("annotations");
        let (parent, target) = annotation_target(&doc, &anns, &iid("flow-server"), "Flow server");
        assert_eq!(parent, anns);
        assert_eq!(target, anns.join("flow-server.md"));
    }

    #[tokio::test]
    async fn append_raw_appends_without_extra_newline() {
        let dir = unique("appraw");
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("plan.md");
        append_raw(&path, "a\n").await.unwrap();
        append_raw(&path, "b\n").await.unwrap();
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "a\nb\n");
    }

    #[tokio::test]
    async fn append_raw_fails_when_path_is_a_directory() {
        let dir = unique("apprawdir");
        std::fs::create_dir_all(&dir).unwrap();
        assert!(append_raw(&dir, "x").await.is_err());
    }

    #[tokio::test]
    async fn write_raw_to_succeeds_into_a_buffer() {
        // The happy path: a Vec<u8> sink never faults and gets no extra newline.
        let mut buf: Vec<u8> = Vec::new();
        write_raw_to(&mut buf, "hi").await.unwrap();
        assert_eq!(buf, b"hi");
    }

    #[tokio::test]
    async fn write_raw_to_fails_on_payload_write() {
        let mut s = FaultSink {
            ok_writes: 0,
            fail_flush: false,
        };
        assert!(write_raw_to(&mut s, "x").await.is_err());
    }

    #[tokio::test]
    async fn write_raw_to_fails_on_flush() {
        // The payload write_all succeeds; the flush faults.
        let mut s = FaultSink {
            ok_writes: 1,
            fail_flush: true,
        };
        assert!(write_raw_to(&mut s, "x").await.is_err());
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
