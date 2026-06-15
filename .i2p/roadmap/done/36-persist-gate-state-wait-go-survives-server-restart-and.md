---
id: 36
title: "Persist gate state — WAIT/GO survives server restart and surfaces in roadmap view"
status: COMPLETE
priority: MEDIUM
added: 2026-06-14
depends_on: "—"
completed: 2026-06-14
---

# [36] Persist gate state — WAIT/GO survives server restart and surfaces in roadmap view

**Brief Description**
The WAIT/GO gate toggle is currently in-memory only: a server restart resets every card to GO
and the gate state is invisible to the `what's on the roadmap` command. This item does two
things: (1) persists gate state so it survives restarts, and (2) surfaces it whenever the
roadmap is queried — so PENDING items show as either `WAIT` or `GO` rather than a
undifferentiated list.

### User Stories
- AS A builder I WANT my WAIT decisions to survive a server restart SO THAT I don't have to
  re-gate items every time I restart the flow-server.
- AS A builder asking "what's on the roadmap" I WANT to see which PENDING items are gated WAIT
  vs GO SO THAT I can tell at a glance what is actively in motion and what I've paused.

### EARS Specification

**Event-driven requirements:**
- WHEN a gate is toggled via `POST /api/items/:id/gate` THE SYSTEM SHALL persist the new gate
  value to a durable store (`.flow/gates.json` alongside `events.jsonl`).
- WHEN the flow-server starts THE SYSTEM SHALL load `.flow/gates.json` and restore each item's
  gate state before serving the first request.

**Unwanted behaviour requirements:**
- IF `.flow/gates.json` is absent or malformed THE SYSTEM SHALL default all gates to `go` and
  continue without error (idempotent cold-start).
- IF an item in `.flow/gates.json` no longer exists in the roadmap THE SYSTEM SHALL silently
  discard that entry.

**State-driven requirements:**
- WHILE the flow-server is running, `GET /api/items` SHALL include each item's current `gate`
  field (`"go"` or `"wait"`), which is already the case — this requirement ensures it is also
  the persisted value after restart.

### Acceptance Criteria
1. Toggle a card to WAIT, restart the flow-server, reload the canvas — the card is still WAIT.
2. `GET /api/items` returns `gate: "wait"` for that card after restart.
3. With the server running, `what's on the roadmap` shows PENDING items grouped by gate:
   **WAIT** items listed separately from **GO** items.
4. A missing or corrupt `.flow/gates.json` does not prevent the server from starting; all
   gates default to `go`.
5. An item removed from the roadmap whose gate entry lingers in `.flow/gates.json` is silently
   ignored on load.

### Implementation Notes
- **Persistence:** on every `set_gate` call in `store.rs`, serialise the full `id → gate` map
  to `.flow/gates.json` (atomic write via temp-file rename). Load it in `Store::new` /
  `ingest_roadmap` before the store is exposed to the API.
- **Roadmap view:** when the `what's on the roadmap` query runs (MCP `list_items` or the agent
  querying `GET /api/items`), group PENDING items into two sub-lists: **WAIT** (gate=wait) and
  **GO** (gate=go, the default).
- **File location:** `.flow/gates.json` in the project root (same directory as `events.jsonl`);
  created on first gate write, absent on a fresh project.
- Keep the Rust suite at 100% coverage; add a unit test for the cold-start / corrupt-file paths.

### Development Plan Reference
`docs/internal/FLOW_GATE_PERSIST_PLAN.md`
