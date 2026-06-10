# ComfyUI model guide — which asset for which intent

> The canonical, evidence-based asset-selection reference for PRESSROOM's generative raster path. **One
> source, referenced not forked:** both [`handler-comfyui`](../agents/handler-comfyui.md) (which renders) and
> the [`illustrator`](../skills/illustrator/SKILL.md) (which routes) consult this — neither hardcodes asset
> choices. Names below are **verbatim live filenames** enumerated from the rig's `/object_info` (mind the
> `LIGHTNING/` and `SDXL/` subfolder prefixes — they are part of the `ckpt_name`/`lora_name`). The handler
> still lists assets live; this guide tells it *which* to pick, and pairs with the
> [prompt-craft](../skills/illustrator/references/prompt-craft.md) and
> [workflow-strategy](../skills/illustrator/references/workflow-strategy.md) references it points at.
>
> **Backend:** `${PRESSROOM_COMFYUI_URL:-http://10.10.10.163:8188}` (RTX 3090 24 GB; 89 checkpoints,
> 239 LoRAs, 24 upscalers, Impact-Pack/IPAdapter/FreeU/LatentUpscale present).

## How to use it (the handler's decision)
1. Read the SPEC's `intent` → map to an **intent class** below.
2. Take the **top asset** for that class present in the live list (copy the exact name verbatim, incl. any
   `SDXL/` prefix). Set it into the template's `CheckpointLoaderSimple.ckpt_name` before submit.
3. Use the class's **settings** (steps/cfg/sampler/res) and, where named, its **stage recipe** and **LoRAs**.
4. If the class is flagged **"route to vector"**, do **not** use ComfyUI — tell the orchestrator to use a
   vector handler (`handler-chart`/`handler-graphviz`). This is canonical and durable; never route here.

## The award bar (scores are calibrated to it)
Every fitness score in this marketplace is judged against **award-winning reference work**, not "good enough
for a doc." A **95 means award-tier**, not "usable"; a clean, on-prompt, artifact-free image with no focal
point and flat light is the *entry-level trap* (~70s), not a pass. The multi-stage recipes below exist to
clear that bar. The bar itself — and the hard failure modes that cap a score regardless of polish — live in
the [image-aesthetic canon](../skills/design-reviewer/references/image-aesthetic-canon.md).

## Intent → recommended asset (decision table)

