//! The pure flow model: [`Item`], [`Status`], [`WaitGate`], [`Edge`], and the
//! [`Flow`] graph. No IO. Construction is fallible where it must be; once you
//! hold a [`Flow`], it is a valid (acyclic, every edge endpoint known) graph.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use super::error::{FlowError, GraphError};
use super::ids::ItemId;

/// Carriage status of an item across the DO·DOING·DONE board.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    /// Not started (DO column).
    Do,
    /// In progress (DOING column).
    Doing,
    /// Complete (DONE column).
    Done,
}

/// The human governance gate on an item. WAIT halts carriage-advance.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum WaitGate {
    /// Value may flow down this path.
    Go,
    /// Value-add is paused on this item.
    Wait,
}

/// A single work item, keyed by its stable slug [`ItemId`].
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Item {
    /// Stable slug identity.
    pub id: ItemId,
    /// Display title.
    pub title: String,
    /// Carriage status.
    pub status: Status,
    /// Governance gate.
    pub gate: WaitGate,
    /// Cumulative token spend recorded against this item.
    pub tokens: u64,
    /// The model assigned to this item's carriage agent (resolved value).
    pub model: String,
    /// Number of times this item has been re-drafted (roadmap #4 rewrite loop).
    /// Starts at 0 and is incremented each time a rewrite is requested.
    /// `#[serde(default)]` so a flow serialized before this field existed still
    /// deserializes (draft = 0).
    #[serde(default)]
    pub draft: u32,
    /// Provenance flag: `true` for proxy historical items derived from the git
    /// log (see [`crate::history`]); `false` for real roadmap tickets. A
    /// synthesized item is visually distinct and is never mutated as if real.
    pub synthesized: bool,
}

impl Item {
    /// Create a fresh, real item in the DO column, GO, with zero spend and
    /// `synthesized = false`.
    pub fn new(id: ItemId, title: impl Into<String>, model: impl Into<String>) -> Self {
        Item {
            id,
            title: title.into(),
            status: Status::Do,
            gate: WaitGate::Go,
            tokens: 0,
            model: model.into(),
            draft: 0,
            synthesized: false,
        }
    }
}

/// A directed dependency edge: `from` depends on `to` (`to` must precede `from`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Edge {
    /// The dependent item.
    pub from: ItemId,
    /// The blocking prerequisite item.
    pub to: ItemId,
}

/// The flow graph: an ordered set of items plus dependency edges, guaranteed
/// acyclic with all endpoints known.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Flow {
    /// Items keyed by stable slug; ordering is independent of display order.
    items: BTreeMap<ItemId, Item>,
    /// Display order (a permutation of the item ids); `[N]` is read from here.
    order: Vec<ItemId>,
    /// Dependency edges.
    edges: Vec<Edge>,
}

impl Flow {
    /// An empty flow.
    pub fn new() -> Self {
        Flow::default()
    }

    /// Insert (or replace) an item, appending to display order if new.
    pub fn upsert_item(&mut self, item: Item) {
        if !self.items.contains_key(&item.id) {
            self.order.push(item.id.clone());
        }
        self.items.insert(item.id.clone(), item);
    }

    /// Look up an item by id.
    pub fn get(&self, id: &ItemId) -> Option<&Item> {
        self.items.get(id)
    }

    /// True if the item exists.
    pub fn contains(&self, id: &ItemId) -> bool {
        self.items.contains_key(id)
    }

    /// Items in display order.
    pub fn items_in_order(&self) -> Vec<&Item> {
        self.order
            .iter()
            .filter_map(|id| self.items.get(id))
            .collect()
    }

    /// All edges.
    pub fn edges(&self) -> &[Edge] {
        &self.edges
    }

