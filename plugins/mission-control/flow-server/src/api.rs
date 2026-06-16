//! The axum router: static-serve + the REST verb surface, the WS upgrade, and
//! the MCP JSON-RPC endpoint — all behind the shared bearer-token gate.

use std::path::PathBuf;
use std::sync::Arc;

use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{json, Value};
use tower_http::services::ServeDir;

use crate::auth::{require_token, Token};
use crate::domain::graph::Mutation;
use crate::domain::{FlowError, GraphError, ItemId, Status, WaitGate};
use crate::store::{Store, StoreError};
use crate::{mcp, ws};

/// Shared application state handed to every handler.
#[derive(Clone)]
pub struct AppState {
    /// The single serialized writer.
    pub store: Arc<Store>,
    /// The shared bearer token (also used by the WS handshake check).
    pub token: Token,
}

/// Build the full router: static assets, REST verbs, WS, and MCP, all gated.
pub fn build_router(store: Arc<Store>, token: Token, static_dir: PathBuf) -> Router {
    let state = AppState {
        store,
        token: token.clone(),
    };

    // The gated surfaces (REST verbs + MCP) sit behind the auth middleware.
    let gated = Router::new()
        .route("/api/items", get(list_items))
        .route("/api/items/:id", get(get_item))
        .route("/api/items/:id/gate", post(set_wait_go))
        .route("/api/items/:id/status", post(post_status))
        .route("/api/items/:id/spend", post(append_spend))
        .route("/api/items/:id/model", post(set_item_model))
        .route("/api/items/:id/annotate", post(annotate))
        .route("/api/items/:id/rewrite", post(request_rewrite))
        .route("/api/roadmap/rendered", get(roadmap_rendered))
        .route("/api/connection/validate", post(validate_connection))
        .route("/api/connection/mutate", post(mutate_connection))
        .route("/api/sysmsg", post(append_sysmsg))
        .route("/api/events", get(list_events))
        .route("/mcp", post(mcp::handle))
        .layer(axum::middleware::from_fn_with_state(
            token.clone(),
            require_token,
        ))
        .with_state(state.clone());

    // The WS route checks the token itself (the handshake cannot use the
    // Authorization header from a browser, so it accepts `?token=`).
    let ws_route = Router::new()
        .route("/ws", get(ws::upgrade))
        .with_state(state);

    Router::new()
        .merge(gated)
        .merge(ws_route)
        .fallback_service(ServeDir::new(static_dir))
}

// --- request bodies -------------------------------------------------------

#[derive(Deserialize)]
struct GateBody {
    gate: WaitGate,
}

#[derive(Deserialize)]
struct StatusBody {
    status: Status,
}

#[derive(Deserialize)]
struct SpendBody {
    delta: u64,
}

#[derive(Deserialize)]
struct ModelBody {
    model: String,
}

#[derive(Deserialize)]
struct ValidateBody {
    from: String,
    to: String,
}

#[derive(Deserialize)]
struct MutateBody {
    op: String,
    from: String,
    to: String,
}

#[derive(Deserialize)]
struct SysMsgBody {
    text: String,
}

#[derive(Deserialize)]
struct AnnotateBody {
    text: String,
}

#[derive(Deserialize)]
struct RewriteBody {
    comment: String,
}

#[derive(Deserialize)]
struct EventsQuery {
    /// Optional `kind` filter (the event's serde tag, e.g. `sys_msg`).
    kind: Option<String>,
}

// --- handlers -------------------------------------------------------------

async fn list_items(State(state): State<AppState>) -> Response {
    let flow = state.store.snapshot().await;
    let events = match state.store.read_events().await {
        Ok(e) => e,
        Err(e) => return store_error_response(e),
    };
    let items: Vec<Value> = flow
        .items_in_order()
        .iter()
        .map(|i| {
            let deps = deps_for(i, flow.edges());
            let annotations = annotations_for(i, &events);
            item_json(i, &deps, &annotations)
        })
        .collect();
    Json(items).into_response()
}

async fn get_item(State(state): State<AppState>, Path(id): Path<String>) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    let flow = state.store.snapshot().await;
    let events = match state.store.read_events().await {
        Ok(e) => e,
        Err(e) => return store_error_response(e),
    };
    match flow.get(&id) {
        Some(item) => {
            let deps = deps_for(item, flow.edges());
            let annotations = annotations_for(item, &events);
            Json(item_json(item, &deps, &annotations)).into_response()
        }
        None => error_response(StatusCode::NOT_FOUND, "unknown", "no such item"),
    }
}

