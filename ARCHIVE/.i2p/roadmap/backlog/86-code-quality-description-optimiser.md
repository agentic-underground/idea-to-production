---
id: 86
title: "code-quality v1.6 — self-improving description optimiser"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [86] code-quality v1.6 — self-improving description optimiser

**Brief Description**
Run the skill-creator's description optimiser on a schedule, automatically sharpening triggering accuracy
based on usage patterns.

### User Stories
- AS the marketplace owner I WANT the code-quality skill's description sharpened automatically from usage SO
  THAT its triggering accuracy improves without manual tuning.

### EARS Specification
**Ubiquitous**
- The system SHALL be able to run the description optimiser on a schedule against observed usage patterns.

**Event-driven**
- WHEN the optimiser runs THE SYSTEM SHALL propose a sharpened skill description derived from
  trigger/usage data.

**Unwanted behaviour**
- IF an optimised description would broaden/narrow triggering beyond the skill's scope THEN THE SYSTEM SHALL
  surface the change for review rather than apply it blindly.

### Acceptance Criteria
1. Given usage data, When the optimiser runs, Then a sharpened description is proposed with the rationale.
2. Given a proposed change, When it materially shifts triggering, Then it is gated for review.

### Implementation Notes
- Reuse the skill-creator's description optimiser; schedule it; feed trigger/usage signals.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v1.6) under roadmap item [47].
