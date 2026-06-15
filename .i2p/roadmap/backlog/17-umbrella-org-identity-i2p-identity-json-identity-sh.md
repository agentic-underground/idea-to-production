---
id: 17
title: "Umbrella-org identity — `.i2p/identity.json` + `identity.sh`"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "— (atomic; PR-A)"
---

# [17] Umbrella-org identity — `.i2p/identity.json` + `identity.sh`

**Brief Description**
A schema-versioned `.i2p/identity.json` (with a committed `.example`) naming the github org, this
marketplace repo, and sibling marketplaces (e.g. token-fairness). One field (`github_org`) re-targets the
whole marketplace when the umbrella org is created. A `gemba/scripts/identity.sh` resolves a target-repo +
SELF/GEMBA verdict from a "where does this belong" hint.

### EARS Specification
**Ubiquitous**
- The system SHALL resolve, for any learning, a target repo and a SELF_IMPROVEMENT-vs-GEMBA verdict from `.i2p/identity.json`.
**Event-driven**
- WHEN `.i2p/identity.json` is absent THE SYSTEM SHALL seed it from `git remote -v` + `marketplace.json.owner`.
**Unwanted behaviour**
- IF `github_org` changes THEN every target SHALL re-point off that one field (verified via `--dry-run`).

### Acceptance Criteria
1. Given this repo, `identity.sh` returns `self`; given a token-fairness-class hint, it returns `gemba` + the correct sibling repo.
2. Given no identity file, it is seeded from git remote + marketplace owner.
3. Given `github_org` flipped, `--dry-run` shows every target re-pointed.

### Implementation Notes
- Reuse the `git remote -v` resolution from `plugins/foundry/skills/pr-review/scripts/gather-diff.sh`.
- See `docs/internal/KAIZEN_UPLIFT_PLAN.md` §1a.

### Development Plan Reference
`doc/GEMBA_IDENTITY_PLAN.md`
