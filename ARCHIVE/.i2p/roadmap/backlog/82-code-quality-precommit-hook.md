---
id: 82
title: "code-quality v1.2 — pre-commit hook integration"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [82] code-quality v1.2 — pre-commit hook integration

**Brief Description**
A hook script that runs the quality analysis on changed files only, with a configurable threshold (fail the
commit if the score is below X) and a fast mode (lint only, no LLM call).

### User Stories
- AS a developer I WANT a pre-commit hook that quality-checks only my changed files SO THAT regressions are
  caught before commit without scanning the whole tree.

### EARS Specification
**Ubiquitous**
- The system SHALL provide a pre-commit hook that analyses changed files and can fail the commit below a
  configurable score threshold.

**Event-driven**
- WHEN the hook runs in fast mode THE SYSTEM SHALL lint only (no LLM call) for speed.

**Unwanted behaviour**
- IF the score is below the configured threshold THEN THE SYSTEM SHALL block the commit with the findings.

### Acceptance Criteria
1. Given changed files and a threshold, When committing, Then the hook analyses only those files and blocks
   below threshold.
2. Given fast mode, When the hook runs, Then it lints without an LLM call.

### Implementation Notes
- Hook script scoped to `git diff` changed files; configurable threshold; fast (lint-only) path.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v1.2) under roadmap item [47].
