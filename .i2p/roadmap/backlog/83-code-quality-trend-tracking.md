---
id: 83
title: "code-quality v1.3 — quality trend tracking + regression alerts"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [83] code-quality v1.3 — quality trend tracking + regression alerts

**Brief Description**
Write quality scores to `.claude/quality-history.json` after each run; a `/quality-trend` command shows
improvement over time; regression detection alerts when a file's score drops.

### User Stories
- AS a maintainer I WANT quality scores tracked over time SO THAT I can see trends and get alerted when a
  file regresses.

### EARS Specification
**Ubiquitous**
- The system SHALL persist each run's quality scores to `.claude/quality-history.json`.

**Event-driven**
- WHEN `/quality-trend` runs THE SYSTEM SHALL show the score trend over time; WHEN a file's score drops
  versus its history THE SYSTEM SHALL flag a regression.

### Acceptance Criteria
1. Given two runs, When the second completes, Then `quality-history.json` has both and `/quality-trend`
   shows the trend.
2. Given a file whose score dropped, When analysed, Then a regression alert is raised.

### Implementation Notes
- Append per-run scores to `.claude/quality-history.json`; `/quality-trend` reads it; per-file regression
  comparison.
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v1.3) under roadmap item [47].
