# Craft evidence — award-quality images on the 10.10.10.163 ComfyUI rig

> **Host-grounded** reference for producing award-quality images on **our specific rig**
> (`http://10.10.10.163:8188`, RTX 3090 24 GB). Every asset named below was enumerated **live**
> from the backend's `/object_info` (read-only) on 2026-06-09, so it is authoritative for what is
> actually loadable. Web reputation is cross-referenced and cited. This grounds the rewrite of
> `comfyui-model-guide.md` + the prompt-craft + workflow-strategy canon.
>
> **Live enumeration (re-run to refresh):**
> ```
> curl -s $URL/object_info/CheckpointLoaderSimple | python3 -c "import sys,json;print('\n'.join(json.load(sys.stdin)['CheckpointLoaderSimple']['input']['required']['ckpt_name'][0]))"
> curl -s $URL/object_info/LoraLoader        # .LoraLoader.input.required.lora_name[0]   — 239
> curl -s $URL/object_info/UpscaleModelLoader # .input.required.model_name → COMBO.options — 24
> curl -s $URL/object_info/KSampler          # .sampler_name[0] / .scheduler[0]
> ```
> **Rig facts:** 89 checkpoints, 239 LoRAs, 24 upscale models, 1969 node types incl. Impact-Pack
> (FaceDetailer/UltimateSDUpscale), IPAdapter, FreeU, TiledKSampler, LatentUpscale. Schedulers include
> `karras, sgm_uniform, exponential, simple, normal, beta, kl_optimal`. The full modern sampler set is
> present (`dpmpp_2m`, `dpmpp_3m_sde`, `dpmpp_sde`, `euler_ancestral`, `lcm`, `uni_pc`, `res_multistep`, …).

---

## 1. ASSET SHORTLIST — strong picks from OUR catalogue

All names below are **verbatim from the live list** (mind the `LIGHTNING/` and `SDXL/` subfolder prefixes —
they are part of the `ckpt_name`).

### Checkpoints — best pick per use

