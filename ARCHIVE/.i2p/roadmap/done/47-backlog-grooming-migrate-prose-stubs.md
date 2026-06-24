---
id: 47
title: "Backlog grooming — migrate per-plugin prose-stub items into the tree"
status: COMPLETE
priority: LOW
added: 2026-06-15
completed: 2026-06-16
depends_on: "—"
---

# [47] Backlog grooming — migrate per-plugin prose-stub items into the tree

> **COMPLETE (2026-06-16).** All five source roadmaps migrated into the tree as full EARS/AC items and the
> sources deleted: PRESSROOM → [49]–[58]; SENTINEL → [59]–[67]; FRONTEND design-system → [68]–[72];
> comfyui-mcp → EPIC [73] + [74]–[80] (and the disposition [45] resolved to IMPLEMENT); code-quality
> (DEPLOYMENT.md roadmap section) → [81]–[91]. `find . -name ROADMAP.md` now returns nothing in scope; the
> flow-server ingests 92 items from the tree.

**Brief Description**
Migrate the remaining per-plugin roadmap prose-stubs (pressroom, sentinel expansion paths; foundry/frontend
deferred capabilities) into discrete `.i2p/roadmap/backlog/` items, then retire those stub files to pointers.
These were banner-marked "pending migration" during the roadmap consolidation (item-tree PR).

### User Stories
- AS the owner I WANT every roadmap item in the single `.i2p/roadmap/` tree SO THAT there is exactly one
  source of truth and no prose stubs lingering in plugins.

### EARS Specification
**Event-driven**
- WHEN grooming runs THE SYSTEM SHALL convert each prose-stub bullet into a self-contained backlog item file
  (front-matter + body) and replace the stub file with a pointer to `.i2p/roadmap/`.

**Unwanted behaviour**
- IF a stub item duplicates an existing tree item THEN THE SYSTEM SHALL merge rather than create a duplicate.

### Acceptance Criteria
1. pressroom/sentinel/frontend prose items exist as discrete `.i2p/roadmap/backlog/` files.
2. The three stub files are reduced to pointers.
3. No duplicate items; ids continue the sequence.

### Implementation Notes
- Sources: `plugins/pressroom/ROADMAP.md`, `plugins/sentinel/ROADMAP.md`,
  `plugins/foundry/skills/frontend/resources/ROADMAP.md` (currently banner-marked).
- Assign new ids continuing from the max existing id.
