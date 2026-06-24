---
id: 91
title: "code-quality v2.0 — pipeline orchestrator (run all three per PR)"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "#88, #89, #90"
---

# [91] code-quality v2.0 — pipeline orchestrator (run all three per PR)

**Brief Description**
An orchestrator that runs the three quality agents (spec-reviewer, coverage-gate, architecture-guardian) in
parallel on every PR and synthesises their verdicts.

### User Stories
- AS a team I WANT one orchestrator to run all three quality agents in parallel on every PR SO THAT I get a
  single combined quality verdict per PR.

### EARS Specification
**Ubiquitous**
- The system SHALL run the spec-reviewer, coverage-gate, and architecture-guardian agents in parallel on
  every PR and synthesise one combined verdict.

**Event-driven**
- WHEN a PR is opened THE SYSTEM SHALL fan out the three agents concurrently and combine their results
  (max-severity wins).

### Acceptance Criteria
1. Given a PR, When the orchestrator runs, Then all three agents run in parallel and a single combined
   verdict is produced.
2. Given any agent returning a blocking verdict, When synthesised, Then the combined verdict blocks.

### Implementation Notes
- Depends on the three agents [88]/[89]/[90]; mirrors the existing fan-out-then-synthesise pattern
  (e.g. `/foundry:pr-review`).
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v2.0) under roadmap item [47].