    /// Reorder the display sequence. The new order must be a permutation of the
    /// existing ids; otherwise the order is left unchanged and `false` returned.
    /// Identity (the slug) is unaffected, so references survive reorder.
    pub fn reorder(&mut self, new_order: Vec<ItemId>) -> bool {
        if new_order.len() != self.order.len() {
            return false;
        }
        for id in &new_order {
            if !self.items.contains_key(id) {
                return false;
            }
        }
        // permutation: no duplicates (lengths equal + all known + unique)
        let mut seen = std::collections::BTreeSet::new();
        for id in &new_order {
            if !seen.insert(id.clone()) {
                return false;
            }
        }
        self.order = new_order;
        true
    }

    /// Set the WAIT/GO gate on an item. Returns the unknown error if absent.
    pub fn set_gate(&mut self, id: &ItemId, gate: WaitGate) -> Result<(), FlowError> {
        let item = self
            .items
            .get_mut(id)
            .ok_or_else(|| FlowError::Unknown { id: id.clone() })?;
        item.gate = gate;
        Ok(())
    }

    /// Advance an item's status. Refused with [`FlowError::Waiting`] if the item
    /// is in WAIT — the carriage-advance guard.
    pub fn advance_status(&mut self, id: &ItemId, status: Status) -> Result<(), FlowError> {
        let item = self
            .items
            .get_mut(id)
            .ok_or_else(|| FlowError::Unknown { id: id.clone() })?;
        if item.gate == WaitGate::Wait {
            return Err(FlowError::Waiting { id: id.clone() });
        }
        item.status = status;
        Ok(())
    }

    /// Add token spend to an item. Refused with [`FlowError::Waiting`] if WAIT —
    /// spend is a carriage-advance action.
    pub fn append_spend(&mut self, id: &ItemId, delta: u64) -> Result<u64, FlowError> {
        let item = self
            .items
            .get_mut(id)
            .ok_or_else(|| FlowError::Unknown { id: id.clone() })?;
        if item.gate == WaitGate::Wait {
            return Err(FlowError::Waiting { id: id.clone() });
        }
        item.tokens = item.tokens.saturating_add(delta);
        Ok(item.tokens)
    }

    /// Roll a token tally up onto an item unconditionally — used to accrue a
    /// child's spend onto each composite ancestor. Unlike [`Flow::append_spend`]
    /// this is **not** a carriage-advance action, so it is *not* refused while
    /// the ancestor is in WAIT: WAIT gates an item's own carriage agent, not the
    /// derived sub-tree total it carries. Returns the unknown error if absent.
    pub fn accrue_tokens(&mut self, id: &ItemId, delta: u64) -> Result<u64, FlowError> {
        let item = self
            .items
            .get_mut(id)
            .ok_or_else(|| FlowError::Unknown { id: id.clone() })?;
        item.tokens = item.tokens.saturating_add(delta);
        Ok(item.tokens)
    }

    /// Set the resolved model on an item.
    pub fn set_model(&mut self, id: &ItemId, model: impl Into<String>) -> Result<(), FlowError> {
        let item = self
            .items
            .get_mut(id)
            .ok_or_else(|| FlowError::Unknown { id: id.clone() })?;
        item.model = model.into();
        Ok(())
    }

    /// Increment an item's draft counter (roadmap #4 rewrite loop) and return the
    /// new draft number. Unlike carriage-advance verbs this is **not** WAIT-gated:
    /// requesting a re-draft is exactly the human-in-the-loop action a paused item
    /// is paused *for*. Returns the unknown error if the item is absent.
    pub fn bump_draft(&mut self, id: &ItemId) -> Result<u32, FlowError> {
        let item = self
            .items
            .get_mut(id)
            .ok_or_else(|| FlowError::Unknown { id: id.clone() })?;
        item.draft = item.draft.saturating_add(1);
        Ok(item.draft)
    }

    /// Validate that adding the edge `from -> to` keeps the graph buildable:
    /// both endpoints known, not a self-edge, and no cycle. Pure — mutates
    /// nothing.
    pub fn validate_connection(&self, from: &ItemId, to: &ItemId) -> Result<(), GraphError> {
        if !self.items.contains_key(from) {
            return Err(GraphError::Unknown { id: from.clone() });
        }
        if !self.items.contains_key(to) {
            return Err(GraphError::Unknown { id: to.clone() });
        }
        if from == to {
            return Err(GraphError::Cycle {
                from: from.clone(),
                to: to.clone(),
            });
        }
        // Adding from->to creates a cycle iff `from` is already reachable from
        // `to` along existing edges.
        if self.reachable(to, from) {
            return Err(GraphError::Cycle {
                from: from.clone(),
                to: to.clone(),
            });
        }
        Ok(())
    }

