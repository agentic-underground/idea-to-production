---
id: 19
title: "Issue-raiser — `raise-feedback.sh` (gh api · dedup · autonomy)"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "#17"
---

# [19] Issue-raiser — `raise-feedback.sh` (gh api · dedup · autonomy)

**Brief Description**
The genuinely net-new primitive (there is no `gh issue create` anywhere yet): wrap
`gh api repos/<org>/<repo>/issues` (+ optional draft PR carrying the brief), deduping by a stable
title/slug search before filing, honouring autonomy (same-repo auto; sibling repo requires `--confirm`),
with `--dry-run`.

### EARS Specification
**Event-driven**
- WHEN asked to raise feedback THE SYSTEM SHALL file an issue on the resolved target repo via `gh api`.
**Unwanted behaviour**
- IF an identical issue exists (slug search) THEN it SHALL NOT file again (dedup).
- IF the target is a sibling repo AND `--confirm` is absent THEN it SHALL refuse and print the would-be issue.
- WHERE `--dry-run` is set THE SYSTEM SHALL compose the body but file nothing.

### Acceptance Criteria
1. `--dry-run` composes a correct body and files nothing; a second identical call is suppressed by dedup.
2. Same-repo files without prompt; a sibling repo refuses without `--confirm`.

### Implementation Notes
- The token-fairness `gh api` calls from this session are the proven shape; REST-only PAT. Plan §1d.

### Development Plan Reference
`doc/GEMBA_ISSUE_RAISER_PLAN.md`
