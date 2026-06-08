# ComfyUI model guide — which checkpoint for which intent

> The canonical, evidence-based model-selection reference for PRESSROOM's generative raster path. **One
> source, referenced not forked:** both [`handler-comfyui`](../agents/handler-comfyui.md) (which renders) and
> the [`illustrator`](../skills/illustrator/SKILL.md) (which routes) consult this — neither hardcodes model
> choices. Populated and sharpened by the [model survey](../skills/model-survey/SKILL.md) (run under `/loop`);
> each run appends evidence via the shared
> [self-improvement protocol](../skills/rich-pdf-with-diagrams/references/self-improvement.md).
>
> **Backend:** `${PRESSROOM_COMFYUI_URL:-http://10.0.1.19:8188}`. The handler still lists checkpoints live;
> this guide tells it *which* to pick.

## How to use it (the handler's decision)
1. Read the SPEC's `intent` and map it to an **intent class** below.
2. Pick the **top recommended model** for that class that is present in the live checkpoint list (the survey
   validated loadability — prefer models it confirmed load; note the SDXL-subfolder quirk).
3. Use the **recommended settings** (steps/cfg/sampler) for that model's base.
4. If the intent class is flagged **"route to vector"**, do **not** use ComfyUI — tell the orchestrator to use
   a vector handler instead (e.g. `line-goes-up` belongs to `handler-chart`/`handler-graphviz`, not diffusion).

## Intent → recommended models (decision table)

_Recommendations below are from the 2026-06 survey (12 models × 5 objectives; image-fitness 0–100)._

| Intent class | Examples | Recommended (best-first) | Settings | Notes |
|---|---|---|---|---|
| **Photoreal scene** | hero shots, atmospheric environments | `dreamshaper_8` · `realcartoon3d_v8` (SD1.5, 100) · `juggernautXL_v2` · `protovisionXL` (SDXL, 100) | SD1.5 768×512 25–28 / SDXL 1216×832 28–30 · dpmpp_2m karras | scenes are the universal strength — even the cheapest SD1.5 nails them |
| **Landscape / nature** | vistas, backgrounds | `realcartoon3d_v8` (100) · `epicrealism` · `cyberrealistic_v31` · `epicdream_lullaby` (97) | as above | bright skies are a "hard-baked light field" — crop/subject for a dark doc |
| **People / marketing-stock** | candid office, team, lifestyle | `realisticStockPhoto_v10` (SDXL, 86) · `juggernautXL_lightning` (86) · `dreamshaper_8`/`epicdream_lullaby` (85) | SDXL photoreal; **inspect hands** | SD1.5 hands go mushy at scale — the artifact gate; SDXL is safer for people |
| **Cartoon / mascot** | logos, characters, friendly mascots | `dynavisionXL` · `juggernautXL_lightning` (97) · `protovisionXL` (96) · `cardosAnimated_v20` (95) · `modernDisneyXL_v11` (94) | — | mascots ship a bright ground → subject/cut out before embed |
| **Stylized 3D / concept** | game-art, painterly, dreamy | `dynavisionXL` · `protovisionXL` · `epicdream_lullaby` | — | — |
| **Chart / infographic / text** | `line-goes-up`, labeled diagrams | **route to vector** (`handler-chart` / `handler-graphviz`) | — | **CONFIRMED:** best score was 72; every model baked gibberish axis text. Diffusion cannot render legible labels — never route here. |
| **Fast / draft** | quick options, A/B challengers | `juggernautXL_lightning` | **6 steps · cfg ~2 · dpmpp_sde sgm_uniform** | standout: tied **best overall (87 avg)** at ~3× speed — not just a draft engine |

## Per-model scorecard

Image-fitness 0–100 per category (image-aesthetic canon), from the 2026-06 survey
(`doc/comfyui-experiment/journal.jsonl`; full notes in `catalog.md` + the PDF). **avg** across the five.