| Intent class | Examples | Top pick (live name) · backups | Settings | LoRA / stage note |
|---|---|---|---|---|
| **Photoreal scene** | hero shots, atmospheric environments | `juggernautXL_version2.safetensors` · `epicrealism_naturalSinRC1VAE` · `realisticStockPhoto_v10` · `cyberrealistic_v31` | 1216×832 · 30 · cfg 6 · dpmpp_2m karras | recipe A — base→latent-hires→UltraSharp; LoRA usually none |
| **Photoreal portrait / character** | faces, people, lifestyle | `nightvisionXLPhotorealisticPortrait_v0743ReleaseBakedvae` · `realisticStockPhoto_v10` · `fullyREALXL_v90Vividreal` | 832×1216 · 30 · cfg 6 · dpmpp_2m karras | recipe E — **FaceDetailer mandatory**; `perfecteyes-000007`@0.4 |
| **Stylized / concept / game-art** | painterly, dreamy, concept | `dynavisionXLAllInOneStylized_beta0411Bakedvae` · `protovisionXLHighFidelity3D_beta0520Bakedvae` · `zavychromaxl_v12` · `crystalClearXL_ccxl` | 1344×768 · 30 · cfg 7 · dpmpp_2m karras | recipe B — `xl_more_art-full_v1`@0.6 + 1 artist anchor; **FreeU V2** |
| **Landscape / nature** | vistas, matte, backgrounds | `juggernautXL_version2` (native res) · `realcartoon3d_v8` (SD1.5) · `epicdream_lullaby` (SD1.5) | XL 1344×768 / SD1.5 768×512 · 28–30 · cfg 6 · dpmpp_2m karras | recipe C — Remacri upscale; **no FaceDetailer**; bright-sky → §dark |
| **Anime / stylized character** | anime, cel | `animagineXL_v10` · `counterfeitxl_v10` · `bluePencilXL_v050` · `nijianimesdxl_v10` | 832×1216 · 30 · cfg 7 · dpmpp_2m karras | tag-style prompt; `RealESRGAN_x4plus_anime_6B` upscaler |
| **Cartoon / mascot** | logos, friendly mascots | `modernDisneyXL_v11` · `dynavisionXL…` · `samaritan3dCartoon_v40SDXL` · `realcartoonXL_v3` | 1216×832 · 28–30 · cfg 6.5 · dpmpp_2m karras | mascots bake a bright ground → cut out before embed |
| **Fast / draft / lightning** | A/B challengers, high-iteration | `LIGHTNING/juggernautXL_v9Rdphoto2Lightning` · `LIGHTNING/RealitiesEdgeXLLIGHTNING_V7Bakedvae` | 1216×832 · **6 · cfg ~2 · dpmpp_sde sgm_uniform** | tied best-overall at 6 steps — a credible *final* for mascot/office |
| **Dark-key hero** (README mastheads) | text-free, people-free dark assets | `dynavisionXLAllInOneStylized…` · `zavychromaxl_v12` | 1344×768 · 32 · cfg 6.5 · dpmpp_2m karras | recipe F — `lowkey_v1.1`@0.6 + `LowRA`@0.4 + void-bg steer; **the gold** |
| **Inpaint / background fix** | object removal, dark-ground repaint | `LIGHTNING/dreamshaperXL_lightningInpaint` · `epicrealism_v10-inpainting` | per base | repaint a bright ground dark before keying a hero |
| **Chart / infographic / text** | `line-goes-up`, labelled diagrams | **route to vector** (`handler-chart`/`handler-graphviz`) | — | **CONFIRMED:** best score was 72; every model baked gibberish text. Diffusion cannot render legible labels — never route here. |

## Upscale models — the 4–5 to actually reach for (24 present)

| Live name | Best for | Note |
|---|---|---|
| `ESRGAN/4x-UltraSharp.pth` | **default photoreal / mixed** | community default; maximum sharpness, can over-sharpen skin |
| `ESRGAN/4x_foolhardy_Remacri.pth` | **photoreal where UltraSharp over-sharpens** | softer, natural texture — the "less crunchy" choice for skin/landscape |
| `ESRGAN/4x_NMKD-Superscale-SP_178000_G.pth` | **balanced general** | fewer halos; crisp without artefacts |
| `ESRGAN/4xLSDIRplus.pth` (+ `4xLSDIRplusR.pth`) | **high-fidelity detail restore** | modern LSDIR; `…R` denoises/restores more |
| `RealESRGAN/RealESRGAN_x4plus_anime_6B.pth` | **anime / flat illustration** | preserves line art; `realesr-animevideov3.pth` for cel |
| `SwinIR/SwinIR_4x.pth` | **max fidelity, slow** | transformer; heavier, top scores for digital art |

> Skip for finals: `BSRGAN.pth`, `DF2K*.pth`, `ESRGAN_4x.pth`, classical-SwinIR-M — older/noisier than the
> picks above. The six listed cover every real need.

## Notable LoRAs (live names, by intent)
- **Dark-key / mood (the hero gold):** `lowkey_v1.1.safetensors`, `LowRA.safetensors`, `Silhouette.safetensors`,
  `Night.safetensors`, `Dark_Novel.safetensors`, `NeonNight.safetensors`, `luts-000004.safetensors` (grade).
- **Painterly / illustration:** `xl_more_art-full_v1.safetensors`, `greg_rutkowski_xl_2.safetensors`,
  `ChristopherBalaskas.safetensors`, `CraigMullins.safetensors`, `ClassipeintXL2.1.safetensors`.
- **Concept / sci-fi env:** `Sci-fi_Environments_sdxl.safetensors`, `21Stalenhag.safetensors`,
  `Beeple(MikeWinkelmann).safetensors`, `Microverse_Creator_sdxl.safetensors`.
