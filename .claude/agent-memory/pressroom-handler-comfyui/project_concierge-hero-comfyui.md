---
name: concierge-hero-comfyui
description: The concierge README hero.png is a ComfyUI raster asset (dark-key, no alpha) — reproducible dreamshaper_8 recipe + winning seed recorded.
metadata:
  type: project
---

`plugins/concierge/diagrams/hero.png` (the ARRIVAL-layer greeter hero) is
generated raster, not vector.

Fact: **dark-key composition (opaque RGB, no alpha)** — the txt2img-basic template
has no transparent-VAE/bg-removal node, so per dark-mode canon §4 this asset
**assumes a dark-ish host**. Concept: a warm amber lantern crowning an arched
threshold door, against teal-dark architecture — "a warm light at the door."

Reproducible recipe (rubric target >95):
- model: `dreamshaper_8.safetensors` (SD1.5, intent class "photoreal scene /
  atmospheric environment" per model guide — scenes 100)
- 768x512, steps 28, cfg 7.0, sampler dpmpp_2m, scheduler karras
- **winning seed: 303** (of 101/202/303)
- HARD constraints that protect the score: NO text, NO people/figures/hands/faces
  (sidesteps the anatomy cap), dark-key, warm amber (#e0af68) focal glow against
  teal/cyan (#5ad7e6/#7aa2f7) dark architecture.

**Why:** rubric has hard caps for gibberish text + mangled anatomy; a peopleless
lit-threshold scene avoids both and carries the welcome via light.
**How to apply:** if regenerating, reuse this recipe/seed. Seed-selection note:
seed 101 split the focal (two competing lights, amber pushed to edge) and seed 202
made the *door* glow cool teal rather than warm — both weakened the "warm welcome"
message. Seed 303 put the amber lantern directly over a central door = clear warm
focal. Watch that the door reads inviting (closed-but-warm-lit was fine here).
Distinct asset/recipe from the SDXL [[i2p-hero-comfyui]]. Endpoint +
template gotcha: see [[comfyui-endpoint]] / [[template-meta-strip]].
