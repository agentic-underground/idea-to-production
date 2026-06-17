---
id: 104
title: "Regenerate lifecycle/masthead art for the v2 model"
status: PENDING
priority: LOW
added: 2026-06-17
depends_on: "#100"
---

# [104] Regenerate lifecycle/masthead art for the v2 model

**Brief Description**
Regenerate the lifecycle and masthead imagery for the v2 model from #100: update the `STAGES` arrays
in the doc image toolchain frame builders and re-render the lifecycle/masthead images, then refresh
the README masthead alt-text. The toolchain carries the eight-stage sequence as a `STAGES=(…)` bash
array in `docs/internal/image-craft-study/toolchain/src/build-lifecycle-frames.sh` (line 10) and
`build-masthead-cycle-frames.sh` (line 26), each currently
`STAGES=(DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE)`. The new sequence inserts
DELIVER and the BUILD ⇄ ASSURE ⇄ SECURE loop.

### User Stories
- AS a reader of `product-lifecycle.md` and the README I WANT the lifecycle GIF and masthead to show
  the nine v2 stages SO THAT the art matches the canonical model rather than the retired eight-stage
  one.
- AS a maintainer I WANT the regeneration driven by updating the `STAGES` arrays SO THAT the imagery
  stays reproducible from the toolchain, not hand-edited.

### EARS Specification
**Ubiquitous**
- The `STAGES` array in `build-lifecycle-frames.sh` and `build-masthead-cycle-frames.sh` SHALL encode
  the nine v2 stages (DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE).
- The regenerated lifecycle and masthead images SHALL render all nine stages and SHALL depict the
  BUILD/ASSURE/SECURE segment as a loop consistent with #100.
- The README masthead alt-text SHALL describe the nine-phase v2 cycle (including DELIVER and the
  loop), replacing the eight-phase description.

**Event-driven**
- WHEN the frame builders are run after the `STAGES` update THE rendered output SHALL include DELIVER
  between IDEATE and DESIGN.

**Unwanted behaviour**
- IF any regenerated frame or alt-text still shows eight stages or omits DELIVER/the loop THEN that is
  a defect — every regenerated artefact SHALL reflect v2.
- IF the toolchain is unavailable to re-render in this environment THEN the `STAGES` source edits and
  the alt-text update SHALL still be made, and the item SHALL note that the binary image regeneration
  is deferred (source-of-truth updated, render pending), never shipping art that contradicts the
  source.

### Acceptance Criteria
1. Given both frame builders, When inspected, Then `STAGES` is the nine-stage v2 array.
2. Given the regenerated lifecycle and masthead images, When viewed, Then they show nine stages with
   DELIVER in place and the B/A/S loop depicted.
3. Given the README, When read, Then the masthead alt-text describes the nine v2 phases and the loop.

### Implementation Notes
- Implements the visual rendering of the model from #100 — read it for the stage order, DELIVER's
  placement, and the loop depiction.
- Edit `STAGES` in `docs/internal/image-craft-study/toolchain/src/build-lifecycle-frames.sh` (line 10)
  and `docs/internal/image-craft-study/toolchain/src/build-masthead-cycle-frames.sh` (line 26); each
  derives `N=${#STAGES[@]}` and lays out positions/text from the array, so inserting DELIVER flows
  through automatically — but check the geometry (circle/track spacing) still reads well at nine
  stages and adjust label sizing if needed.
- The B/A/S loop will likely need a deliberate back-edge/loop glyph in the frame layout rather than
  just one more pip; treat the loop as a layout change, not only a stage insertion.
- After updating `STAGES`, run the builders to regenerate the lifecycle GIF (referenced at
  `docs/images/lifecycle-cycle.gif` from `product-lifecycle.md` line 8) and the masthead, then update
  the README masthead alt-text. The sibling builders `build-pipeline-frames.sh` and
  `build-foundry-conveyor-frames.sh` also carry `STAGES` — check whether they render the full
  lifecycle (and thus need the same update) or a BUILD-only conveyor (and don't); update only those
  that depict the lifecycle phase sequence.
- This is LOW priority and depends only on #100 (it tracks the canonical model, not the runtime
  state-machine/statusline work).
