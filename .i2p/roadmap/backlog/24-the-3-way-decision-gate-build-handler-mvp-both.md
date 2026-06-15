---
id: 24
title: "The 3-way decision gate — BUILD-handler · MVP · BOTH"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "#23, #20"
---

# [24] The 3-way decision gate — BUILD-handler · MVP · BOTH

**Brief Description**
On a missing handler, surface the roadmapper GO/DISCUSS/DEFER-idiom 3-way gate: (1) BUILD HANDLER FIRST
(author `handler-<stack>` via the research→synthesis→build→review pipeline, then resume); (2) MVP WITH
EXISTING (nearest handler + record DEGRADED_CAPABILITIES, disclose in FOUNDRY_PLAN.md); (3) BOTH (MVP now +
`/mission-control:gemba` raises the new-handler feedback + a DEFERRED "Create handler-<stack>" item + mark the
original awaiting-handler).

### EARS Specification
**Event-driven**
- WHEN the missing-handler pause fires THE SYSTEM SHALL present the 3-way gate and act on the chosen path.
**Unwanted behaviour**
- IF option MVP is chosen THEN the system SHALL emit DEGRADED_CAPABILITIES and disclose it in FOUNDRY_PLAN.md.

### Acceptance Criteria
1. Given option BOTH, the system produces an MVP plan + a filed handler issue + a DEFERRED "Create handler-<stack>" item + an awaiting-handler mark on the original.
2. Given option BUILD, it authors `handler-<stack>` via the proven pipeline, then resumes the original build.

### Implementation Notes
- Reuse `docs/internal/handler-build/` pipeline + `handler-rust-tauri` as the worked example; consumes #20. Plan §2b.

### Development Plan Reference
`doc/MISSING_CAPABILITY_GATE_PLAN.md`
