---
id: 5
title: "Roadmap history + git-log proxy synthesis"
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "— (atomic)"
---

# [5] Roadmap history + git-log proxy synthesis

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
