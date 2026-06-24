---
id: 9
title: "EPIC — Process-Documentation & Git Governance (docs emerge as we build)"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "—"
completed: 2026-06-13 (PR #42)
branch: flow-tracking-ui (carried with the flow epic; this is the value system's governance + online-docs behaviour)
---

# [9] EPIC — Process-Documentation & Git Governance (docs emerge as we build)

**Brief Description**
As value passes between phases, the system documents the *process itself* online and keeps git tidy. Commits
are emoji Conventional Commits (the existing FOUNDRY standard); when a repo's origin is in the org allowlist
(default `agentic-underground/*`) the orchestrator raises a GitHub issue per completed work item, annotates
that issue as each handler adds value (activities + value-add — "issues as process documentation"), and the
parcel's pull request references and closes those issues on merge. Separately, each completed roadmap item is
documented by a PRESSROOM pipeline (sonnet draft → opus review → opus final, plus an illustration loop) whose
output also feeds the issues and an opt-in GitHub wiki. Every new or newly-onboarded project is told, up
front, that its roadmap items will be documented this way.

### User Stories
- AS the maintainer I WANT every completed item to leave a GitHub issue annotated with what each handler did
  SO THAT the build's process is self-documenting and auditable online.
- AS the maintainer I WANT the PR to reference and close those issues on merge SO THAT git history, issues,
  and the roadmap stay in lock-step.
- AS a reader I WANT professional, illustrated documentation to emerge as the project is built SO THAT the
  product is explained without a separate documentation phase.
- AS the maintainer I WANT to be told, when a project onboards, that this is how it will now work SO THAT the
  behaviour is never a surprise.

### EARS Specification (epic-level; per-child EARS live in #10–#14)
**Ubiquitous**
- The system SHALL write every commit as an emoji Conventional Commit per the FOUNDRY commit standard.
**Event-driven**
- WHEN a work item completes AND the repo origin is in the configured org allowlist THE SYSTEM SHALL raise a
  GitHub issue for it; WHEN a parcel's PR merges THE SYSTEM SHALL close the referenced issues.
- WHEN a roadmap item completes THE SYSTEM SHALL commission its documentation + illustrations (per #12),
  scheduled under the token-fairness gate.
- WHEN a project is created or newly onboarded to idea-to-production THE SYSTEM SHALL alert the user that
  roadmap items will be documented this way.
**Unwanted behaviour**
- IF the origin is not in the allowlist THEN THE SYSTEM SHALL NOT raise issues (commits + local docs only).
- IF running the opus documentation pipeline per commit would breach the token-fairness window THEN THE
  SYSTEM SHALL run it per completed item, off-peak, never per commit.

### Acceptance Criteria
1. Given an allowlisted origin, When an item completes, Then a GitHub issue exists for it, annotated with the
   handlers' value-add, and the parcel PR closes it on merge.
2. Given any completed item, Then professional documentation + at least one reviewed illustration exist for it.
3. Given a github origin, When the project onboards, Then the user is offered the professional wiki and told
   how items will be documented.

### Implementation Notes
- **Cross-plugin** — FOUNDRY (governance/orchestration), PRESSROOM (doc + art pipeline), CONCIERGE (alert),
  MISSION-CONTROL flow UI (issue/annotation surfacing). Each degrades gracefully when a partner is absent.
- **Reuse, don't reinvent:** `foundry/knowledge/protocols/commit-message.md` (emoji conv-commits) and
  `merge-governance.md` (pr-approval, one-branch-one-PR) already exist — extend them with issue linkage.
- **Token safety is load-bearing:** the opus doc + illustration pipeline is expensive and recurring; it MUST
  be scheduled through the `tf` token-fairness gate, per completed item, off-peak — never per commit.

### Development Plan Reference
`docs/internal/PROCESS_DOC_GIT_GOVERNANCE_PLAN.md` (master epic plan; each child gets its own `doc/<TITLE>_PLAN.md`).
