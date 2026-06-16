---
id: 84
title: "code-quality v1.4 — PR / diff mode"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [84] code-quality v1.4 — PR / diff mode

**Brief Description**
`/code-quality --diff HEAD~1` analyses only changed lines; output formatted as GitHub PR review comments;
integration with the `gh pr review` command.

### User Stories
- AS a reviewer I WANT code-quality to analyse only the diff and post its findings as PR review comments SO
  THAT feedback lands inline on the changed lines.

### EARS Specification
**Ubiquitous**
- The system SHALL support analysing only the lines changed since a ref and emitting findings as GitHub PR
  review comments.

**Event-driven**
- WHEN `/code-quality --diff <ref>` runs THE SYSTEM SHALL restrict analysis to the changed lines and format
  output for `gh pr review`.

**Unwanted behaviour**
- IF a finding's context spans unchanged lines THEN THE SYSTEM SHALL note that diff-mode is line-scoped (not
  a full-file review).

### Acceptance Criteria
1. Given a diff, When `--diff HEAD~1` runs, Then only changed lines are analysed.
2. Given the findings, When posted, Then they are valid `gh pr review` comments on the right lines.

### Implementation Notes
- Map findings to changed-line ranges; format for `gh pr review`.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v1.4) under roadmap item [47].
