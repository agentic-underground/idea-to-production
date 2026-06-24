---
id: 100
title: "Lifecycle phase model v2 — canonical doc (DELIVER + B/A/S loop)"
status: COMPLETE
priority: HIGH
added: 2026-06-17
completed: 2026-06-18
depends_on: "—"
---

# [100] Lifecycle phase model v2 — canonical doc (DELIVER + B/A/S loop)

**Brief Description**
Rewrite the canonical phase model in `plugins/i2p/knowledge/product-lifecycle.md` to define the
v2 lifecycle: insert a new **DELIVER** phase (roadmap intake → EARS/feature authoring →
decomposition into atomic items and dependency-chains, owned by the new flow plugin +
`foundry:roadmapper`) between IDEATE and DESIGN, and model **BUILD → ASSURE → SECURE as a loop**
that re-enters BUILD on an ASSURE/SECURE failure and advances only when all three pass. The new
sequence is **DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE↻**
(today's model is 8 phases: DISCOVER, IDEATE, DESIGN, BUILD, ASSURE, SECURE, PUBLISH, OPERATE↻).
This document is the **single source of truth** every other item in Stream 2 (#101–#104) implements
against, so it lands first and unblocks the rest.

### User Stories
- AS a builder I WANT the canonical doc to name a DELIVER phase SO THAT roadmap intake and
  EARS/feature decomposition has a phase of its own with a clear owner, rather than being implicit
  inside IDEATE or BUILD.
- AS a builder I WANT BUILD/ASSURE/SECURE described as a loop SO THAT the lifecycle reflects what
  actually happens — a failed quality or security gate sends work back to BUILD, not forward.
- AS a maintainer of `lifecycle.sh`, the statusline, and the i2p surfaces I WANT one authoritative
  description of the v2 model SO THAT every surface that renders the lifecycle inherits the same
  phases, owners, and loop semantics from one place.

### EARS Specification
**Ubiquitous**
- The lifecycle SHALL be defined as **nine working phases** forming a cycle:
  DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ▸ ASSURE ▸ SECURE ▸ PUBLISH ▸ OPERATE↻.
- The doc SHALL define **DELIVER** with: its value added (roadmap intake → EARS/feature authoring →
  decomposition into atomic, dependency-ordered items), its owner (the new **flow** plugin +
  `foundry:roadmapper`), its entry signal, and its exit signal.
- The doc SHALL define the **BUILD ⇄ ASSURE ⇄ SECURE loop**: the three phases form a loop whose
  **exit signal is "all three satisfied"** (BUILD reaches SHIP, ASSURE's quality review PASSES, and
  SECURE's security-gate PASSES), and on any ASSURE or SECURE failure the lifecycle **re-enters
  BUILD**.

**Event-driven**
- WHEN IDEATE completes (a handoff-contract-complete IDEA package) THE lifecycle SHALL enter DELIVER.
- WHEN DELIVER completes (a decomposed, dependency-ordered set of build-ready items) THE lifecycle
  SHALL enter DESIGN.
- WHEN ASSURE or SECURE fails THE lifecycle SHALL re-enter BUILD (the loop's back-edge), not advance.
- WHEN BUILD, ASSURE, and SECURE are all satisfied THE lifecycle SHALL exit the loop to PUBLISH.

**Unwanted behaviour**
- IF the doc still describes the old 8-phase linear B→A→S sequence anywhere (prose, table, entry/exit
  list, or the "(n/8)" statusline note) THEN that is a defect — every reference SHALL be updated to
  the 9-phase model and the loop, with no stale "(n/8)" left behind.
- IF DELIVER's owner or the loop's exit signal is left implicit THEN that is a defect — both SHALL be
  stated explicitly so #101–#104 can implement against them without guessing.

### Acceptance Criteria
1. Given the rewritten `product-lifecycle.md`, When read, Then the phase table lists nine phases in
   the order DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ▸ ASSURE ▸ SECURE ▸ PUBLISH ▸ OPERATE↻, each
   with an owner and canon lineage.
2. Given the DELIVER section, When read, Then it names the new flow plugin + `foundry:roadmapper` as
   owner and gives its entry signal (IDEA package complete) and exit signal (decomposed
   dependency-ordered items).
3. Given the loop section, When read, Then it states that BUILD/ASSURE/SECURE form a loop, that an
   ASSURE/SECURE failure re-enters BUILD, and that the loop exits to PUBLISH only when all three are
   satisfied.
4. Given the entry/exit-signals list and the "How the marketplace aligns" section, When read, Then
   they describe the loop and the DELIVER transitions, and no "(n/8)" or 8-phase wording remains.

### Implementation Notes
- Edit `plugins/i2p/knowledge/product-lifecycle.md` only (this item is the doc; #101 reworks the
  state machine, #102 the statusline, #103 the i2p surfaces, #104 the art).
- Today's model: the phase table (lines ~52–62) lists 8 phases; the entry/exit-signals section
  (lines ~98–110) is a linear chain; line ~119 mentions the statusline showing `(n/8)`. All three
  regions need updating, plus the opening paragraph and the lifecycle-gif alt text (~line 8).
- DELIVER slots **between IDEATE and DESIGN**: IDEATE produces the IDEA package; DELIVER turns it into
  a roadmap of atomic, EARS-specified, dependency-ordered items; DESIGN then makes the surfaces usable.
- Keep the existing "two kinds of element" framing — DELIVER is a **phase** (linear value-creation
  spine, one owner), while ASSURE/SECURE remain the quality/security cross-cutting concerns now
  certified inside the loop.
- The covenant at the foot of the doc already says "fix it here once" — this rewrite is exactly that:
  every downstream surface (#101–#104) inherits the corrected model from this file.