| Model | Base | Family | scenes | landsc | office | line↑ | mascot | avg | best-for | avoid |
|---|---|---|--:|--:|--:|--:|--:|--:|---|---|
| `dreamshaper_8` | sd15 | versatile | **100** | 94 | 85 | 65 | 89 | **87** | scenes, landscapes, mascot | line-goes-up |
| `juggernautXL_lightning` | sdxl-lightning | photoreal-fast | 91 | 94 | **86** | 67 | **97** | **87** | mascot, office, fast | line-goes-up |
| `realisticStockPhoto_v10` | sdxl | stock-photo | 100 | 89 | **86** | 69 | 80 | 85 | office/people, scenes | line-goes-up |
| `protovisionXL` | sdxl | photoreal-3d | 100 | 92 | 70 | 65 | 96 | 85 | scenes, mascot | — |
| `epicrealism` | sd15 | photoreal | 98 | 97 | 82 | 49 | 93 | 84 | scenes, landscapes, mascot | line-goes-up |
| `juggernautXL_v2` | sdxl | photoreal | 100 | 92 | 76 | 68 | 84 | 84 | scenes, landscapes | — |
| `modernDisneyXL_v11` | sdxl | cartoon-mascot | 96 | 97 | 82 | 53 | 94 | 84 | landscapes, mascot, scenes | line-goes-up |
| `dynavisionXL` | sdxl | stylized-3d | 97 | 86 | 66 | **72** | **97** | 84 | mascot, scenes | office, line-goes-up |
| `realcartoon3d_v8` | sd15 | 3d-cartoon | **100** | **100** | 85 | 34 | 90 | 82 | scenes, landscapes, mascot | line-goes-up |
| `cardosAnimated_v20` | sd15 | animated | 95 | 95 | 78 | 41 | **95** | 81 | scenes, landscapes, mascot | line-goes-up |
| `cyberrealistic_v31` | sd15 | photoreal | 96 | 97 | 73 | 51 | 88 | 81 | landscapes, scenes, mascot | line-goes-up, office hands |
| `epicdream_lullaby` | sd15 | artistic | 96 | 97 | 85 | 36 | 80 | 79 | landscapes, scenes | line-goes-up |

> **`SDXL/sd_xl_base_1.0` was excluded** — it is listed by the API but fails to load (the subfolder quirk).
> The survey records loadability; prefer the confirmed-loadable names above.

## Base-level routing rules (the durable findings) — confirmed by the 2026-06 survey
- **Diffusion cannot render legible chart text or axes.** Across all 12 models, `line-goes-up` peaked at **72**
  and every result baked gibberish glyphs for axis labels/numbers. → **`line-goes-up` and any
  labelled-infographic intent routes to the vector handlers (`handler-chart`/`handler-graphviz`), never
  ComfyUI.** This is the single most important rule.
- **Scenes & landscapes are the universal strength** (90–100 nearly everywhere) — even the cheapest SD1.5
  model is excellent here; reach for SDXL only when you need the higher native resolution.
- **People/office is where SD1.5 hands fail** — mushy/soft fingers at scale (artifact dock, occasionally the
  ≤2 anatomy cap). → prefer SDXL photoreal (`realisticStockPhoto_v10`) for people, and **inspect hands** before
  shipping.
- **LIGHTNING is not just a draft engine** — `juggernautXL_lightning` tied for **best overall (87)** at **6
  steps**. Use it as the default fast lane *and* a credible final for mascots/office.
- **Bright grounds fight dark docs** — landscapes and mascots often bake a bright sky/background; crop or
  subject (cut-out) before embedding on a dark page (the [dark-mode canon](../skills/illustrator/references/dark-mode-canon.md)).
- **SDXL subfolder quirk:** `SDXL/sd_xl_base_1.0.safetensors` is listed by `/object_info` but fails to load
  via the API; other subfolder models (`SDXL_3/…`, `SDXL_4/…`) load fine. The survey records loadability —
  the handler should prefer survey-confirmed names.

## Settings cheatsheet
| Base | Resolution | Steps | CFG | Sampler / scheduler |
|---|---|---|---|---|
| SD1.5 | 768×512 (landscape) | 25–28 | 6–7 | dpmpp_2m / karras |
| SDXL | 1216×832 (landscape) | 28–30 | 5.5–7 | dpmpp_2m / karras |
| SDXL-Lightning | 1216×832 | 6 | ~2 | dpmpp_sde / sgm_uniform |
