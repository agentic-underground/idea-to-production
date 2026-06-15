---
id: 44
title: "Taxonomy reorg toward the value-handling paradigm (map first)"
status: PENDING
priority: MEDIUM
added: 2026-06-15
depends_on: "—"
---

# [44] Taxonomy reorg toward the value-handling paradigm (map first)

**Brief Description**
Reorganise the marketplace's emergent families around the value-handling paradigm. First produce a
**taxonomy map** of the repeated patterns, then restructure as sub-items. Families observed: inspector ×9,
`/check` ×9, `/self-improve` ×8, handlers ×28 (foundry + pressroom), reviewer/critic loops, and shared canon
resources. Map first, restructure later.

### User Stories
- AS the owner I WANT the repeated families named and grouped by characteristic + action SO THAT the
  marketplace structure reflects the value-handling paradigm instead of incidental layout.
- AS a maintainer I WANT a map before any move SO THAT restructuring is deliberate and low-risk.

### EARS Specification
**Ubiquitous**
- The taxonomy map SHALL enumerate every repeated family with its members and a proposed grouping.

**Event-driven**
- WHEN the map is approved THE SYSTEM SHALL spawn sub-items for each restructure (e.g. shared `_handlers/`,
  `_critique/`, `_canon/`), each independently shippable.

**Unwanted behaviour**
- IF a proposed move would break a plugin's self-contained installability THEN THE SYSTEM SHALL flag it and
  not proceed without a path that preserves `${CLAUDE_PLUGIN_ROOT}`-only resolution.

### Acceptance Criteria
1. A taxonomy map document exists listing families (inspectors, checks, self-improve, handlers, reviewers,
   canon) with members + proposed grouping.
2. Each restructure is captured as its own sub-item with acceptance criteria.
3. No restructure violates the self-contained-plugin / canonical-copy promises.

### Implementation Notes
- Survey `plugins/*/agents`, `skills`, `commands`.
- Respect the canonical-copy promise (KAIZEN) and self-contained-plugin rule.
- Reference foundry VALUE_FLOW.md value-station/value-handler definitions.
