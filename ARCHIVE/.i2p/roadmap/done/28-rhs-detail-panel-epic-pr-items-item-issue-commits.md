---
id: 28
title: "RHS detail panel — EPIC→PR + items · ITEM→issue + commits"
status: COMPLETE
priority: MEDIUM
added: 2026-06-14
depends_on: "— (atomic; epic #27)"
completed: 2026-06-14
---

# [28] RHS detail panel — EPIC→PR + items · ITEM→issue + commits

**Brief Description**
A 35%-width right-hand panel. Click an EPIC → its PR (title·description·labels·assignees) fills the top
content panel and its nested item list shows at the bottom. Click an ITEM → its issue text fills the top
and its commit list the bottom. Both panels scroll; the description takes the larger share (inverted ratio).

### Acceptance Criteria
1. EPIC click → PR text + labels + assignee chips on top; nested items (with count) below; both scroll.
2. ITEM click → issue text on top; commit list below; large text fits and overflows scroll.

### Implementation Notes
- New HTML panel mounted by app.js beside the canvas; reads item/epic data from `/api/items` (+ events/PR fields). Plan §RHS.

### Development Plan Reference
`doc/FLOW_RHS_PANEL_PLAN.md`
