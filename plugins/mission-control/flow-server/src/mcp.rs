//! Hand-rolled MCP JSON-RPC surface on the same router and behind the same
//! token gate as REST. The tool set mirrors the REST verbs exactly, so an agent
//! reads/mutates flow through one authoritative surface. (rmcp is intentionally
//! out for the MVP — this is a self-contained JSON-RPC handler.)

use axum::extract::State;
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde_json::{json, Value};

use crate::api::{annotations_for, deps_for, events_json, item_json, AppState};
use crate::domain::graph::Mutation;
use crate::domain::{FlowError, GraphError, ItemId, Status, WaitGate};
use crate::store::StoreError;

/// The verb names this MCP surface exposes (mirrors the REST routes).
pub const TOOLS: &[&str] = &[
    "list_items",
    "get_item",
    "set_wait_go",
    "post_status",
    "append_spend",
    "set_item_model",
    "validate_connection",
    "mutate_connection",
    "append_sysmsg",
    "render_roadmap",
    "annotate",
    "request_rewrite",
    "list_events",
];

/// One-line human description per verb, surfaced in the MCP `tools/list`
/// descriptors so clients can present each tool. Order mirrors `TOOLS`.
const TOOL_DESCRIPTIONS: &[(&str, &str)] = &[
    (
        "list_items",
        "List roadmap items grouped by status (pending/in_progress/done).",
    ),
    (
        "get_item",
        "Fetch one roadmap item by id with its deps and annotations.",
    ),
    ("set_wait_go", "Toggle an item's WAIT/GO gate."),
    (
        "post_status",
        "Move an item to a new status (the folder = the status).",
    ),
    (
        "append_spend",
        "Record token spend against an item (rolls up to ancestors).",
    ),
    (
        "set_item_model",
        "Set the model tier (Haiku/Sonnet/Opus/Fable) for an item.",
    ),
    (
        "validate_connection",
        "Validate a proposed dependency edge without applying it.",
    ),
    (
        "mutate_connection",
        "Add or remove a dependency edge between two items.",
    ),
    (
        "append_sysmsg",
        "Append a system message to the event feed.",
    ),
    (
        "render_roadmap",
        "Render 'what's on the roadmap' as text — ~0 LLM tokens.",
    ),
    ("annotate", "Annotate an item's plan (pauses the item)."),
    (
        "request_rewrite",
        "Request a plan rewrite, bumping the draft number.",
    ),
    (
        "list_events",
        "Read the append-only event log, oldest first.",
    ),
];

/// Build the MCP `tools/list` descriptor array: each verb as a
/// `{name, description, inputSchema}` object (a permissive object schema —
/// arguments are validated per-verb in `call_tool`). Bare strings are NOT a
/// conformant `tools/list` payload and prevent the client from registering.
fn tool_descriptors() -> Vec<Value> {
    TOOL_DESCRIPTIONS
        .iter()
        .map(|(name, desc)| {
            json!({
                "name": name,
                "description": desc,
                "inputSchema": { "type": "object" },
            })
        })
        .collect()
}

/// Thin axum handler: deserialises the JSON body via extractor, delegates to
/// `dispatch`, and serialises the result back into an HTTP response. The real
/// dispatch logic lives in `dispatch` so it can be called from any transport
/// (HTTP or stdio) without going through the axum extractor chain.
pub async fn handle(State(state): State<AppState>, Json(req): Json<Value>) -> Response {
    Json(dispatch(&state, req).await).into_response()
}

/// Dispatch a single JSON-RPC request, returning a JSON-RPC `Value` response.
///
/// This function is transport-agnostic: it is called by the HTTP handler
/// (`handle`) and by the stdio read loop (`run_stdio` in `main.rs`). The
/// caller is responsible for serialising the returned `Value` to the wire.
pub async fn dispatch(state: &AppState, req: Value) -> Value {
    let id = req.get("id").cloned().unwrap_or(Value::Null);
    let method = req.get("method").and_then(Value::as_str).unwrap_or("");

    match method {
        // MCP handshake: the client's mandatory first request. Without this the
        // server is dropped before any tool is exposed. We advertise the `tools`
        // capability and echo the client's requested protocol version when given.
        "initialize" => {
            let protocol = req
                .get("params")
                .and_then(|p| p.get("protocolVersion"))
                .and_then(Value::as_str)
                .unwrap_or("2024-11-05")
                .to_string();
            ok(
                id,
                json!({
                    "protocolVersion": protocol,
                    "capabilities": { "tools": {} },
                    "serverInfo": {
                        "name": "flow-server",
                        "version": env!("CARGO_PKG_VERSION"),
                    },
                }),
            )
        }
        // Post-handshake notification — acknowledged with no response by the
        // caller (it carries no `id`); see `run_stdio` / the HTTP handler.
        "notifications/initialized" | "initialized" => Value::Null,
        "tools/list" => ok(id, json!({ "tools": tool_descriptors() })),
        "tools/call" => {
            let params = req.get("params").cloned().unwrap_or(Value::Null);
            let name = params.get("name").and_then(Value::as_str).unwrap_or("");
            let args = params
                .get("arguments")
                .cloned()
                .unwrap_or_else(|| json!({}));
            call_tool(state, id, name, args).await
        }
        other => rpc_error(
            id,
            -32601,
            &format!("method not found: {other}"),
            Value::Null,
        ),
    }
}

