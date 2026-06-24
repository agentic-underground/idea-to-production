---
id: 62
title: "SENTINEL severity-policy config — sentinel.config.json verdict tuning"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [62] SENTINEL severity-policy config — sentinel.config.json verdict tuning

**Brief Description**
A `sentinel.config.json` letting a project tune the verdict rule (e.g. treat HIGH as BLOCK for regulated
products; downgrade a specific advisory with a documented justification + expiry).

### User Stories
- AS a security owner of a regulated product I WANT to make HIGH findings BLOCK SO THAT the gate matches my
  risk posture, and I WANT to downgrade a specific advisory with a justification + expiry SO THAT accepted
  risks are explicit and time-bounded.

### EARS Specification
**Ubiquitous**
- The system SHALL apply a project `sentinel.config.json` to compute the gate verdict from findings.

**Event-driven**
- WHEN the security-gate computes a verdict THE SYSTEM SHALL apply the configured severity→verdict mapping
  and any per-advisory downgrade that is in date.

**Unwanted behaviour**
- IF a per-advisory downgrade has passed its `expiry` THEN THE SYSTEM SHALL ignore the downgrade (the
  advisory returns to its default severity) and note the lapse.

### Acceptance Criteria
1. Given a config mapping HIGH→BLOCK, When a HIGH finding exists, Then the gate verdict is BLOCK.
2. Given a downgrade for advisory X with a future expiry, When X is found, Then it is downgraded; given a
   past expiry, Then it is not.

### Implementation Notes
- Define `sentinel.config.json` (severity→verdict map; per-advisory downgrades with justification + expiry).
- Apply in `/security-gate`'s verdict synthesis.
- Migrated from `plugins/sentinel/ROADMAP.md` (mid-term) under roadmap item [47].
