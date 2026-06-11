# Gate — Reviewer calibration ("review the reviewers") · FULLY CLOSED — all three reviewers PASS (Run 1 2026-06-11 · Run 2 2026-06-11 · Run 3 2026-06-11)

**Date:** 2026-06-10 · **Branch:** `visual-quality-overhaul` · **Scope:** prove the three design
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
- `plugins/pressroom/skills/design-reviewer/agents/layout-reviewer.md` — the dedicated **layout &
  legibility GATE** (the eye the maintainer kept having to be), run with its companion
  [`references/layout-canon.md`](../../../plugins/pressroom/skills/design-reviewer/references/layout-canon.md)
  (the 8-item checklist + the inline-legibility rule).

The two aesthetic reviewers are each run with their companion canon (`image-aesthetic-canon.md` ·
`plugins/atelier/knowledge/canon/art-direction.md`); all carry the RENDER-FIRST first step, and the
two aesthetic reviewers carry the two taste caps. This gate verifies they *fire* on graded inputs and
planted defects.

**The layout-reviewer's "three criteria" are adapted to its role — it is a GATE, not a taste-scorer
(it disposes `PASS` / `NEEDS_REVISION` / `BLOCK`; it never emits a 0–100 score).** Its criteria are:
(1) **grade-ranking by SEVERITY of layout defect** — clean `<` one-minor `<` one-major `<`
multiple/meaning-destroying — in place of the aesthetic reviewers' craft-grade ranking;
(2a) **flag a too-wide / tiny-text figure as inline-illegible**; (2b) **flag a planted overflow →
`NEEDS_REVISION`/`BLOCK`**. All criteria are exercised through its **tiered RENDER-FIRST procedure**
(`layout-check.sh` SVG-math → `raster-lint.sh` cheap raster → vision-on-suspicion + a backstop vision
pass), with the two machine tiers **cross-checked** on every fixture.

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

Each reviewer file is calibrated independently: the `image-aesthetic-reviewer` on the generative
figures; the `ui-design-reviewer` composing the AESTHETICS + RICHNESS-MOTION lenses on the same inputs
by capability; and the **`layout-reviewer`** on planted layout fixtures, with its three criteria
**adapted to its gate role** — (1) grade-ranking by *severity of layout defect* (clean `<` one-minor
`<` one-major `<` multiple/meaning-destroying), (2a) a too-wide/tiny-text figure flagged
inline-illegible, (2b) a planted overflow → `NEEDS_REVISION`/`BLOCK` — all driven through its tiered
RENDER-FIRST procedure with the machine tiers cross-checked. The gate PASSES only when **ALL THREE
reviewers clear all three criteria.**

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

**FULLY CLOSED — all three reviewers PASS.** The gate requires **all three** design reviewers to
clear all three criteria; as of Run 3 they do.

- **Run 1 (2026-06-11) — `image-aesthetic-reviewer` (PRESSROOM):** executed under its RENDER-FIRST
  protocol on all four grade figures and both planted defects. All three criteria held — Test 1
  ranked worst→best with strictly monotonic overalls (35 < 79 < 88 < 98) and the broken figure
  caught as a layout defect (not a low aesthetic score); Test 2(a) demoted the flat figure on
  Composition + Medium-richness with a named concrete lift; Test 2(b) flagged the planted
  text-past-border overflow from the rendered pixels → `NEEDS_REVISION`; machine pre-flight
  (`layout-check.sh`) agreed independently (exit 1 on the same overflow).
- **Run 2 (2026-06-11) — `ui-design-reviewer` (ATELIER):** the companion calibration, composing the
  AESTHETICS + RICHNESS-MOTION lenses on the same inputs. All three criteria held — Test 1 ranked
  worst→best with strictly monotonic overalls (34 < 78 < 88 < 97); Test 2(a) demoted the flat figure
  on Composition + Medium-richness with a named concrete lift; Test 2(b) flagged the planted overflow
  from the rendered pixels → `NEEDS_REVISION`; machine pre-flight agreed (exit 1 on the same
  overflow). See the log below.
