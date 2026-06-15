---
id: 20
title: "GEMBA reflex skill — `/mission-control:gemba` (capture · route · raise)"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "#17, #18, #19"
---

# [20] GEMBA reflex skill — `/mission-control:gemba` (capture · route · raise)

**Brief Description**
The one-step reflex skill: **capture** into `doc/learnings/<event-slug>/{incident-report,proposed-solutions}.md`
(the exact shape of `docs/internal/token-fairness-learnings/…`, the canonical template) + a ledger record; **route** via
`identity.sh` (SELF → `/X:self-improve` or auto-file here; GEMBA → draft, ask, file on the sibling); **raise**
via `raise-feedback.sh`, recording `issue_url` back to the ledger.

### EARS Specification
**Event-driven**
- WHEN invoked THE SYSTEM SHALL capture the event in the canonical learnings shape, route it by target, and raise the feedback.
**Unwanted behaviour**
- IF the target is GEMBA (cross-repo) THEN it SHALL ask before filing; SELF_IMPROVEMENT MAY auto-file (never self-merge).

### Acceptance Criteria
1. Given a seeded test gap, one real issue is filed end-to-end on this repo (the dogfood), with the ledger open→filed.
2. Given a GEMBA-target gap, the skill drafts and asks before filing on the sibling.

### Implementation Notes
- `plugins/mission-control/skills/gemba/SKILL.md`; reuses #17/#18/#19. Plan §1c. Branding: `gemba` (aligns with the GEMBA covenant principle).

### Development Plan Reference
`doc/GEMBA_REFLEX_SKILL_PLAN.md`
