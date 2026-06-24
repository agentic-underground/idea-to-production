---
id: 65
title: "SENTINEL diff-scoped mode — /security-gate --since <ref>"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [65] SENTINEL diff-scoped mode — /security-gate --since <ref>

**Brief Description**
Scan only what changed since a ref (`/security-gate --since main`) for fast, incremental gating on every PR.

### User Stories
- AS a developer I WANT the gate to scan only my diff SO THAT PR feedback is fast instead of re-scanning the
  whole tree every time.

### EARS Specification
**Ubiquitous**
- The system SHALL support scanning only the files changed since a given git ref.

**Event-driven**
- WHEN `/security-gate --since <ref>` runs THE SYSTEM SHALL restrict each lens to the changed files and
  report findings only within that diff.

**Unwanted behaviour**
- IF a finding's risk extends beyond the diff (e.g. a secret added in an earlier commit on the branch) THEN
  THE SYSTEM SHALL disclose that diff-scoped mode may miss it, so it is not mistaken for a full scan.

### Acceptance Criteria
1. Given a branch with changes, When `/security-gate --since main` runs, Then only changed files are scanned
   and the run is faster than a full scan.
2. Given diff-scoped mode, When it completes, Then the output states it was diff-scoped (not a full audit).

### Implementation Notes
- Compute the changed-file set via `git diff --name-only <ref>`; pass it to each lens.
- Clearly label diff-scoped results as PARTIAL coverage.
- Migrated from `plugins/sentinel/ROADMAP.md` (longer-term) under roadmap item [47].