- **Run 3 (2026-06-11) — `layout-reviewer` (PRESSROOM):** the dedicated layout & legibility gate, run
  under its tiered RENDER-FIRST procedure (`layout-check.sh` → `raster-lint.sh` → vision-on-suspicion +
  backstop). All three gate-adapted criteria held — (1) severity grade-ranking ordered correctly
  (clean `<` one-minor `<` one-major `<` multiple/meaning-destroying); (2a) a too-wide / tiny-text
  figure flagged inline-illegible (machine: `layout-check.sh` exit 1); (2b) a planted overflow flagged
  → `NEEDS_REVISION`/`BLOCK`. Every planted defect class — too-wide/tiny-text **(c)**, vertical-clip
  **(d)**, occlusion **(e)**, overlap **(f)** — was caught, each at the *right* tier: (c)/(d) by the
  free `layout-check.sh` SVG-math, the multi-defect overflow additionally by `raster-lint.sh`, and the
  vision-only (e)/(f) by the backstop vision pass (the machine tiers stayed clean *by design*). The
  clean figure passed both cheap tiers (exit 0 / exit 0), proving the tiers discriminate rather than
  always-fail. No defect slipped → no layout-canon gap to fold back. See the log below.

With **all three** reviewers calibrated and green — the PRESSROOM `image-aesthetic-reviewer` that
drives the illustrator's A/B-until-best loop and the masthead/figure pipeline, the ATELIER
`ui-design-reviewer` that gates `/mockup` and `/ui-review`, and the PRESSROOM `layout-reviewer` that
gates layout & legibility *before* taste is even scored — the gate's "all three clear all three" rule
is satisfied and the gate is **fully closed**. A regression in any one reviewer re-opens it.

<!-- CALIBRATION LOG — append one dated block per run (per-figure scores · bands · named lifts · PASS/FAIL) -->

### 2026-06-11 — Run 1 · reviewer: `image-aesthetic-reviewer` (PRESSROOM, opus) · verdict: **PASS**

Executed the reviewer's RENDER-FIRST protocol honestly: each figure rasterised to PNG
(`rsvg-convert -b "#0b0b12"` for SVG frames), READ with vision, run through the layout-defect
checklist, then scored on the six dimensions with the two taste caps. Broken figure constructed from
`build-lifecycle-frames.sh` by flipping the masthead `<text>` to `text-anchor="start"` at `x=W-280`
(=1040) so the 35-char title overruns to ~x=1508 past the `W=1320` bound; poster frame + frame 0
rasterised.

**Test 1 — grade-ranking (worst → best):**

| Rank | Figure | Source | Fit | Adher | Artifact | Comp&AD | Rich | DocFit | Overall/100 | Band | One-line rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 (worst) | broken | `build-lifecycle-frames.sh` tampered → PNG | 3 | 2 | 1 | 1 | 2 | 1 | **35** | broken / NEEDS_REVISION | masthead title clipped hard at the right SVG edge ("idea → production · t" cut mid-word) — a layout defect, gated before taste |
| 2 | competent-but-generated | `toolchain/out/flat-masthead.png` | 4 | 4 | 5 | 3 | 3 | 4 | **79** | competent-but-generated | clean + legible but a single flat `#1e1e2e` ground, no blend/depth, wordmark adrift in dead space — AI-slop cap holds Comp ≤ 3, Rich = 3 |
| 3 | strong | `toolchain/proof/masthead-blend.jpg` | 5 | 5 | 4 | 4 | 4 | 4 | **88** | strong | true SVG↔raster blend — crisp vector wordmark over a rich gold-arch / teal raster atmosphere, scrim working; focal sun a touch dead-centre keeps Comp at 4 |
| 4 (best) | award-tier | `craft/validate/i2p-premium-test.png` (Gate-06 anchor) | 5 | 5 | 5 | 5 | 5 | 4 | **98** | award-tier | decisive focal hierarchy (crown-jewel → light-beam → portal gate), motivated volumetric key, disciplined teal-vs-gold script, real fore/mid/deep depth — reads as authored |

Overalls **35 < 79 < 88 < 98** — strictly monotonic, bands map one-to-one onto the four grades, broken
caught as a layout defect not a low score. **Test 1 PASS.**

