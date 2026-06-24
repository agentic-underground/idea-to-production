---
id: 1
title: "Flow server — HTTP + WebSocket + MCP in one Rust binary"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "— (atomic; foundation for the epic)"
---

# [1] Flow server — HTTP + WebSocket + MCP in one Rust binary

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
`docs/internal/FLOW_SERVER_PLAN.md`