    /// Add the edge `from -> to` after validation. State is unchanged on error.
    pub fn add_connection(&mut self, from: ItemId, to: ItemId) -> Result<(), GraphError> {
        self.validate_connection(&from, &to)?;
        if !self.has_edge(&from, &to) {
            self.edges.push(Edge { from, to });
        }
        Ok(())
    }

    /// Remove the edge `from -> to`. Both endpoints must exist and the edge must
    /// be present (removing a missing edge would break a dependency contract).
    pub fn remove_connection(&mut self, from: &ItemId, to: &ItemId) -> Result<(), GraphError> {
        if !self.items.contains_key(from) {
            return Err(GraphError::Unknown { id: from.clone() });
        }
        if !self.items.contains_key(to) {
            return Err(GraphError::Unknown { id: to.clone() });
        }
        if !self.has_edge(from, to) {
            return Err(GraphError::BrokenDep {
                from: from.clone(),
                to: to.clone(),
            });
        }
        self.edges.retain(|e| !(e.from == *from && e.to == *to));
        Ok(())
    }

    fn has_edge(&self, from: &ItemId, to: &ItemId) -> bool {
        self.edges.iter().any(|e| e.from == *from && e.to == *to)
    }

    /// Is `target` reachable from `start` following `from -> to` edges?
    fn reachable(&self, start: &ItemId, target: &ItemId) -> bool {
        let mut stack = vec![start.clone()];
        let mut visited = std::collections::BTreeSet::new();
        while let Some(node) = stack.pop() {
            if &node == target {
                return true;
            }
            if !visited.insert(node.clone()) {
                continue;
            }
            for e in &self.edges {
                if e.from == node {
                    stack.push(e.to.clone());
                }
            }
        }
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    fn item(s: &str) -> Item {
        Item::new(id(s), s, "claude-sonnet-4-6")
    }

    #[test]
    fn new_item_defaults_to_do_go_zero() {
        let it = item("a");
        assert_eq!(it.status, Status::Do);
        assert_eq!(it.gate, WaitGate::Go);
        assert_eq!(it.tokens, 0);
        assert_eq!(it.model, "claude-sonnet-4-6");
        assert_eq!(it.draft, 0);
        assert!(!it.synthesized);
    }

    #[test]
    fn bump_draft_increments_and_reports_unknown() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        assert_eq!(f.bump_draft(&id("a")).unwrap(), 1);
        assert_eq!(f.bump_draft(&id("a")).unwrap(), 2);
        assert_eq!(f.get(&id("a")).unwrap().draft, 2);
        assert_eq!(
            f.bump_draft(&id("z")),
            Err(FlowError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn bump_draft_not_gated_by_wait() {
        // A rewrite is exactly what a paused item is paused for, so WAIT must not
        // refuse the draft bump.
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.set_gate(&id("a"), WaitGate::Wait).unwrap();
        assert_eq!(f.bump_draft(&id("a")).unwrap(), 1);
    }

    #[test]
    fn upsert_appends_once_and_replaces() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        assert_eq!(f.items_in_order().len(), 2);
        // replace a (no new order entry)
        let mut a2 = item("a");
        a2.title = "renamed".into();
        f.upsert_item(a2);
        assert_eq!(f.items_in_order().len(), 2);
        assert_eq!(f.get(&id("a")).unwrap().title, "renamed");
    }

    #[test]
    fn contains_and_get() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        assert!(f.contains(&id("a")));
        assert!(!f.contains(&id("z")));
        assert!(f.get(&id("z")).is_none());
    }

    #[test]
    fn reorder_is_a_permutation_only() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        f.upsert_item(item("c"));
        assert!(f.reorder(vec![id("c"), id("a"), id("b")]));
        let order: Vec<_> = f.items_in_order().iter().map(|i| i.id.as_str()).collect();
        assert_eq!(order, vec!["c", "a", "b"]);
        // wrong length
        assert!(!f.reorder(vec![id("a")]));
        // unknown id
        assert!(!f.reorder(vec![id("a"), id("b"), id("z")]));
        // duplicate
        assert!(!f.reorder(vec![id("a"), id("a"), id("b")]));
    }

