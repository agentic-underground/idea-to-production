---
id: 59
title: "SENTINEL license-audit skill — SPDX policy + copyleft conflicts"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [59] SENTINEL license-audit skill — SPDX policy + copyleft conflicts

**Brief Description**
Scan dependency licenses for compatibility and copyleft conflicts (e.g. GPL in a permissively-licensed
product). Map each dependency's SPDX license against a configurable policy; flag conflicts and
unknown/missing licenses. Pairs naturally with `dependency-audit` (same manifests, different question).

### User Stories
- AS a maintainer shipping a permissively-licensed product I WANT to know if a dependency's licence
  conflicts with my policy SO THAT I don't unknowingly inherit copyleft obligations.

### EARS Specification
**Ubiquitous**
- The system SHALL resolve each dependency's SPDX licence and evaluate it against a configurable policy.

**Event-driven**
- WHEN `/license-audit` runs THE SYSTEM SHALL report each dependency's licence, flag policy conflicts (e.g.
  copyleft in a permissive product), and flag unknown/missing licences.

**Unwanted behaviour**
- IF a dependency's licence cannot be determined THEN THE SYSTEM SHALL flag it as unknown (a finding),
  never assume it is compatible.

### Acceptance Criteria
1. Given a dependency graph and a policy, When `/license-audit` runs, Then every conflicting and every
   unknown-licence dependency is reported with its SPDX id.
2. Given a clean graph, When run, Then the audit passes with each licence listed.

### Implementation Notes
- New skill `plugins/sentinel/skills/license-audit/`; reuse `dependency-audit`'s ecosystem/manifest detection.
- Configurable policy (allowed/denied SPDX ids); SPDX resolution per ecosystem.
- Migrated from `plugins/sentinel/ROADMAP.md` (near-term) under roadmap item [47].
