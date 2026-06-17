---
id: 107
title: "value-flow-report — build the static-HTML snapshot repo (absorbs #40)"
status: PENDING
priority: MEDIUM
added: 2026-06-17
depends_on: "#105, #97 (flow-mcp rename)"
---

# [107] value-flow-report — build the static-HTML snapshot repo (absorbs #40)

**Brief Description**
Build the queued [40]: a **separate `~/Code/value-flow-report` repository** that reads the `.i2p/roadmap/`
tree (or the `flow-mcp` read verbs) and emits **one self-contained static HTML report** — the offline
successor to the removed live web board. Point-in-time, not real-time. Item [40] already specifies this
reporter in full; **this item supersedes and executes it** under the v2 flow/DELIVER stream, retargeted at
the renamed `flow-mcp` backend.

This builds the offline successor to the web UI that was **already removed in the already-shipped [39]** —
this stream relocates/renames that work and now delivers its planned replacement; it does not redo the
removal.

### User Stories
- AS the owner I WANT to run one command and get a shareable HTML snapshot of the value flow (items by
  stage, who is DOING / WHAT, cost roll-ups) SO THAT I can see current state without hosting a server.
- AS the owner I WANT it in its own repo SO THAT the reporter evolves independently of the marketplace.

### EARS Specification
**Ubiquitous**
- The tool SHALL produce a single self-contained HTML file with no runtime server dependency.

**Event-driven**
- WHEN run against an i2p project THE SYSTEM SHALL read the `.i2p/roadmap/` tree (or the `flow-mcp` read
  verbs) and render items grouped by stage (backlog ▸ do ▸ doing ▸ done) with per-item who/what/cost.

**Unwanted behaviour**
- IF neither `flow-mcp` nor a `.i2p/roadmap/` tree is reachable THEN THE SYSTEM SHALL exit with a clear
  message and a non-zero code, never an empty or misleading report.

### Acceptance Criteria
1. Given an i2p project, When the tool runs, Then it writes one HTML file showing backlog/do/doing/done with
   item titles, statuses, and any who/what/cost telemetry.
2. Given no data source, When run, Then it errors clearly and writes nothing.
3. The repo is independent (own README, tests, license) and consumes the `flow-mcp` read verbs or the
   `.i2p/roadmap/` tree as input.
4. This item is reconciled with [40]: [40] is marked superseded-by-[107] and not built twice.

### Implementation Notes
- Depends on [105] (flow/DELIVER stream is stood up) and [97] (the `flow-mcp` rename, so the reporter binds
  the renamed read verbs).
- New repo in `~/Code`; pick a stack that reads MCP/JSON and emits HTML (no live server). Confirm the final
  **repo name with the owner before `git init`** (working name `value-flow-report`).
- Consume `flow-mcp`'s read verbs (`list_items`, `list_events`, `render_roadmap`) when tree-aware, or scan
  `.i2p/roadmap/` directly.
- [40] already specifies the reporter (offline successor to the removed [39] board); this item executes it —
  carry [40]'s acceptance criteria forward rather than re-deriving them.