async fn set_wait_go(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<GateBody>,
) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    map_store(state.store.set_gate(&id, body.gate).await)
}

async fn post_status(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<StatusBody>,
) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    map_store(state.store.post_status(&id, body.status).await)
}

async fn append_spend(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<SpendBody>,
) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    match state.store.append_spend(&id, body.delta).await {
        Ok(total) => Json(json!({ "total": total })).into_response(),
        Err(e) => store_error_response(e),
    }
}

async fn set_item_model(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<ModelBody>,
) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    map_store(state.store.set_item_model(&id, body.model).await)
}

async fn validate_connection(
    State(state): State<AppState>,
    Json(body): Json<ValidateBody>,
) -> Response {
    let (from, to) = match (parse_id(&body.from), parse_id(&body.to)) {
        (Ok(f), Ok(t)) => (f, t),
        (Err(e), _) | (_, Err(e)) => return id_error_response(e),
    };
    match state.store.validate_connection(&from, &to).await {
        Ok(()) => Json(json!({ "ok": true })).into_response(),
        Err(e) => graph_error_response(e),
    }
}

async fn mutate_connection(
    State(state): State<AppState>,
    Json(body): Json<MutateBody>,
) -> Response {
    let mutation = match body.op.as_str() {
        "add" => Mutation::Add,
        "remove" => Mutation::Remove,
        other => {
            return error_response(
                StatusCode::BAD_REQUEST,
                "bad_op",
                &format!("unknown op {other:?}"),
            )
        }
    };
    let (from, to) = match (parse_id(&body.from), parse_id(&body.to)) {
        (Ok(f), Ok(t)) => (f, t),
        (Err(e), _) | (_, Err(e)) => return id_error_response(e),
    };
    map_store(state.store.mutate_connection(mutation, from, to).await)
}

async fn append_sysmsg(State(state): State<AppState>, Json(body): Json<SysMsgBody>) -> Response {
    map_store(state.store.append_sysmsg(body.text).await)
}

/// Return the full event log (append order, newest-last) as a JSON array, each
/// event in its canonical jsonl/serde shape. `?kind=<tag>` filters to one event
/// kind (the serde `kind` tag, e.g. `sys_msg`). Feeds the frontend's
/// system-message feed (#6), which loads past events on connect.
async fn list_events(State(state): State<AppState>, Query(q): Query<EventsQuery>) -> Response {
    match state.store.read_events().await {
        Ok(events) => Json(events_json(&events, q.kind.as_deref())).into_response(),
        Err(e) => store_error_response(e),
    }
}

async fn annotate(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<AnnotateBody>,
) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    map_store(state.store.annotate(&id, body.text).await)
}

async fn request_rewrite(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<RewriteBody>,
) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    match state.store.request_rewrite(&id, body.comment).await {
        Ok(draft) => Json(json!({ "draft": draft })).into_response(),
        Err(e) => store_error_response(e),
    }
}

/// The local-compute roadmap view (roadmap #15): a deterministic, byte-stable
/// rendered table returned as `text/plain`. The agent presents this directly,
/// spending ~0 LLM tokens on formatting.
async fn roadmap_rendered(State(state): State<AppState>) -> Response {
    let flow = state.store.snapshot().await;
    let rendered = crate::domain::render_roadmap(&flow);
    (
        [(
            axum::http::header::CONTENT_TYPE,
            "text/plain; charset=utf-8",
        )],
        rendered,
    )
        .into_response()
}

// --- shared rendering -----------------------------------------------------

/// Render an item as the canonical JSON the REST + MCP surfaces both return.
/// `deps` is the pre-computed list of ids this item depends on (from the flow's
/// edge list, `edge.from == item.id`). `annotations` is the ordered list of
/// annotation text strings from `Annotated` events for this item, newest-last.
/// `commits` is always an empty array in this cycle (future work). `pr` is null.
pub(crate) fn item_json(
    item: &crate::domain::Item,
    deps: &[String],
    annotations: &[String],
) -> Value {
    json!({
        "id": item.id.as_str(),
        "title": item.title,
        "status": item.status,
        "gate": item.gate,
        "tokens": item.tokens,
        "model": item.model,
        "draft": item.draft,
        "deps": deps,
        "annotations": annotations,
        "commits": [],
        "pr": null,
    })
}

