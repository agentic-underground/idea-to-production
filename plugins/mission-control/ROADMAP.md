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
 ├─ #8 Per-job model selection (default shown · per-card override)                 → blocks on #1, #2, #3
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
A single Rust binary — the **sole writer** of flow state — that serves the static governance UI over
HTTP, pushes realtime updates over WebSocket, and exposes an MCP endpoint (streamable-HTTP, same
process and port) so agents read/mutate flow exclusively through typed, token-authenticated verbs. The
one source of truth is the roadmap markdown (items keyed by **stable slug IDs**) plus an append-only
JSONL event log; no client ever writes those files directly.

### User Stories
- AS the governance UI I WANT an HTTP+WS server SO THAT I can render and live-update the flow.
- AS a carriage/orchestrator agent I WANT typed MCP verbs SO THAT I can read items, post status, and
  record token spend without scraping the UI.
- AS the maintainer I WANT a single writer behind authenticated verbs SO THAT concurrent agents and the
  UI never race on the roadmap files and the board can be safely watched from another device.

### EARS Specification
**Ubiquitous**
- The system SHALL serve the static frontend and a REST verb surface over HTTP, and SHALL be the only
  process that writes the roadmap markdown and the JSONL event log.
- The system SHALL expose an MCP endpoint (streamable-HTTP, same process/port) whose tools cover: list
  items, get item, set WAIT/GO, post carriage status, append token spend, set item model, validate a
  proposed connection, mutate a connection, and append a system message.
- The system SHALL identify every item by a stable slug ID (the `[N]` number is display order only) so
  that reordering, board moves, and re-sequencing never break edges, telemetry, or model overrides.
- The system SHALL bind to a configurable host (default LAN-reachable) and SHALL require a shared bearer
  token, read from a local file, on **every** HTTP, WebSocket, and MCP request.
**Event-driven**
- WHEN flow state changes (status, WAIT/GO, token spend, comment, model, connection) THE SYSTEM SHALL
  broadcast the delta to all connected WebSocket clients.
**Unwanted behaviour**
- IF a request (REST, WebSocket, or MCP) lacks a valid token THEN THE SYSTEM SHALL reject it and mutate
  nothing — the same authorization gates all three surfaces.
- IF an MCP verb or REST request would mutate the roadmap into an invalid graph (cycle / broken
  dependency) THEN THE SYSTEM SHALL reject it with a typed error and leave state unchanged.
- IF a client attempts to write the roadmap markdown or JSONL by any path other than a server verb THEN
  that path SHALL NOT exist (the server owns the files; there is no direct-write endpoint).
**State-driven**
- WHILE an item is in WAIT THE SYSTEM SHALL refuse carriage-advance verbs for that item.

### Acceptance Criteria
1. Given the binary runs, When a browser presents a valid token and requests `/`, Then the SVG UI is served.
2. Given a request without a valid token (REST, WS, or MCP), Then it is rejected and no state changes.
3. Given a WebSocket client is connected, When any item's state changes, Then the client receives the
   delta without polling.
4. Given an MCP client, When it calls `validate_connection(from,to)` that would form a cycle, Then it
   receives a rejection naming the cycle and the graph is unchanged.
5. Given two clients mutate concurrently through verbs, Then all writes serialize through the server and
   the markdown/JSONL never interleave or corrupt.
6. Given an item is referenced by slug ID, When items are reordered, Then every edge/telemetry/model
   reference to that item still resolves.

### Implementation Notes
- Rust: `axum` (HTTP + WS upgrade), an MCP server crate (`rmcp` or equivalent) mounted on the same
  router, `serde`/`serde_json`; graph validation in a pure domain core (parse-don't-validate; no cycles
  by construction). All writes go through a single serialized writer (actor/`Mutex`-guarded) so the files
  never race.
- **Identity:** each roadmap item carries a stable slug ID (e.g. an HTML comment `<!-- id: flow-server -->`
  beside its `[N]` heading); the domain model and all references key on the ID. A migration pass stamps
  IDs onto the existing entries.
- **Auth:** bearer token generated on first run into a local file (e.g. `.flow/token`), required on HTTP,
  WS handshake, and MCP. Host configurable (`--host`, default LAN-reachable); document the exposure.
