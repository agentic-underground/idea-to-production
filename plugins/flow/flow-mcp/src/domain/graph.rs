//! Graph validation entry points. The cycle/dependency logic lives on
//! [`Flow`](super::model::Flow); this module is the named, free-function surface
//! the API/MCP verbs call (`validate_connection`, `mutate_connection`).

use super::error::GraphError;
use super::ids::ItemId;
use super::model::Flow;

/// The kind of connection mutation a client proposes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mutation {
    /// Add the edge `from -> to`.
    Add,
    /// Remove the edge `from -> to`.
    Remove,
}

/// Validate, without mutating, that connecting `from -> to` keeps the graph
/// buildable (known endpoints, no self-edge, no cycle).
pub fn validate_connection(flow: &Flow, from: &ItemId, to: &ItemId) -> Result<(), GraphError> {
    flow.validate_connection(from, to)
}

/// Apply a connection mutation. On any error the flow is left unchanged.
pub fn mutate_connection(
    flow: &mut Flow,
    mutation: Mutation,
    from: &ItemId,
    to: &ItemId,
) -> Result<(), GraphError> {
    match mutation {
        Mutation::Add => flow.add_connection(from.clone(), to.clone()),
        Mutation::Remove => flow.remove_connection(from, to),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::model::Item;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    fn flow_with(ids: &[&str]) -> Flow {
        let mut f = Flow::new();
        for s in ids {
            f.upsert_item(Item::new(id(s), *s, "claude-sonnet-4-6"));
        }
        f
    }

    #[test]
    fn validate_connection_ok_for_dag() {
        let f = flow_with(&["a", "b"]);
        assert_eq!(validate_connection(&f, &id("a"), &id("b")), Ok(()));
    }

    #[test]
    fn validate_connection_reports_cycle() {
        let mut f = flow_with(&["a", "b"]);
        mutate_connection(&mut f, Mutation::Add, &id("a"), &id("b")).unwrap();
        assert_eq!(
            validate_connection(&f, &id("b"), &id("a")),
            Err(GraphError::Cycle {
                from: id("b"),
                to: id("a")
            })
        );
    }

    #[test]
    fn validate_connection_reports_unknown() {
        let f = flow_with(&["a"]);
        assert_eq!(
            validate_connection(&f, &id("a"), &id("z")),
            Err(GraphError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn mutate_add_then_remove() {
        let mut f = flow_with(&["a", "b"]);
        mutate_connection(&mut f, Mutation::Add, &id("a"), &id("b")).unwrap();
        assert_eq!(f.edges().len(), 1);
        mutate_connection(&mut f, Mutation::Remove, &id("a"), &id("b")).unwrap();
        assert_eq!(f.edges().len(), 0);
    }

    #[test]
    fn mutate_add_cycle_leaves_graph_unchanged() {
        let mut f = flow_with(&["a", "b"]);
        mutate_connection(&mut f, Mutation::Add, &id("a"), &id("b")).unwrap();
        let before = f.edges().to_vec();
        assert!(mutate_connection(&mut f, Mutation::Add, &id("b"), &id("a")).is_err());
        assert_eq!(f.edges().to_vec(), before);
    }

    #[test]
    fn mutate_remove_missing_is_broken_dep() {
        let mut f = flow_with(&["a", "b"]);
        assert_eq!(
            mutate_connection(&mut f, Mutation::Remove, &id("a"), &id("b")),
            Err(GraphError::BrokenDep {
                from: id("a"),
                to: id("b")
            })
        );
    }
}
