//! Typed domain errors. No strings-as-errors: every variant is matchable so a
//! coordinate (test) can pin it exactly.

use thiserror::Error;

use super::ids::ItemId;

/// Errors raised while constructing a stable slug [`ItemId`](super::ids::ItemId).
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum IdError {
    /// The candidate slug was empty.
    #[error("item id must not be empty")]
    Empty,
    /// The candidate slug exceeded the maximum length.
    #[error("item id too long: max {max}, got {got}")]
    TooLong { max: usize, got: usize },
    /// The candidate slug contained a character outside `[a-z0-9-]`.
    #[error("item id contains invalid character {ch:?} (allowed: a-z 0-9 '-')")]
    InvalidChar { ch: char },
    /// The candidate slug started or ended with `-`, or contained `--`.
    #[error("item id has a malformed hyphen (no leading/trailing '-' and no '--')")]
    MalformedHyphen,
}

/// Errors raised when validating a proposed graph mutation.
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum GraphError {
    /// The connection would introduce a cycle (`from` is reachable from `to`).
    #[error("connection {from} -> {to} would form a cycle")]
    Cycle { from: ItemId, to: ItemId },
    /// Adding/removing this edge would break an existing dependency.
    #[error("connection {from} -> {to} would break a dependency")]
    BrokenDep { from: ItemId, to: ItemId },
    /// One of the endpoints is not a known item in the flow.
    #[error("unknown item {id} referenced in connection")]
    Unknown { id: ItemId },
}

/// Errors raised by carriage-advance / mutation verbs at the domain level.
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum FlowError {
    /// A carriage-advance verb was refused because the item is in WAIT.
    #[error("item {id} is in WAIT; carriage-advance is refused")]
    Waiting { id: ItemId },
    /// The referenced item does not exist.
    #[error("unknown item {id}")]
    Unknown { id: ItemId },
    /// A proposed connection mutation failed graph validation.
    #[error(transparent)]
    Graph(#[from] GraphError),
}

#[cfg(test)]
mod tests {
    use super::*;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    #[test]
    fn id_error_messages() {
        assert_eq!(IdError::Empty.to_string(), "item id must not be empty");
        assert_eq!(
            IdError::TooLong { max: 64, got: 65 }.to_string(),
            "item id too long: max 64, got 65"
        );
        assert_eq!(
            IdError::InvalidChar { ch: '_' }.to_string(),
            "item id contains invalid character '_' (allowed: a-z 0-9 '-')"
        );
        assert_eq!(
            IdError::MalformedHyphen.to_string(),
            "item id has a malformed hyphen (no leading/trailing '-' and no '--')"
        );
    }

    #[test]
    fn graph_error_messages() {
        assert_eq!(
            GraphError::Cycle {
                from: id("a"),
                to: id("b")
            }
            .to_string(),
            "connection a -> b would form a cycle"
        );
        assert_eq!(
            GraphError::BrokenDep {
                from: id("a"),
                to: id("b")
            }
            .to_string(),
            "connection a -> b would break a dependency"
        );
        assert_eq!(
            GraphError::Unknown { id: id("z") }.to_string(),
            "unknown item z referenced in connection"
        );
    }

    #[test]
    fn flow_error_messages_and_graph_from() {
        assert_eq!(
            FlowError::Waiting { id: id("a") }.to_string(),
            "item a is in WAIT; carriage-advance is refused"
        );
        assert_eq!(
            FlowError::Unknown { id: id("z") }.to_string(),
            "unknown item z"
        );
        // The #[from] conversion and transparent Display: assert the converted
        // value equals the Graph-wrapped error directly (no synthetic arm).
        let f: FlowError = GraphError::Unknown { id: id("z") }.into();
        assert_eq!(f, FlowError::Graph(GraphError::Unknown { id: id("z") }));
        assert_eq!(f.to_string(), "unknown item z referenced in connection");
    }
}
