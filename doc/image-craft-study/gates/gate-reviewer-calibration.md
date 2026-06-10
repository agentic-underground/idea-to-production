# Gate — Reviewer calibration ("review the reviewers") · OPEN — awaiting first calibration run

**Date:** 2026-06-10 · **Branch:** `visual-quality-overhaul` · **Scope:** prove the two design
reviewers reliably **demote entry-level / AI-slop AND catch layout bugs** (text past a border)
*before* output reaches the user — the calibration the maintainer demanded after the reviewers
passed figures with at-a-glance defects.

> **Status note (honesty).** This document **defines and arms** the gate; it does **not** claim a
> PASS. The reviewer runs below are executed during verification (Workstream A6 / VISUAL_UPGRADE_PLAN
> step 6). A PASS is recorded only after the runs land. Until then this gate is **OPEN**.

## What this proves

The maintainer skimmed the repo and caught, *at a glance*, defects the adversarial reviewers had
passed: text over lines, text past borders, crowded padding, overlap. Root cause: the reviewers
read SPECs and generator bash, never the **rendered pixels**. Two fixes were made upstream — the
**RENDER-FIRST protocol** (render to pixels and run a layout-defect checklist *before* reading any
source) and the **taste caps** (AI-slop / entry-level cap + photorealism trap, which hold
Composition & art-direction ≤ 3 for clean-but-soulless work). This gate is the **proof those fixes
bite**: a repeatable test that a reviewer which has regressed — passing slop, or missing a planted
overflow — is caught here and re-tuned *before* the next production cycle, not by the maintainer's
eye after ship.

The reviewers under test (the exact files):

- `plugins/pressroom/skills/design-reviewer/agents/image-aesthetic-reviewer.md`
- `plugins/atelier/agents/ui-design-reviewer.md`

Each is run with its companion canon (`image-aesthetic-canon.md` ·
`plugins/atelier/knowledge/canon/art-direction.md`). Both already carry the RENDER-FIRST first step
and the two taste caps; this gate verifies they *fire* on graded inputs and planted defects.

---

## Test 1 — Grade-ranking (does the reviewer rank craft correctly?)

Feed the reviewer **one figure per grade** and require it to rank all four **worst → best**. The
verdict bands the reviewers already emit (`broken/NEEDS_REVISION` · `competent-but-generated` ·
`strong` · award-tier) map one-to-one onto the four grades, so "ranks correctly" means the emitted
band for each figure matches its intended grade **and** the overall scores are monotonic across the
four.

| Grade | Test figure | Source / construction |
|---|---|---|
| **Broken** | a figure carrying a deliberate **layout defect** (text crossing the SVG border) | construct from any generator under `toolchain/src/build-*-frames.sh`: nudge one `<text>` `x` past the frame bound (or shrink the frame), rasterise one frame to PNG. This is the SAME artifact Test 2(b) feeds — build it once. |
| **Competent-but-generated** | a **clean-but-flat** figure (single solid ground, no blend/depth, no focal motivation) | `toolchain/out/flat-masthead.png`, rendered from `toolchain/src/flat-masthead.svg` (the flat masthead from Gate 09). Clean and legible but flat — the AI-slop / richness trap target. |
| **Strong** | the proven blended masthead | `toolchain/proof/masthead-blend.jpg` — the SVG↔raster blend (crisp vector wordmark over a generative raster atmosphere), scored **89 / strong** at Gate 08–09. |
| **Award-tier** | the art-directed contrast anchor | the **i2p-premium-test** regeneration scored **88 / strong** at [Gate 06](gate-06-calibration.md) (real focal hierarchy, motivated light, disciplined teal-vs-gold script). If a higher-craft exemplar exists in the corpus at run time, prefer it; otherwise this is the top anchor — what matters is that it ranks **above** the strong/blend figure on Composition & art-direction. |

> The `richness-calibration-AB.jpg` proof (`toolchain/proof/richness-calibration-AB.jpg`, the A-over-B
> blend-vs-flat pair from Gate 09) is the ready-made **strong-vs-flat** contrast; feed it as a
> cross-check that the reviewer keeps A above B.

