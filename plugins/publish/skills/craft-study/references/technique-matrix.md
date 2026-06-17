# Technique matrix — the curated short-list

The craft study never runs a full cross (objectives × every technique × every model). That burns GPU and
proves nothing: a beauty contest cannot tell you *which stage* did the work. Instead it sweeps a **curated
short-list, one variable at a time** — a controlled A/B per objective.

## The controlled-A/B principle

For each objective, the two cells share **ckpt, prompt, seed, and base resolution**. The only difference is
the **named stage under test**. So a visible difference is *caused* by that stage — reproducible (fixed seed)
and namable (one variable). This is the direct answer to "is this 'gain' real, or seed/prompt luck?"

| Objective | Checkpoint (live, post-path-move) | Baseline cell | Treatment cell | Stage under test |
|---|---|---|---|---|
| **portrait** | `nightvisionXLPhotorealisticPortrait_v0743…` | `flat` (hires-fix @ scale 1.0, pass-2 denoise 0.2/1-step ≈ single pass) | `hires` (scale 1.5, 0.45-denoise 20-step re-detail) | latent hires-fix re-detail on skin / eyes / hair |
| **landscape** | `crystalClearXL_ccxl` | `flat` | `hires` | hires re-detail on atmospheric depth + micro-texture |
| **marketing-hero** | `foddaxlPhotorealism_v51` | `flat` | `hires` | hires re-detail on product reflections + studio crispness |
| **dark-key** | `epicrealism_naturalSinRC1VAE` (SD1.5) | `loraoff` (lora-detail, both LoRA strengths 0) | `loraon` (lowkey_v1.1 @0.8 + LowRA @0.6) | the dark-key LoRA stack — deep chiaroscuro, controlled low-key |
| **world-axis** | `reproductionSDXL_2v12` | — (single exemplar) | `tricomposite` (3 regions → 2 feathered composites → unify pass) | regional latent composition coherence (vertical world-axis, aerial→warm depth gradient) |

Both `flat` and `hires` run through the **same** `txt2img-hires-fix` template — the baseline simply sets the
upscale to a no-op (`scale_by 1.0`, a 1-step low-denoise pass-2). That keeps the pass-1 sampler, scheduler and
seed **byte-identical** between the two cells, so the hires pass is the lone variable. The dark-key pair runs
through the **same** `lora-detail` template with the LoRA strengths the only change (the template's own
"set strengths to 0 to disable" path).

## Why these objectives

They span the genres where multi-stage technique is known to pay differently, so a single small matrix
exercises the full claim surface:

- **portrait** — faces are where a re-detail pass and (later) FaceDetailer earn their keep; flat SDXL skin is
  the classic "competent but generated" tell.
- **landscape** — depth, fog, and micro-texture reward the second pass; a flat render reads as a wallpaper.
- **marketing-hero** — the "standard stock image" the marketing team needs: clean studio product shots where
  crisp reflections and edge fidelity separate stock-grade from amateur.
- **dark-key** — proves a *LoRA-craft* gain (not just resolution): controlled low-key lighting the base model
  cannot hold on its own.
- **world-axis** — proves *compositional* control (tricomposite) — the regional-latent craft the maintainer
  flagged to learn from.

## Extending the matrix

Add objectives/techniques to `references/manifest.example.json` (copied to `craft/manifest.json`). Keep every
addition a **controlled single-variable A/B** through an allowlisted template — never an arbitrary node graph,
never a full cross. New candidate stages worth a controlled pass next cycle: **base+refiner handoff**,
**UltimateSDUpscale**, **FaceDetailer** (Impact Pack), **FreeU**, **IPAdapter** style-transfer, and a
**sampler/CFG** micro-sweep on the winning recipe. Each must clear the same bar: a visible, named, reproducible
gain over its matched baseline, or it is recorded as "tested, no gain" and not promoted.
