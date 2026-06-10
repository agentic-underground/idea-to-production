# Workflow-strategy reference — which multi-stage pipeline, and how it's wired

> The multi-stage decision guide [`handler-comfyui`](../../../agents/handler-comfyui.md) points at. Pairs with
> the [model guide](../../../knowledge/comfyui-model-guide.md) (which asset) and
> [prompt-craft](prompt-craft.md) (how to prompt). All recipes are tuned for the rig's **RTX 3090 24 GB**.
> Node names below are the live ComfyUI nodes present on the rig (Impact-Pack, FreeU, LatentUpscale all
> present) and match the canonical official-example wiring patterns by name. Scores target **award-tier** —
> see the [image-aesthetic canon](../../design-reviewer/references/image-aesthetic-canon.md).

## Decision tree — intent/genre → pipeline

```
intent ──▶ chart / labelled text? ──▶ ROUTE TO VECTOR (handler-chart/graphviz). STOP.
       │
       ├─ fast draft / A/B / high-iteration?
       │     └▶ Lightning checkpoint, BASE-ONLY (6 steps · cfg ~2 · dpmpp_sde sgm_uniform)
       │
       ├─ photoreal scene / landscape?
       │     └▶ base → LATENT-HIRES → (UltraSharp/Remacri upscale-model finish)   [recipe A / C]
       │
       ├─ stylized / concept / game-art?
       │     └▶ base → LoRA STACK + FreeU V2 → LATENT-HIRES → (NMKD upscale)        [recipe B]
       │
       ├─ portrait / character / people in frame?
       │     └▶ base → (LoRA) → LATENT-HIRES → FaceDetailer ×2 (around the upscale) [recipe E]
       │
       ├─ action / dynamic?
       │     └▶ base (dpmpp_2m_sde) → effect-LoRA → LATENT-HIRES → FaceDetailer?    [recipe D]
       │
       └─ dark-key README hero (text-free, people-free)?
             └▶ stylized base → lowkey+LowRA LoRAs + FreeU V2 → LATENT-HIRES
                → UltraSharp; NO FaceDetailer                                       [recipe F]
```

The six recipes (A–F), their checkpoints, LoRAs, and exact settings live in the
[model guide](../../../knowledge/comfyui-model-guide.md) decision table; this doc gives the **stage wiring**.

## Canonical stage wiring (named nodes)

**Base pass** — `CheckpointLoaderSimple` → `CLIPTextEncode` (pos/neg) → `EmptyLatentImage` → `KSampler` →
`VAEDecode` → `SaveImage`. Set `ckpt_name` from the model guide; set steps/cfg/sampler per base.

**Latent hires-fix** *(the biggest single quality lever)*
`KSampler(base)` latent → `LatentUpscaleBy` (×1.5, `bislerp`) → **2nd `KSampler`** at
**denoise 0.4–0.5** (same model, ~12 steps) → `VAEDecode`.
Matches `2_pass_txt2img_hiresfix_latent` / `…latent_upscale_different_prompt_model`. Keep denoise **≤0.45**
when likeness/composition must hold (detail drifts above that).

**Upscale-model (ESRGAN)** *(crispness, no new content)*
`UpscaleModelLoader` (e.g. `ESRGAN/4x-UltraSharp.pth`) → `ImageUpscaleWithModel` → `ImageScale` (down to
target). For a re-detail pass: → `VAEEncode` → `KSampler` @ **denoise ~0.35**. Matches
`2_pass_txt2img_hiresfix_esrgan`. Pick model by content (UltraSharp sharp / Remacri natural / anime-6B line).
Run **after** latent hires, not as the only upscale on a soft base.

**LoRA stack** — chain `LoraLoader` nodes model→model→CLIP before the KSampler (`lora_lora` /
`lora_lora_multiple`). **Weights: 0.6–0.8 solo; drop each to 0.5–0.6 when stacking.** Give the *primary* LoRA
the higher weight; reduce `strength_clip` before `strength_model` if a LoRA hijacks the prompt; **validate
each solo before stacking.** ≥3 high-strength LoRAs go incoherent.

**FaceDetailer** (Impact-Pack) — detect→crop→re-diffuse→paste; **denoise 0.4–0.5**, `bbox_crop_factor` ~3,
modest `bbox_dilation`, feather edges. High-end two-pass: pass 1 (structure) **before** upscale, pass 2
(detail) **after** upscale @ **denoise 0.3**. **Portraits only** — skip for landscapes/abstract/dark-key.

