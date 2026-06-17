//! Shared application state and the render helpers the MCP verb surface returns.
//!
//! The web governance UI (the axum HTTP router, the REST verbs, the WebSocket
//! upgrade, and the static-asset server) was removed in roadmap #39; the MCP
//! core now runs over stdio only. What remains here is `AppState` (the shared,
//! single-writer handle) and the pure JSON render helpers (`item_json`,
//! `deps_for`, `annotations_for`, `events_json`) that `mcp::dispatch` calls.

use std::sync::Arc;

use serde_json::{json, Value};

use crate::auth::Token;
use crate::store::Store;

/// Shared application state handed to the MCP dispatch surface.
#[derive(Clone)]
pub struct AppState {
    /// The single serialized writer.
    pub store: Arc<Store>,
    /// Reserved bearer token. No token file is loaded — the stdio MCP transport
    /// has no auth layer, so this field is filled with a placeholder and is
    /// never read. Retained for back-compat against a future authed transport.
    pub token: Token,
}

// --- shared rendering -----------------------------------------------------

/// Render an item as the canonical JSON the MCP surface returns. `deps` is the
/// pre-computed list of ids this item depends on (from the flow's edge list,
/// `edge.from == item.id`). `annotations` is the ordered list of annotation
/// text strings from `Annotated` events for this item, newest-last. `commits`
/// is always an empty array in this cycle (future work). `pr` is null.
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

/// Render the event log as the JSON array the MCP surface returns. Each event is
/// serialized in its canonical serde shape (the same `kind`-tagged form as the
/// jsonl log). When `kind` is `Some`, only events whose serde `kind` tag equals
/// it are kept; the events already carry that tag, so the filter reads the
/// rendered value rather than re-deriving it.
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::ItemId;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
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

    // --- events_json --------------------------------------------------------

    /// events_json renders every event in its canonical kind-tagged shape.
    #[test]
    fn events_json_renders_all_without_filter() {
        use crate::domain::Event;
        let events = vec![
            Event::SysMsg { text: "one".into() },
            Event::Annotated {
                id: id("a"),
                text: "note".into(),
            },
        ];
        let rendered = events_json(&events, None);
        assert_eq!(rendered.len(), 2);
        assert_eq!(rendered[0]["kind"], "sys_msg");
        assert_eq!(rendered[1]["kind"], "annotated");
    }

    /// events_json with a kind filter keeps only matching events.
    #[test]
    fn events_json_filters_by_kind() {
        use crate::domain::Event;
        let events = vec![
            Event::SysMsg { text: "one".into() },
            Event::Annotated {
                id: id("a"),
                text: "note".into(),
            },
        ];
        let rendered = events_json(&events, Some("sys_msg"));
        assert_eq!(rendered.len(), 1);
        assert_eq!(rendered[0]["kind"], "sys_msg");
    }
}
