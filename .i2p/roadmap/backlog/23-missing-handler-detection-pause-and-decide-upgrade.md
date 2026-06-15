---
id: 23
title: "Missing-handler detection — pause-and-decide upgrade"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "— (PR-B; consumes PR-A once merged)"
---

# [23] Missing-handler detection — pause-and-decide upgrade

**Brief Description**
Upgrade detection from silent-degrade to pause: `builder-lead.md` Phase 4.5 roster cross-check **PAUSES** on a
missing VALUE_HANDLER (instead of routing to the nearest one); `builder/SKILL.md` §8/§14 updated; and an
ideator stack-fit check (`challenge-protocol.md` + the IDEA-brief LANGUAGE/STACK field) catches the gap at
ideation time too.

### EARS Specification
**Event-driven**
- WHEN a required value-handler is absent from the pool THE SYSTEM SHALL pause (not silently degrade).
- WHEN an IDEA brief names a stack with no handler THE SYSTEM SHALL flag the gap at ideation.

### Acceptance Criteria
1. Given a synthetic item with an unknown stack, `builder-lead` stops (does not route to the nearest handler).
2. Given an IDEA brief with an unsupported stack, the stack-fit challenge flags it.

### Implementation Notes
- `plugins/foundry/agents/builder-lead.md` (Phase 4.5), `skills/builder/SKILL.md`, `plugins/ideator/knowledge/ideation/challenge-protocol.md`. Plan §2a.

### Development Plan Reference
`doc/MISSING_HANDLER_DETECTION_PLAN.md`