**Test 2(a) — clean-but-flat (`flat-masthead.png`):** demoted on **Composition & art-direction (3)**
AND **Medium-richness (3)**, banded **competent-but-generated** (79, below strong). Named lift:
*"composite the crisp vector wordmark over a generative raster atmosphere behind a working dark-blur
scrim (the masthead-blend treatment) — and give the wordmark a focal reason to sit where it does
rather than floating in left-third dead space."* **Test 2(a) PASS.**

**Test 2(b) — text-past-border overflow (constructed broken figure):** RENDER-FIRST layout-defect
checklist fired on the rendered pixels — checklist item *"text clipped/cut at the SVG edge"* — the
masthead title is cut at the right border in **both** the poster frame (`f008`) and **frame 0**
(`f000`, "idea → production · t" terminating at the canvas edge). Verdict: **`NEEDS_REVISION`**,
citing the frame, grounded in pixels (the source-bash overflow is invisible until rasterised).
**Test 2(b) PASS.**

**Machine pre-flight cross-check:**
`bash doc/image-craft-study/toolchain/src/layout-check.sh <broken-generator>` →
`exit 1`, violation line: `f000.svg:text@x=1040 anchor=start fs=25: "idea → production · the value cycl…"
extends to x=1508 > bound=1320`. The human-grade reviewer's eye and the machine pre-flight **agree**
on the same overflow. (Sanity check: the un-tampered `build-lifecycle-frames.sh` passes
layout-check clean — 9 frames, 82 text elements, 0 violations — so the machine is discriminating, not
always-failing.)

**Reviewer-tuning gaps found:** none that block. The protocol as written caught every planted defect
and demoted the slop with a concrete lift. One minor observation for a future sharpening (not a
FAIL): the broken poster frame ALSO carries a secondary crowding/overlap tell — the return-arc
caption "↻ OPERATE's learnings re-enter DISCOVER" sits on top of the dashed arc line — which the
checklist's "text overlapping a line/arc" item also covers; the reviewer should make a habit of
listing *all* triggered checklist items, not stopping at the first (the gate only requires the
overflow be caught, and it was). Recommend the ATELIER `ui-design-reviewer` companion run be
scheduled to complete the two-reviewer PASS.

### 2026-06-11 — Run 2 · reviewer: `ui-design-reviewer` (ATELIER, opus) · verdict: **PASS**

Executed the ATELIER reviewer's RENDER-FIRST protocol honestly, composing the **AESTHETICS +
RICHNESS-MOTION** lenses on the design-fitness rubric (these figures are pictorial, not live SPAs).
Each figure rendered to pixels and READ with vision *before* any source was opened; the layout-defect
checklist run on every rendered frame; then scored on the six dimensions with the two taste caps
(AI-slop / entry-level cap + photoreal trap) and the artifact floor. Broken figure constructed
independently for this run: copied `build-lifecycle-frames.sh` → `/tmp/build-broken-frames.sh`,
hand-edited the masthead title `<text>` from `text-anchor="middle"` (x=W/2) to `text-anchor="start"`
at `x=W-280` (=1040) so the 35-char title overruns to x≈1508 past the `W=1320` bound; rasterised
frame 0 and the poster frame (f008) with `rsvg-convert -b "#0b0b12"`.

**Test 1 — grade-ranking (worst → best):**

