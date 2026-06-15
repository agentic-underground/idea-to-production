---
id: 22
title: "GEMBA trigger points — incident · reviewer-BLOCK · missing-handler"
status: PENDING
priority: MEDIUM
added: 2026-06-14
depends_on: "#20"
---

# [22] GEMBA trigger points — incident · reviewer-BLOCK · missing-handler

**Brief Description**
Wire the instinct into the conveyor: doc/skill instructions that invoke `/mission-control:gemba` when a
postmortem action item is cross-cutting (`incident`), a reviewer returns BLOCK or repeated NEEDS_REVISION
(`foundry:pr-review`/`reviewer`), or the missing-handler gate fires (#24). Backed by #21 so even un-wired
surprises prompt the reflex.

### EARS Specification
**Event-driven**
- WHEN a reviewer returns BLOCK/repeated-NEEDS_REVISION, or a postmortem item is cross-cutting, THE SYSTEM SHALL prompt `/mission-control:gemba`.

### Acceptance Criteria
1. Given a BLOCK verdict, the reviewer flow points to `/mission-control:gemba`.
2. Given a cross-cutting postmortem item, `incident` points to the reflex.

### Implementation Notes
- Touch `plugins/foundry/agents/reviewer.md` / `skills/pr-review`, `plugins/mission-control/skills/incident`. Plan §1f.

### Development Plan Reference
`doc/GEMBA_TRIGGER_POINTS_PLAN.md`
