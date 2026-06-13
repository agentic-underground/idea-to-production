# MISSION-CONTROL — Roadmap

> Last updated: 2026-06-13
> Maintained by: idea-to-production marketplace (mission-control plugin)

This document is the authoritative list of planned features for the **mission-control** plugin.
Each entry is self-contained and can be acted upon by an AI agent or developer without additional
context. Features are implemented using THE DEVELOPMENT SYSTEM defined in the FOUNDRY ROADMAPPER skill.

The shipped surface covers OPERATE — incident, iterate, maintain, observability, operate-gate. This
roadmap captures the **Flow-Tracking Governance UI** epic: the standing observability/governance
interface through which the human element steers value through the idea-to-production system.

---

## Status Legend
- **PENDING** — not yet started
- **IN PROGRESS** — actively being implemented
- **SUSPENDED** — mid-implementation pause; plan file has resumption instructions
- **AWAITING MERGE** — built, PASSed review, PR open for human merge
- **COMPLETE** — shipped
- **DEFERRED** — postponed, reason noted in entry

---

## Dependency tree (the EPIC, #0)

```
EPIC #0 Flow-Tracking Governance UI  (branch: flow-tracking-ui)
 ├─ #1 Flow server (HTTP + WebSocket + MCP, one Rust binary)   [atomic]
 ├─ #2 SVG flow-canvas (cards · curved connectors · 3-col boards · pan/zoom/drag)  → blocks on #1
 ├─ #3 Carriage agent + token telemetry (JSONL ledger → Grafana)                   → blocks on #1
 ├─ #4 Comment / pause / annotate / rewrite loop                                   → blocks on #2, #3
 ├─ #5 Roadmap history + git-log proxy synthesis                                   [atomic]
 ├─ #6 Masthead progress bar + pac-man completion gauge + system-message feed      → blocks on #3
 └─ #7 The finale — stunning PR, README tree, double-reviewed screenshots          → blocks on all
```

A composite item may carry links to other composite items; #2 must render this tree exactly — atomic
nodes, blocking edges, and boards-within-boards — because the tree it draws is the tree above.

---