| Rank | Figure | Source | Fit | Adher | Artifact | Comp&AD | Rich | DocFit | Overall/100 | Band | One-line rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 (worst) | broken | `/tmp/build-broken-frames.sh` (tampered lifecycle) → PNG | 3 | 2 | 1 | 1 | 2 | 1 | **34** | broken / NEEDS_REVISION | layout-defect gate fires first — masthead title hard-clipped at the right SVG edge (f000 cuts "· t" mid-word) + arc-caption overlapping the dashed arc (f008); gated before taste is scored |
| 2 | competent-but-generated | `toolchain/out/flat-masthead.png` | 4 | 4 | 5 | 3 | 3 | 4 | **78** | competent-but-generated | clean + legible but a single flat `#1e1e2e` ground, no blend/depth/atmosphere, wordmark adrift in left-third dead space — AI-slop / entry-level cap holds Comp ≤ 3, Rich = 3 (flat single-layer where a blend obviously serves) |
| 3 | strong | `toolchain/proof/masthead-blend.jpg` | 5 | 5 | 4 | 4 | 4 | 4 | **88** | strong | genuine SVG↔raster blend — crisp vector wordmark over a rich gold-arch / teal-nebula raster atmosphere with a working dark scrim; a nameable graphic voice. Focal sun rides near top-center (slightly axial) + a touch-heavy wordmark scrim keep Comp at 4 |
| 4 (best) | award-tier | `craft/validate/i2p-premium-test.png` (Gate-06 anchor) | 5 | 5 | 5 | 5 | 5 | 4 | **97** | award-tier | decisive focal hierarchy (crown-jewel keystone → vertical light-beam → portal gate at the vanishing point), motivated volumetric key, disciplined teal-vs-gold colour script, real fore/mid/deep depth with a reflective floor leading the eye in — reads as authored, not generated |

Overalls **34 < 78 < 88 < 97** — strictly monotonic, bands map one-to-one onto the four grades,
broken caught as a layout defect not a low aesthetic score. (Cross-check vs Run 1's PRESSROOM overalls
35/79/88/98: same ordering, near-identical magnitudes — the two reviewers agree on craft rank.)
Sanity note on the award anchor: the `masthead-cycle-strip.png` animation was also inspected as a
candidate higher-craft anchor but it is competent flat-grounded *diagram* craft (gradient wordmark +
lit lifecycle nodes), nowhere near the art-directed depth of the i2p-premium portal — so the Gate-06
premium-test remains the correct top anchor, as the gate specifies. **Test 1 PASS.**

**Test 2(a) — clean-but-flat (`flat-masthead.png`):** demoted on **Composition & art-direction (3)**
AND **Medium-richness (3)**, banded **competent-but-generated** (78, below strong). Named lift:
*"composite the crisp vector wordmark over a generative raster atmosphere behind a working dark-blur
scrim (the masthead-blend treatment) — and give the wordmark a focal reason to sit where it does
rather than floating in left-third dead space; add fore/mid/deep depth so the medium isn't left on
the table."* A concrete fix, not "make it better." **Test 2(a) PASS.**

**Test 2(b) — text-past-border overflow (constructed broken figure):** the RENDER-FIRST layout-defect
checklist fired on the rendered pixels — checklist item *"text clipped / cut at the edge"* — the
masthead title is cut at the right border in **both frame 0** (`f000`, "idea → production · t"
terminating off-canvas mid-word) and the **poster frame** (`f008`, same clip). The poster also trips
a second checklist item — *"text overlapping a line/arc"* — the return-arc caption "↻ OPERATE's
learnings re-enter DISCOVER" sits directly on top of the dashed teal arc. Verdict:
**`NEEDS_REVISION`**, citing the specific frames, grounded in the rendered pixels (the source-bash
overflow is invisible until rasterised). **Test 2(b) PASS.**

**Machine pre-flight cross-check:**
`bash doc/image-craft-study/toolchain/src/layout-check.sh /tmp/build-broken-frames.sh` →
`exit 1`, violation line: `f000.svg:text@x=1040 anchor=start fs=25: "idea → production · the value cycl…"
extends to x=1508 > bound=1320`. The un-tampered `build-lifecycle-frames.sh` passes layout-check
**clean** (`exit 0` — 9 frames, 82 text elements, 0 violations), so the machine is discriminating, not
always-failing. The reviewer's eye and the machine pre-flight **agree** on the same overflow.

**Reviewer-tuning gaps found:** none that block. The ATELIER protocol as written caught every planted
defect from pixels, demoted the slop with a concrete named lift, and produced overalls within ~1 point
of the PRESSROOM run on every grade — the two reviewers are mutually consistent. One reinforcing
observation (not a FAIL, echoing Run 1): the ATELIER checklist's "list ALL triggered items" habit was
honoured here — the poster's secondary arc-caption overlap was reported alongside the primary edge-clip
rather than stopping at the first trigger; worth keeping as the standard. (Superseded by Run 3 below:
the gate now requires **all three** reviewers.)

