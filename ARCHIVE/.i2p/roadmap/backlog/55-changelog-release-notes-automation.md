---
id: 55
title: "PRESSROOM changelog & release-notes automation"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [55] PRESSROOM changelog & release-notes automation

**Brief Description**
Generate release notes directly from conventional commits between two refs, then let the writer polish them
— a `/publish release-notes vX..vY` flow.

### User Stories
- AS a maintainer I WANT release notes generated from the commits between two tags SO THAT I don't
  hand-assemble them, and AS an editor I WANT the writer to polish the draft SO THAT they read well.

### EARS Specification
**Ubiquitous**
- The system SHALL generate release notes from the conventional-commit history between two git refs and
  pass the draft through the writer for polish.

**Event-driven**
- WHEN `/publish release-notes vX..vY` runs THE SYSTEM SHALL collect commits in that range, group them by
  conventional-commit type (feat/fix/docs/…), and emit a polished, human-readable changelog.

**Unwanted behaviour**
- IF the range contains non-conventional commit subjects THEN THE SYSTEM SHALL still include them under an
  "other" group rather than dropping them.

### Acceptance Criteria
1. Given two refs, When the flow runs, Then a changelog grouped by commit type is produced for exactly the
   commits in that range.
2. Given the generated draft, When the writer polishes it, Then the output is readable prose, not a raw
   commit dump.

### Implementation Notes
- Reuse the conventional-commit parsing already used by the flow-server's git-log synthesis where helpful.
- Wire `release-notes` as a `/pressroom:publish` mode taking a `vX..vY` range.
- Migrated from `plugins/pressroom/ROADMAP.md` (mid-term) under roadmap item [47].