## [0] EPIC — Flow-Tracking Governance UI
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> BRANCH: flow-tracking-ui (single feature branch for the whole epic; the issue/PR is raised from it once the roadmap is empty)

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
  `doc/image-craft-study/toolchain/src/build-masthead-svg.sh` (for #6); mission-control's existing
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

---

## [1] Flow server — HTTP + WebSocket + MCP in one Rust binary
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: — (atomic; foundation for the epic)

**Brief Description**
A single Rust binary that serves the static governance UI over HTTP, pushes realtime updates over
WebSocket, and exposes an MCP endpoint so agents can read/mutate flow state through typed verbs. The one
source of truth is the roadmap markdown plus an append-only JSONL event log.

### User Stories
- AS the governance UI I WANT a local HTTP+WS server SO THAT I can render and live-update the flow.
- AS a carriage/orchestrator agent I WANT typed MCP verbs SO THAT I can read items, post status, and
  record token spend without scraping the UI.

### EARS Specification
**Ubiquitous**
- The system SHALL serve the static frontend and a REST verb surface over local HTTP.
- The system SHALL expose an MCP endpoint whose tools cover: list items, get item, set WAIT/GO, post
  carriage status, append token spend, validate a proposed connection, and append a system message.
**Event-driven**
- WHEN flow state changes (status, WAIT/GO, token spend, comment) THE SYSTEM SHALL broadcast the delta to
  all connected WebSocket clients.
**Unwanted behaviour**
- IF an MCP verb or REST request would mutate the roadmap into an invalid graph (cycle / broken
  dependency) THEN THE SYSTEM SHALL reject it with a typed error and leave state unchanged.
- IF the MCP and HTTP verb surfaces would expose the same mutation by two unauthenticated paths THEN THE
  SYSTEM SHALL require the same authorization for both.
**State-driven**
- WHILE an item is in WAIT THE SYSTEM SHALL refuse carriage-advance verbs for that item.

### Acceptance Criteria
1. Given the binary runs, When a browser requests `/`, Then the SVG UI is served.
2. Given a WebSocket client is connected, When any item's status changes, Then the client receives the
   delta without polling.
3. Given an MCP client, When it calls `validate_connection(from,to)` that would form a cycle, Then it
   receives a rejection naming the cycle.

### Implementation Notes
- Rust: `axum` (HTTP + WS upgrade), an MCP server crate (`rmcp` or equivalent), `serde`/`serde_json`,
  graph validation in a pure domain core (parse-don't-validate; no cycles by construction).
- Roadmap markdown is parsed into the domain model; JSONL event log is the write-ahead record.
- SENTINEL `/security-gate` before ship — this is a locally-served mutable surface.

### Human Interface Test Plan
- (Server has no UI of its own; its UI surfaces are exercised via #2's tests and API/MCP contract tests.)

### Development Plan Reference
`doc/FLOW_SERVER_PLAN.md`

---

## [2] SVG flow-canvas — cards, curved connectors, nested boards, pan/zoom/drag
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: #1

**Brief Description**
The interactive canvas: rounded-rectangle cards joined by curved connectors, grouped into nested
three-column DO·DOING·DONE boards (boards can contain items that contain boards), laid out as a
top-down dependency graph traversable in parallel. Mouse-wheel zoom, click-and-hold pan, drag-to-move,
and auto-align by order/dependency. Connections are initially auto-sequenced by mission-control; the user
may re-draw them, but the UI refuses any edit that breaks a dependency or forms a cycle. Cards carry
badges (token cost, state, draft#, error-catches, child-tasks like red-green-refactor) and a WAIT/GO toggle.

### User Stories
- AS A builder I WANT to pan (click-drag), zoom (wheel), and drag cards SO THAT I can navigate a large flow.
- AS A builder I WANT auto-align by order/dependency SO THAT the graph tidies itself.
- AS A builder I WANT badges on each card SO THAT cost, state, draft count, error-catches, and child-tasks
  are visible without opening the item.
- AS A builder I WANT the canvas to forbid invalid connections SO THAT the drawn graph is always buildable.

### EARS Specification
**Ubiquitous**
- The system SHALL render every roadmap item as a rounded-rect card and every dependency as a curved
  connector, grouped into nested DO·DOING·DONE boards.
- The system SHALL display, per card, badges for token cost, current state, draft number, error-catches,
  and child-tasks; and a WAIT/GO toggle.
**Event-driven**
- WHEN the user rotates the mouse wheel THE SYSTEM SHALL zoom the canvas about the cursor.
- WHEN the user clicks and holds on empty canvas and drags THE SYSTEM SHALL pan.
- WHEN the user drags a card THE SYSTEM SHALL move it; WHEN the user invokes auto-align THE SYSTEM SHALL
  arrange all nodes by order and dependency.
- WHEN an item advances across DO→DOING→DONE THE SYSTEM SHALL animate the card's move between columns.
**Unwanted behaviour**
- IF the user draws a connection that breaks a dependency or forms a circular dependency THEN THE SYSTEM
  SHALL refuse it and show why.

### Acceptance Criteria
1. Given a large flow, When the user wheels/drags, Then the canvas zooms about the cursor and pans smoothly.
2. Given two cards, When the user draws an edge that would create a cycle, Then the edge snaps back and a
   reason is shown.
3. Given an item moves to DONE, Then its card visibly transitions into the DONE column.

### Implementation Notes
- Vanilla JS on the `frontend` design system; `svg-pan-zoom` for navigation; ELK or dagre for auto-layout;
  curved connectors as SVG `<path>` (cubic Béziers). Connection validity calls #1's `validate_connection`.
- Clickable cards/badges/toggles are native SVG DOM events.

### Human Interface Test Plan
- [WAIT/GO toggle on a card]: navigate to canvas → find a card → click WAIT → verify card shows paused
  highlight and toggle reads WAIT → reload → verify still WAIT → click GO → verify resumes.
- [Pan]: click-hold empty canvas → drag → verify viewport translates → release → reload → verify last
  view persists (or resets to fit, per design).
- [Zoom]: wheel up over a card → verify zoom centres on cursor.
- [Draw invalid connection]: drag from card A's port to card B forming a cycle → verify edge is rejected
  with a visible reason and no edge persists after reload.
- [Auto-align]: click "Auto-align" → verify nodes re-arrange by dependency order.

### Development Plan Reference
`doc/SVG_FLOW_CANVAS_PLAN.md`

---

## [3] Carriage agent + token telemetry (JSONL ledger → Grafana)
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: #1

**Brief Description**
Every work item is backed by a carriage agent that annotates its card with who is processing it, what
they are processing, and how many tokens the ticket has cost. All of it is captured to append-only JSONL
log files and pushed to the local Grafana, and rolled up into reports of total token cost broken down by
work item and sub-item — for each atomic item and up the dependency tree of composite items.

### User Stories
- AS A builder I WANT each item's card to show who/what/token-cost in real time SO THAT I can see where
  value (and spend) is going.
- AS A builder I WANT token cost rolled up per atomic item and per composite item SO THAT I can read cost
  by work item and sub-item.
- AS the telemetry host I WANT the data as JSONL SO THAT reports and Grafana can consume it as a data source.

### EARS Specification
**Ubiquitous**
- The system SHALL record, for every item, the processing agent identity, the current activity, and a
  cumulative token tally.
- The system SHALL persist every telemetry event as a line in an append-only JSONL log and push it to the
  local Grafana.
**Event-driven**
- WHEN a carriage agent consumes tokens on an item THE SYSTEM SHALL add them to that item's tally and to
  every ancestor composite item's tally.
- WHEN a report is requested THE SYSTEM SHALL compute total token cost broken down by item and sub-item
  from the JSONL data sources.
**Unwanted behaviour**
- IF an item is in WAIT THEN THE SYSTEM SHALL NOT let its carriage agent advance value or accrue work tokens.

### Acceptance Criteria
1. Given a carriage agent processes item X, Then X's card shows the agent, the activity, and a rising token
   count, and a JSONL line is appended.
2. Given X is a child of composite C, When X accrues 1000 tokens, Then C's rolled-up tally rises by 1000.
3. Given the JSONL logs, When a token-cost report is generated, Then totals reconcile to the sum of events.

### Implementation Notes
- Carriage agent is a FOUNDRY-style value-handler bound to one item; reports status/spend via #1's MCP verbs.
- JSONL schema: `{ts, item_id, agent, activity, tokens_delta, tokens_total, ancestors[]}`. Grafana via the
  local agent/Loki already referenced in mission-control observability knowledge.

### Human Interface Test Plan
- [Carriage status on a card]: start processing an item → verify card shows agent name + activity + token
  badge incrementing → reload → verify last status persists from the JSONL log.

### Development Plan Reference
`doc/CARRIAGE_AGENT_TELEMETRY_PLAN.md`

---

## [4] Comment / pause / annotate / rewrite loop
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: #2, #3

**Brief Description**
Human-in-the-loop tuning of any item. The moment the user begins typing a comment, the item pauses and is
highlighted as paused. Ctrl-Enter unpauses the item and appends the commentary as a markdown annotation to
the item's plan document. A "Rewrite entirely" button passes the commentary to the item's carriage agent,
which re-drafts the item.

### User Stories
- AS A builder I WANT typing a comment to immediately pause the item SO THAT no value is spent while I think.
- AS A builder I WANT Ctrl-Enter to unpause and append my comment to the plan markdown SO THAT my direction
  is recorded in the item's own document.
- AS A builder I WANT a "rewrite" button that hands my commentary to the agent SO THAT the item is re-drafted
  with my direction.

### EARS Specification
**Event-driven**
- WHEN the user begins typing a comment on an item THE SYSTEM SHALL pause that item and highlight it as paused.
- WHEN the user presses Ctrl-Enter THE SYSTEM SHALL unpause the item and append the comment as an annotation
  to the item's plan markdown.
- WHEN the user clicks "Rewrite entirely" THE SYSTEM SHALL pass the commentary to the carriage agent and
  replace the item's draft, incrementing its draft number.
**State-driven**
- WHILE a comment is being composed THE SYSTEM SHALL keep the item paused and visibly highlighted.

### Acceptance Criteria
1. Given an item, When the user types the first character of a comment, Then the item shows paused/highlighted.
2. Given a composed comment, When the user presses Ctrl-Enter, Then the item unpauses and the comment appears
   appended to the plan markdown (persists after reload).
3. Given a comment, When the user clicks "Rewrite entirely", Then the agent re-drafts the item and the draft#
   badge increments.

### Implementation Notes
- Pause-on-type reuses the WAIT mechanism from #1/#2; annotation writes to `doc/<TITLE>_PLAN.md` via an MCP
  verb; rewrite invokes the carriage agent (#3) with the comment as context.

### Human Interface Test Plan
- [Comment pauses item]: focus an item's comment box → type a character → verify item highlights as paused →
  finish comment → Ctrl-Enter → verify unpaused and comment text now in the plan doc after reload.
- [Rewrite button]: type guidance → click "Rewrite entirely" → verify a new draft replaces the item and draft#
  badge increments.

### Development Plan Reference
`doc/COMMENT_REWRITE_LOOP_PLAN.md`

---

## [5] Roadmap history + git-log proxy synthesis
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: — (atomic)

**Brief Description**
The UI shows the full history of roadmap items from beginning to end. When a project adopted the roadmap
late, a proxy set of historical roadmap items is synthesized from the git log so the user can still see the
project's whole arc, with a done/not-done toggle view.

### User Stories
- AS A builder I WANT to see every roadmap item's history SO THAT I can review the project end-to-end.
- AS A builder on a project that adopted the roadmap late I WANT historical items synthesized from git SO
  THAT the timeline is complete, not blank before adoption.
- AS A builder I WANT a done-vs-not-done toggle SO THAT I can filter the board to either view.

### EARS Specification
**Ubiquitous**
- The system SHALL present the complete history of roadmap items from first to last.
**Event-driven**
- WHEN the roadmap's recorded history predates the roadmap file THE SYSTEM SHALL synthesize proxy historical
  items from the git log to fill the gap.
- WHEN the user toggles the done/not-done view THE SYSTEM SHALL filter the board accordingly.
**Unwanted behaviour**
- IF the git log is empty or unreadable THEN THE SYSTEM SHALL show the roadmap-native history only and say so.

### Acceptance Criteria
1. Given a project with a late-added roadmap, When history is opened, Then synthesized items derived from git
   commits appear before the first real roadmap item, clearly marked as synthesized.
2. Given the history view, When done/not-done is toggled, Then only matching items are shown.

### Implementation Notes
- Git-log parse (conventional-commit aware) → proxy items; mark provenance (`synthesized: true`) so they are
  visually distinct and never mutated as if real tickets.

### Human Interface Test Plan
- [Done/not-done toggle]: open history → toggle "Done" → verify only DONE items show → toggle "Not done" →
  verify only open items show.
- [Synthesized history]: on a repo with commits predating the roadmap → verify synthesized items appear,
  marked, before the first roadmap item.

### Development Plan Reference
`doc/ROADMAP_HISTORY_SYNTHESIS_PLAN.md`

---

## [6] Masthead progress bar + pac-man completion gauge + system-message feed
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: #3

**Brief Description**
A progress bar across the top of the screen — in the spirit of the root README masthead graphic — wired to
the **actual** roadmap: completion is when no tickets remain and the project returns to "run and observe."
Alongside it, a "pac-man graph" that gradually fills to 100% as the roadmap empties, and a system-message
feed: a mini-blog of orchestrator updates on what's been happening in the value system.

### User Stories
- AS A builder I WANT a top-of-screen progress bar wired to the real roadmap SO THAT I always know how close
  the project is to "done / run and observe."
- AS A builder I WANT a pac-man gauge that fills to 100% SO THAT completion is glanceable and motivating.
- AS A builder I WANT a feed of orchestrator system messages SO THAT I can read what the value system has
  been doing.

### EARS Specification
**Ubiquitous**
- The system SHALL display a masthead progress bar and a pac-man completion gauge whose fill equals the
  fraction of roadmap items that are DONE.
- The system SHALL display a chronological feed of orchestrator system messages.
**Event-driven**
- WHEN the last open ticket closes THE SYSTEM SHALL render both gauges at 100% and indicate the return to
  "run and observe."
- WHEN the orchestrator emits a system message THE SYSTEM SHALL prepend it to the feed in realtime.

### Acceptance Criteria
1. Given N items with K done, Then both gauges read K/N.
2. Given the last item completes, Then both gauges read 100% and the "run and observe" state is shown.
3. Given an orchestrator message is emitted, Then it appears at the top of the feed without reload.

### Implementation Notes
- Reuse `doc/image-craft-study/toolchain/src/build-masthead-svg.sh` for the bar's look; fill bound to the
  DONE fraction over the WebSocket stream; system messages come from the JSONL event log (#3).

### Human Interface Test Plan
- [Progress reflects roadmap]: mark an item DONE → verify both gauges advance without reload.
- [System feed]: trigger an orchestrator message → verify it appears at the top of the feed live.

### Development Plan Reference
`doc/MASTHEAD_PROGRESS_PACMAN_PLAN.md`

---

## [7] The finale — stunning PR, README tree, double-reviewed screenshots
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: #1, #2, #3, #4, #5, #6

**Brief Description**
Once the roadmap is empty, the `flow-tracking-ui` branch becomes the source of the issue/PR: a rich markdown
document that *sells* the PR — complete with stunning, 4×-adversarially-reviewed SVG diagrams, a detailed PR
message, and a carefully planned README tree linked back to (and traversable from) the root README, which
gains awesome, double-reviewed screenshots of the UI. If the screenshots are not excellent, we are not at MVP.

### User Stories
- AS the maintainer I WANT the PR to read as a compelling, illustrated case SO THAT the work's value is
  unmistakable.
- AS a future reader I WANT a README tree linked from the root README SO THAT I can navigate into and out of
  the feature's docs.
- AS the maintainer I WANT double-reviewed screenshots SO THAT the UI quality is proven, not asserted.

### EARS Specification
**Event-driven**
- WHEN the roadmap reaches zero open tickets THE SYSTEM (operator) SHALL raise an issue/PR from
  `flow-tracking-ui` with the rich markdown, the reviewed diagrams, and the README tree.
**Unwanted behaviour**
- IF any shipped SVG diagram or screenshot fails its adversarial review THEN it SHALL NOT be considered MVP
  and SHALL be re-drafted until it passes.

### Acceptance Criteria
1. Given the roadmap is empty, Then a PR exists from `flow-tracking-ui` with a selling markdown body, the
   reviewed diagrams, and a README tree linked from the root README.
2. Given the diagrams, Then each has survived 4 adversarial design reviews (draft# ≥ 4 recorded).
3. Given the screenshots, Then each has passed two ATELIER ui-design-reviewer passes.

### Implementation Notes
- Diagrams via PRESSROOM illustrator (dark-mode, transparent, A/B-until-best); screenshots via ATELIER
  ui-review on the running UI; root-README screenshots embedded and link-checked by `scripts/verify-prereqs.sh`.

### Human Interface Test Plan
- [Root README → feature README]: from the root README, follow the flow-tracking-ui link → verify it reaches
  the feature README tree → verify a link back to the root README resolves.

### Development Plan Reference
`doc/FLOW_TRACKING_FINALE_PLAN.md`

---

## Principles guiding expansion

Every surface here (a) keeps mission-control self-contained (`${CLAUDE_PLUGIN_ROOT}` only, no assumption
another plugin is installed — degrade gracefully when PRESSROOM/ATELIER/SENTINEL are absent), (b) treats the
roadmap markdown + JSONL event log as the single source of truth and the UI as a view, (c) carries the
self-improvement covenant, and (d) holds the maintainer's HIGH taste bar: stunning, reviewed visuals or it
is not MVP.