### 2026-06-11 — Run 3 · reviewer: `layout-reviewer` (PRESSROOM, opus) · verdict: **PASS**

Executed the layout-reviewer's **tiered RENDER-FIRST procedure** honestly, in the fixed cost order
(`layout-check.sh` SVG-math → `raster-lint.sh` cheap raster → vision-on-suspicion, plus the mandatory
one backstop vision pass), citing the `layout-canon.md` item by name on every finding. This reviewer
**gates** — it disposes `PASS`/`NEEDS_REVISION`/`BLOCK` and emits no 0–100 score — so its three
criteria are adapted: severity grade-ranking, inline-illegibility, and planted-overflow disposition.
Each fixture was a **one-line tamper** of `build-lifecycle-frames.sh` (mirroring how Run-1/Run-2 built
their broken fixture), rasterised to PNG with `rsvg-convert -b "#0b0b12"`. Fixtures lived in
`/tmp/run3-layout/`.

**Criterion 1 — grade-ranking by SEVERITY of layout defect (clean → meaning-destroying):**

| Rank | Severity band | Fixture | Defect(s) seen in pixels | Disposition |
|---|---|---|---|---|
| 1 (cleanest) | **clean** | `build-lifecycle-frames.sh` frame `f007` (active=8, arc off) | none — title centred with margin, all 8 labels clear above their nodes, dim return arc carries no text | **PASS** |
| 2 | **one-minor** | the clean **poster** `f008` (arc on) | ONE minor overlap — the return-arc caption rides on the dashed teal arc, but every word stays legible | NEEDS_REVISION (low severity) |
| 3 | **one-major** | **(e)** occlusion fixture | ONE major defect — all 8 node labels half-eaten by the node fill drawn over them ("DIS⬤VER", "B⬤ILD"…); glyphs lost | NEEDS_REVISION (high severity) |
| 4 (worst) | **multiple / meaning-destroying** | **multi** fixture (occlusion + title overflow + arc-overlap) | title sheared off the right canvas edge (most of it lost) **+** every label occluded **+** arc caption on the arc | **BLOCK** |

Ranked correctly clean `<` one-minor `<` one-major `<` multiple/meaning-destroying — severity is
monotonic and the meaning-destroying figure lands `BLOCK`, not a graded nit. **Criterion 1 PASS.**

**Criterion 2a — too-wide / tiny-text → inline-illegibility (fixture (c)):** built the value-flow-style
too-wide case — one-line tamper shrinking the arc caption to `font-size="10"`, then widening the canvas
to `W=2246` (the value-flow width). Rendered to the **inline ~640px strip the reader actually sees**:
the arc caption "↻ OPERATE's learnings re-enter DISCOVER" collapses to an **unreadable teal smear** and
the whole figure drops sub-floor. Flagged **inline-illegibility (layout-canon §4.4 / §4.8)** →
`NEEDS_REVISION`. Machine cross-check: **`layout-check.sh` exit 1** at *both* the shipped `FLOOR=6`
(`~4.6px @640`) and the strict target `INLINE_W=640 FLOOR=9` (`idea → production… renders ~7.1px <9`);
`raster-lint.sh` CLEAN (inline-illegibility is the SVG-math tier's domain by design — raster-lint owns
crowding/occlusion/edge, not tiny-but-spaced text). **Tier that caught it: `layout-check.sh`.
Criterion 2a PASS.**

**Criterion 2b — planted overflow → NEEDS_REVISION/BLOCK:** exercised across two fixtures and the
multi:
- **(d) vertical-clip** — one-line tamper pushing the node-label `y` from `CY-32` to `H+40`. In the
  render **all 8 node labels are clipped off the canvas bottom** — eight unlabelled nodes, the labels
  simply not there for the reader. Flagged **vertical clipping (§4.5)** → `NEEDS_REVISION`. Cross-check:
  **`layout-check.sh` exit 1** (`y=343 > H=300 clipped at bottom`); `raster-lint.sh` CLEAN (labels
  entirely off-canvas → no ink in the edge strip; the maths tier owns this). **Tier: `layout-check.sh`.**
