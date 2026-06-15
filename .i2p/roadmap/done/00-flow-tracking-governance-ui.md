---
id: 0
title: "EPIC — Flow-Tracking Governance UI"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "—"
branch: flow-tracking-ui (single feature branch for the whole epic; the issue/PR is raised from it once the roadmap is empty)
---

# [0] EPIC — Flow-Tracking Governance UI

**Brief Description**
A per-project local web application — packaged as an enhancement to **mission-control** — that renders
the live roadmap as an interactive SVG graph of rounded-rectangle cards joined by curved connectors,
arranged into nested DO·DOING·DONE boards. Each work item is backed by a **carriage agent** that
annotates its card (who/what/token-cost) and streams telemetry. The human governs flow directly:
a WAIT/GO toggle per card gates value-add down that path; commenting pauses an item, and Ctrl-Enter
annotates or fully rewrites the item's plan. A masthead progress bar (identical in spirit to the root
README masthead) and a pac-man completion gauge fill toward 100% as the roadmap empties — at which
point the project returns to "run and observe." This is the **permanent governance/observability
surface** of the human element of the software value system.

### User Stories
- AS A solo builder I WANT to see every roadmap item, its sub-items, and its blocking relationships as a
  live SVG graph SO THAT I can comprehend the whole value system at a glance and steer it.
- AS A builder I WANT a WAIT/GO toggle on each card SO THAT I can stop or release value-add down any path
  while I review, discuss, or re-direct that work — maintaining a healthy flow.
- AS A builder I WANT each item carried by an agent that reports who/what/token-cost SO THAT cost and
  progress are visible per atomic and per composite (dependency-tree) item.
- AS A builder I WANT to comment on an item (which pauses it) and either annotate or trigger a full
  rewrite SO THAT I can tune the plan of any work item before more value is spent on it.
- AS A builder I WANT the board to reject connections that break a dependency or form a cycle SO THAT the
  graph always describes a buildable plan.
- AS A builder I WANT to see the project's whole history — synthesized from git when no roadmap existed —
  SO THAT I can review the value system end-to-end.

### EARS Specification (epic-level; per-child EARS live in #1–#7)
**Ubiquitous**
- The system SHALL present the live roadmap as an interactive SVG governance UI served locally over HTTP.
- The system SHALL keep, per atomic item and per composite (dependency-tree) item, a running token tally.

**Event-driven**
- WHEN the roadmap reaches zero open tickets THE SYSTEM SHALL signal completion (full masthead + full
  pac-man) and surface the "raise the issue/PR from flow-tracking-ui" finale action.

**Unwanted behaviour**
- IF a user-drawn connection would break a dependency or create a circular dependency THEN THE SYSTEM
  SHALL refuse the connection and explain why.

**State-driven**
- WHILE an item is paused (WAIT, or a comment is being typed) THE SYSTEM SHALL highlight it and prevent
  its carriage agent from advancing value.

### Acceptance Criteria
1. Given the plugin is installed in a project, When the user starts the flow server, Then a local web UI
   renders the project's roadmap as an SVG card-graph with curved connectors and nested DO·DOING·DONE boards.
2. Given any card, When the user toggles WAIT, Then that item's carriage agent halts and the card shows
   a paused state; toggling GO resumes it.
3. Given the roadmap empties, Then both the masthead bar and the pac-man gauge read 100% and the finale
   action becomes available.
4. Given the epic ships, Then the root README links to (and is reachable from) the flow-tracking-ui
   README tree, and carries double-reviewed screenshots of the UI.

### Implementation Notes
- **Stack (decided 2026-06-13):** backend is **one Rust binary** (e.g. `axum` HTTP + WebSocket + an MCP
  endpoint via `rmcp`/an MCP server crate) that also serves the static frontend; frontend is **vanilla
  JS on the marketplace `frontend` design system** (dark-mode tokens) with a proven graph/pan-zoom lib
  (`svg-pan-zoom` for canvas navigation; ELK or dagre for automatic DAG layout / auto-align). **No WASM
  for MVP** — captured as a possible follow-on (see EPIC risks). Clickable SVG is native DOM events on
  shapes; animated SVG stays clickable.
- **Packaging:** lives under `plugins/mission-control/` as a new skill/command (`/mission-control:flow`
  or similar) plus the server + static assets; must keep mission-control self-contained
  (`${CLAUDE_PLUGIN_ROOT}` only).
- **Reuse:** the masthead progress-bar generator at
  `docs/internal/image-craft-study/toolchain/src/build-masthead-svg.sh` (for #6); mission-control's existing
  observability/golden-signals knowledge and the local-Grafana target (for #3).
- **Taste bar (maintainer HIGH standard):** every shipped SVG diagram is 4×-adversarially-reviewed and
  must look *stunning*; screenshots are double-reviewed (ATELIER ui-design-reviewer). "If the
  screenshots are no good, we are not at MVP."
- **Adversarial review:** completed UI designs run through ATELIER's ui-design-reviewer (full panel)
  before build, per the DESIGN station.
- **Branch discipline:** the whole epic is carried on `flow-tracking-ui`; the issue/PR is raised from it
  only once the roadmap is empty. (Note: this overrides the usual trunk-based default at the maintainer's
  explicit request, because the branch *is* the live flow the UI tracks.)

### Known risks / open questions
- Realtime fan-out (WebSocket) consistency between the file-backed roadmap, carriage-agent state, and the
  canvas — single source of truth must be the roadmap markdown + a JSONL event log, with the UI as a view.
- MCP-over-the-same-process-as-HTTP: verbs/endpoints and the MCP tool surface must not overlap or leak
  (security review by SENTINEL before ship).
- WASM live-SVG is explicitly **deferred**, not rejected — a follow-on entry can graft a Rust/WASM
  frontend onto the same Rust server if the vanilla-JS canvas hits a ceiling.

### Development Plan Reference
`doc/FLOW_TRACKING_GOVERNANCE_UI_PLAN.md` (master epic plan; each child gets its own `doc/<TITLE>_PLAN.md`).
