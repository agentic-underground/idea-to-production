---
id: 89
title: "code-quality v2.0 — coverage-gate-agent (block merges below threshold)"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "#87"
---

# [89] code-quality v2.0 — coverage-gate-agent (block merges below threshold)

**Brief Description**
A `coverage-gate-agent` that blocks merges below a coverage threshold, integrated into CI.

### User Stories
- AS a maintainer I WANT merges blocked when coverage falls below threshold SO THAT the coverage floor is
  enforced automatically in CI.

### EARS Specification
**Ubiquitous**
- The system SHALL evaluate coverage against a configured threshold in CI and block a merge below it.

**Event-driven**
- WHEN coverage on a PR is below the threshold THE SYSTEM SHALL fail the gate and report the gap.

### Acceptance Criteria
1. Given coverage below threshold, When the gate runs in CI, Then the merge is blocked with the shortfall.
2. Given coverage at/above threshold, When the gate runs, Then it passes.

### Implementation Notes
- Part of the v2.0 multi-agent pipeline [87]; CI-integrated; configurable threshold.
- Complements the coverage-loop discipline (100% is the floor that results, not the target).
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v2.0) under roadmap item [47].
