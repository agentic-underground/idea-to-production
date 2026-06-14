---
name: flow-domain-gap
description: The flow-server Item struct has no PR fields (pr_title, pr_body, pr_labels, pr_assignees) or commit data — cycles that need this must stub with null/[] and plan a future domain extension
metadata:
  type: project
---

The domain `Item` struct (`domain/model.rs`) only carries: `id, title, status, gate, tokens, model, draft, synthesized`. There is no PR linkage, no commit list, no issue text field.

**Why:** These fields were referenced in roadmap items (#10 PR linkage, epic #27 RHS detail panel) but the domain model was never extended to hold them. The JSONL event log has `Annotated` events (which carry issue-style text) but no `PrLinked` or `CommitRecorded` events.

**How to apply:** When a cycle requires PR or commit data in the frontend, scope the panel to available data only (`annotations` from `Annotated` events, `deps` from `Flow.edges()`). Stub `pr: null` and `commits: []` in `item_json`. Recommend a KAIZEN item to add `PrLinkage` and `CommitRef` types to the domain model.

See: `doc/FLOW_KANBAN_UPLIFT_PLAN.md` §1.3 for the full data gap analysis from epic [27] planning.
