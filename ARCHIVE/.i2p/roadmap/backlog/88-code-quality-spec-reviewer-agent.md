---
id: 88
title: "code-quality v2.0 — spec-reviewer-agent (testability before impl)"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "#87"
---

# [88] code-quality v2.0 — spec-reviewer-agent (testability before impl)

**Brief Description**
A `spec-reviewer-agent` that checks specs for testability before implementation begins.

### User Stories
- AS a builder I WANT specs checked for testability before I implement SO THAT untestable requirements are
  caught at the spec stage, not after code is written.

### EARS Specification
**Ubiquitous**
- The system SHALL review a spec for testability before implementation.

**Event-driven**
- WHEN a spec is submitted THE SYSTEM SHALL flag requirements that are ambiguous, unmeasurable, or otherwise
  untestable.

### Acceptance Criteria
1. Given a spec with an untestable requirement, When reviewed, Then that requirement is flagged with why.
2. Given a fully-testable spec, When reviewed, Then it passes.

### Implementation Notes
- Part of the v2.0 multi-agent pipeline [87]; runs pre-implementation.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v2.0) under roadmap item [47].
