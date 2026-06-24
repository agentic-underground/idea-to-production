---
id: 13
title: "GitHub wiki construction (opt-in, any github origin)"
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "#10, #12"
completed: 2026-06-13 (PR #42)
---

# [13] GitHub wiki construction (opt-in, any github origin)

**Brief Description**
If a repository has a github origin, the system asks the user whether to construct a fully professional wiki
(and/or Pages), with opus-class models writing the final drafts and information-rich illustrations from #12.
The wiki emerges and updates as the project is built.

### User Stories
- AS the maintainer of a github repo I WANT to opt into a professional, illustrated wiki SO THAT the project
  has first-class public documentation that grows with the build.

### EARS Specification
**Event-driven**
- WHEN a repo has a github origin THE SYSTEM SHALL ask the user whether to construct the professional wiki.
- WHEN the user opts in AND an item's documentation (#12) is ready THE SYSTEM SHALL publish/refresh the
  corresponding wiki page using opus-class final drafts and the reviewed illustrations.
**Unwanted behaviour**
- IF the user declines THEN THE SYSTEM SHALL not create or modify the wiki, and SHALL not ask again unless asked.

### Acceptance Criteria
1. Given a github origin, When onboarding, Then the user is offered the professional wiki (one clear yes/no).
2. Given opt-in, When an item is documented, Then its wiki page is created/updated with opus finals + #12 art.
3. Given opt-out, Then no wiki content is created.

### Implementation Notes
- Wiki via the repo's `.wiki.git` (or the Pages branch); content sourced from #12; gating reuses the #10
  origin check (github) but is opt-in for ANY github origin, not just the allowlist.

### Development Plan Reference
`doc/GITHUB_WIKI_CONSTRUCTION_PLAN.md`