| Use | Top pick (rig name) | Backups on rig | Why / web reputation |
|---|---|---|---|
| **Photoreal scene** | `juggernautXL_version2.safetensors` | `epicrealism_naturalSinRC1VAE.safetensors`, `realisticStockPhoto_v10.safetensors`, `cyberrealistic_v31.safetensors`, `foddaxlPhotorealism_v51.safetensors`, `sdxlYamersRealism_version2.safetensors` | Juggernaut XL is the community default photoreal SDXL base (Civitai's most-downloaded realism XL line); native 1024px, robust anatomy. Our model-survey scored `juggernautXL_v2` 100 on scenes. `epicrealism` (SD1.5) is the cheapest 98-scene engine for crops. |
| **Photoreal portrait / character** | `nightvisionXLPhotorealisticPortrait_v0743ReleaseBakedvae.safetensors` | `realisticStockPhoto_v10.safetensors`, `fullyREALXL_v90Vividreal.safetensors`, `7Of9_v20.safetensors`, `epicrealism_naturalSinRC1VAE.safetensors` | Purpose-trained on portraits; pair with **FaceDetailer** (below). For people prefer SDXL — SD1.5 hands/eyes go mushy at scale (our artifact gate). |
| **Stylized / concept / game-art** | `dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors` | `protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors`, `zavychromaxl_v12.safetensors`, `crystalClearXL_ccxl.safetensors`, `rundiffusionXL_beta.safetensors`, `sdxlEvolvedAesthetic_v10.safetensors` | DynaVision/ProtoVision are the stylized-3D concept staples; ZavyChromaXL is a top-rated artistic/fantasy XL. Our survey: dynavision/protovision = 96–97 mascot, 97–100 scenes. |
| **Landscape / scene / matte** | `juggernautXL_version2.safetensors` | `epicdream_lullaby.safetensors` (SD1.5), `realcartoon3d_v8.safetensors` (SD1.5, survey 100/100), `pixelwave_02.safetensors`, `novaPrimeXL_v10.safetensors` | Landscapes are the universal strength (90–100 nearly everywhere); reach for XL only for native res. **Warning:** these bake a bright sky → see §5 for dark-doc handling. |
| **Anime / stylized character** | `animagineXL_v10.safetensors` | `counterfeitxl_v10.safetensors`, `bluePencilXL_v050.safetensors`, `sdxlYamersAnime_stageAnima.safetensors`, `nijianimesdxl_v10.safetensors` | Animagine XL is the reference anime-XL base; tag-style prompting. |
| **Cartoon / mascot (friendly)** | `modernDisneyXL_v11.safetensors` | `samaritan3dCartoon_v40SDXL.safetensors`, `realcartoonXL_v3.safetensors`, `xlYamersCartoonArcadia_v1.safetensors`, `LahCuteCartoonSDXL_alpha.safetensors` | Survey: modernDisneyXL 94 mascot / 97 landscape. |
| **Fast / draft / lightning** | `LIGHTNING/juggernautXL_v9Rdphoto2Lightning.safetensors` | `LIGHTNING/RealitiesEdgeXLLIGHTNING_V7Bakedvae.safetensors`, `LIGHTNING/airtistRealisticXL_v50Lightning.safetensors`, `LIGHTNING/dreamshaperXL_lightningInpaint.safetensors` | Juggernaut-Lightning tied **best overall (87 avg) at 6 steps** in our survey — a credible *final* for mascots/office, not just a draft. **6 steps · cfg ~2 · dpmpp_sde / sgm_uniform.** |
| **Inpaint / outpaint** | `LIGHTNING/dreamshaperXL_lightningInpaint.safetensors` | `epicrealism_v10-inpainting.safetensors`, `dreamshaper_8Inpainting.safetensors`, `512-inpainting-ema.safetensors` | dedicated inpaint heads for clean background fixes / object removal. |

> **Avoid for finals:** `512-base-ema.ckpt`, `768-v-ema.ckpt`, `v2-1_768-ema-pruned` (legacy SD2.x —
> present but obsolete; the canonical hires/esrgan demo graphs use them only because that's what the
> official examples shipped with). `SDXL/sd_xl_base_1.0.safetensors` is **listed but fails to load** via the
> API (subfolder quirk) — use the named fine-tunes instead. `SDXL/sd_xl_refiner_1.0.safetensors` **does**
> load and is the only true SDXL refiner head on the rig.

### Upscale models — the 4–5 to actually reach for (24 present)

| Rig name | Best for | Reputation |
|---|---|---|
| `ESRGAN/4x-UltraSharp.pth` | **default photoreal / mixed** | The community default. Documented training (150k iters, RAW + Adobe-MIT5K + DIV2K), JPEG-optimised, maximum sharpness. Cross-ref: aimodels.fyi, upscale.wiki. Slightly aggressive — can over-sharpen skin. |
| `ESRGAN/4x_foolhardy_Remacri.pth` | **photoreal where UltraSharp over-sharpens** | Softer, more natural texture; the standard "less crunchy" alternative to UltraSharp for skin/landscape. |
| `ESRGAN/4x_NMKD-Superscale-SP_178000_G.pth` | **balanced general** | NMKD project; solid all-rounder, fewer halos than UltraSharp; good when you want crispness without artefacts. |
| `ESRGAN/4xLSDIRplus.pth` (+ `4xLSDIRplusR.pth`) | **high-fidelity detail restore** | LSDIR-trained, modern, strong real-photo detail; `…R` variant restores/denoises more. |
| `RealESRGAN/RealESRGAN_x4plus_anime_6B.pth` | **anime / flat illustration** | The canonical anime upscaler — preserves line art, kills JPEG mush. Use `realesr-animevideov3.pth` for cel/animation. |
| `RealESRGAN/RealESRGAN_x4plus.pth` | **safe photoreal fallback** | The conservative baseline (the official `2_pass…esrgan` demo uses it); 9.2/10 overall in 2025 round-ups. |
| `SwinIR/SwinIR_4x.pth` | **max fidelity, slow** | Transformer upscaler, top quality scores (9.7–9.8) for digital art; heavier. `2xLexicaSwinIR.pth` for 2× gentle passes. |

> Skip on this rig for finals: `BSRGAN.pth`, `DF2K.pth`/`DF2K_JPEG.pth`, `ESRGAN_4x.pth`,
> `001_classicalSR…SwinIR-M` (older/sharper-but-noisier than the picks above) — they exist but UltraSharp /
> Remacri / NMKD-Superscale / anime-6B cover every real need.

### Notable style / quality LoRAs present (real filenames)

The 239-LoRA library is mostly **style and subject** packs. High-value picks by intent:

- **Painterly / illustration style:** `greg_rutkowski_xl_2.safetensors`, `xl_more_art-full_v1.safetensors`
  (also `SDXL/xl_more_art-full_v1.safetensors`), `John Singer Sargent Style.safetensors`,
  `CraigMullins.safetensors`, `AlessandroGottardo.safetensors`, `IrisCompietStyle.safetensors`,
  `ClassipeintXL2.1.safetensors`, `baroqueAI.safetensors`.
- **Concept / sci-fi environment:** `Sci-fi_Environments_sdxl.safetensors`,
  `Stalenhag`→`21Stalenhag.safetensors`, `Beeple(MikeWinkelmann).safetensors`,
  `ChristopherBalaskas.safetensors`, `AngusMcKie.safetensors`, `SpaceshipAI.safetensors`,
  `Microverse_Creator_sdxl.safetensors`.
- **Photo quality / detail sliders:** `SDXL/sdxl_photorealistic_slider_v1-0.safetensors`
  (also unprefixed `sdxl_photorealistic_slider_v1-0.safetensors`), `perfecteyes-000007.safetensors`,
  `LowRA.safetensors` (low-light/darkening — **directly useful for dark-key, see §5**),
  `lowkey_v1.1.safetensors` (**low-key lighting — the single most on-target LoRA for our heroes**),
  `luts-000004.safetensors` (cinematic colour grade), `add-detail`-style via `xl_more_art-full_v1`.
- **Lighting / mood:** `lowkey_v1.1.safetensors`, `LowRA.safetensors`, `NeonNight.safetensors`,
  `Night.safetensors`, `Dark_Novel.safetensors`, `Silhouette.safetensors`, `Hologram-v1.safetensors`.
- **3D / clay / toy (mascot):** `3DMM_V12.safetensors`, `SDXL/3DMM_XL_V13.safetensors`,
  `blindbox_v1_mix.safetensors`, `nendoroid_xl_v7.safetensors`, `CLAYMATION.safetensors`,
  `VoxelXL_v1.safetensors`.
- **Graphic / logo / line:** `LogoRedmond_LogoRedAF.safetensors`, `vntg-line-art-v2.safetensors`,
  `InkPunk XL - Alpha.safetensors`, `zyd232_InkStyle_v1_0.safetensors`, `SDXL/pixel-art-xl-v1.1.safetensors`.

> **No `lcm_lora_sdxl` on the rig** — the LCM example graph references it but it is **not** in our
> library, so prefer the native `LIGHTNING/*` checkpoints for the fast lane rather than an LCM-LoRA path.
> Filename collisions exist (`MechStyle V1` vs `MechStyle-V1`, `Venator v1`/`v2.0`, several `pokemon*`) —
> always copy the exact string from the live list.

---

## 2. PER-GENRE MULTI-STAGE RECIPES

All recipes are tuned for the **3090's 24 GB** (headroom for a 2-pass + FaceDetailer at 1024-base).
Stage syntax: `base → [refiner] → [hires/latent] → [model-upscale] → [LoRA] → [FaceDetailer]`.
Graph wiring is exactly as in the canonical examples (cited per stage in §3).

### A. Photoreal-scene
- **Base:** `juggernautXL_version2.safetensors` @ **1216×832** (or 832×1216), **30 steps · cfg 6 ·
  dpmpp_2m · karras · denoise 1.0**.
- **Hires (latent):** `LatentUpscaleBy` ×1.5 (bislerp) → 2nd KSampler **12 steps · cfg 5.5 ·
  dpmpp_2m · karras · denoise 0.45**. Coherent res + invented micro-detail.
- **Model-upscale (optional finish):** `ImageUpscaleWithModel` with `ESRGAN/4x-UltraSharp.pth`, then
  `ImageScale` down to target — crispness pass.
- **LoRA:** none, or `SDXL/sdxl_photorealistic_slider_v1-0` @ 0.3–0.4 for extra grain/realism.
- **FaceDetailer:** only if a person is in frame.
- **Rationale:** XL base gives the native-res scene; latent hires is where photoreal "pops" (texture,
  depth); UltraSharp adds the final bite. Refiner is *not* needed — the fine-tune already bakes detail.

### B. Stylized-concept (game-art / painterly)
- **Base:** `dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors` (or `zavychromaxl_v12`) @
  **1344×768**, **30 steps · cfg 7 · dpmpp_2m · karras**.
- **LoRA stack:** `xl_more_art-full_v1` @ 0.6 **+** one artist anchor (`greg_rutkowski_xl_2` @ 0.5 **or**
  `ChristopherBalaskas` @ 0.5). Stack rule: drop each to 0.5–0.6 when combining (§3).
- **FreeU (V2):** **b1 1.3 / b2 1.4 / s1 0.9 / s2 0.2** — stylized models gain composition/detail here.
- **Hires (latent) ×1.5 · denoise 0.4–0.5**, then optional `4x_NMKD-Superscale`.
- **Rationale:** concept art lives on style LoRAs + FreeU; latent hires keeps brushwork coherent.

### C. Landscape / scene
- **Base:** `juggernautXL_version2` (XL native res) **or** `realcartoon3d_v8`/`epicdream_lullaby` (SD1.5,
  cheaper, survey 100) @ **XL 1344×768 / SD1.5 768×512**, **28–30 steps · cfg 6 · dpmpp_2m · karras**.
- **Hires (ESRGAN path):** `ImageUpscaleWithModel` `ESRGAN/4x_foolhardy_Remacri.pth` (natural foliage/sky)
  → light 2nd-pass KSampler **denoise 0.35** to re-detail.
- **LoRA:** `booscapes.safetensors`, `VerticalLandscapes.safetensors`, or
  `Sci-fi_Environments_sdxl` @ 0.6 as appropriate.
- **No FaceDetailer.** **Dark-doc:** crop or low-key steer (§5) — landscapes bake bright skies.
- **Rationale:** Remacri keeps organic texture from going crunchy; landscapes need crispness, not face work.

### D. Action / dynamic
- **Base:** `juggernautXL_version2` (anatomy) or `dynavisionXL` (stylized) @ **1216×832**,
  **30 steps · cfg 6.5 · dpmpp_2m_sde · karras** (sde sampler handles motion energy / particles well).
- **Prompt:** motion-streak / panning-blur / frozen-freeze cues + a strong directional line (per corpus
  `action-01/02`: decisive-moment, implied trajectory).
- **LoRA:** `on_fire10`, `splashes_v.1.1`, `rageMode_v1` @ 0.5–0.7 for effects; `Cinephile_Beta_XL` for grade.
- **Hires (latent) ×1.5 · denoise 0.45**; **FaceDetailer** if a hero face is visible.
- **Rationale:** sde sampler + effect LoRAs deliver kinetic energy; latent hires keeps motion coherent.

### E. Character / portrait
- **Base:** `nightvisionXLPhotorealisticPortrait_v0743…` (photoreal) or `animagineXL_v10` (anime) @
  **832×1216**, **30 steps · cfg 6 (photoreal) / 7 (anime) · dpmpp_2m · karras**.
- **LoRA:** subject/style LoRA @ **0.7 solo, 0.6 when stacked**; `perfecteyes-000007` @ 0.4 for eyes.
- **Hires (latent) ×1.5 · denoise 0.4** (keep low — high denoise drifts likeness).
- **FaceDetailer (Impact-Pack):** **denoise 0.4–0.5**, `bbox_crop_factor` ~3, modest `bbox_dilation`,
  feather the edges. Two-pass pattern: one before upscale (structure), one after at **denoise 0.3** (detail).
- **Rationale:** portraits are the one genre where FaceDetailer is *mandatory* for award quality; refiner
  optional (`SDXL/sd_xl_refiner_1.0` 20→25 of 25 steps) only on the pure `sd_xl_base` path.

### F. Hero-masthead (dark-key — our marketplace README use)
- **Base:** `dynavisionXLAllInOneStylized…` or `zavychromaxl_v12` @ **1344×768**,
  **32 steps · cfg 6.5 · dpmpp_2m · karras**.
- **LoRA:** `lowkey_v1.1.safetensors` @ 0.6 **+** `LowRA.safetensors` @ 0.4 (low-key/low-light anchors) —
  **the rig's two on-target dark-key LoRAs**. Optional `luts-000004` @ 0.3 for cinematic grade.
- **FreeU V2** (b1 1.3/b2 1.4/s1 0.9/s2 0.2) for composition depth.
- **Hires (latent) ×1.5 · denoise 0.4**, then `4x-UltraSharp` finish.
- **Prompt steering:** dark-key, low-key, single rim light, deep shadow, void/black background,
  centred negative space, **text-free, people-free** (§4/§5 negatives).
- **No FaceDetailer** (no people by design).
- **Rationale:** combine model + low-key LoRAs + composition steering so the hero reads as a
  transparent-feeling dark asset; see §5 for the reliable dark/text-free/people-free recipe.

---

## 3. TECHNIQUE GAINS — what each stage actually buys, and when it's not worth it

Grounded in the canonical graphs at
`doc/image-craft-study/workflows/raw/official/*.png` (read with `extract-workflow.py <file> prompt`).

- **SDXL refiner** *(micro-detail / texture polish).* The canonical
  `sdxl_sdxl_refiner_prompt_example.png` runs **two `KSamplerAdvanced`**: base
  `start 0 → end 20`, `add_noise enable`; refiner `start 20 → end 10000`, `add_noise disable` (25 total
  steps, euler, cfg 8) — i.e. base does ~80%, refiner finishes ~20% on a **separate prompt**. Web: the
  refiner improves eyes/skin/edges. **Not worth it** when you use a community fine-tune (Juggernaut,
  NightVision, DynaVision) — they already bake refiner-grade detail, and the only true refiner head on
  the rig (`SDXL/sd_xl_refiner_1.0`) is paired with base 1.0, which itself fails to load. **Use the refiner
  only on the literal base-1.0 path; otherwise spend the budget on hires + FaceDetailer.**
- **Hires-fix / latent-upscale** *(coherent higher res + new detail).* `2_pass_txt2img_hiresfix_latent`
  = `LatentUpscale` (nearest-exact) + 2nd KSampler **denoise 0.5**;
  `2_pass…latent_upscale_different_prompt_model` = `LatentUpscaleBy` bislerp ×1.5 + KSampler **denoise
  ~0.5**. This is the **biggest single quality lever** — it both raises resolution and *invents* coherent
  micro-detail. Denoise 0.4–0.5 is the sweet spot (web: TechTactician/Prompting-Pixels). **Not 1:1** with
  the first pass — details shift; keep denoise ≤0.45 when likeness/composition must hold.
- **Upscale-model (ESRGAN)** *(crispness, no new content).* `2_pass_txt2img_hiresfix_esrgan` =
  `UpscaleModelLoader` → `ImageUpscaleWithModel` → `ImageScale` → VAEEncode → 2nd KSampler **denoise 0.5**.
  Adds edge crispness/sharpening; **does not invent** structure. **Not worth it** as the *only* upscale on a
  soft base (it sharpens softness into crunch) — best **after** a latent hires pass, or as a pure final
  resize. Pick model by content: UltraSharp (sharp photoreal), Remacri (natural), anime-6B (line art).
- **UltimateSDUpscale** *(tiled high-res on 24 GB).* Tile-based SD pass; lets the 3090 reach 4K+ without
  OOM. Web (cubiq, comfyui.dev): **not for pixel-perfect** — even low denoise changes detail; pair with a
  **Tile ControlNet** + denoise 0.25–0.35 for "incredibly detailed and close to original." **Not worth it**
  below ~2K output — a single latent hires is simpler and cleaner.
- **LoRA** *(style / subject control).* `lora_lora` / `lora_lora_multiple` chain `LoraLoader` nodes
  model→model. Web consensus: **0.6–0.8 solo; drop to 0.5–0.6 each when stacking**; ≥3 high-strength LoRAs
  go incoherent; give the *primary* LoRA the higher weight, reduce `strength_clip` before `strength_model`
  if a LoRA hijacks the prompt; **validate each solo before stacking.** **Not worth it** when the base
  checkpoint already nails the look — every LoRA narrows the model and can fight the prompt.
- **FaceDetailer (Impact-Pack)** *(faces only).* Detect→crop→re-diffuse→paste. Web: **denoise ~0.5
  default**, `bbox_crop_factor` ~3, feather edges; **two-pass around the upscale** (pass 1 structure pre-up,
  pass 2 detail post-up @ denoise 0.3) is the high-end standard. **Mandatory** for portraits/people;
  **skip entirely** for landscapes, abstract, dark-key heroes (no faces) — it wastes time and can
  hallucinate a face into a non-face region.
- **FreeU (V2)** *(composition + detail, free).* SDXL: **b1 1.3 / b2 1.4 / s1 0.9 / s2 0.2** (CVPR-2024;
  Stable-Diffusion-Art). Backbone (b) = global composition, skip (s) = fine detail/colour. **Worth it** on
  stylized/anime/painterly. **Not worth it** on realistic photo models — it **over-contrasts** them
  (web: "using it in realistic models often increases contrast too much"). Verify before shipping.

---

## 4. PROMPT CRAFT

### Positive-prompt structure (SDXL = natural language, not SD1.5 tag soup)
Order, front-loaded (web: neurocanvas SDXL best-practices; SDXL reads natural phrases, 5–15 words/segment):
1. **Subject** — the one concrete thing, stated first ("a lone lighthouse on a basalt cliff").
2. **Descriptors** — material, age, state, action ("weathered, storm-battered, beam cutting the dark").
3. **Art-direction** — composition + medium ("low-angle wide shot, cinematic concept art, matte painting").
4. **Light** — the highest-leverage clause ("single warm rim light, deep shadow, chiaroscuro, golden hour").
5. **Lens / medium** — ("35 mm, shallow depth of field, anamorphic" / "oil on canvas, visible brushwork").
6. **Quality anchors** — a *short* tail: "highly detailed, sharp focus, professional." Legacy but harmless.

Anchor light + composition with **named theory** from our corpus (`CORPUS.md`): atmospheric perspective,
figure-ground, leading lines, focal hierarchy, rule-of-thirds, chiaroscuro/tenebrism, limited/complementary
palette, golden-hour/contre-jour rim light, negative space, S-curve. These are what actually moved the
award winners — not adjective piles.

### Negative-prompt strategy (SDXL needs *little*)
- Web consensus (Layer/neurocanvas): **SDXL needs short, concrete negatives** — sometimes performs *worse*
  with long lists. Use concrete visual artefacts SD actually learned: `blurry, watermark, text, signature,
  jpeg artifacts, lowres, oversaturated, deformed hands, extra fingers`.
- **Drop abstract junk** ("ugly", "bad", "masterpiece-negative") — SD was never trained on labelled "ugly",
  so it's a no-op token burning attention.
- **Never contradict the positive:** if the positive wants shadow/dark, do **not** put `dark`/`shadows` in
  the negative (web: it muddies the result) — see §5.

### Art-direction anchors that work (composition / light / colour)
- **Composition:** rule-of-thirds, leading lines, low/high angle, wide establishing shot, centred negative
  space, figure-ground separation, silhouette.
- **Light:** single key light, rim/contre-jour, volumetric haze, chiaroscuro, golden hour, low-key/high-key.
- **Colour:** limited palette, complementary accent, analogous, teal-and-orange, muted earth tones, cool
  shadow / warm key.

### Anti-patterns (cargo-cult / bloat)
- **Token piles:** `8k, 4k, uhd, hyperdetailed, ultra-realistic, trending on artstation, award-winning,
  masterpiece, best quality` stacked — dilutes attention; keep ≤4 quality words.
- **SD1.5 negative boilerplate on SDXL** (the 40-token `bad anatomy, extra limbs, …` wall) — counter-
  productive on XL.
- **Contradiction** (dark positive + dark negative), **duplicate concepts**, **fighting LoRAs** (style LoRA
  trigger + opposite style words), and **prompt > ~75 tokens of real content** (later tokens get ignored).

---

## 5. DARK-KEY / DOC-EMBED constraints (the README-hero recipe)

Goal: a **dark-key, transparent-feeling, text-free, people-free** asset that drops onto a dark page.

### Steer it in generation (cheapest, most reliable)
- **Positive (composition + light):** `dark-key, low-key lighting, single rim light, deep shadow,
  chiaroscuro, subject centred on a void black background, vast negative space, minimalist, cinematic,
  volumetric haze`. State **"black background / void / empty dark backdrop"** explicitly — it both darkens
  and isolates the subject (a built-in matte).
- **LoRA:** `lowkey_v1.1.safetensors` @ 0.6 **+** `LowRA.safetensors` @ 0.4 — the rig's two on-target dark
  LoRAs; optional `Silhouette.safetensors` for pure shape, `luts-000004` for grade.
- **Negative (the people/text/bright killers):** `text, words, letters, typography, watermark, signature,
  logo, caption, UI, person, people, human, face, crowd, bright background, white background, overexposed,
  high-key, busy background, clutter`.
- **Critical non-contradiction:** because the positive is dark, keep `dark`/`shadow`/`low-key` **out** of
  the negative (web-confirmed) — only negate the *bright/high-key* terms.
- **Settings:** cfg slightly higher (6.5–7) so the steering holds; `dpmpp_2m · karras`.

### Background handling / post-processing on our rig
- **Diffusion-side matte:** the explicit "void black background" prompt yields a near-uniform dark ground
  that reads as transparent on a dark doc — often enough, no cut-out needed.
- **Hard cut-out when needed:** the rig has 1969 node types — use a rembg / `RemoveBackground`-class node
  (Impact/`was`-style) or a **Mask → InvertMask → composite onto transparent** path, then save PNG with
  alpha. For a subject baked on a bright ground, run an inpaint head (`epicrealism_v10-inpainting` /
  `dreamshaperXL_lightningInpaint`) to repaint the background dark before keying.
- **Tone-match to the page:** apply `luts-000004` LoRA or a post `ImageBlend`/levels node to pull the
  black point down so the asset's ground matches the README's background value.
- **Never rely on diffusion for text** — our model survey confirmed *every* checkpoint bakes gibberish
  glyphs (`line-goes-up` peaked at 72). Keep heroes **text-free** and add any labels in the page/SVG layer,
  not in the image. This is the single hardest rule.

---

## Sources (web evidence cross-referenced)

- SDXL base+refiner & best-practice: followfoxai.substack.com (Part 3), neurocanvas.net/blog/sdxl-best-practices-guide, learn.runcomfy.com (mastering SDXL), github.com/SeargeDP/SeargeSDXL.
- Hires vs UltimateSDUpscale: techtactician.com (latent hires), medium.com/@promptingpixels (hires fix), github.com/cubiq/ComfyUI_Workflows/upscale, comfyui.dev (Ultimate SD Upscale).
- Upscalers: blog.segmind.com (best AI upscalers), apatero.com (ESRGAN vs beyond 2025), aimodels.fyi (4x_foolhardy_Remacri), upscale.wiki Model_Database, tensor.art upscaling guide.
- FaceDetailer: runcomfy.com (FaceDetailer node + tutorial), mybyways.com (Impact-Pack detailers), github.com/ltdrdata/ComfyUI-Impact-Pack, comfyai.run (FaceDetailer docs).
- FreeU: stable-diffusion-art.com/freeu, github.com/ChenyangSi/FreeU (CVPR 2024), runcomfy.com (FreeU V2).
- Prompt craft: neurocanvas.net (SDXL + SD prompting guides), help.layer.ai (negative prompts SDXL), wiki.drawthings.ai (prompting basics), blog.segmind.com (SDXL prompt guide).
- LoRA stacking: neurocanvas.net/blog/multi-lora-workflows-comfyui, pixai.art (LoRA weight settings), blog.pixai.art (multi-character LoRA).
- Dark/low-key & negatives: help.layer.ai, prompthero.com (dark cinematic lighting), aiphotogenerator.net (negative prompts 2026).

## Live-asset citations (this rig, 2026-06-09)
- Checkpoints / LoRAs / upscalers / samplers: `http://10.10.10.163:8188/object_info/{CheckpointLoaderSimple,LoraLoader,UpscaleModelLoader,KSampler}` — enumerated read-only.
- Canonical wiring: `doc/image-craft-study/workflows/raw/official/{sdxl_sdxl_refiner_prompt_example, 2_pass_txt2img_hiresfix_latent_workflow, 2_pass_txt2img_hiresfix_esrgan_workflow, 2_pass_txt2img_latent_upscale_different_prompt_model, lora_lora, lora_lora_multiple, lcm_lcm_basic_example, controlnet_2_pass_pose_worship}.png` (read via `extract-workflow.py`).
- Taste calibration: `doc/image-craft-study/corpus/CORPUS.md` + `exemplars.jsonl` (120 award exemplars, theory-tagged).
- Prior canon being grounded: `plugins/pressroom/knowledge/comfyui-model-guide.md` (2026-06 model survey scores).
