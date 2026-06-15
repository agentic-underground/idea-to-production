---
id: 11
title: "Issues as process-documentation — per-handler annotation"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "#10"
completed: 2026-06-13 (PR #42)
---

# [11] Issues as process-documentation — per-handler annotation

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
