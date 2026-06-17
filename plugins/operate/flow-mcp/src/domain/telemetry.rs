//! Token telemetry — pure core for roadmap #3 (carriage agent + JSONL ledger →
//! Grafana). No IO: ancestor roll-up over the dependency graph, the
//! [`TelemetryEvent`] JSONL record, the Grafana/Loki push-payload builder, and
//! the per-item / per-ancestor-tree cost report. Every function here is pure and
//! exhaustively pinned by tests; the thin IO that appends a line and pushes to
//! Grafana lives in [`crate::store`].

use std::collections::{BTreeMap, BTreeSet};

use serde::{Deserialize, Serialize};

use super::ids::ItemId;
use super::model::Flow;

/// The transitive **ancestors** of `id`: every item `id` depends on, following
/// `from -> to` dependency edges up the tree, excluding `id` itself.
///
/// Pure and cycle-safe (a visited set guarantees termination even if the in-
/// memory graph were ever cyclic — the domain keeps it acyclic by construction,
/// but this function does not rely on that). The returned ids are unique and in
/// stable (sorted) order so a spend roll-up is deterministic.
///
/// A spend on an atomic item accrues to each ancestor composite item: the
/// ancestors are exactly the items whose rolled-up tally must rise.
pub fn ancestors(flow: &Flow, id: &ItemId) -> Vec<ItemId> {
    let mut seen: BTreeSet<ItemId> = BTreeSet::new();
    let mut stack: Vec<ItemId> = Vec::new();
    // Seed with the direct prerequisites of `id` (never `id` itself).
    for e in flow.edges() {
        if &e.from == id {
            stack.push(e.to.clone());
        }
    }
    while let Some(node) = stack.pop() {
        if node == *id {
            // A cycle led back to the origin; never record the item as its own
            // ancestor.
            continue;
        }
        if !seen.insert(node.clone()) {
            continue;
        }
        for e in flow.edges() {
            if e.from == node {
                stack.push(e.to.clone());
            }
        }
    }
    seen.into_iter().collect()
}

/// One telemetry record (roadmap #3 schema:
/// `{ts, item_id, agent, activity, tokens_delta, tokens_total, ancestors[]}`).
/// Serialized to a single JSONL line — the append-only ledger that reports and
/// Grafana consume.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TelemetryEvent {
    /// Event timestamp (caller-supplied; epoch millis, monotonic per writer).
    pub ts: u64,
    /// The item the spend was recorded against.
    pub item_id: ItemId,
    /// The carriage-agent identity that consumed the tokens.
    pub agent: String,
    /// What the agent was doing when the tokens were consumed.
    pub activity: String,
    /// Tokens consumed in this event.
    pub tokens_delta: u64,
    /// Cumulative tokens on `item_id` after this event.
    pub tokens_total: u64,
    /// The item's transitive ancestors at the time of the event — each one's
    /// rolled-up tally also rose by `tokens_delta`.
    pub ancestors: Vec<ItemId>,
}

impl TelemetryEvent {
    /// Serialize as a single JSONL line (no trailing newline).
    pub fn to_jsonl(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }

    /// Parse a single JSONL line back into a [`TelemetryEvent`].
    pub fn from_jsonl(line: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(line)
    }
}

/// A Loki stream label set + log line, as the local Grafana/Loki push API wants.
/// Pure builder: turns telemetry events into the JSON body of a
/// `POST /loki/api/v1/push` request. The thin IO that actually pushes it (and
/// degrades gracefully when `$GRAFANA_URL` is absent) lives in the store.
///
/// Each event becomes one log line under a stream keyed by `item_id` + `agent`,
/// timestamped in nanoseconds (Loki's unit) from the event's epoch-millis `ts`.
pub fn grafana_payload(events: &[TelemetryEvent]) -> serde_json::Value {
    let streams: Vec<serde_json::Value> = events
        .iter()
        .map(|ev| {
            let line = ev.to_jsonl().unwrap_or_default();
            serde_json::json!({
                "stream": {
                    "job": "flow-telemetry",
                    "item_id": ev.item_id.as_str(),
                    "agent": ev.agent,
                },
                "values": [[ (ev.ts as u128 * 1_000_000).to_string(), line ]],
            })
        })
        .collect();
    serde_json::json!({ "streams": streams })
}

/// A reconciled token-cost report computed from the JSONL ledger.
///
/// `per_item` is the direct spend recorded *against* each item (the sum of that
/// item's own `tokens_delta`s). `per_tree` is the rolled-up spend: each item's
/// own spend plus the spend of every descendant that named it as an ancestor —
/// i.e. the cost of the whole sub-tree rooted at that composite item.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct CostReport {
    /// Direct spend recorded against each item.
    pub per_item: BTreeMap<ItemId, u64>,
    /// Rolled-up spend per item (own + all descendants that named it ancestor).
    pub per_tree: BTreeMap<ItemId, u64>,
    /// Grand total — the sum of every event's `tokens_delta`. Reconciles to
    /// `per_item.values().sum()`.
    pub total: u64,
}

