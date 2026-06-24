---
id: 103
title: "i2p lifecycle surfaces to v2 — i2p-flow/help/lifecycle"
status: COMPLETE
completed: 2026-06-18
priority: MEDIUM
added: 2026-06-17
depends_on: "#100"
---

# [103] i2p lifecycle surfaces to v2 — i2p-flow/help/lifecycle

**Brief Description**
Update the user-facing i2p lifecycle surfaces — the `i2p-flow`, `i2p-help`, and `i2p-lifecycle`
skills and their commands — to the v2 model from #100: render the value flow with the new **DELIVER**
stage, show **BUILD ⇄ ASSURE ⇄ SECURE as a loop**, and name DELIVER's owner (the new flow plugin +
`foundry:roadmapper`). Today these surfaces describe the eight-phase linear flow
`DISCOVER ▸ IDEATE ▸ DESIGN ▸ BUILD ▸ ASSURE ▸ SECURE ▸ PUBLISH ▸ OPERATE ↻` in their skill text,
command descriptions, and Mermaid/markdown renderings.

### User Stories
- AS a user running `/i2p-flow` I WANT to see DELIVER placed between IDEATE and DESIGN and the B/A/S
  loop drawn as a loop SO THAT the rendered pipeline matches the v2 lifecycle.
- AS a user running `/i2p-help` I WANT the value-flow grouping to include DELIVER (and its owner) SO
  THAT I can discover the roadmap-intake/decomposition powers and the next command to run there.
- AS a user running `/i2p-lifecycle` I WANT the phase model it explains and reports to be the
  nine-phase v2 model with the loop SO THAT what it says matches the state file and statusline.

### EARS Specification
**Ubiquitous**
- The `i2p-flow`, `i2p-help`, and `i2p-lifecycle` surfaces SHALL describe the nine-phase v2 flow
  DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE↻.
- Each surface SHALL place **DELIVER** between IDEATE and DESIGN and name its owner (the new flow
  plugin + `foundry:roadmapper`).
- `i2p-flow`'s rendering (Mermaid where available, else markdown) SHALL depict the BUILD/ASSURE/SECURE
  segment as a **loop**, not a straight line.

**Event-driven**
- WHEN `/i2p-flow` traces an ordered path to PRODUCTION THE path SHALL route through DELIVER and SHALL
  show the loop back-edge (ASSURE/SECURE fail → BUILD).
- WHEN `/i2p-help` groups installed plugins by stage THE DELIVER stage SHALL appear with its headline
  command and next-step pointer (marked dark if its owner is not installed).

**Unwanted behaviour**
- IF any surface still hard-codes the eight-phase linear order in its description, skill body, command
  front-matter, or rendered diagram THEN that is a defect — every occurrence SHALL be updated to v2.
- IF DELIVER's owner plugin is absent THEN the surfaces SHALL still name the stage and say what
  installing the owner unlocks (graceful degradation, a gap named not skipped).

### Acceptance Criteria
1. Given `/i2p-flow`, When rendered, Then DELIVER appears between IDEATE and DESIGN and the
   BUILD/ASSURE/SECURE segment is drawn as a loop in both the Mermaid and markdown fallbacks.
2. Given `/i2p-help`, When rendered, Then the value-flow grouping includes a DELIVER stage with its
   owner and next command, and no eight-phase wording remains.
3. Given `/i2p-lifecycle`, When it explains/reports the model, Then it describes the nine v2 phases
   and the loop, consistent with `product-lifecycle.md`.
4. Given a grep of the three skills + their commands, When searched, Then the old eight-phase string
   no longer appears as the canonical flow.

### Implementation Notes
- Implements the user-facing rendering of the model defined in #100 — read it for DELIVER's
  placement/owner and the loop's exit signal; do not restate the model, point at the canonical doc.
- Surfaces to update: the `i2p:flow`, `i2p:help`, `i2p:lifecycle` skills under
  `plugins/i2p/skills/` and their command files under `plugins/i2p/commands/` (the
  DISCOVER▸…▸OPERATE flow string appears in the skill descriptions and bodies, and in the Mermaid the
  flow skill emits).
- `i2p-lifecycle` explains the model from `knowledge/product-lifecycle.md` and reads/writes via
  `scripts/lifecycle.sh`; once #101 lands its `done`/`fail`/`advance` verbs and loop fields, keep the
  surface's wording aligned with them, but this item can land on #100 alone for the descriptive text.
- These skills are thin (they describe/compose, they don't re-implement) — keep them thin; the loop
  semantics live in #100/#101, the surfaces just render them.