- Roadmap markdown is parsed into the domain model; JSONL event log is the write-ahead record.
- SENTINEL `/security-gate` before ship — this is a network-reachable mutable surface, so the token +
  no-direct-write-path invariants are security-critical, not nice-to-haves.

### Human Interface Test Plan
- (Server has no UI of its own; its UI surfaces are exercised via #2's tests and API/MCP contract tests,
  including a token-rejected path and a concurrent-write serialization test.)

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

## [8] Per-job model selection — default shown, per-card override
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: #1, #2, #3

**Brief Description**
Each job on the board carries a model assignment. The user can see the **default** model assigned to any
item and **override** it per job — switching a given job from Sonnet to Opus, or from Opus to Haiku (or
Fable) — directly on the card. The item's carriage agent then runs under the chosen model, so the human
can tune the cost↔capability trade-off job-by-job (cheap model for mechanical work, the strongest model
for the hard slice) while watching the live token tally that #3 records.

### User Stories
- AS A builder I WANT to see the default model assigned to any item SO THAT I know what will process it
  before I spend anything.
- AS A builder I WANT to set the model for any given job on the board SO THAT I can switch it from Sonnet
  to Opus, or Opus to Haiku, to match the job's difficulty and cost.
- AS A builder I WANT the carriage agent to run under the model I chose SO THAT my selection actually
  governs how the work is done and what it costs.

### EARS Specification
**Ubiquitous**
- The system SHALL display, on each item, the model currently assigned to it and whether that model is the
  default or a user override.
- The system SHALL assign every item a default model when it is created.
**Event-driven**
- WHEN the user selects a different model for an item THE SYSTEM SHALL record the override, broadcast the
  change to all connected clients, and use that model for the item's carriage agent on its next run.
- WHEN the user clears an override THE SYSTEM SHALL revert the item to its default model.
**Unwanted behaviour**
- IF the user selects a model that is not in the configured allowlist THEN THE SYSTEM SHALL refuse the
  change and leave the current assignment unchanged.
- IF an item is mid-run THEN THE SYSTEM SHALL apply a model change only to its next run, never silently
  switching a model under an in-flight agent.
**Optional feature**
- WHERE a model allowlist is configured THE SYSTEM SHALL offer only those models in the picker (default
  set: Haiku 4.5 · Sonnet 4.6 · Opus 4.8 · Fable 5).

### Acceptance Criteria
1. Given any item, Then its card shows the assigned model and a marker distinguishing "default" from
   "overridden".
2. Given an item on the default model, When the user picks a different allowlisted model, Then the card
   shows the new model as an override and the change persists after reload.