/// Compute the dep ids for an item: all edges where `edge.from == item.id`,
/// collecting `edge.to` as a string. Pure — no IO.
pub(crate) fn deps_for(item: &crate::domain::Item, edges: &[crate::domain::Edge]) -> Vec<String> {
    edges
        .iter()
        .filter(|e| e.from == item.id)
        .map(|e| e.to.as_str().to_owned())
        .collect()
}

/// Collect annotation text strings for an item from the event log, in log order
/// (newest-last, since the log is append-only). Pure — no IO.
pub(crate) fn annotations_for(
    item: &crate::domain::Item,
    events: &[crate::domain::Event],
) -> Vec<String> {
    events
        .iter()
        .filter_map(|e| match e {
            crate::domain::Event::Annotated { id, text } if id == &item.id => Some(text.clone()),
            _ => None,
        })
        .collect()
}

/// Render the event log as the JSON array both the REST and MCP surfaces return.
/// Each event is serialized in its canonical serde shape (the same `kind`-tagged
/// form as the jsonl log). When `kind` is `Some`, only events whose serde `kind`
/// tag equals it are kept; the events already carry that tag, so the filter reads
/// the rendered value rather than re-deriving it.
pub(crate) fn events_json(events: &[crate::domain::Event], kind: Option<&str>) -> Vec<Value> {
    events
        .iter()
        .map(|e| json!(e))
        .filter(|v| match kind {
            Some(want) => v.get("kind").and_then(Value::as_str) == Some(want),
            None => true,
        })
        .collect()
}

fn parse_id(raw: &str) -> Result<ItemId, crate::domain::IdError> {
    ItemId::new(raw)
}

fn id_error_response(err: crate::domain::IdError) -> Response {
    error_response(StatusCode::BAD_REQUEST, "bad_id", &err.to_string())
}

fn map_store(result: Result<(), StoreError>) -> Response {
    match result {
        Ok(()) => Json(json!({ "ok": true })).into_response(),
        Err(e) => store_error_response(e),
    }
}

fn store_error_response(err: StoreError) -> Response {
    match err {
        StoreError::Graph(g) => graph_error_response(g),
        StoreError::Flow(f) => flow_error_response(f),
        StoreError::Io(_) | StoreError::Serialize(_) => error_response(
            StatusCode::INTERNAL_SERVER_ERROR,
            "io",
            "internal store error",
        ),
    }
}

fn flow_error_response(err: FlowError) -> Response {
    match err {
        FlowError::Waiting { .. } => {
            error_response(StatusCode::CONFLICT, "waiting", &err.to_string())
        }
        FlowError::Unknown { .. } => {
            error_response(StatusCode::NOT_FOUND, "unknown", &err.to_string())
        }
        FlowError::Graph(g) => graph_error_response(g),
    }
}

fn graph_error_response(err: GraphError) -> Response {
    let code = match err {
        GraphError::Cycle { .. } => "cycle",
        GraphError::BrokenDep { .. } => "broken_dep",
        GraphError::Unknown { .. } => "unknown",
    };
    let status = match err {
        GraphError::Unknown { .. } => StatusCode::NOT_FOUND,
        _ => StatusCode::CONFLICT,
    };
    error_response(status, code, &err.to_string())
}