    #[test]
    fn refs_survive_reorder() {
        let mut f = Flow::new();
        f.upsert_item(item("first"));
        f.upsert_item(item("second"));
        f.add_connection(id("second"), id("first")).unwrap();
        assert!(f.reorder(vec![id("second"), id("first")]));
        // edge still resolves to the same items after reorder
        assert_eq!(f.edges().len(), 1);
        assert_eq!(f.edges()[0].from, id("second"));
        assert_eq!(f.edges()[0].to, id("first"));
        assert!(f.get(&id("first")).is_some());
    }

    #[test]
    fn set_gate_toggles_and_reports_unknown() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.set_gate(&id("a"), WaitGate::Wait).unwrap();
        assert_eq!(f.get(&id("a")).unwrap().gate, WaitGate::Wait);
        assert_eq!(
            f.set_gate(&id("z"), WaitGate::Go),
            Err(FlowError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn advance_status_blocked_while_wait() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.set_gate(&id("a"), WaitGate::Wait).unwrap();
        assert_eq!(
            f.advance_status(&id("a"), Status::Doing),
            Err(FlowError::Waiting { id: id("a") })
        );
        // unchanged
        assert_eq!(f.get(&id("a")).unwrap().status, Status::Do);
        // release and advance
        f.set_gate(&id("a"), WaitGate::Go).unwrap();
        f.advance_status(&id("a"), Status::Doing).unwrap();
        assert_eq!(f.get(&id("a")).unwrap().status, Status::Doing);
    }

    #[test]
    fn advance_status_unknown() {
        let mut f = Flow::new();
        assert_eq!(
            f.advance_status(&id("z"), Status::Done),
            Err(FlowError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn append_spend_accrues_and_blocks_on_wait() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        assert_eq!(f.append_spend(&id("a"), 100).unwrap(), 100);
        assert_eq!(f.append_spend(&id("a"), 50).unwrap(), 150);
        f.set_gate(&id("a"), WaitGate::Wait).unwrap();
        assert_eq!(
            f.append_spend(&id("a"), 10),
            Err(FlowError::Waiting { id: id("a") })
        );
        assert_eq!(f.get(&id("a")).unwrap().tokens, 150);
    }

    #[test]
    fn append_spend_saturates_and_unknown() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.append_spend(&id("a"), u64::MAX).unwrap();
        assert_eq!(f.append_spend(&id("a"), 5).unwrap(), u64::MAX);
        assert_eq!(
            f.append_spend(&id("z"), 1),
            Err(FlowError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn accrue_tokens_bumps_unconditionally_even_while_wait() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        // A normal spend accrues…
        assert_eq!(f.accrue_tokens(&id("a"), 100).unwrap(), 100);
        // …and a roll-up still accrues even when the item is in WAIT, because a
        // roll-up is a derived sub-tree total, not the item's own carriage work.
        f.set_gate(&id("a"), WaitGate::Wait).unwrap();
        assert_eq!(f.accrue_tokens(&id("a"), 50).unwrap(), 150);
        assert_eq!(f.get(&id("a")).unwrap().tokens, 150);
    }

    #[test]
    fn accrue_tokens_saturates_and_reports_unknown() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.accrue_tokens(&id("a"), u64::MAX).unwrap();
        assert_eq!(f.accrue_tokens(&id("a"), 5).unwrap(), u64::MAX);
        assert_eq!(
            f.accrue_tokens(&id("z"), 1),
            Err(FlowError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn set_model_changes_and_unknown() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.set_model(&id("a"), "claude-opus-4-8").unwrap();
        assert_eq!(f.get(&id("a")).unwrap().model, "claude-opus-4-8");
        assert_eq!(
            f.set_model(&id("z"), "x"),
            Err(FlowError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn validate_connection_rejects_unknown_endpoints() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        assert_eq!(
            f.validate_connection(&id("z"), &id("a")),
            Err(GraphError::Unknown { id: id("z") })
        );
        assert_eq!(
            f.validate_connection(&id("a"), &id("z")),
            Err(GraphError::Unknown { id: id("z") })
        );
    }

    #[test]
    fn validate_connection_rejects_self_edge() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        assert_eq!(
            f.validate_connection(&id("a"), &id("a")),
            Err(GraphError::Cycle {
                from: id("a"),
                to: id("a")
            })
        );
    }

    #[test]
    fn cycle_rejected_and_graph_unchanged() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        f.add_connection(id("a"), id("b")).unwrap();
        // a->b exists; b->a would cycle
        assert_eq!(
            f.add_connection(id("b"), id("a")),
            Err(GraphError::Cycle {
                from: id("b"),
                to: id("a")
            })
        );
        assert_eq!(f.edges().len(), 1);
    }

    #[test]
    fn add_connection_is_idempotent() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("a"), id("b")).unwrap();
        assert_eq!(f.edges().len(), 1);
    }

    #[test]
    fn remove_connection_paths() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        f.add_connection(id("a"), id("b")).unwrap();
        // unknown endpoints
        assert_eq!(
            f.remove_connection(&id("z"), &id("b")),
            Err(GraphError::Unknown { id: id("z") })
        );
        assert_eq!(
            f.remove_connection(&id("a"), &id("z")),
            Err(GraphError::Unknown { id: id("z") })
        );
        // missing edge => broken dep
        assert_eq!(
            f.remove_connection(&id("b"), &id("a")),
            Err(GraphError::BrokenDep {
                from: id("b"),
                to: id("a")
            })
        );
        // present edge removes
        f.remove_connection(&id("a"), &id("b")).unwrap();
        assert_eq!(f.edges().len(), 0);
    }

    #[test]
    fn deep_cycle_detected() {
        let mut f = Flow::new();
        for s in ["a", "b", "c", "d"] {
            f.upsert_item(item(s));
        }
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("b"), id("c")).unwrap();
        f.add_connection(id("c"), id("d")).unwrap();
        // d->a closes the loop
        assert_eq!(
            f.add_connection(id("d"), id("a")),
            Err(GraphError::Cycle {
                from: id("d"),
                to: id("a")
            })
        );
    }

    #[test]
    fn diamond_is_not_a_cycle() {
        let mut f = Flow::new();
        for s in ["a", "b", "c", "d"] {
            f.upsert_item(item(s));
        }
        // a depends on b and c; both depend on d — a DAG diamond, no cycle.
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("a"), id("c")).unwrap();
        f.add_connection(id("b"), id("d")).unwrap();
        f.add_connection(id("c"), id("d")).unwrap();
        assert_eq!(f.edges().len(), 4);
    }

    #[test]
    fn reachability_revisits_shared_node_in_diamond() {
        // Build a diamond rooted at `a` (a->b, a->c, b->d, c->d). Validating a
        // new edge whose reachability search starts at `a` enqueues `d` twice
        // (via b and via c), exercising the visited-set short-circuit.
        let mut f = Flow::new();
        for s in ["a", "b", "c", "d", "x"] {
            f.upsert_item(item(s));
        }
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("a"), id("c")).unwrap();
        f.add_connection(id("b"), id("d")).unwrap();
        f.add_connection(id("c"), id("d")).unwrap();
        // validate x -> a runs reachable(a, x): traverses the whole diamond,
        // re-popping `d`, and finds x unreachable, so the edge is allowed.
        assert_eq!(f.validate_connection(&id("x"), &id("a")), Ok(()));
    }
}