- the **multi** fixture's **horizontal title overflow** (title anchored `start` at `x=W-200`, running
  to `x=1588 > 1320`) → the title sheared off the right edge, a meaning-destroying clip. Cross-check:
  **`layout-check.sh` exit 1** AND **`raster-lint.sh` SUSPECT** (edge-clip tile=right, ink_frac 0.0278
  > 0.01 → escalation). **Tiers: both `layout-check.sh` and `raster-lint.sh`.**

Both flagged → `NEEDS_REVISION` (the multi → `BLOCK` on the meaning-destroying clip). **Criterion 2b PASS.**

**Vision-only classes (machine-blind by design — caught on the backstop):**
- **(e) z-index / occlusion** — one-line-equivalent tamper drawing the node label *before* its filled
  circle (at the node centre), so the opaque circle eats the label's middle. **`layout-check.sh`
  exit 0** (maths sees no overflow) and **`raster-lint.sh` CLEAN** (a *filled-shape* occluder, not the
  thin-bright-line the occlusion heuristic targets) — both machine tiers pass **by design**. Caught on
  the **vision backstop**: every label half-eaten by its node fill (§4.6). The worst kind — source
  review passes it; only the pixels reveal it. **Tier: vision-backstop. PASS.**
- **(f) overlap** — one-line tamper moving the arc caption from `y=CY+82` to `y=CY`, laying it across
  the bright teal 5px spine line and through two node circles. **`layout-check.sh` exit 0** and
  **`raster-lint.sh` CLEAN** — honest record: the thin-line-through-text heuristic did **not** trip
  (the caption is centred while the spine spans full-width through sparse node-gap tiles, so the
  line∧text coincidence never reached the contiguous-run threshold; raster-lint's header documents
  *semantic overlap* as vision-only). Caught on the **vision backstop**, not by escalation: the
  caption's glyphs are bisected by the spine line (§4.2). **Tier: vision-backstop. PASS.**

**Clean-figure discrimination (the tiers don't false-positive):** on the clean `f007`,
**`layout-check.sh` exit 0** (FLOOR=6, 9 frames / 82 text elements / 0 violations) and
**`raster-lint.sh` exit 0** (CLEAN, 0 suspect tiles → reviewer may skip vision). The backstop vision
pass found nothing. The cheap tiers are **discriminating, not always-failing** — they passed a genuine
clean and tripped on every real defect within their reach.

**Machine cross-check summary:**

| Class | Fixture (one-line tamper) | layout-check.sh | raster-lint.sh | Caught by tier | Verdict |
|---|---|---|---|---|---|
| (c) too-wide / tiny-text | caption fs 20→10, `W=1320→2246` | **exit 1** (both floors) | CLEAN | layout-check | NEEDS_REVISION |
| (d) vertical-clip | label `y CY-32 → H+40` | **exit 1** (y>H) | CLEAN | layout-check | NEEDS_REVISION |
| (e) z-index / occlusion | label drawn before its filled node | exit 0 | CLEAN | **vision-backstop** | NEEDS_REVISION |
| (f) overlap | arc caption `y CY+82 → CY` (onto spine) | exit 0 | CLEAN (no escalation) | **vision-backstop** | NEEDS_REVISION |
| multi / meaning-destroying | (e) + title overflow `x=W-200` | **exit 1** | **SUSPECT** (edge-clip) | both + vision | BLOCK |
| clean | none (`f007`) | exit 0 | CLEAN | — | PASS |

**Reviewer-tuning / canon gaps found:** **none.** Every planted class was caught at the correct tier;
the two free machine tiers stayed clean on the vision-only classes **by design**, the backstop vision
pass caught those, and the clean figure cleared both cheap tiers — so the cost-tier doctrine held and
there is **no layout-canon gap to fold back** (the covenant only triggers on a *slipped* defect, and
nothing slipped). One honest observation (not a FAIL): (f)'s text-on-line did not trip
`raster-lint.sh`'s occlusion heuristic — but this is **already documented** in the canon and the
script header as vision-only *semantic overlap*, and the backstop caught it, so it is a known boundary
of the cheap tier, not a missed class. **All three reviewers now PASS all three criteria — gate
FULLY CLOSED.**
