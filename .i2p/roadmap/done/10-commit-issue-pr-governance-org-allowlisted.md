---
id: 10
title: "Commit → Issue → PR governance (org-allowlisted)"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "— (extends existing FOUNDRY commit + merge governance; needs the `gh` CLI)"
completed: 2026-06-13 (PR #42)
---

# [10] Commit → Issue → PR governance (org-allowlisted)

**Brief Description**
Standardises git flow for all idea-to-production projects: emoji Conventional Commits (existing FOUNDRY
standard); when the origin is in the configured org allowlist (default `agentic-underground/*`), raise a
GitHub issue per completed work item; the parcel's pull request references those issues and closes them on
merge. Non-allowlisted origins keep commits + local docs only.

### User Stories
- AS the orchestrator I WANT to raise an issue per completed item on allowlisted origins SO THAT each unit of
  value has a durable online record.
- AS the maintainer I WANT the PR to close the referenced issues on merge SO THAT nothing is left dangling.

### EARS Specification
**Ubiquitous**
- The system SHALL format every commit as an emoji Conventional Commit per the FOUNDRY commit standard.
- The system SHALL read the org allowlist from configuration (default `agentic-underground/*`).
**Event-driven**
- WHEN a work item completes AND `origin` matches the allowlist THE SYSTEM SHALL create a GitHub issue
  titled and linked to that item, recording its roadmap ID.
- WHEN a parcel of items is complete THE SYSTEM SHALL open one PR whose body references each item's issue with
  a closing keyword (`Closes #N`), so merging closes them.
**Unwanted behaviour**
- IF `origin` is not in the allowlist THEN THE SYSTEM SHALL skip all GitHub issue/PR automation and proceed
  with commits + local docs only.
- IF the `gh` CLI is unavailable or unauthenticated THEN THE SYSTEM SHALL report the gap and continue without
  blocking the build.

### Acceptance Criteria
1. Given an allowlisted origin and a completed item, Then a GitHub issue exists carrying its roadmap ID.
2. Given a parcel PR, When it merges, Then every referenced issue is closed automatically.
3. Given a non-allowlisted origin, Then no issues/PRs are auto-created and the build still completes.

### Implementation Notes
- `gh issue create` / `gh pr create`; allowlist match on the parsed `origin` host/owner. Extends
  `merge-governance.md` (pr-approval already opens one PR to main) and `commit-message.md` (already emoji
  conv-commits) — add the issue-linkage layer; do not duplicate either standard.
- "Parcel" = a set of completed roadmap items released together (typically the epic's PR, per #0/#7 model).

### Development Plan Reference
`doc/COMMIT_ISSUE_PR_GOVERNANCE_PLAN.md`