async fn call_tool(state: &AppState, id: Value, name: &str, args: Value) -> Value {
    match name {
        "list_items" => {
            let flow = state.store.snapshot().await;
            let events = match state.store.read_events().await {
                Ok(e) => e,
                Err(e) => return store_error(id, e),
            };
            // Group items by status and (for PENDING) by gate.
            // EARS-G36-06: {"pending":{"wait":[...],"go":[...]},"in_progress":[...],"done":[...]}
            let mut pending_wait: Vec<Value> = Vec::new();
            let mut pending_go: Vec<Value> = Vec::new();
            let mut in_progress: Vec<Value> = Vec::new();
            let mut done: Vec<Value> = Vec::new();

            for i in flow.items_in_order() {
                let deps = deps_for(i, flow.edges());
                let annotations = annotations_for(i, &events);
                let v = item_json(i, &deps, &annotations);
                match i.status {
                    Status::Do => match i.gate {
                        WaitGate::Wait => pending_wait.push(v),
                        WaitGate::Go => pending_go.push(v),
                    },
                    Status::Doing => in_progress.push(v),
                    Status::Done => done.push(v),
                }
            }

            ok(
                id,
                json!({
                    "pending": {
                        "wait": pending_wait,
                        "go":   pending_go
                    },
                    "in_progress": in_progress,
                    "done":        done
                }),
            )
        }
        "get_item" => match arg_id(&args, "id") {
            Ok(item_id) => {
                let flow = state.store.snapshot().await;
                let events = match state.store.read_events().await {
                    Ok(e) => e,
                    Err(e) => return store_error(id, e),
                };
                match flow.get(&item_id) {
                    Some(item) => {
                        let deps = deps_for(item, flow.edges());
                        let annotations = annotations_for(item, &events);
                        ok(id, json!({ "item": item_json(item, &deps, &annotations) }))
                    }
                    None => rpc_error(id, -32004, "unknown item", json!({ "error": "unknown" })),
                }
            }
            Err(e) => invalid_params(id, &e),
        },
        "set_wait_go" => {
            let item_id = match arg_id(&args, "id") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            let gate = match arg_enum::<WaitGate>(&args, "gate") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            map_store(id, state.store.set_gate(&item_id, gate).await)
        }
        "post_status" => {
            let item_id = match arg_id(&args, "id") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            let status = match arg_enum::<Status>(&args, "status") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            map_store(id, state.store.post_status(&item_id, status).await)
        }
        "append_spend" => {
            let item_id = match arg_id(&args, "id") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            let delta = match args.get("delta").and_then(Value::as_u64) {
                Some(v) => v,
                None => return invalid_params(id, "delta must be a u64"),
            };
            match state.store.append_spend(&item_id, delta).await {
                Ok(total) => ok(id, json!({ "total": total })),
                Err(e) => store_error(id, e),
            }
        }
        "set_item_model" => {
            let item_id = match arg_id(&args, "id") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            let model = match args.get("model").and_then(Value::as_str) {
                Some(v) => v.to_string(),
                None => return invalid_params(id, "model must be a string"),
            };
            map_store(id, state.store.set_item_model(&item_id, model).await)
        }
        "validate_connection" => {
            let (from, to) = match arg_pair(&args) {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            match state.store.validate_connection(&from, &to).await {
                Ok(()) => ok(id, json!({ "ok": true })),
                Err(e) => graph_error(id, e),
            }
        }
        "mutate_connection" => {
            let mutation = match args.get("op").and_then(Value::as_str) {
                Some("add") => Mutation::Add,
                Some("remove") => Mutation::Remove,
                _ => return invalid_params(id, "op must be 'add' or 'remove'"),
            };
            let (from, to) = match arg_pair(&args) {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            map_store(id, state.store.mutate_connection(mutation, from, to).await)
        }
        "append_sysmsg" => {
            let text = match args.get("text").and_then(Value::as_str) {
                Some(v) => v.to_string(),
                None => return invalid_params(id, "text must be a string"),
            };
            map_store(id, state.store.append_sysmsg(text).await)
        }
        "render_roadmap" => {
            let flow = state.store.snapshot().await;
            let rendered = crate::domain::render_roadmap(&flow);
            ok(id, json!({ "rendered": rendered }))
        }
        "annotate" => {
            let item_id = match arg_id(&args, "id") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            let text = match args.get("text").and_then(Value::as_str) {
                Some(v) => v.to_string(),
                None => return invalid_params(id, "text must be a string"),
            };
            map_store(id, state.store.annotate(&item_id, text).await)
        }
        "request_rewrite" => {
            let item_id = match arg_id(&args, "id") {
                Ok(v) => v,
                Err(e) => return invalid_params(id, &e),
            };
            let comment = match args.get("comment").and_then(Value::as_str) {
                Some(v) => v.to_string(),
                None => return invalid_params(id, "comment must be a string"),
            };
            match state.store.request_rewrite(&item_id, comment).await {
                Ok(draft) => ok(id, json!({ "draft": draft })),
                Err(e) => store_error(id, e),
            }
        }
        "list_events" => {
            // Optional `kind` filter; a non-string `kind` is simply ignored
            // (returns the full log) rather than erroring.
            let kind = args.get("kind").and_then(Value::as_str);
            match state.store.read_events().await {
                Ok(events) => ok(id, json!({ "events": events_json(&events, kind) })),
                Err(e) => store_error(id, e),
            }
        }
        other => rpc_error(id, -32602, &format!("unknown tool: {other}"), Value::Null),
    }
}

// --- argument helpers -----------------------------------------------------

fn arg_id(args: &Value, key: &str) -> Result<ItemId, String> {
    let raw = args
        .get(key)
        .and_then(Value::as_str)
        .ok_or_else(|| format!("{key} must be a string"))?;
    ItemId::new(raw).map_err(|e| e.to_string())
}

fn arg_pair(args: &Value) -> Result<(ItemId, ItemId), String> {
    Ok((arg_id(args, "from")?, arg_id(args, "to")?))
}

fn arg_enum<T: serde::de::DeserializeOwned>(args: &Value, key: &str) -> Result<T, String> {
    let v = args.get(key).ok_or_else(|| format!("{key} is required"))?;
    serde_json::from_value(v.clone()).map_err(|e| format!("{key}: {e}"))
}

// --- JSON-RPC response builders ------------------------------------------
// All builders return `Value` so they can be used by both the HTTP handler
// (which wraps the result in `Json(...).into_response()`) and the stdio loop
// (which serialises the `Value` directly to stdout).

fn ok(id: Value, result: Value) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "result": result })
}