- **Photo quality / detail:** `SDXL/sdxl_photorealistic_slider_v1-0.safetensors`, `perfecteyes-000007.safetensors`.
- **3D / clay / toy (mascot):** `3DMM_V12.safetensors`, `blindbox_v1_mix.safetensors`, `nendoroid_xl_v7.safetensors`.

> **No `lcm_lora_sdxl` on the rig** — the LCM example graph references it but it is **not** in our library.
> Use the native `LIGHTNING/*` checkpoints for the fast lane, never an LCM-LoRA path. Filename collisions
> exist (`MechStyle V1`/`MechStyle-V1`, several `pokemon*`) — always copy the exact live string.

## Failure modes (per base / model)
- **SD1.5 hands & eyes** — mushy/soft fingers at scale (the artifact gate). For people/portraits prefer **SDXL**
  photoreal; if SD1.5, **inspect hands** and run FaceDetailer before shipping.
- **SDXL base + refiner — WORKS and is maintainer-preferred** (corrects an earlier wrong note).
  `SDXL/sd_xl_base_1.0.safetensors` loads fine and is the maintainer's *primary* base (45× across the curated
  favourites); `SDXL/sd_xl_refiner_1.0` is used with it. The proper SDXL dual-conditioning flow
  (`CLIPTextEncodeSDXL` / `CLIPTextEncodeSDXLRefiner`, `KSamplerAdvanced` step-split) is a first-class
  pipeline here. Community fine-tunes (Juggernaut/NightVision/DynaVision/oasis) also bake refiner-grade detail,
  so a refiner is optional — but it is **not** "dead". See the maintainer-proven recipes below.
- **Bright-ground landscapes/mascots** — these bake a bright sky/background that fights a dark page. Crop,
  subject-isolate, or dark-key-steer before embedding (see §dark-key + the
  [dark-mode canon](../skills/illustrator/references/dark-mode-canon.md)).
- **Lightning's micro-detail trade** — 6-step Lightning checkpoints are fast and ship-worthy for mascot/office,
  but lose fine micro-detail vs a 30-step base→hires pass. Use Lightning for high-iteration/drafts and as a
  *final* only where micro-texture isn't the point; reach for the full base path for photoreal heroes.
- **Legacy SD2.x** (`512-base-ema.ckpt`, `768-v-ema.ckpt`, `v2-1_768-ema-pruned`) — present but obsolete; the
  official demo graphs ship them only as historical defaults. Avoid for finals.

## Multi-stage gains — what each stage adds, and when it's NOT worth it

| Stage (nodes) | Adds | Skip when |
|---|---|---|
| **Latent hires-fix** (`LatentUpscaleBy` + 2nd KSampler @ denoise 0.4–0.5) | **biggest lever** — coherent higher res *and* invented micro-detail | never on a final hero; keep denoise ≤0.45 when likeness/composition must hold (details drift) |
| **Upscale-model** (`UpscaleModelLoader` + `ImageUpscaleWithModel`) | edge crispness; **no new structure** | as the *only* upscale on a soft base (sharpens softness into crunch) — run it *after* latent hires or as a pure final resize |
| **LoRA stack** (`LoraLoader` chaining) | style/subject control | the base already nails the look — every LoRA narrows the model and can fight the prompt; ≥3 high-weight LoRAs go incoherent |
| **FaceDetailer** (Impact-Pack) | sharp on-model faces — **mandatory for portraits** | landscapes / abstract / dark-key heroes (no faces) — it wastes time and can hallucinate a face |
| **FreeU V2** (b1 1.3/b2 1.4/s1 0.9/s2 0.2) | composition depth + detail, free | realistic photo models — it **over-contrasts** them; use on stylized/anime/painterly only |
| **Refiner** (`KSamplerAdvanced` step-split, base→refiner) | micro-detail polish on the sd_xl_base_1.0 path — **maintainer-used** | when a fine-tune already bakes refiner-grade detail (Juggernaut/oasis) — then a latent-hires pass is simpler. Optional, not dead. |
| **UltimateSDUpscale** (tiled, `SwinIR_4x`, denoise ~0.25) | **maintainer's preferred HD finish** — tiled re-detail to 4K+ without OOM | below ~2K output (a single latent-hires is simpler/cleaner) |
| **unCLIP REIMAGINE** (`CLIPVisionLoader` g + `CLIPVisionEncode` + `unCLIPConditioning`) | steer a generation by a **reference image's look** — the maintainer's signature move | when there is no reference look to carry; a text prompt suffices |

