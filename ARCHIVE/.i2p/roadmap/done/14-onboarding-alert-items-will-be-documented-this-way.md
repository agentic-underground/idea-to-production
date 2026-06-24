---
id: 14
title: "Onboarding alert — \"items will be documented this way\""
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "— (atomic; CONCIERGE)"
completed: 2026-06-13 (PR #42)
---

# [14] Onboarding alert — "items will be documented this way"

**Brief Description**
For every new project — or one newly onboarded to idea-to-production — the system alerts the user that, from
now on, roadmapper items will be documented in this way (emoji commits, issues-as-process-log on allowlisted
origins, per-item professional documentation, and the opt-in wiki).

### User Stories
- AS a user onboarding a project I WANT a clear up-front notice of the new documentation behaviour SO THAT it
  is never a surprise and I know where the docs will appear.

### EARS Specification
**Event-driven**
- WHEN a project is created or newly onboarded to idea-to-production THE SYSTEM SHALL alert the user, once,
  that roadmap items will now be documented via emoji commits, process-issues, per-item docs, and the opt-in wiki.
**Unwanted behaviour**
- IF the project has already been alerted THEN THE SYSTEM SHALL NOT repeat the alert on later sessions.

### Acceptance Criteria
1. Given a newly onboarded project, When the first session opens, Then the documentation-behaviour alert is shown once.
2. Given a project already alerted, Then the alert does not recur.

### Implementation Notes
- CONCIERGE SessionStart/welcome hook (alongside `offer-welcome.sh`); one-shot state under
  `~/.claude/hook-state/` (never written into the user's repo).

### Development Plan Reference
`doc/ONBOARDING_DOC_ALERT_PLAN.md`
