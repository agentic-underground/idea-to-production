---
name: i2p-hero-comfyui
description: The i2p README hero.png is a ComfyUI raster asset that assumes a dark-ish host (dark-key, no alpha); reproducible recipe recorded.
metadata:
  type: project
---

`plugins/i2p/diagrams/hero.png` (the marketplace front-door hero) is generated, not vector.

Fact: it is a **dark-key composition (opaque RGB, no alpha channel)** — the txt2img-basic template has no transparent-VAE/bg-removal node, so per dark-mode canon §4 this asset **assumes a dark-ish host** (embeds cleanly on a dark GitHub page; would show its near-black ground on a light page).

Reproducible recipe (target >95 aesthetic rubric):
- model: `SDXL_1/protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors`
- 1216x832, steps 30, cfg 6.5, sampler dpmpp_2m, scheduler karras
- **winning seed: 202**
- HARD constraints that protect score: NO text, NO people/figures/hands/faces (sidesteps anatomy cap), dark-key, teal/cyan (#5ad7e6/#7aa2f7) primary glow + restrained amber (#e0af68).

**Why:** rubric has hard caps for gibberish text + mangled anatomy; an empty cosmic-gateway scene avoids both.
**How to apply:** if regenerating this hero, reuse this exact recipe/seed; watch that seeds don't sneak a human figure into the portal (seed 101 did — rejected for that).