Full per-stage node wiring and the genre→pipeline decision tree:
[workflow-strategy](../skills/illustrator/references/workflow-strategy.md). Prompt structure, negatives, and
the dark-key recipe: [prompt-craft](../skills/illustrator/references/prompt-craft.md).

## Base-level routing rules (durable findings)
- **Diffusion cannot render legible chart text or axes.** `line-goes-up` peaked at **72**; every model baked
  gibberish glyphs. → labelled-infographic intent **routes to vector** (`handler-chart`/`handler-graphviz`),
  never ComfyUI. **The single most important rule.**
- **Scenes & landscapes are the universal strength** (90–100 nearly everywhere) — even cheap SD1.5 excels;
  reach for SDXL only for native resolution.
- **People/office is where SD1.5 hands fail** — prefer SDXL photoreal and **inspect hands** before shipping.
- **Lightning is not just a draft engine** — `LIGHTNING/juggernautXL_v9Rdphoto2Lightning` tied best-overall at
  **6 steps**; default fast lane *and* a credible final for mascot/office.
- **Bright grounds fight dark docs** — crop or cut out before embedding on a dark page.
- **SDXL base+refiner works** — `SDXL/sd_xl_base_1.0` is the maintainer's primary base; use the refiner
  (`SDXL/sd_xl_refiner_1.0`) or a latent-hires pass for the detail finish (both are fine). The base, refiner,
  and `svd_xt_1_1` are the **only** checkpoints still under the `SDXL/` subfolder — see the path rule below.

## Maintainer-proven recipes (mined from the curated favourites — these supersede the defaults)

The marketplace's *measured-on-this-rig* preferences (see `doc/image-craft-study/rig-inventory/maintainer-recipes.md`):
- **Samplers/scheduler:** `dpmpp_sde_gpu` and `dpmpp_3m_sde_gpu` on **karras** (the SDE-GPU family) — not
  `dpmpp_2m`. Upscale passes use `euler` / `normal`.
- **CFG is LOW for SDXL: 3.5–4.5** (naturalism), with **high steps** (50–60 for a hero base pass, ~31 for
  refine passes) — not cfg 6–7.
- **HD finish:** `UltimateSDUpscale` with the **`SwinIR_4x`** model, tiled 1024, denoise ~0.25.
- **The REIMAGINE flow:** `sd_xl_base_1.0` + unCLIP image-prompt (`clip_vision_g.safetensors`) → refine →
  UltimateSDUpscale (the 42-node `IRU` premium graph).
- **Favoured checkpoints (now at the checkpoints *root*, no subfolder):** `oasisSDXL_v10` (workhorse),
  `crystalClearXL_ccxl` (crisp), `LahCuteCartoonSDXL_alpha` / `xlYamersCartoonArcadia_v1` (cute),
  `animagineXL_v10` / `nijianimesdxl_v10` (anime), `nigi-cyber-umaaji` (stylised);
  favoured LoRA **`BAS-RELIEF.safetensors`** (the sculptural-relief signature) + `xl_more_art-full_v1`.

> **⚠ Path rule — list, don't assume.** The rig was reorganised: every fine-tune was moved to the checkpoints
> **root** (a name that *was* `SDXL_2/modernDisneyXL_v11` or `SDXL/oasisSDXL_v10` is now the **bare**
> `modernDisneyXL_v11.safetensors` / `oasisSDXL_v10.safetensors`). The **only** survivors of the `SDXL/`
> subfolder are `SDXL/sd_xl_base_1.0`, `SDXL/sd_xl_refiner_1.0`, `SDXL/svd_xt_1_1`; Lightning models keep the
> `LIGHTNING/` prefix. **Never hardcode a subfolder** — the handler must read `ckpt_name` from live
> `/object_info` (`CheckpointLoaderSimple`) and copy the exact string ComfyUI returns, so a future move can't
> break a recipe. The names above are the *current* truth; `/object_info` is the *authoritative* one.