**FreeU V2** — insert between checkpoint and sampler; SDXL **b1 1.3 / b2 1.4 / s1 0.9 / s2 0.2**. Stylized /
anime / painterly only — it over-contrasts realistic photo models.

**Tricomposite (regional latent composition)** *(the maintainer's vertical-stack signature)* — for a
**tall image built from three independently-controlled registers**: three `EmptyLatentImage` → three
prompt pairs (`CLIPTextEncode` ×6) → three `KSampler` (one per region) → chain two `LatentComposite` nodes
to paste the regions into one latent at fixed offsets → a **4th unifying `KSampler` at low-ish denoise**
over the combined latent → `VAEDecode`. **Composition rule:** give the three registers a **vertical
world-axis** (trunk/column/bolt/tower) and an **aerial→warm depth gradient** so they read as one picture,
not three stacked tiles. Soften seams with `LatentCompositeMasked` (feathered) or a higher unify-denoise.
Full mined graph + the taste read: `doc/image-craft-study/rig-inventory/maintainer-recipes.md`.

> **SDXL base + refiner WORKS here (maintainer-preferred).** `SDXL/sd_xl_base_1.0` is the maintainer's primary
> base; the canonical `KSamplerAdvanced` step-split (base `0→N`, refiner `N→∞`) with proper SDXL dual
> conditioning is a first-class flow. A latent-hires pass is an equally fine, simpler alternative when a
> fine-tune already bakes the detail. (This corrects an earlier "won't load / dead" note.)
>
> **Maintainer-proven premium flow — REIMAGINE + UltimateSDUpscale (the 42-node `IRU` graph).** Base
> `sd_xl_base_1.0` with **unCLIP image-prompting** (`CLIPVisionLoader: clip_vision_g.safetensors` →
> `CLIPVisionEncode` → `unCLIPConditioning`) so a reference image's *look* steers the result; **high steps
> (50–60), low CFG (3.5–4.5), `dpmpp_3m_sde_gpu`/`dpmpp_sde_gpu` · karras**; finished with **UltimateSDUpscale**
> (`SwinIR_4x`, tiled 1024, denoise 0.25). Resolution via `RecommendedResCalc` / `CM_NearestSDXLResolution`.
> Full graph: `doc/image-craft-study/rig-inventory/iru-premium-workflow.json`; recipes:
> `…/maintainer-recipes.md`.

## Cost / VRAM notes (RTX 3090 24 GB)

- **Headroom:** a 2-pass latent-hires + FaceDetailer at 1024-base fits comfortably.
- **OOM-risky stacks** — flag and budget carefully: ×2 latent-hires to 4K+, FaceDetailer two-pass *plus* a
  large model-upscale in one graph, or `UltimateSDUpscale` at high tile counts. Prefer **a single latent
  hires** below ~2K output (simpler and cleaner than tiled upscale). For 4K+, use `UltimateSDUpscale` (tiled,
  fits 24 GB) with a Tile ControlNet + denoise 0.25–0.35 — not pixel-perfect, so only when resolution demands.
- **Lightning for high-iteration** — 6-step Lightning checkpoints cut wall-clock ~3× for A/B sweeps and draft
  rolls; reserve the full base→hires path for photoreal finals.

## Allowlisted-template tie-in

These recipes map onto the in-plugin `knowledge/comfyui-workflows/` template set the handler fills (it sets
params into a **known** template, never a caller-supplied graph):

| Template | Stages it wires | Recipes |
|---|---|---|
| `txt2img-hires-fix` | base → `LatentUpscaleBy` → 2nd KSampler (+ optional upscale-model) | A, C, F |
| `lora-detail` | `LoraLoader` chain → base → hires → FaceDetailer | B, D, E |
| `upscale` | `UpscaleModelLoader` → `ImageUpscaleWithModel` → `ImageScale` | finish pass for A/C/F |
| `tricomposite` | 3 region `KSampler`s → 2 feathered `LatentComposite` → unify `KSampler` @ denoise ~0.5 | vertical world-axis / multi-register scenes |

The handler chooses the template from the decision tree above, fills `ckpt_name`, prompts, LoRA names/weights,
and bounded steps/denoise per the recipe, then submits. Until that MCP template set ships, the handler uses an
inline `txt2img` template and steers the extra stages through prompt + base choice.
