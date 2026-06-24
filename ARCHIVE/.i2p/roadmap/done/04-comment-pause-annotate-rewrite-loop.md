---
id: 4
title: "Comment / pause / annotate / rewrite loop"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "#2, #3"
---

# [4] Comment / pause / annotate / rewrite loop

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
