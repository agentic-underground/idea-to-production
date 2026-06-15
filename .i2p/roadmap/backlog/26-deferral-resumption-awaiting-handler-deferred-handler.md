---
id: 26
title: "Deferral + resumption — awaiting-handler ↔ DEFERRED handler item"
status: PENDING
priority: MEDIUM
added: 2026-06-14
depends_on: "#24"
---

# [26] Deferral + resumption — awaiting-handler ↔ DEFERRED handler item

**Brief Description**
Reuse roadmapper DEFER/RESTORE (§11.7) + RESUME (§11.6): the original build item is marked
*awaiting-handler*, paired with the DEFERRED handler-creation item; when the handler lands (and the
marketplace updates) the original is RESTORED and re-planned with the real handler — optionally armed via a
durable `tf` registry follow-up job.

### EARS Specification
**Event-driven**
- WHEN a handler-creation item completes THE SYSTEM SHALL surface the paired awaiting-handler item for RESTORE + re-plan.
**State-driven**
- WHILE a build is awaiting-handler THE SYSTEM SHALL keep it paused and visibly paired with its DEFERRED handler item.

### Acceptance Criteria
1. Given option BOTH, the original item is awaiting-handler and paired with a DEFERRED "Create handler-<stack>" item.
2. Given the handler lands, the original is RESTORED and re-planned with the real handler.

### Implementation Notes
- Reuse roadmapper DEFER/RESTORE/RESUME + `.i2p/scheduled-jobs.json` / `tf` registry. Plan §2d.

### Development Plan Reference
`doc/HANDLER_DEFERRAL_RESUMPTION_PLAN.md`
