---
id: 71
title: "FRONTEND automate adversarial design-critic spawning — scored loop"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [71] FRONTEND automate adversarial design-critic spawning — scored loop

**Brief Description**
v1 documents *how* to run the design-critic (small, self-contained context) and provides its
definition-of-good. Later: automate spawning critic sub-agents on every build, route their findings (and
the Feedback-Marker signal) into a scored, tracked improvement loop — the second-way HIL optimisation
closing on itself.

### User Stories
- AS a builder I WANT the design-critic to run automatically on every build SO THAT design feedback is
  continuous and tracked, not a manual step I forget.

### EARS Specification
**Ubiquitous**
- The system SHALL be able to spawn the adversarial design-critic automatically and route its findings into
  a scored, tracked improvement loop.

**Event-driven**
- WHEN a build completes THE SYSTEM SHALL spawn critic sub-agent(s), collect their findings + Feedback-Marker
  signal, score them, and record the result in the improvement loop.

**Unwanted behaviour**
- IF a critic sub-agent cannot run THEN THE SYSTEM SHALL surface that the design lens did not run rather than
  record a clean pass.

### Acceptance Criteria
1. Given a build, When it completes, Then critic sub-agents run automatically and their scored findings are
   recorded.
2. Given a critic that fails to run, When the build finishes, Then the gap is disclosed (no false-green).

### Implementation Notes
- Build on v1's documented design-critic procedure + definition-of-good.
- Wire findings + Feedback-Marker into a scored, tracked loop (the second-way HIL).
- Migrated from `plugins/foundry/skills/frontend/resources/ROADMAP.md` (§4) under roadmap item [47].
