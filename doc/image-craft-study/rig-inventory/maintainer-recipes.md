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
- Checkpoint names carry the **`SDXL/` subfolder prefix** (`SDXL/oasisSDXL_v10.safetensors`) — copy verbatim.

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

## Favoured checkpoints (by use, on this rig — copy verbatim)

`SDXL/sd_xl_base_1.0` (+ `sd_xl_refiner_1.0`) · `SDXL/oasisSDXL_v10` (versatile workhorse) ·
`SDXL/crystalClearXL_ccxl` (crisp photoreal) · `SDXL/LahCuteCartoonSDXL_alpha` & `SDXL/xlYamersCartoonArcadia_v1`
(cute/cartoon) · `SDXL/animagineXL_v10` & `SDXL/nijianimesdxl_v10` (anime) · `nigi-cyber-umaaji` & `nigi3d_v20`
(stylised) · `SDXL/copaxTimelessxlSDXL1_colorfulV2`. Favoured LoRA: **`BAS-RELIEF.safetensors`**,
`SDXL/xl_more_art-full_v1` (detail/quality).

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
