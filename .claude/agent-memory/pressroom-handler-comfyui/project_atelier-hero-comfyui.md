---
name: atelier-hero-comfyui
description: The atelier plugin hero.png is a ComfyUI dark-key raster; reproducible recipe + the SDXL prompt-tension lesson (amber-dominant vs floating-cyan-wireframe).
metadata:
  type: project
---

`plugins/atelier/diagrams/hero.png` is a generated dark-key raster (opaque RGB, no alpha — assumes a dark-ish host, per dark-mode canon §4 and [[i2p-hero-comfyui]]).

Subject: craftsman's design studio at night — warm amber pendant/sconce over a wooden drafting desk, a single coherent cyan holographic WIREFRAME CHAIR, cool cyan schematic accents, dark-key, depth of field.

Winning recipe (pass-4: sharpened the "DESIGN STUDIO" read past the soft-91 plateau toward >95):
- model: `SDXL_1/protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors`
- 1216x832, steps 30, cfg 6.5, sampler dpmpp_2m, scheduler karras
- **CURRENT winning seed: 701** (pass-4 prompt: explicit angled DRAFTING TABLE as central work surface + large glowing cyan holographic wireframe blueprint(s) on the wall). The ornate cast-iron angled drawing board is the unambiguous craft-of-design tell that the bare-chair-in-a-dark-room composition lacked.
- prior pass-3 winning seed 614 (amber-dominant focal + single floating cyan wireframe chair) scored ~91 but the design-studio read was SOFT — looked like "an elegant dark room with a chair." The fix that broke the plateau was adding an explicit drafting table + wall blueprint to the prompt.
- palette: teal/cyan #5ad7e6/#7aa2f7 + warm amber #e0af68; HARD constraints: NO text, NO people/hands/faces, NO second lamp / wall circle.

**Why this recipe / the prompt-tension lesson (the load-bearing part):**
SDXL protovision has a strong **solid-object bias for the word "chair"**: when the prompt pushes warm-amber dominance, it renders a SOLID office chair (fails the "hologram" fix); when the prompt pushes a floating cyan wireframe, the room floods CYAN and the warm-amber lamp loses focal ownership (fails the KEEP mood). The two goals fight each other.
- The phrase **"see-through / x-ray / transparent"** is DANGEROUS: it triggered glowing cyan **SKELETONS** (anatomy hard-cap reject) on multiple seeds. Avoid "x-ray".
- **The drafting-table tell beats the floating-wireframe-object focal for legibility of intent.** When the brief is "make it read clearly as a design studio," prompting an explicit angled drafting/drawing board + wall blueprint resolves the read far more reliably than a hovering cyan object in an otherwise generic dark room. Naming "chair" in the scene still risks the SDXL solid-office-chair trap (seeds 909/1024 reintroduced a solid chair) — the 701 winner has no chair, the teal focal lives in the glowing board surface.
- dreamshaper_8 was worse here: it baked readable schematic TEXT on a wall screen (text-cap risk) and went cyan-dominant — confirms reviewer's note that SD1.5 tangles/mis-handles this geometry. SDXL is correct for coherent wireframe geometry.

**How to apply:** to regen, reuse model/settings/seed 614. To improve toward a cleaner amber-pendant-OWNS-focal + crisp-floating-wireframe combo, the unsolved lever is spatial composition control (the txt2img-basic template has no regional/controlnet node) — note for the comfyui-mcp template set. Watch seeds for: solid chair, two chairs, skeletons, second lamp, baked daylight window.
