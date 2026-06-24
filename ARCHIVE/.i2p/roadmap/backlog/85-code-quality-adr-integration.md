---
id: 85
title: "code-quality v1.5 — ADR integration"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [85] code-quality v1.5 — ADR integration

**Brief Description**
Detect existing Architecture Decision Records in `docs/decisions/`, cross-reference findings against
recorded decisions, and suggest new ADRs when a pattern inconsistency is found.

### User Stories
- AS an architect I WANT code-quality to check findings against our recorded ADRs SO THAT it doesn't flag
  deliberate decisions, and suggests an ADR when it finds an undocumented inconsistency.

### EARS Specification
**Ubiquitous**
- The system SHALL detect ADRs in `docs/decisions/` and cross-reference findings against them.

**Event-driven**
- WHEN a finding contradicts a recorded ADR THE SYSTEM SHALL note the ADR; WHEN a pattern inconsistency has
  no ADR THE SYSTEM SHALL suggest writing one.

### Acceptance Criteria
1. Given an ADR that sanctions a pattern, When that pattern is found, Then the finding references the ADR
   rather than flagging it as a defect.
2. Given an undocumented inconsistency, When found, Then a new-ADR suggestion is emitted.

### Implementation Notes
- Parse `docs/decisions/` ADRs; map findings ↔ decisions; suggest ADRs for unrecorded inconsistencies.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v1.5) under roadmap item [47].