fn error_response(status: StatusCode, code: &str, message: &str) -> Response {
    (status, Json(json!({ "error": code, "message": message }))).into_response()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::ItemId;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    /// The IO/Serialize store error renders a 500 internal error. This path is
    /// not reachable through a normal request (a write only fails on a real disk
    /// fault), so the renderer is pinned directly.
    #[test]
    fn store_io_error_renders_500() {
        let err = StoreError::Io(std::io::Error::other("disk"));
        assert_eq!(
            store_error_response(err).status(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
    }

    #[test]
    fn store_serialize_error_renders_500() {
        // A serde_json error wrapped as a Serialize store error.
        let serde_err = serde_json::from_str::<serde_json::Value>("{").unwrap_err();
        let err = StoreError::Serialize(serde_err);
        assert_eq!(
            store_error_response(err).status(),
            StatusCode::INTERNAL_SERVER_ERROR
        );
    }

    /// A `FlowError::Graph` cannot arise from a carriage-advance verb (only the
    /// connection verbs raise graph errors, and they surface as `StoreError::Graph`
    /// directly), but the renderer handles it defensively: delegate to the graph
    /// renderer. Pin that delegation directly.
    #[test]
    fn flow_graph_error_delegates_to_graph_renderer() {
        let err = FlowError::Graph(GraphError::Unknown { id: id("z") });
        // Unknown graph endpoint → 404, matching graph_error_response.
        assert_eq!(flow_error_response(err).status(), StatusCode::NOT_FOUND);
    }

    /// The graph BrokenDep variant renders 409 with the broken_dep code (the
    /// non-Unknown, non-Cycle status arm).
    #[test]
    fn graph_broken_dep_renders_409() {
        let err = GraphError::BrokenDep {
            from: id("a"),
            to: id("b"),
        };
        assert_eq!(graph_error_response(err).status(), StatusCode::CONFLICT);
    }

    // --- item_json extended shape -------------------------------------------

    fn make_item(s: &str) -> crate::domain::Item {
        crate::domain::Item::new(id(s), s, "claude-sonnet-4-6")
    }

    /// item_json with no deps or annotations produces empty arrays and null pr.
    #[test]
    fn item_json_empty_deps_and_annotations() {
        let item = make_item("a");
        let v = item_json(&item, &[], &[]);
        assert_eq!(v["id"], "a");
        assert_eq!(v["deps"], serde_json::json!([]));
        assert_eq!(v["annotations"], serde_json::json!([]));
        assert_eq!(v["commits"], serde_json::json!([]));
        assert_eq!(v["pr"], serde_json::Value::Null);
    }

    /// item_json includes the draft field.
    #[test]
    fn item_json_includes_draft() {
        let item = make_item("a");
        let v = item_json(&item, &[], &[]);
        assert_eq!(v["draft"], 0);
    }

    /// item_json with deps propagates them to the JSON array.
    #[test]
    fn item_json_with_deps() {
        let item = make_item("b");
        let v = item_json(&item, &["a".to_string(), "c".to_string()], &[]);
        assert_eq!(v["deps"], serde_json::json!(["a", "c"]));
    }

    /// item_json with annotations propagates them in order.
    #[test]
    fn item_json_with_annotations() {
        let item = make_item("a");
        let v = item_json(&item, &[], &["first".to_string(), "second".to_string()]);
        assert_eq!(v["annotations"], serde_json::json!(["first", "second"]));
    }

    // --- deps_for -----------------------------------------------------------

    /// deps_for returns the `to` ids for edges where `from == item.id`.
    #[test]
    fn deps_for_returns_outgoing_edges() {
        use crate::domain::Edge;
        let item = make_item("a");
        let edges = vec![
            Edge {
                from: id("a"),
                to: id("b"),
            },
            Edge {
                from: id("a"),
                to: id("c"),
            },
            Edge {
                from: id("x"),
                to: id("a"),
            }, // not a dep of "a"
        ];
        let deps = deps_for(&item, &edges);
        assert_eq!(deps, vec!["b".to_string(), "c".to_string()]);
    }

    /// deps_for returns empty when no edges match.
    #[test]
    fn deps_for_no_match_returns_empty() {
        let item = make_item("z");
        let edges = vec![crate::domain::Edge {
            from: id("a"),
            to: id("b"),
        }];
        let deps = deps_for(&item, &edges);
        assert!(deps.is_empty());
    }

    // --- annotations_for ----------------------------------------------------

    /// annotations_for collects only Annotated events for the given item.
    #[test]
    fn annotations_for_filters_by_item_id() {
        use crate::domain::Event;
        let item = make_item("a");
        let events = vec![
            Event::Annotated {
                id: id("a"),
                text: "note one".into(),
            },
            Event::Annotated {
                id: id("b"),
                text: "other item".into(),
            },
            Event::Annotated {
                id: id("a"),
                text: "note two".into(),
            },
            Event::SysMsg { text: "sys".into() },
        ];
        let annotations = annotations_for(&item, &events);
        assert_eq!(
            annotations,
            vec!["note one".to_string(), "note two".to_string()]
        );
    }

    /// annotations_for returns empty when no events match.
    #[test]
    fn annotations_for_no_match_returns_empty() {
        use crate::domain::Event;
        let item = make_item("z");
        let events = vec![Event::Annotated {
            id: id("a"),
            text: "for a".into(),
        }];
        let annotations = annotations_for(&item, &events);
        assert!(annotations.is_empty());
    }

    /// annotations_for returns empty on an event log with no Annotated events.
    #[test]
    fn annotations_for_empty_log_returns_empty() {
        use crate::domain::Event;
        let item = make_item("a");
        let events = vec![Event::SysMsg {
            text: "hello".into(),
        }];
        let annotations = annotations_for(&item, &events);
        assert!(annotations.is_empty());
    }
}
