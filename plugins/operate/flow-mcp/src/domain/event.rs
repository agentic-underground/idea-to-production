//! Event schema. Each mutation produces an [`Event`] serialized as one JSONL
//! line (the append-only write-ahead record); the MCP surface reads the log back
//! via `list_events`.

use serde::{Deserialize, Serialize};

use super::ids::ItemId;
use super::model::{Status, WaitGate};

/// A single flow-state delta. `tag`-style serde so a JSONL line is
/// self-describing and a WS client can switch on `"kind"`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum Event {
    /// An item was created or replaced.
    ItemUpserted {
        /// Affected item.
        id: ItemId,
        /// Display title.
        title: String,
    },
    /// An item's WAIT/GO gate changed.
    GateSet {
        /// Affected item.
        id: ItemId,
        /// New gate value.
        gate: WaitGate,
    },
    /// An item's carriage status advanced.
    StatusPosted {
        /// Affected item.
        id: ItemId,
        /// New status.
        status: Status,
    },
    /// Token spend was appended to an item.
    SpendAppended {
        /// Affected item.
        id: ItemId,
        /// Tokens added in this event.
        delta: u64,
        /// Cumulative total after this event.
        total: u64,
    },
    /// An item's model assignment changed.
    ModelSet {
        /// Affected item.
        id: ItemId,
        /// New resolved model.
        model: String,
    },
    /// A connection was added.
    ConnectionAdded {
        /// Dependent item.
        from: ItemId,
        /// Prerequisite item.
        to: ItemId,
    },
    /// A connection was removed.
    ConnectionRemoved {
        /// Dependent item.
        from: ItemId,
        /// Prerequisite item.
        to: ItemId,
    },
    /// A human comment was appended to an item's plan as an annotation
    /// (roadmap #4 comment loop).
    Annotated {
        /// Annotated item.
        id: ItemId,
        /// The comment text recorded against the item's plan.
        text: String,
    },
    /// A full re-draft of an item was requested, carrying the human's commentary
    /// (roadmap #4 rewrite loop). The actual re-draft is external orchestration;
    /// this records the request and the item's new draft number.
    RewriteRequested {
        /// Item to be re-drafted.
        id: ItemId,
        /// The commentary handed to the carriage agent for the re-draft.
        comment: String,
        /// The item's draft number after this request.
        draft: u32,
    },
    /// An orchestrator system message.
    SysMsg {
        /// Free-text message.
        text: String,
    },
}

impl Event {
    /// Serialize this event as a single JSONL line (no trailing newline).
    pub fn to_jsonl(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }

    /// Parse a single JSONL line back into an [`Event`].
    pub fn from_jsonl(line: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(line)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::ids::ItemId;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    fn samples() -> Vec<Event> {
        vec![
            Event::ItemUpserted {
                id: id("a"),
                title: "A".into(),
            },
            Event::GateSet {
                id: id("a"),
                gate: WaitGate::Wait,
            },
            Event::StatusPosted {
                id: id("a"),
                status: Status::Doing,
            },
            Event::SpendAppended {
                id: id("a"),
                delta: 10,
                total: 10,
            },
            Event::ModelSet {
                id: id("a"),
                model: "claude-opus-4-8".into(),
            },
            Event::ConnectionAdded {
                from: id("a"),
                to: id("b"),
            },
            Event::ConnectionRemoved {
                from: id("a"),
                to: id("b"),
            },
            Event::Annotated {
                id: id("a"),
                text: "looks good".into(),
            },
            Event::RewriteRequested {
                id: id("a"),
                comment: "redo with X".into(),
                draft: 3,
            },
            Event::SysMsg {
                text: "hello".into(),
            },
        ]
    }

    #[test]
    fn every_variant_round_trips_through_jsonl() {
        for ev in samples() {
            let line = ev.to_jsonl().unwrap();
            assert!(!line.contains('\n'), "jsonl line must be single-line");
            let back = Event::from_jsonl(&line).unwrap();
            assert_eq!(back, ev);
        }
    }

    #[test]
    fn jsonl_is_self_describing_with_kind() {
        let ev = Event::SysMsg { text: "hi".into() };
        let line = ev.to_jsonl().unwrap();
        assert!(line.contains("\"kind\":\"sys_msg\""));
    }

    #[test]
    fn malformed_line_errors() {
        assert!(Event::from_jsonl("not json").is_err());
        assert!(Event::from_jsonl("{\"kind\":\"nope\"}").is_err());
    }
}
