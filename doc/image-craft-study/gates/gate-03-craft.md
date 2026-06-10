# Gate 3 — empirical multi-stage craft study · PASS

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste`

## What was tested

A resumable, 0-token harness (`plugins/pressroom/skills/craft-study/`) ran a **controlled single-variable A/B**
per objective — baseline vs one named multi-stage stage, sharing **ckpt / prompt / seed / base-resolution**, so
any visible difference is attributable to the stage, not seed or prompt luck. Five objectives, nine cells, all
rendered clean on the rig through the Phase-5 allowlisted templates. Each A/B sheet was then scored by the
image-aesthetic reviewer **prompted to refute the gain** (default: "this is placebo / seed-luck").

## Verdicts (the panel tried to break each claim)

| Objective | Stage | Baseline → Treatment | Verdict | Why it survived refutation |
|---|---|---|---|---|
| portrait | latent hires-fix @0.45 | 72 → **66** | **NO-GAIN (regression)** | Quantified detail LOSS (−17…−20% high-freq on eyes/beard/face), directional across 3 independent regions — a named failure mode, not noise. |
| landscape | latent hires-fix @0.45 | 79 → **83** | gain (incremental) | Panel-diff ≈0 (same seed/comp); micro-texture resolved per plane; reviewer flagged the uplift as modest + mixed-sign — honest, not oversold. |
| marketing-hero | latent hires-fix @0.45 | 68 → **74** | gain | +12.5% micro-texture on marble/crema, ~0 on the flat wall control → rules out placebo global sharpen. |
| dark-key | LoRA `lowkey`@0.8 + `LowRA`@0.6 | 62 → **81** | **gain (strong)** | Res-matched; histogram collapses to true low-key tenebrism; anatomy clean; attributable solely to the LoRA stage. |
| world-axis | regional tricomposite | 68 → **92** | **gain (strong)** | Coherent vertical world-axis + working cool→warm depth descent across 3 feathered planes; reviewer named the seam-2 cost honestly (Composition 4 not 5). |

## Verdict: **PASS**

Every **promoted** gain is visible, named, and reproducible over its matched baseline — the Gate-3 bar. The most
valuable result is the **honest negative**: blanket latent-hires-fix **hurts** close-up portraits, a finding the
reviewer quantified rather than rationalising a win. The study therefore did exactly what the program demanded —
it produced **per-genre intelligence**, including where a popular technique *fails*, not a uniform "everything is
better" story.

Synthesized into canon:
- `plugins/pressroom/knowledge/comfyui-model-guide.md` — the per-genre findings table + actionable rules.
- `plugins/pressroom/skills/illustrator/references/workflow-strategy.md` — the decision tree is now
  evidence-backed (hires is genre-dependent; faces want low-denoise/FaceDetailer; dark-key LoRA + tricomposite
  are real gains).

## STEER

The harness is resumable and the matrix is extensible (`references/technique-matrix.md`). Next controlled passes
worth running (each a single-variable A/B through an allowlisted template, never a full cross): **portrait hires
at 0.25–0.35 denoise** (confirm the fix for the regression), **base+refiner handoff**, **UltimateSDUpscale**,
**FaceDetailer on the portrait**, **FreeU**. Each must clear the same bar or be recorded as "tested, no gain".