3. Given an overridden item, When the user clears the override, Then the card reverts to the default model.
4. Given an override is set, When the item's carriage agent next runs, Then it runs under the chosen model
   (verifiable in the JSONL telemetry's recorded model field).
5. Given a non-allowlisted model is requested, Then the change is refused and the prior assignment stands.

### Implementation Notes
- **Data:** each item gains a `model` field (`{default, override?}`); the resolved model is `override ??
  default`. Stored with the item; broadcast over #1's WebSocket; mutated via a new MCP/REST verb
  `set_item_model(item_id, model | null)`.
- **Default assignment:** the orchestrator picks the default per item (e.g. by task class/complexity) when
  the item is created — keep the policy in one place so it is tunable later; this entry only requires that
  a default exists and is shown.
- **Carriage agent (#3):** reads the resolved model before each run and spawns under it; records the model
  used in the telemetry line so cost is attributable per model.
- **UI (#2):** a model picker on the card (badge + dropdown), default-vs-override styling, allowlist-driven
  options; pairs naturally beside the token-cost badge so cost and model are read together.
- **Allowlist:** marketplace model IDs — `claude-haiku-4-5`, `claude-sonnet-4-6`, `claude-opus-4-8`,
  `claude-fable-5`; configurable so a project can narrow the set.

### Human Interface Test Plan
- [Model badge shows default]: navigate to canvas → find an item → verify its card shows a model badge
  marked "default" with the assigned model name.
- [Override the model]: click the model badge → verify a picker lists the allowlisted models → choose a
  different one (e.g. Opus → Haiku) → verify the badge updates and now reads "override" → reload → verify
  the override persists.
- [Clear the override]: open an overridden item's picker → choose "Use default" → verify the badge reverts
  to the default model → reload → verify reverted.
- [Override governs the run]: set an item's model, then let its carriage agent run → verify the telemetry
  line for that run records the chosen model.

### Development Plan Reference
`doc/PER_JOB_MODEL_SELECTION_PLAN.md`

---

## [7] The finale — stunning PR, README tree, double-reviewed screenshots
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: #1, #2, #3, #4, #5, #6, #8

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

## Dependency tree (the EPIC, #9)

```
EPIC #9 Process-Documentation & Git Governance — docs emerge as we build
 ├─ #10 Commit→Issue→PR governance (emoji conv-commits · issue-per-completed-item · PR closes issues)  → blocks on: gh, merge-governance
 ├─ #11 Issues-as-process-documentation (per-handler value-add annotation)                              → blocks on #10
 ├─ #12 Roadmap-item doc + illustration pipeline (per completed item · parallel sub-agents)             [atomic · pressroom]
 ├─ #13 GitHub wiki construction (opt-in, any github origin · opus finals + #12 diagrams)               → blocks on #10, #12
 └─ #14 Onboarding alert — "from now on, items are documented this way"                                 [atomic · concierge]
```

This is a **standing process change** for every project using the idea-to-production system, implemented
across FOUNDRY (commit/governance + orchestrator), PRESSROOM (doc + illustration pipeline), CONCIERGE (the
onboarding alert), and surfaced in the flow UI (#0) as issue links/annotations on cards. The cheap layer
(emoji commits + per-handler issue annotation) is **always-on**; the expensive opus doc + illustration
pipeline runs **per completed roadmap item**, gated by the token-fairness scheduler — never per commit.

---

## [9] EPIC — Process-Documentation & Git Governance (docs emerge as we build)
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> BRANCH: flow-tracking-ui (carried with the flow epic; this is the value system's governance + online-docs behaviour)

**Brief Description**
As value passes between phases, the system documents the *process itself* online and keeps git tidy. Commits
are emoji Conventional Commits (the existing FOUNDRY standard); when a repo's origin is in the org allowlist
(default `agentic-underground/*`) the orchestrator raises a GitHub issue per completed work item, annotates
that issue as each handler adds value (activities + value-add — "issues as process documentation"), and the
parcel's pull request references and closes those issues on merge. Separately, each completed roadmap item is
documented by a PRESSROOM pipeline (sonnet draft → opus review → opus final, plus an illustration loop) whose
output also feeds the issues and an opt-in GitHub wiki. Every new or newly-onboarded project is told, up
front, that its roadmap items will be documented this way.

### User Stories
- AS the maintainer I WANT every completed item to leave a GitHub issue annotated with what each handler did
  SO THAT the build's process is self-documenting and auditable online.
- AS the maintainer I WANT the PR to reference and close those issues on merge SO THAT git history, issues,
  and the roadmap stay in lock-step.
- AS a reader I WANT professional, illustrated documentation to emerge as the project is built SO THAT the
  product is explained without a separate documentation phase.
- AS the maintainer I WANT to be told, when a project onboards, that this is how it will now work SO THAT the
  behaviour is never a surprise.

### EARS Specification (epic-level; per-child EARS live in #10–#14)
**Ubiquitous**
- The system SHALL write every commit as an emoji Conventional Commit per the FOUNDRY commit standard.
**Event-driven**
- WHEN a work item completes AND the repo origin is in the configured org allowlist THE SYSTEM SHALL raise a
  GitHub issue for it; WHEN a parcel's PR merges THE SYSTEM SHALL close the referenced issues.
- WHEN a roadmap item completes THE SYSTEM SHALL commission its documentation + illustrations (per #12),
  scheduled under the token-fairness gate.
- WHEN a project is created or newly onboarded to idea-to-production THE SYSTEM SHALL alert the user that
  roadmap items will be documented this way.
**Unwanted behaviour**
- IF the origin is not in the allowlist THEN THE SYSTEM SHALL NOT raise issues (commits + local docs only).
- IF running the opus documentation pipeline per commit would breach the token-fairness window THEN THE
  SYSTEM SHALL run it per completed item, off-peak, never per commit.

### Acceptance Criteria
1. Given an allowlisted origin, When an item completes, Then a GitHub issue exists for it, annotated with the
   handlers' value-add, and the parcel PR closes it on merge.
2. Given any completed item, Then professional documentation + at least one reviewed illustration exist for it.
3. Given a github origin, When the project onboards, Then the user is offered the professional wiki and told
   how items will be documented.

### Implementation Notes
- **Cross-plugin** — FOUNDRY (governance/orchestration), PRESSROOM (doc + art pipeline), CONCIERGE (alert),
  MISSION-CONTROL flow UI (issue/annotation surfacing). Each degrades gracefully when a partner is absent.
- **Reuse, don't reinvent:** `foundry/knowledge/protocols/commit-message.md` (emoji conv-commits) and
  `merge-governance.md` (pr-approval, one-branch-one-PR) already exist — extend them with issue linkage.
- **Token safety is load-bearing:** the opus doc + illustration pipeline is expensive and recurring; it MUST
  be scheduled through the `tf` token-fairness gate, per completed item, off-peak — never per commit.

### Development Plan Reference
`doc/PROCESS_DOC_GIT_GOVERNANCE_PLAN.md` (master epic plan; each child gets its own `doc/<TITLE>_PLAN.md`).

---

## [10] Commit → Issue → PR governance (org-allowlisted)
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: — (extends existing FOUNDRY commit + merge governance; needs the `gh` CLI)

**Brief Description**
Standardises git flow for all idea-to-production projects: emoji Conventional Commits (existing FOUNDRY
standard); when the origin is in the configured org allowlist (default `agentic-underground/*`), raise a
GitHub issue per completed work item; the parcel's pull request references those issues and closes them on
merge. Non-allowlisted origins keep commits + local docs only.

### User Stories
- AS the orchestrator I WANT to raise an issue per completed item on allowlisted origins SO THAT each unit of
  value has a durable online record.
- AS the maintainer I WANT the PR to close the referenced issues on merge SO THAT nothing is left dangling.

### EARS Specification
**Ubiquitous**
- The system SHALL format every commit as an emoji Conventional Commit per the FOUNDRY commit standard.
- The system SHALL read the org allowlist from configuration (default `agentic-underground/*`).
**Event-driven**
- WHEN a work item completes AND `origin` matches the allowlist THE SYSTEM SHALL create a GitHub issue
  titled and linked to that item, recording its roadmap ID.
- WHEN a parcel of items is complete THE SYSTEM SHALL open one PR whose body references each item's issue with
  a closing keyword (`Closes #N`), so merging closes them.
**Unwanted behaviour**
- IF `origin` is not in the allowlist THEN THE SYSTEM SHALL skip all GitHub issue/PR automation and proceed
  with commits + local docs only.
- IF the `gh` CLI is unavailable or unauthenticated THEN THE SYSTEM SHALL report the gap and continue without
  blocking the build.

### Acceptance Criteria
1. Given an allowlisted origin and a completed item, Then a GitHub issue exists carrying its roadmap ID.
2. Given a parcel PR, When it merges, Then every referenced issue is closed automatically.
3. Given a non-allowlisted origin, Then no issues/PRs are auto-created and the build still completes.

### Implementation Notes
- `gh issue create` / `gh pr create`; allowlist match on the parsed `origin` host/owner. Extends
  `merge-governance.md` (pr-approval already opens one PR to main) and `commit-message.md` (already emoji
  conv-commits) — add the issue-linkage layer; do not duplicate either standard.
- "Parcel" = a set of completed roadmap items released together (typically the epic's PR, per #0/#7 model).

### Development Plan Reference
`doc/COMMIT_ISSUE_PR_GOVERNANCE_PLAN.md`

---

## [11] Issues as process-documentation — per-handler annotation
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: #10

**Brief Description**
As an item passes through each handler/value-station, the system annotates its GitHub issue with commentary
stating the activities performed and the value-add achieved — turning the issue into a live, ordered log of
how the work was actually done ("issues as documentation" — of the process). This is the always-on, cheap
layer (no opus pipeline).

### User Stories
- AS the maintainer I WANT each handler to append what it did and the value it added to the item's issue SO
  THAT the issue becomes a faithful, timestamped record of the build process.

### EARS Specification
**Event-driven**
- WHEN a handler finishes its contribution to an item THE SYSTEM SHALL append a comment to that item's issue
  naming the handler, the activity, and the value-add.
**Unwanted behaviour**
- IF the item has no associated issue (non-allowlisted origin) THEN THE SYSTEM SHALL record the same
  commentary to the local JSONL/system-message log instead, losing nothing.

### Acceptance Criteria
1. Given an item with an issue, When a handler completes, Then a new annotation appears on that issue naming
   handler + activity + value-add.
2. Given the item reaches DONE, Then its issue reads top-to-bottom as the ordered story of its construction.

### Implementation Notes
- `gh issue comment`; the annotation source is the same carriage/handler telemetry as flow-UI #3 — one event,
  two sinks (issue comment + JSONL). Cheap: plain text, no model fan-out.

### Development Plan Reference
`doc/ISSUES_AS_PROCESS_DOC_PLAN.md`

---

## [12] Roadmap-item documentation + illustration pipeline (PRESSROOM)
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: HIGH
> DEPENDS ON: — (atomic; PRESSROOM; token-fairness-gated)

**Brief Description**
For each **completed** roadmap item, the orchestrator commissions a PRESSROOM documentation pipeline on
parallel sub-agents: a **sonnet** pass collects, synthesises, and drafts the documentation; an **opus** pass
adversarially reviews it; an **opus** pass produces the final draft. The document is **adaptive** — every
item gets a how-to; a UI/usage section is added only when the item has a user interface, and a
technical/architecture section only when the item introduces structure. In parallel, the illustrator mines
the content for figures and commissions each through a **bounded** loop: a **sonnet** agent draws the initial
concept art, an **opus** adversarial reviewer scores it on the design-fitness rubric, and an **opus**
craft-handler polishes — looping up to **N=4** rounds, accepting early on a passing rubric score, and
shipping the best-scoring draft if the cap is reached. The whole pipeline is scheduled per item as a durable
off-peak job through the token-fairness gate.

### User Stories
- AS a reader I WANT professional, illustrated documentation for each item — how-to always, UI and technical
  sections where relevant — SO THAT the product explains itself as it is built.
- AS the maintainer I WANT the heavy opus work tiered, bounded, and budgeted SO THAT quality is high and the
  token meter is never put at risk.

### EARS Specification
**Event-driven**
- WHEN a roadmap item completes THE SYSTEM SHALL commission its documentation on parallel sub-agents: sonnet
  collect+draft → opus adversarial review → opus final.
- WHEN drafting the document THE SYSTEM SHALL include a how-to for every item, a UI/usage section only where
  the item has a user interface, and a technical/architecture section only where the item introduces structure.
- WHEN the documentation is drafted THE SYSTEM SHALL commission each illustration through a bounded loop
  (sonnet concept → opus review → opus craft), accepting early when the design-reviewer's fitness score meets
  the threshold or the verdict is PASS.
- WHEN an item completes THE SYSTEM SHALL schedule its pipeline as a durable off-peak job with an explicit
  per-item +Xk token ceiling, gating every wave through the `tf` scheduler.
**Unwanted behaviour**
- IF the illustration loop reaches N=4 rounds without a passing score THEN THE SYSTEM SHALL ship the
  best-scoring draft and log that it capped (round count + final score) — it SHALL NOT loop unbounded.
- IF dispatching this pipeline would breach the live token-fairness window or the per-item ceiling THEN THE
  SYSTEM SHALL pause to the ledger and resume off-peak, never running it inline past the gate.
**Optional feature**
- WHERE per-job model selection (#8) is available THE SYSTEM SHALL honour any per-item model overrides for
  these sub-agents.

### Acceptance Criteria
1. Given a completed item, Then an adaptive documentation artefact exists (how-to always; UI/technical
   sections present iff relevant) that passed an opus adversarial review.
2. Given a figure, Then it either passed the rubric within 4 rounds, or the best-scoring draft was shipped
   with a logged cap note — the loop never runs unbounded.
3. Given the token window or per-item ceiling is near its limit, Then the pipeline pauses to the ledger and
   resumes off-peak, not inline.
4. Given a non-UI item, Then no UI/usage section is generated (no wasted opus pass).

### Implementation Notes
- Reuse PRESSROOM `illustrator` (A/B-until-best), `design-reviewer` (fitness score + verdict — the rubric
  gate), and `craft-study` craft-handler; for the doc text, PRESSROOM `writer` + an opus DOCUMENT-REVIEWER.
  Set the agent model tiers explicitly per stage (sonnet draft / opus review / opus final) via the same
  model-override mechanism as #8.
- **Adaptivity inputs:** "has a UI" / "introduces structure" come from the item's own roadmap fields (its
  Human Interface Test Plan presence ⇒ UI; new bounded-context/architecture note ⇒ technical section).
- **Loop guard:** N=4 max rounds, accept on `fitness ≥ threshold` or `verdict == PASS`, else best-so-far +
  cap log. Mirrors the finale (#7) "4×-reviewed stunning" bar.
- **Token governance:** each item is a `tf plan --profile doc --width W` fan-out with a per-item +Xk ceiling;
  queued as a durable off-peak job (22:00–08:00), every wave gated, pause/resume via `tf ledger`.
- Output is reused three ways: the item's docs, the issue annotations (#11), and the wiki (#13).
- Token safety: dispatch only through the `tf` scheduler; cadence is per completed item, never per commit.

### Development Plan Reference
`doc/ROADMAP_ITEM_DOC_PIPELINE_PLAN.md`

---

## [13] GitHub wiki construction (opt-in, any github origin)
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: #10, #12

**Brief Description**
If a repository has a github origin, the system asks the user whether to construct a fully professional wiki
(and/or Pages), with opus-class models writing the final drafts and information-rich illustrations from #12.
The wiki emerges and updates as the project is built.

### User Stories
- AS the maintainer of a github repo I WANT to opt into a professional, illustrated wiki SO THAT the project
  has first-class public documentation that grows with the build.

### EARS Specification
**Event-driven**
- WHEN a repo has a github origin THE SYSTEM SHALL ask the user whether to construct the professional wiki.
- WHEN the user opts in AND an item's documentation (#12) is ready THE SYSTEM SHALL publish/refresh the
  corresponding wiki page using opus-class final drafts and the reviewed illustrations.
**Unwanted behaviour**
- IF the user declines THEN THE SYSTEM SHALL not create or modify the wiki, and SHALL not ask again unless asked.

### Acceptance Criteria
1. Given a github origin, When onboarding, Then the user is offered the professional wiki (one clear yes/no).
2. Given opt-in, When an item is documented, Then its wiki page is created/updated with opus finals + #12 art.
3. Given opt-out, Then no wiki content is created.

### Implementation Notes
- Wiki via the repo's `.wiki.git` (or the Pages branch); content sourced from #12; gating reuses the #10
  origin check (github) but is opt-in for ANY github origin, not just the allowlist.

### Development Plan Reference
`doc/GITHUB_WIKI_CONSTRUCTION_PLAN.md`

---

## [14] Onboarding alert — "items will be documented this way"
> STATUS: PENDING
> ADDED: 2026-06-13
> PRIORITY: MEDIUM
> DEPENDS ON: — (atomic; CONCIERGE)

**Brief Description**
For every new project — or one newly onboarded to idea-to-production — the system alerts the user that, from
now on, roadmapper items will be documented in this way (emoji commits, issues-as-process-log on allowlisted
origins, per-item professional documentation, and the opt-in wiki).

### User Stories
- AS a user onboarding a project I WANT a clear up-front notice of the new documentation behaviour SO THAT it
  is never a surprise and I know where the docs will appear.

### EARS Specification
**Event-driven**
- WHEN a project is created or newly onboarded to idea-to-production THE SYSTEM SHALL alert the user, once,
  that roadmap items will now be documented via emoji commits, process-issues, per-item docs, and the opt-in wiki.
**Unwanted behaviour**
- IF the project has already been alerted THEN THE SYSTEM SHALL NOT repeat the alert on later sessions.

### Acceptance Criteria
1. Given a newly onboarded project, When the first session opens, Then the documentation-behaviour alert is shown once.
2. Given a project already alerted, Then the alert does not recur.

### Implementation Notes
- CONCIERGE SessionStart/welcome hook (alongside `offer-welcome.sh`); one-shot state under
  `~/.claude/hook-state/` (never written into the user's repo).

### Development Plan Reference
`doc/ONBOARDING_DOC_ALERT_PLAN.md`

---

## Principles guiding expansion

Every surface here (a) keeps mission-control self-contained (`${CLAUDE_PLUGIN_ROOT}` only, no assumption
another plugin is installed — degrade gracefully when PRESSROOM/ATELIER/SENTINEL are absent), (b) treats the
roadmap markdown + JSONL event log as the single source of truth and the UI as a view, (c) carries the
self-improvement covenant, and (d) holds the maintainer's HIGH taste bar: stunning, reviewed visuals or it
is not MVP.
