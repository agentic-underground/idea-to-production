---
name: sentinel-hero-comfyui
description: The sentinel plugin hero.png is a ComfyUI dark-key raster — reproducible dreamshaper_8 recipe + winning seed, fixes the amber-summit/rim-light regen that lifted it past the rubric.
metadata:
  type: project
---

`plugins/sentinel/diagrams/hero.png` (the sentinel watchtower hero) is generated
raster, dark-key (opaque RGB, no alpha — txt2img-basic has no transparent VAE, so
per dark-mode canon §4 it assumes a dark-ish host).

Concept: a solitary monolithic watchtower silhouette on a dark plain, vertical teal
scanning beam from the summit, deep dark-key night, atmospheric haze, and
bioluminescent cyan veins/network across the foreground ground-plane (the reviewer
called those veins the best storytelling detail in the whole set — always keep them).

Reproducible recipe (rubric target >95):
- model: `dreamshaper_8.safetensors` (SD1.5, "photoreal scene / atmospheric
  environment" intent — scenes 100, same base as [[concierge-hero-comfyui]])
- 768x512, steps 28, cfg 7.0, sampler dpmpp_2m, scheduler karras
- **winning seed: 3303** (3rd pass, scored past 95). Earlier passes used seed
  410 (pass 1/2, ~91) — superseded; the file on disk is now seed 3303.
- HARD constraints that protect the score: NO text/letters/glyphs, NO
  people/figures/hands/faces (watchtower is a STRUCTURE not humanoid), dark-key.
  Palette teal/cyan (#5ad7e6/#7aa2f7) + amber summit beacon (#e0af68).

**Why the regen happened:** the first pass scored 87 — the tower was pure black
negative space with ZERO amber, so the brightest point (and accidental focal) was
the sky-glow ABOVE the tower, not the tower. Two fixes lifted it: (1) an amber
beacon light at the tower's SUMMIT where the beam originates (adds the brand's
two-tone teal+amber AND makes the top a bright anchor), (2) a faint cyan rim-light
down the tower's left edge so the silhouette SEPARATES from the sky and the tower
itself is the brightest-edged subject.

**How to apply:** if regenerating, reuse this recipe/seed. Seed-selection note from
this batch: 410 = clean single focal, bright amber crown, teal-rim tower, cyan
foreground — the only clean hit on all four criteria. 511 grew a second competing
teal tower (split focal); 622 bled amber into the right sky (sky-glow problem
partly recurred); 733 spawned two towers with amber on the wrong (secondary)
structure. Watch for these failure modes: extra towers split the focal, and amber
prompted too strongly bleeds into the sky instead of staying a tight summit crown.
**Third-pass fix (91 -> >95): the summit pseudo-text trap.** At ~91 the only
defect was the tower's summit lantern/gallery baking small amber glyph-like
inscription marks (read as "[⊥⊥]") — the SD1.5 lantern-room gallery with
repeating window slots/balustrade looks like engraved text. Fix that worked:
(1) POSITIVE add "smooth clean amber beacon dome at the summit, simple unadorned
tower crown, the summit is a single round amber lantern light"; (2) NEGATIVE
add/strengthen "text, letters, glyphs, inscription, engraving, carvings, ornate
balustrade, railing, gallery, symbols, signage, numbers, pseudo-text, runes,
characters, writing, latticework, fretwork, ornamentation". Seed-selection note
from this batch (410/821/1337/2024/3303): 3303 = clean smooth amber+dark-cap
lantern dome, deep dark-key, cyan-rim tower as brightest focal, bold cyan
foreground vein — the only seed whose summit carried ZERO glyph-like marks
anywhere (verified at 4x and 8x crop). Failure modes seen again: 410 kept the
rectangular-window-pane "[⊥⊥]" glyph slots; 1337 grew a bright white gallery
band that competes with the rim-light; 821/2024 went too-bright/white-washed
(lost dark-key) and demoted amber off the summit. ALWAYS scan the summit at
high zoom — pseudo-text hides at the lantern room. No local ImageMagick/PIL on
the handler box; crop+zoom via the stdlib PNG decoder at /tmp/pngtool.py
(zlib-only) to inspect details before handing back.

Distinct asset from [[concierge-hero-comfyui]] / [[i2p-hero-comfyui]]. Endpoint +
template gotcha: see [[comfyui-endpoint]] / [[template-meta-strip]].