## Settings cheatsheet
| Base | Resolution | Steps | CFG | Sampler / scheduler |
|---|---|---|---|---|
| **SDXL (maintainer)** | nearest-SDXL (RecommendedResCalc) | **50–60 base / ~31 refine** | **3.5–4.5** | **dpmpp_3m_sde_gpu / dpmpp_sde_gpu · karras** |
| SDXL (generic) | 1216×832 / 1344×768 | 28–32 | 5.5–7 | dpmpp_2m / karras |
| SD1.5 | 768×512 (landscape) | 25–28 | 6–7 | dpmpp_2m / karras |
| SDXL-Lightning | 1216×832 | 6 | ~2 | dpmpp_sde / sgm_uniform |
| UltimateSDUpscale finish | tile 1024 → 4K | 32 | — | euler / normal · denoise 0.25 |

## Empirical craft-study findings (controlled A/B, 2026-06-10)

The [`craft-study`](../skills/craft-study/SKILL.md) ran a **controlled single-variable A/B** per objective
(baseline vs one named stage, sharing ckpt/prompt/seed/base-res) and scored each with the adversarial image
reviewer. The gains below are **visible, attributable, reproducible** — not seed luck. (Full evidence:
`doc/image-craft-study/craft/catalog.md`.)

| Objective (ckpt) | Stage tested | Verdict | What the evidence showed |
|---|---|---|---|
| **portrait** (`nightvisionXLPhotorealisticPortrait`) | latent hires-fix @0.45 denoise | **REGRESSION 72→66** | The re-detail pass **scrubbed** close-up skin/hair micro-detail into smooth "AI skin" (high-pass energy −17…−20% on eyes/beard/face). A canonical latent-hires failure on tight faces. |
| **landscape** (`crystalClearXL_ccxl`) | latent hires-fix @0.45 | gain 79→83 | Resolves smeared mid/foreground into real micro-texture (conifers, rock facets, layered fog). Real but **incremental**; does **not** author the depth gradient (a base property). |
| **marketing-hero** (`foddaxlPhotorealism_v51`) | latent hires-fix @0.45 | gain 68→74 | **Region-selective** lift: +12.5% micro-texture on marble veining / crema, ~0 on the flat wall (so not a placebo global sharpen). |
| **dark-key** (`epicrealism_naturalSinRC1VAE`, SD1.5) | LoRA stack `lowkey_v1.1`@0.8 + `LowRA`@0.6 | **gain 62→81** | Converts an even mid-tone portrait into **true low-key tenebrist chiaroscuro** — background to near-black, motivated key carving form. The strongest gain. |
| **world-axis** (`reproductionSDXL_2v12`) | regional **tricomposite** | **gain 68→92** | Coherent vertical world-axis (cosmic vortex → cracked-earth dome → warm profile figure) with a working cool→warm depth descent; three layered, feathered planes (richness 3→5). |

**Actionable rules learned:**
- **Do NOT blanket-apply latent hires-fix to close-up portraits** — at 0.45 denoise it *removes* skin/hair
  fidelity. For faces, prefer a **lower re-detail denoise (~0.25–0.35)**, or route detail through
  **FaceDetailer** (Impact Pack) rather than a full-frame latent upscale.
- **Hires-fix pays on textured/atmospheric subjects** (landscape, product surfaces) where there is real
  micro-structure to resolve — but the gain is incremental, so spend it where it shows.
- **The dark-key LoRA stack is a genuine craft tool**, not a gimmick: reach for `lowkey_v1.1 + LowRA` when the
  brief calls for low-key/chiaroscuro/film-noir lighting the base model renders too evenly.
- **Tricomposite is the strongest single technique** for layered, vertical-world-axis compositions — use it
  when the brief is compositional (a coherent top→bottom journey) rather than a single subject.
