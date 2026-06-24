---
id: 30
title: "REDO badge + required-comment modal (backward moves)"
status: COMPLETE
priority: MEDIUM
added: 2026-06-14
depends_on: "#29"
completed: 2026-06-14
---

# [30] REDO badge + required-comment modal (backward moves)

**Brief Description**
When a card is dragged DONE→DO or DONE→DOING, a blurred modal pops up requiring a "why" comment before the
move commits; the comment is stored on the item (reusing #4 annotate), the card stays where dropped, and a
coral **REDO** badge appears top-right (removed if moved elsewhere).

### Acceptance Criteria
1. Given a DONE→DO/DOING drag, the modal blocks the move until a non-empty comment is entered.
2. Given a submitted comment, it is stored on the item and the card shows a REDO badge and stays put.

### Implementation Notes
- Modal as an HTML overlay; comment via `POST /api/items/:id/annotate` (#4). `--redo` coral token already in app.css. Plan §redo.

### Development Plan Reference
`doc/FLOW_REDO_MODAL_PLAN.md`
