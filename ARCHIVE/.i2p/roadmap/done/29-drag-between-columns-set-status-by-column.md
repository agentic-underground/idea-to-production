---
id: 29
title: "Drag-between-columns — set status by column"
status: COMPLETE
priority: MEDIUM
added: 2026-06-14
depends_on: "— (atomic; epic #27)"
completed: 2026-06-14
---

# [29] Drag-between-columns — set status by column

**Brief Description**
Drag a card from one column to another (DO↔DOING↔DONE) to change its status via the API; the status badge
recolours to the new column (the look-and-feel already keys colour off `data-status`). A target column
shows a drop-zone glow while dragging. As part of this item, the canvas also subscribes to the existing
WebSocket `StatusPosted` broadcast so that status changes driven by the FOUNDRY lifecycle (agent-side
`POST /api/items/:id/status`) appear on the board in real time without a page refresh.

### Acceptance Criteria
1. Given a card dropped in another column, its status posts to the server and the badge/colour follow.
2. Given an in-progress drag, the target column shows a drop-active glow.
3. Given the FOUNDRY lifecycle posts a status change for any item (e.g. step-9 syncing to `done`),
   the canvas updates that card's column and badge without a page reload — the WebSocket `StatusPosted`
   event is received and applied to in-memory state.
4. Given the WebSocket connection drops and reconnects, the canvas re-fetches current state
   (via `api.getItems()`) so no stale cards remain.

### Implementation Notes
- Extend the canvas pointer/drag handling (currently card-move within the canvas) to detect column drop + `POST /api/items/:id/status`. Plan §drag.
- Wire `ws.onmessage` in the canvas JS to handle `StatusPosted` events: look up the card by `item_id`,
  update `data-status`, re-colour badge, and move the card to the correct column group — the server
  already broadcasts this event on every `POST /api/items/:id/status` call (see `store.rs`).
- On reconnect, call `api.getItems()` and re-render to recover from any missed events.

### Development Plan Reference
`doc/FLOW_DRAG_COLUMNS_PLAN.md`