fn rpc_error(id: Value, code: i64, message: &str, data: Value) -> Value {
    json!({
        "jsonrpc": "2.0",
        "id": id,
        "error": { "code": code, "message": message, "data": data }
    })
}

fn invalid_params(id: Value, message: &str) -> Value {
    rpc_error(id, -32602, message, Value::Null)
}

fn map_store(id: Value, result: Result<(), StoreError>) -> Value {
    match result {
        Ok(()) => ok(id, json!({ "ok": true })),
        Err(e) => store_error(id, e),
    }
}

fn store_error(id: Value, err: StoreError) -> Value {
    match err {
        StoreError::Graph(g) => graph_error(id, g),
        StoreError::Flow(f) => flow_error(id, f),
        StoreError::Io(_) | StoreError::Serialize(_) => {
            rpc_error(id, -32603, "internal store error", json!({ "error": "io" }))
        }
    }
}

fn flow_error(id: Value, err: FlowError) -> Value {
    let code = match err {
        FlowError::Waiting { .. } => "waiting",
        FlowError::Unknown { .. } => "unknown",
        FlowError::Graph(g) => return graph_error(id, g),
    };
    rpc_error(id, -32000, &err.to_string(), json!({ "error": code }))
}

fn graph_error(id: Value, err: GraphError) -> Value {
    let code = match err {
        GraphError::Cycle { .. } => "cycle",
        GraphError::BrokenDep { .. } => "broken_dep",
        GraphError::Unknown { .. } => "unknown",
    };
    rpc_error(id, -32000, &err.to_string(), json!({ "error": code }))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn id_val() -> Value {
        json!(1)
    }

    /// IO/Serialize store errors render the -32603 internal error. Not reachable
    /// through a normal request (only a real disk fault triggers it), so the
    /// renderer is pinned directly.
    #[test]
    fn store_io_error_is_internal() {
        let err = StoreError::Io(std::io::Error::other("disk"));
        let v = store_error(id_val(), err);
        assert_eq!(v["error"]["code"], -32603);
        assert_eq!(v["error"]["data"]["error"], "io");
    }

    #[test]
    fn store_serialize_error_is_internal() {
        let serde_err = serde_json::from_str::<Value>("{").unwrap_err();
        let v = store_error(id_val(), StoreError::Serialize(serde_err));
        assert_eq!(v["error"]["code"], -32603);
    }

    /// A `FlowError::Graph` cannot arise from a carriage-advance verb, but the
    /// renderer delegates defensively to the graph renderer. Pin that.
    #[test]
    fn flow_graph_error_delegates_to_graph() {
        let inner = GraphError::Unknown {
            id: ItemId::new("z").unwrap(),
        };
        let v = flow_error(id_val(), FlowError::Graph(inner));
        assert_eq!(v["error"]["code"], -32000);
        assert_eq!(v["error"]["data"]["error"], "unknown");
    }

    /// The graph BrokenDep variant renders the broken_dep code (the middle arm).
    #[test]
    fn graph_broken_dep_code() {
        let err = GraphError::BrokenDep {
            from: ItemId::new("a").unwrap(),
            to: ItemId::new("b").unwrap(),
        };
        let v = graph_error(id_val(), err);
        assert_eq!(v["error"]["data"]["error"], "broken_dep");
    }
}
