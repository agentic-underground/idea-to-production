//! The axum router: static-serve + the REST verb surface, the WS upgrade, and
//! the MCP JSON-RPC endpoint — all behind the shared bearer-token gate.

use std::path::PathBuf;
use std::sync::Arc;

use axum::extract::{Path, State};
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

// --- handlers -------------------------------------------------------------

async fn list_items(State(state): State<AppState>) -> Response {
    let flow = state.store.snapshot().await;
    let items: Vec<Value> = flow.items_in_order().iter().map(|i| item_json(i)).collect();
    Json(items).into_response()
}

async fn get_item(State(state): State<AppState>, Path(id): Path<String>) -> Response {
    let id = match parse_id(&id) {
        Ok(id) => id,
        Err(e) => return id_error_response(e),
    };
    let flow = state.store.snapshot().await;
    match flow.get(&id) {
        Some(item) => Json(item_json(item)).into_response(),
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
pub(crate) fn item_json(item: &crate::domain::Item) -> Value {
    json!({
        "id": item.id.as_str(),
        "title": item.title,
        "status": item.status,
        "gate": item.gate,
        "tokens": item.tokens,
        "model": item.model,
    })
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
}
