# Prompt-craft reference — writing prompts that clear the award bar

> The prompt-craft canon [`handler-comfyui`](../../../agents/handler-comfyui.md) points at. Pairs with the
> [model guide](../../../knowledge/comfyui-model-guide.md) (which asset) and
> [workflow-strategy](workflow-strategy.md) (which pipeline). Scores are calibrated to **award-tier, not
> "usable"** — see the [image-aesthetic canon](../../design-reviewer/references/image-aesthetic-canon.md). The
> rig is SDXL-first, so **natural language beats SD1.5 tag-soup.**

## Positive-prompt structure (front-loaded, ≤~75 tokens of real content)

Order matters — earliest tokens carry the most weight:

| # | Slot | What goes here | Example |
|---|---|---|---|
| 1 | **Subject** | the one concrete thing, stated first | `a lone lighthouse on a basalt cliff` |
| 2 | **Descriptors** | material, age, state, action | `weathered, storm-battered, beam cutting the dark` |
| 3 | **Art-direction** | composition + medium (from the anchors below) | `low-angle wide shot, cinematic concept art, matte painting` |
| 4 | **Light** | the highest-leverage clause | `single warm rim light, deep shadow, chiaroscuro, golden hour` |
| 5 | **Lens / medium** | optics or material | `35mm, shallow depth of field, anamorphic` / `oil on canvas, visible brushwork` |
| 6 | **Quality anchors** | a *short* tail, **≤4 words** | `highly detailed, sharp focus, professional` |

SDXL reads **natural phrases (5–15 words/segment)**, not comma-walls of tags. State light and composition
explicitly with named theory — that is what moved the award winners, not adjective piles.

## Negative-prompt strategy (SDXL needs *little*)

- **Short, concrete, visual artefacts SD actually learned:**
  `blurry, watermark, text, signature, jpeg artifacts, lowres, oversaturated, deformed hands, extra fingers`.
- **Drop cargo-cult junk** — `ugly`, `bad`, `masterpiece-negative`. SD was never trained on a labelled "ugly"
  class; these burn attention for nothing.
- **Never contradict the positive.** If the positive wants shadow/dark, do **not** put `dark`/`shadows` in the
  negative (it muddies the result) — see the dark-key recipe. Negate only the things you genuinely don't want.
- **No SD1.5 boilerplate walls** on SDXL — the 40-token `bad anatomy, extra limbs, …` block is
  counter-productive on XL.

## Art-direction anchors (the terms that actually move quality)

| Axis | Anchors that work |
|---|---|
| **Composition** | rule of thirds, leading lines, low/high angle, wide establishing shot, centred negative space, figure-ground separation, silhouette, S-curve |
| **Light** | single key light, rim / contre-jour, volumetric haze, chiaroscuro, tenebrism, golden hour, low-key / high-key |
| **Colour** | limited palette, complementary accent, analogous, teal-and-orange, muted earth tones, cool shadow / warm key |

Reach for `cinematic`, `volumetric`, `chiaroscuro`, `golden hour`, `rim light`, `rule of thirds`,
`negative space`, `complementary palette` deliberately — each names a real craft lever the model responds to.

## Dark-key / doc-hero recipe (text-free, people-free, dark-ground)

The reliable way to get a README-hero asset that drops onto a dark page as if transparent.

- **Positive (composition + light):**
  `dark-key, low-key lighting, single rim light, deep shadow, chiaroscuro, subject centred on a void black
  background, vast negative space, minimalist, cinematic, volumetric haze`.
  State **"black background / void / empty dark backdrop"** explicitly — it darkens *and* isolates the subject,
  a built-in matte.
- **LoRAs (the rig's two on-target dark anchors):** `lowkey_v1.1.safetensors` @ **0.6** +
  `LowRA.safetensors` @ **0.4**. Optional `Silhouette.safetensors` for pure shape, `luts-000004.safetensors`
  @ 0.3 for cinematic grade.
- **Negative (people / text / bright killers):**
  `text, words, letters, typography, watermark, signature, logo, caption, UI, person, people, human, face,
  crowd, bright background, white background, overexposed, high-key, busy background, clutter`.
- **Critical non-contradiction:** because the positive is dark, keep `dark`/`shadow`/`low-key` **out** of the
  negative — negate only the *bright/high-key* terms.
- **Settings:** cfg slightly higher (**6.5–7**) so the steering holds; `dpmpp_2m · karras`; base
  `dynavisionXLAllInOneStylized…` or `zavychromaxl_v12`.
- **Never rely on diffusion for text** — every checkpoint bakes gibberish glyphs. Keep heroes **text-free**;
  add any labels in the page/SVG layer. This is the single hardest rule.

## Anti-patterns

- **Token piles** — `8k, 4k, uhd, hyperdetailed, ultra-realistic, trending on artstation, award-winning,
  masterpiece, best quality` stacked dilutes attention. Keep quality anchors ≤4 words.
- **Contradiction** — dark positive + dark negative; a style-LoRA trigger fighting opposite style words.
- **Duplicate concepts** — repeating the same idea three ways doesn't strengthen it; it crowds the budget.
- **Over-length** — past ~75 tokens of real content the later tokens get ignored. Cut, don't pile.
- **Cargo-cult negatives** — `ugly`/`bad`/`worst quality` on SDXL are no-ops; remove them.
