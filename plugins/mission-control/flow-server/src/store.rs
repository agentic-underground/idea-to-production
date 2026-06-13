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

    /// Append token spend to an item (refused while WAIT).
    pub async fn append_spend(&self, id: &ItemId, delta: u64) -> Result<u64, StoreError> {
        let mut guard = self.inner.lock().await;
        let total = guard.flow.append_spend(id, delta)?;
        let ev = Event::SpendAppended {
            id: id.clone(),
            delta,
            total,
        };
        self.commit(&mut guard, ev).await?;
        Ok(total)
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
        let line = event.to_jsonl()?;
        let mut file = tokio::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&guard.jsonl_path)
            .await?;
        file.write_all(line.as_bytes()).await?;
        file.write_all(b"\n").await?;
        file.flush().await?;

        write_markdown(&guard.markdown_path, &guard.flow).await?;

        // A send error only means no subscribers; that is not a write failure.
        let _ = self.tx.send(event);
        Ok(())
    }
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
            let _ = flow.append_spend(id, *delta);
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