/// Compute the [`CostReport`] from an ordered slice of telemetry events.
///
/// Pure: the report is a fold over the events and reconciles exactly — `total`
/// equals the sum of every `tokens_delta` and equals `per_item.values().sum()`.
pub fn rollup(events: &[TelemetryEvent]) -> CostReport {
    let mut report = CostReport::default();
    for ev in events {
        report.total = report.total.saturating_add(ev.tokens_delta);
        accrue(&mut report.per_item, &ev.item_id, ev.tokens_delta);
        // The item's own tree includes its own spend…
        accrue(&mut report.per_tree, &ev.item_id, ev.tokens_delta);
        // …and the spend rolls up into every ancestor's tree.
        for anc in &ev.ancestors {
            accrue(&mut report.per_tree, anc, ev.tokens_delta);
        }
    }
    report
}

/// Add `delta` to `id`'s running tally in `tallies` (saturating).
fn accrue(tallies: &mut BTreeMap<ItemId, u64>, id: &ItemId, delta: u64) {
    let slot = tallies.entry(id.clone()).or_insert(0);
    *slot = slot.saturating_add(delta);
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

    // --- ancestors ---------------------------------------------------------

    #[test]
    fn no_ancestors_when_no_edges() {
        let f = flow_with(&["a"]);
        assert_eq!(ancestors(&f, &id("a")), Vec::<ItemId>::new());
    }

    #[test]
    fn direct_parent_is_an_ancestor() {
        let mut f = flow_with(&["child", "parent"]);
        f.add_connection(id("child"), id("parent")).unwrap();
        assert_eq!(ancestors(&f, &id("child")), vec![id("parent")]);
        // The prerequisite itself has no ancestors.
        assert_eq!(ancestors(&f, &id("parent")), Vec::<ItemId>::new());
    }

    #[test]
    fn deep_chain_collects_every_ancestor() {
        // a -> b -> c -> d : a depends transitively on b, c, d.
        let mut f = flow_with(&["a", "b", "c", "d"]);
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("b"), id("c")).unwrap();
        f.add_connection(id("c"), id("d")).unwrap();
        assert_eq!(ancestors(&f, &id("a")), vec![id("b"), id("c"), id("d")]);
        assert_eq!(ancestors(&f, &id("b")), vec![id("c"), id("d")]);
    }

    #[test]
    fn diamond_dedupes_shared_ancestor() {
        // a -> b, a -> c, b -> d, c -> d : d is reached twice but listed once.
        let mut f = flow_with(&["a", "b", "c", "d"]);
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("a"), id("c")).unwrap();
        f.add_connection(id("b"), id("d")).unwrap();
        f.add_connection(id("c"), id("d")).unwrap();
        assert_eq!(
            ancestors(&f, &id("a")),
            vec![id("b"), id("c"), id("d")],
            "shared ancestor d appears exactly once, sorted"
        );
    }

    #[test]
    fn ancestors_is_cycle_safe() {
        // The domain forbids cycles, so build one by hand around the graph: an
        // edge set with a->b and b->a fed directly. We hand-build a Flow whose
        // edges form a cycle is impossible via add_connection, so emulate by
        // re-pushing edges through the public surface as far as allowed and
        // assert termination on a self-referential lookup instead.
        //
        // Construct a->b->c->a would be refused; instead verify the visited-set
        // short-circuit by traversing a diamond whose start re-enqueues a node:
        // the loop must still terminate and never include the origin.
        let mut f = flow_with(&["a", "b", "c"]);
        f.add_connection(id("a"), id("b")).unwrap();
        f.add_connection(id("b"), id("c")).unwrap();
        f.add_connection(id("a"), id("c")).unwrap();
        // c re-enqueued via a->c and via b->c; terminates, dedupes, no origin.
        let got = ancestors(&f, &id("a"));
        assert_eq!(got, vec![id("b"), id("c")]);
        assert!(!got.contains(&id("a")));
    }

    #[test]
    fn ancestors_never_includes_origin_under_a_synthetic_cycle() {
        // Drive the `node == *id` continue arm directly: craft a Flow whose edge
        // list contains a back-edge to the origin (bypassing add_connection,
        // which would refuse it) via serde round-trip of a hand-written graph.
        let json = r#"{
            "items": {
                "a": {"id":"a","title":"a","status":"do","gate":"go","tokens":0,"model":"m","synthesized":false},
                "b": {"id":"b","title":"b","status":"do","gate":"go","tokens":0,"model":"m","synthesized":false}
            },
            "order": ["a","b"],
            "edges": [{"from":"a","to":"b"},{"from":"b","to":"a"}]
        }"#;
        let f: Flow = serde_json::from_str(json).unwrap();
        // a -> b -> a : the back-edge re-reaches a; the origin-guard drops it.
        let got = ancestors(&f, &id("a"));
        assert_eq!(got, vec![id("b")]);
        assert!(!got.contains(&id("a")));
    }

    // --- TelemetryEvent JSONL ---------------------------------------------

    fn sample(ts: u64, item: &str, delta: u64, total: u64, ancs: &[&str]) -> TelemetryEvent {
        TelemetryEvent {
            ts,
            item_id: id(item),
            agent: "carriage-agent".into(),
            activity: "implement".into(),
            tokens_delta: delta,
            tokens_total: total,
            ancestors: ancs.iter().map(|s| id(s)).collect(),
        }
    }

    #[test]
    fn telemetry_round_trips_through_jsonl() {
        let ev = sample(1718000000000, "child", 1000, 1000, &["parent"]);
        let line = ev.to_jsonl().unwrap();
        assert!(!line.contains('\n'), "jsonl line must be single-line");
        assert_eq!(TelemetryEvent::from_jsonl(&line).unwrap(), ev);
    }

    #[test]
    fn telemetry_jsonl_carries_the_schema_fields() {
        let ev = sample(7, "child", 5, 5, &["parent"]);
        let line = ev.to_jsonl().unwrap();
        for key in [
            "ts",
            "item_id",
            "agent",
            "activity",
            "tokens_delta",
            "tokens_total",
            "ancestors",
        ] {
            assert!(line.contains(&format!("\"{key}\"")), "missing field {key}");
        }
    }

    #[test]
    fn telemetry_from_malformed_line_errors() {
        assert!(TelemetryEvent::from_jsonl("not json").is_err());
    }

    // --- grafana_payload ---------------------------------------------------

    #[test]
    fn grafana_payload_wraps_one_stream_per_event() {
        let evs = vec![sample(1, "a", 10, 10, &[]), sample(2, "b", 20, 20, &["a"])];
        let payload = grafana_payload(&evs);
        let streams = payload["streams"].as_array().unwrap();
        assert_eq!(streams.len(), 2);
        assert_eq!(streams[0]["stream"]["item_id"], "a");
        assert_eq!(streams[0]["stream"]["job"], "flow-telemetry");
        // ts is converted from epoch-millis to nanoseconds (×1_000_000).
        assert_eq!(streams[0]["values"][0][0], "1000000");
        // The log line is the event's own JSONL.
        let line = streams[1]["values"][0][1].as_str().unwrap();
        assert_eq!(TelemetryEvent::from_jsonl(line).unwrap(), evs[1]);
    }

    #[test]
    fn grafana_payload_is_empty_for_no_events() {
        let payload = grafana_payload(&[]);
        assert_eq!(payload["streams"].as_array().unwrap().len(), 0);
    }

    // --- rollup ------------------------------------------------------------

    #[test]
    fn rollup_is_empty_for_no_events() {
        let r = rollup(&[]);
        assert_eq!(r, CostReport::default());
        assert_eq!(r.total, 0);
    }

    #[test]
    fn rollup_reconciles_and_rolls_up_to_ancestors() {
        // child accrues 1000 with ancestors [parent, epic]; a second spend of
        // 500 on parent itself (ancestor [epic]).
        let evs = vec![
            sample(1, "child", 1000, 1000, &["parent", "epic"]),
            sample(2, "parent", 500, 500, &["epic"]),
        ];
        let r = rollup(&evs);

        // Direct spend per item.
        assert_eq!(r.per_item[&id("child")], 1000);
        assert_eq!(r.per_item[&id("parent")], 500);
        assert!(!r.per_item.contains_key(&id("epic")));

        // Rolled-up tree totals.
        assert_eq!(r.per_tree[&id("child")], 1000);
        assert_eq!(r.per_tree[&id("parent")], 1500); // own 500 + child 1000
        assert_eq!(r.per_tree[&id("epic")], 1500); // child 1000 + parent 500

        // Reconciliation: total == sum of deltas == sum of per_item.
        assert_eq!(r.total, 1500);
        assert_eq!(r.per_item.values().sum::<u64>(), r.total);
    }

    #[test]
    fn rollup_accumulates_repeated_spend_on_one_item() {
        let evs = vec![
            sample(1, "child", 100, 100, &["parent"]),
            sample(2, "child", 250, 350, &["parent"]),
        ];
        let r = rollup(&evs);
        assert_eq!(r.per_item[&id("child")], 350);
        assert_eq!(r.per_tree[&id("child")], 350);
        assert_eq!(r.per_tree[&id("parent")], 350);
        assert_eq!(r.total, 350);
    }

    #[test]
    fn cost_report_round_trips_through_serde() {
        let r = rollup(&[sample(1, "child", 10, 10, &["parent"])]);
        let json = serde_json::to_string(&r).unwrap();
        let back: CostReport = serde_json::from_str(&json).unwrap();
        assert_eq!(back, r);
    }
}
