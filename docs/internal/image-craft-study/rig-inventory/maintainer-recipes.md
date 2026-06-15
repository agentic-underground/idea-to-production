# Maintainer recipes & taste — mined from AWESOME_PICTURES (the curated favourites)

> Distilled (metadata-only, no pixels) from the 34 curated favourites in `~/Pictures/AWESOME_PICTURES` on
> the i9. These are **rig-proven** recipes and a clear taste signal — they override the earlier
> craft-evidence guesses where they conflict. Full premium graph: [`iru-premium-workflow.json`](iru-premium-workflow.json).

## Corrections to the earlier craft-evidence (important)

- **`SDXL/sd_xl_base_1.0.safetensors` LOADS and is the maintainer's *primary* base** (45 node-instances
  across the favourites). The earlier "won't load via the API / refiner path is dead" finding was WRONG —
  drop it. `SDXL/sd_xl_refiner_1.0.safetensors` is also used. The full SDXL **base + refiner** flow (proper
  `CLIPTextEncodeSDXL` / `CLIPTextEncodeSDXLRefiner` dual conditioning, `KSamplerAdvanced` step-split) is a
  first-class pipeline here, not a dead one.
- **PATH MOVE (2026-06-10) — the favourites' embedded paths are now STALE.** The rig was reorganised: every
  fine-tune was moved to the checkpoints **root**. A recipe that records `SDXL_1/protovisionXL…`,
  `SDXL_2/modernDisneyXL_v11`, or `SDXL/oasisSDXL_v10` must now load the **bare** root name
  (`protovisionXL…`, `modernDisneyXL_v11.safetensors`, `oasisSDXL_v10.safetensors`). The **only** checkpoints
  still under `SDXL/` are `sd_xl_base_1.0`, `sd_xl_refiner_1.0`, `svd_xt_1_1`; Lightning models stay under
  `LIGHTNING/`. Verified on the rig: **75 checkpoints at root, 12 nested.** **Never copy an embedded path
  verbatim** — resolve every `ckpt_name` against live `/object_info` and use the exact current string.

## Preferred samplers / schedulers / CFG (maintainer-measured)

- **Samplers:** `dpmpp_sde_gpu` (dominant, 34×) and `dpmpp_3m_sde_gpu` (17×) — the SDE-GPU family, not the
  `dpmpp_2m` the earlier guide defaulted to. Upscale passes use plain `euler`.
- **Scheduler:** `karras` (dominant). Upscale pass uses `normal`.
- **CFG is LOW: 3.5–4.5** for SDXL base (naturalism), not 6–7. Hero base pass ran **59 steps @ cfg 3.5**;
  refine passes **31 steps @ cfg 4.5**.

## The premium pipeline — REIMAGINE + UltimateSDUpscale (the `IRU` flow, 42 nodes)

