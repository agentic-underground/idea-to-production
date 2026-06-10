# Gate 09 — richest-imaging review + calibration (Phase 9)

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste` · **Scope:** make the reviewers demand the
*richest* imaging, and prove (adversarially) that they now catch "too simple / entry-level".

## What shipped

- `design-reviewer/references/image-aesthetic-canon.md` — **6th dimension "Medium-richness" (weight 10)**,
  rubric reweighted to 100 (Fit 22 · Adher 20 · Artifact 22 · Comp&AD 16 · **Rich 10** · DocFit 10). New
  *"Reviewing a blended or animated figure"* section (frame-strip review; blend-fitness; "flat single-layer
  where a blend/depth would serve = richness 3"). Inline baseline carries a compact richness/motion fallback
  (self-contained when atelier absent).
- `design-reviewer/agents/image-aesthetic-reviewer.md` — scores six dimensions; builds + reads a **frame-strip**
  for animated input; output tables gained the `Rich` column.
- ATELIER `knowledge/canon/art-direction.md` — new **§9 "Motion & temporal craft"** (motivated motion, easing,
  staging, the loop/seam, reduced-motion); §8 elevated. `agents/ui-design-reviewer.md` gained a
  **RICHNESS-MOTION-REVIEWER** lens; `protocols/design-critique-loop.md` + `canon/README.md` note the
  richness/motion path. Pressroom composes this **by capability**.

## Calibration test (the core proof) — PASS

Two mastheads, **same wordmark/message**, scored under the NEW rubric by an adversarial reviewer told to
*argue the flat one deserves a top score*:

| Figure | Fit | Adher | Artifact | Comp&AD | **Rich** | DocFit | Overall | Verdict |
|---|---|---|---|---|---|---|---|---|
| **A — SVG↔raster blend** (raster atmosphere + crisp vector) | 5 | 5 | 4 | 4 | **5** | 4 | **89** | strong |
| **B — flat** (same type, solid ground, single layer) | 5 | 5 | **5** | 3 | **3** | **5** | **84** | competent-but-generated |

**The assertion that proves the bar:** B is *cleaner* than A on the easy dimensions (Artifact 5 vs 4, DocFit
5 vs 4) — under the old lenience it would have won. The new rubric pins B's **Medium-richness to 3** (the
explicit "flat single-layer where a blend/depth would serve" rule), which — with composition — **flips the
ranking** (A 89 > B 84). The reviewer named B's concrete lift: *"composite the crisp vector over a generative
raster atmosphere behind a working scrim — perform the blend A already does."*

Checks (a) richness forced down despite clean/legible/on-message ✅ · (b) A richness ≥4 > B ✅ · (c) gap
reflected in overall ✅ · (d) lift named concretely ✅ → **PASS**. Calibrated, not merely harsh: B still scores
a respectable 84 (doc-usable, not award-tier), which is the correct band.

Evidence: `toolchain/proof/richness-calibration-AB.jpg` (A over B) + `src/flat-masthead.svg` (the flat source).

## STEER

Green. The "richest imaging" gate is live and proven. Carry into Phase 10: every animated/blended hero is
scored on Medium-richness from a frame-strip; a flat hero that could blend/animate is a *finding*, not a pass.
