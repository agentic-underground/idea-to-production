---
id: 40
title: "value-flow-report — new ~/Code repo, on-demand static-HTML snapshot"
status: PENDING
priority: MEDIUM
added: 2026-06-15
depends_on: "#42 (tree source), #39 (UI removed)"
---

# [40] value-flow-report — new ~/Code repo, on-demand static-HTML snapshot

**Brief Description**
A separate repository in `~/Code` (working name `value-flow-report`) that, when run, reads the current
state of value flow (the flow-server MCP, or the `.i2p/roadmap/` tree directly) and writes a
self-contained static HTML report — the offline successor to the removed live board (item [39]). Point-in-time,
not real-time.

### User Stories
- AS the owner I WANT to run one command and get a shareable HTML snapshot of the value flow (items by
  stage, who is DOING / WHAT, cost roll-ups) SO THAT I can see current state without hosting a server.
- AS the owner I WANT it in its own repo SO THAT the reporter evolves independently of the marketplace.

### EARS Specification
**Ubiquitous**
- The tool SHALL produce a single self-contained HTML file with no runtime server dependency.

**Event-driven**
- WHEN run against an i2p project THE SYSTEM SHALL read the `.i2p/roadmap/` tree (and telemetry if present)
  and render items grouped by stage with per-item who/what/cost.

**Unwanted behaviour**
- IF neither the flow-server MCP nor a `.i2p/roadmap/` tree is reachable THEN THE SYSTEM SHALL exit with a
  clear message and a non-zero code, never an empty/misleading report.

### Acceptance Criteria
1. Given an i2p project, When the tool runs, Then it writes one HTML file showing backlog/do/doing/done with
   item titles, statuses, and any who/what/cost telemetry.
2. Given no data source, When run, Then it errors clearly and writes nothing.
3. The repo is independent (own README, tests, license) and consumes the flow-server MCP or tree as input.

### Implementation Notes
- New repo; pick a stack that reads MCP/JSON and emits HTML (no live server).
- Consume the flow-server's read verbs (`list_items`, `list_events`, `render_roadmap`) once [42] is tree-aware,
  or scan `.i2p/roadmap/` directly.
- Confirm final repo name with the owner before `git init`.
