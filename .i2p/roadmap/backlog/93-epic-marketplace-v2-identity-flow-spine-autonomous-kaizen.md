---
id: 93
title: "EPIC — Marketplace v2: function-first identity, the flow/DELIVER spine, autonomous KAIZEN"
status: PENDING
priority: HIGH
added: 2026-06-17
depends_on: "—"
---

# [93] EPIC — Marketplace v2: function-first identity, the flow/DELIVER spine, autonomous KAIZEN

**Brief Description**
The umbrella for the migration captured in `docs/SLASH_COMMANDS.md` (the owner's git-tracked feedback
surface). It carries the marketplace from its launch identity to **v2**: de-"salesy", function-first plugin
names; a new **DELIVER** lifecycle phase with a unified **`/flow`** command spine; the **BUILD→ASSURE→SECURE
loop**; the long-planned **autonomous KAIZEN** (the GEMBA capture→raise→learn reflex); and two PRESSROOM
structural fixes. Decomposed into **six dependency streams** of atomic items. Owner steering is recorded in
the migration plan; this epic is the authoritative tracker.

### The six streams (child items)
- **Stream 1 — Identity & naming** (#94–#99): the rename slate + concierge→i2p merge.
- **Stream 2 — Lifecycle model** (#100–#104): insert DELIVER; the BUILD⇄ASSURE⇄SECURE loop (full
  state-machine rework).
- **Stream 3 — The flow / DELIVER spine** (#105–#110): a `flow` plugin owning `/flow pull|carry|report|setup`;
  foundry stays the internal BUILD engine. **Absorbs the already-shipped #39, #41 and the queued #40.**
- **Stream 4 — Autonomous KAIZEN** — **absorbs existing #16 (epic) + #18–#26**; this stream implements the
  GEMBA reflex (it is already specified there, not yet built).
- **Stream 5 — publish (ex-pressroom) fixes** (#111–#112): a prose/document reviewer; reclassify
  mermaid-specialist as a value-handler.
- **Stream 6 — Catalog & docs reconciliation** (#113–#114): bring `docs/SLASH_COMMANDS.md` and the shared
  knowledge docs in line with shipped reality.

### Owner decisions (locked — govern every child)
1. **foundry→flow** = *expose a `/flow` surface; keep foundry as the internal BUILD engine.* No whole-plugin
   rename; agent prefixes stay `foundry:*`.
2. **Rename slate (full):** sentinel→security, mission-control→operate, pressroom→publish,
   flow-server→flow-mcp, concierge→RETIRE (fold into i2p); sentinel command renames (security-gate→scan-all,
   dependency-audit→scan-dependencies, secret-scan→scan-for-secrets, pii-audit→scan-for-pii);
   `/i2p:i2p-check`→`/i2p:check`.
3. **BUILD→ASSURE→SECURE** modelled as a loop via a **full lifecycle state-machine rework**.
4. **Scope:** author the full epic; execution order set per item by the owner.

### Hard constraints (apply to every child item)
- Plugin **dir name = plugin.json `name` = marketplace.json entry** — enforced by `scripts/verify-prereqs.sh`
  **Check H**. Every rename is a directory move + manifest edits + canonical re-sync, as one atomic PR.
- `KAIZEN.md` and `hooks/inject-kaizen.sh` are **byte-mirrored** into all 9 plugins (verify Checks N/O).
- `foundry` companions are hard-coded in `plugins/foundry/.claude-plugin/plugin.json` — update on the
  security/publish renames.
- Governance is **direct-merge**: each child = branch → PR → `/foundry:pr-review` PASS → merge; one concern
  per PR; run `verify-prereqs.sh` green before each rename merges.

### Acceptance Criteria
1. Every directive in `docs/SLASH_COMMANDS.md` is represented by exactly one child item (or an absorbed
   existing item), with no directive dropped.
2. The dependency graph is acyclic and each child names its `depends_on`.
3. On completion, `docs/SLASH_COMMANDS.md` carries no unresolved inline `>` notes and matches the shipped
   command surface.

### Implementation Notes
- Recommended low-risk entry: **Stream 4** (no naming entanglement) — and the already-shipped #39/#41.
- Highest risk: **Stream 1** renames — land each as an isolated PR with verify-prereqs green before the next.
- Stream 4 must **link, not recreate**, #16,18–26.
- Dependency DAG and per-stream file lists live in the migration plan that authored this epic.