1. **SDXL resolution** — `RecommendedResCalc` / `CM_NearestSDXLResolution` snap to an SDXL-optimal size
   (don't free-type 1216×832; let the calc pick the nearest valid SDXL ratio).
2. **Base generation** — `SDXL/sd_xl_base_1.0` with SDXL dual text-encode; `KSampler` 59 steps, cfg 3.5,
   `dpmpp_3m_sde_gpu` / karras.
3. **REIMAGINE (unCLIP image-prompt)** — `CLIPVisionLoader: clip_vision_g.safetensors` → `CLIPVisionEncode`
   a source image → `unCLIPConditioning` (+ `ConditioningZeroOut`) feeds the sampler, so a *reference image's
   look* steers the generation (the maintainer's signature "reimagine" move). Refine passes 31 steps, cfg 4.5,
   `dpmpp_sde_gpu` / karras.
4. **HD finish — `UltimateSDUpscale`** — `upscale_by` computed, **denoise 0.25**, `euler`/`normal`, **tiled
   1024×1024**, upscale model **`SwinIR/001_classicalSR_DF2K_…x4.pth`**. This is the preferred upscale (tiled,
   low-denoise re-detail), not a bare latent-upscale.

## The TRICOMPOSITE recipe — regional latent composition (mined from `~/Pictures/ComfyUI/TRICOMPOSITE_*`, 207 imgs)

A second signature flow, distinct from REIMAGINE. The graph (23 nodes, base `reproductionSDXL_2v12` →
now bare at root) builds **one tall vertical image from three independently-prompted regions**:

1. **3 × `EmptyLatentImage`** — three region canvases (top / middle / bottom of a portrait frame).
2. **6 × `CLIPTextEncode`** — a *pos+neg pair per region*, so each band has its own subject and mood
   (e.g. cosmic sky · mid landform · saturated foreground).
3. **3 × `KSampler`** — each region sampled separately (independent composition control).
4. **2 × `LatentComposite`** — paste the three region latents into one combined latent at fixed offsets
   (chained: region-A ⊕ region-B ⊕ region-C).
5. **4th `KSampler`** — a **unifying pass over the composited latent** (low-ish denoise) that knits the
   seams into one coherent picture. Then `VAEDecode` → `SaveImage`.

**Why it works / the composition lesson (read off the contact sheet):** the three registers cohere only
when a **vertical world-axis threads them** — a tree trunk, an energy column, a lightning bolt, a tower —
plus an **atmospheric depth gradient** (cool/hazy at the top → warm/vivid at the base). That through-line
+ gradient is the transferable craft, in raster *or* vector. **Improvements to pursue:** swap
`LatentComposite` for `LatentCompositeMasked` with feathered masks (softer seams), or regional
conditioning (`ConditioningSetArea`/GLIGEN) for cleaner region control, or a tile-ControlNet seam pass.

## Favoured checkpoints (by use, on this rig — resolve names via `/object_info`, do not assume a subfolder)

`SDXL/sd_xl_base_1.0` (+ `SDXL/sd_xl_refiner_1.0` — these two keep the prefix) · `oasisSDXL_v10` (versatile
workhorse) · `crystalClearXL_ccxl` (crisp photoreal) · `LahCuteCartoonSDXL_alpha` & `xlYamersCartoonArcadia_v1`
(cute/cartoon) · `animagineXL_v10` & `nijianimesdxl_v10` (anime) · `nigi-cyber-umaaji` & `nigi3d_v20`
(stylised) · `copaxTimelessxlSDXL1_colorfulV2` · `samaritan3dCartoon_v40SDXL` · `novaPrimeXL_v10` ·
`reproductionSDXL_2v12` (the tricomposite base). All fine-tunes are now **root-level, bare names** (see the
PATH MOVE note above). Favoured LoRA: **`BAS-RELIEF.safetensors`**, `xl_more_art-full_v1` (detail/quality).

## Taste signal — what the maintainer's favourites have in common

- **Bas-relief / sculptural / engraved** — the strongest signature (monochrome carved birds, a relief duck,
  metallic-relief creatures), driven by the `BAS-RELIEF` LoRA. A distinctive, high-craft look worth a named
  style.
- **Intricate biomechanical detail** — cyborg dolphins in ornate decorative frames, a mech insect, ROBOTMAN.
- **Dramatic, motivated, volumetric light** — god-ray enchanted forests, rain-soaked moody cyberpunk, glowing
  rim-lit creatures. (This aligns with the art-direction canon's light §.)
- **Whimsical high-polish creatures** — a cute 3D elephant, kawaii sea-creatures, fantasy rabbits — clean,
  characterful, vivid.
- **Crisp photoreal** — a clean studio portrait, a fox in a meadow.
- **Ornate framing & rich colour** — decorative borders, saturated jewel tones alongside the monochrome relief.

> Net: the maintainer's taste is **broader and richer** than the marketplace's dark teal/amber hero brand —
> it prizes sculptural relief, intricate detail, dramatic light, and imaginative subjects, executed to a HD,
> upscaled, low-CFG-naturalistic finish. The craft corrections above + a named **bas-relief / sculptural**
> style are the concrete incorporations.
