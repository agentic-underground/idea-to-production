---
id: 87
title: "EPIC — code-quality v2.0 multi-agent quality pipeline"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [87] EPIC — code-quality v2.0 multi-agent quality pipeline

**Brief Description**
The v2.0 vision: a multi-agent quality pipeline — a `spec-reviewer-agent` (checks specs for testability
before implementation), a `coverage-gate-agent` (blocks merges below threshold, CI integration), an
`architecture-guardian-agent` (continuous boundary enforcement), and an orchestrator that runs all three in
parallel on every PR. This EPIC umbrellas the three agents ([88]–[90]) and the orchestrator ([91]).

### User Stories
- AS a team I WANT spec, coverage, and architecture each guarded by a dedicated agent on every PR SO THAT
  quality is enforced continuously, not as a single end-of-cycle check.

### EARS Specification
**Ubiquitous**
- The system SHALL provide three specialised quality agents and an orchestrator that runs them on every PR.

**Event-driven**
- WHEN a PR is opened THE SYSTEM SHALL run the spec / coverage / architecture agents in parallel and
  synthesise their verdicts.

### Acceptance Criteria
1. Given the children [88]–[91] complete, When a PR opens, Then all three agents run in parallel and a
   combined verdict is produced.

### Implementation Notes
- Decomposes into [88] spec-reviewer, [89] coverage-gate, [90] architecture-guardian, [91] orchestrator.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v2.0) under roadmap item [47].
