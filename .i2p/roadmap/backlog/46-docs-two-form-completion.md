---
id: 46
title: "Docs two-form completion — per-plugin audience tagging + index"
status: PENDING
priority: LOW
added: 2026-06-15
depends_on: "—"
---

# [46] Docs two-form completion — per-plugin audience tagging + index

**Brief Description**
Finish the user-facing / agent-facing documentation split started by the `docs/` reorg. Tag per-plugin docs
by audience and generate an audience index, so the two-form convention extends beyond the top-level `docs/`
tree into each plugin.

### User Stories
- AS a human reader I WANT to find user-facing docs without wading through agent-facing material SO THAT
  onboarding is clean.
- AS an agent I WANT agent-facing docs clearly marked SO THAT I load the right context.

### EARS Specification
**Ubiquitous**
- Each substantial doc SHALL declare its audience (user | agent) discoverably (frontmatter or location).

**Event-driven**
- WHEN the audience index is generated THE SYSTEM SHALL list docs grouped by audience across the repo.

### Acceptance Criteria
1. Per-plugin docs carry an audience signal (frontmatter `audience:` or placement).
2. A generated index groups docs by audience.
3. The top-level `docs/guide` vs `docs/internal` split is consistent with the per-plugin tagging.

### Implementation Notes
- Builds on the `docs/guide` / `docs/internal` / `docs/historical` split already in place.
- Keep README/CLAUDE/KAIZEN/SOUL at root (canons injected; must not move).