**PASS criterion (Test 1):** the reviewer ranks all four figures correctly, worst → best —
broken (NEEDS_REVISION) < competent-but-generated < strong < award-tier — with the overalls
**strictly monotonic** and the broken figure landing as a layout defect, NOT merely a low aesthetic
score. **Any inversion (e.g. the flat figure ranked above the strong blend, or the broken figure
passed) → FAIL.**

---

## Test 2 — Planted-defect (does the reviewer catch what the maintainer caught?)

Two adversarial inputs, fed one at a time, each with a hard required behaviour:

**(a) Clean-but-flat figure** — `toolchain/out/flat-masthead.png` (the same flat figure as Test 1).
- **PASS only if** the reviewer **demotes it on Composition & art-direction AND/OR Medium-richness**
  (the "flat single-layer where a blend/depth would serve = richness 3" rule), lands it as
  **competent-but-generated** (NOT strong / award-tier), **AND names the specific lift it needs**
  (e.g. *"composite the crisp vector over a generative raster atmosphere behind a working scrim"* —
  a concrete fix, not "make it better"). A clean+legible figure that scores **strong or above** → FAIL.

**(b) Text-past-border overflow** — the broken figure from Test 1 (one `<text>` deliberately pushed
past the SVG bound, rasterised to PNG). This **directly exercises the new RENDER-FIRST layout
checklist**.
- **PASS only if** the reviewer, working from the **rendered pixels** (the checklist item "text
  clipped/cut at the SVG edge, or crossing a border/box it belongs inside"), **flags the overflow as
  a layout defect and returns `NEEDS_REVISION`**, citing the specific frame. A verdict that misses
  the overflow — or one reasoned from the SPEC/script instead of the pixels — → FAIL.

> Optional belt-and-braces: run `toolchain/src/layout-check.sh` on the tampered generator first; it
> should also fail (non-zero exit) on the planted overflow. That is the *machine* pre-flight; Test
> 2(b) proves the **reviewer's eye** independently catches the same defect from pixels — the two are
> complementary, not a substitute for each other.

---

## Pass criteria (the whole gate)

A reviewer PASSES calibration only when **all** hold:

1. **Test 1** — all four grade figures ranked correctly worst → best, monotonic overalls, broken
   caught as a layout defect.
2. **Test 2(a)** — the flat figure demoted (Composition/Richness), banded competent-but-generated,
   with a **named** concrete lift.
3. **Test 2(b)** — the planted text-past-border overflow flagged as a layout defect →
   `NEEDS_REVISION`, grounded in the rendered pixels.

Both reviewer files are calibrated independently (the `image-aesthetic-reviewer` on the generative
figures; the `ui-design-reviewer` composing the AESTHETICS + RICHNESS-MOTION lenses on the same
inputs by capability). The gate PASSES only when **both** clear all three.

## Persistence & failure semantics (hard gate)

- The verdict is **persisted** — the run's per-figure scores, bands, and the named lifts are
  appended below this line on each calibration run (date-stamped), so regressions are visible across
  cycles.
- **If the reviewer ever passes entry-level / AI-slop (Test 1 inversion or Test 2(a) banded strong+)
  or misses the planted overflow (Test 2(b)), calibration FAILS** — and the offending reviewer
  **must be re-tuned** (canon / checklist / cap sharpened) and re-run to a PASS **before the next
  production cycle**. A failing or stale calibration **blocks** the visual-quality production line;
  no figure ships through a reviewer that cannot prove it would catch what the maintainer caught.

---

## Verdict

**OPEN — awaiting first calibration run.** The gate is defined and armed: the four grade figures and
the two planted defects are sourced (`toolchain/proof/masthead-blend.jpg`,
`toolchain/out/flat-masthead.png`, the Gate-06 i2p-premium anchor, plus the constructed
text-past-border figure), the PASS/FAIL conditions are stated, and the two reviewer files are named.
The actual reviewer runs happen during verification; the PASS is recorded here only once both
reviewers clear all three criteria.

<!-- CALIBRATION LOG — append one dated block per run (per-figure scores · bands · named lifts · PASS/FAIL) -->
