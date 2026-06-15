---
id: 2
title: "SVG flow-canvas — cards, curved connectors, nested boards, pan/zoom/drag"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "#1"
---

# [2] SVG flow-canvas — cards, curved connectors, nested boards, pan/zoom/drag

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
