---
id: 27
title: "EPIC — Flow board kanban uplift (RHS detail · drag · REDO · commit-graph)"
status: COMPLETE
priority: MEDIUM
added: 2026-06-14
depends_on: "—"
completed: 2026-06-14
---

# [27] EPIC — Flow board kanban uplift (RHS detail · drag · REDO · commit-graph)

> Numbering note: reserves #27+ after the KAIZEN epic (#16–#26, PR #54); merge this PR **after** #54.

**Brief Description**
The structural features from the claude.ai/design "job items work board" handoff (the look-and-feel was
already applied to the canvas). The board becomes a fuller kanban: a RHS detail panel that shows an EPIC's
PR text + nested items and an ITEM's issue text + commit-graph; drag a card between DO/DOING/DONE to change
its status; a coral REDO badge + required-comment modal on backward moves. Source design:
[`docs/guide/design/job-items-work-board/`](../../docs/guide/design/job-items-work-board/README.md).

### User Stories
- AS a builder I WANT to click an EPIC/ITEM and read its PR/issue text + commits in a side panel SO THAT I
  can review the full context without leaving the board.
- AS a builder I WANT to drag a card between columns to set its status SO THAT steering flow is direct and tactile.
- AS a builder I WANT a backward move (DONE→DO/DOING) to demand a "why" comment SO THAT regressions are explained and tracked.

### Acceptance Criteria
1. Given an EPIC card, clicking it shows its PR (title·description·labels·assignees) at the top of the RHS panel and its nested items below; clicking an ITEM shows its issue text + a clickable commit-graph.
2. Given a card dragged DO↔DOING↔DONE, its status (and badge) follows the column.
3. Given a DONE→DO/DOING drag, a modal requires a comment; the card stays where dropped and carries a coral REDO badge; the comment is stored on the item.

### Implementation Notes
- Surfaces existing data: #5 epic/item structure, #10 PR linkage, #11 issue annotations, the commit log.
- RHS panel + modal are HTML overlays beside the SVG canvas; drag reuses the canvas pointer handling; REDO comment reuses #4 annotate. Keep the vitest suite at 100%.
- Full design intent + tokens: `docs/guide/design/job-items-work-board/chat1.md` + `project/kanban-board.html`.

### Development Plan Reference
`docs/internal/FLOW_KANBAN_UPLIFT_PLAN.md` (master); each child gets its own plan at GO.
