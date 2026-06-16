---
id: 63
title: "SENTINEL CI integration recipes — drop-in gate snippets"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [63] SENTINEL CI integration recipes — drop-in gate snippets

**Brief Description**
Drop-in GitHub Actions / GitLab CI snippets that run `/security-gate` and fail the build on BLOCK, post the
report as a PR comment, and upload the SBOM as an artefact.

### User Stories
- AS a team I WANT a copy-paste CI snippet that runs the security gate and fails on BLOCK SO THAT security
  is enforced on every PR without me wiring it from scratch.

### EARS Specification
**Ubiquitous**
- The system SHALL provide drop-in CI recipes (GitHub Actions and GitLab CI) that run the security gate and
  enforce its verdict.

**Event-driven**
- WHEN the gate returns BLOCK in CI THE SYSTEM SHALL fail the job; WHEN it runs on a PR THE SYSTEM SHALL post
  the report as a comment and upload the SBOM as an artefact.

**Unwanted behaviour**
- IF the gate cannot run (missing tool) THEN the recipe SHALL fail loudly with the missing prerequisite, not
  pass vacuously.

### Acceptance Criteria
1. Given the GitHub Actions recipe, When a BLOCK verdict occurs, Then the workflow fails and the report is
   posted as a PR comment.
2. Given a passing run, When complete, Then the SBOM artefact is uploaded.

### Implementation Notes
- Ship `recipes/` snippets (GitHub Actions + GitLab CI); pin actions; least-privilege permissions.
- Depends conceptually on [60] (SBOM) for the artefact-upload step.
- Migrated from `plugins/sentinel/ROADMAP.md` (mid-term) under roadmap item [47].
