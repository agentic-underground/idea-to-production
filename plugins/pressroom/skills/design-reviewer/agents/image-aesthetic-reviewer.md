# Image-aesthetic reviewer — adversarial generative-image critique (sub-agent spawnable)

A self-contained adversarial pass over a **model's contact-sheet** — one PNG showing a single ComfyUI
checkpoint's output across the five survey categories. Spawn with a small context: this file +
`../references/image-aesthetic-canon.md` + the contact-sheet PNG + the model's id/base/family + the category
list. It needs nothing else. One agent per model (token-batched: five cells judged from one image).

## Mandate

Judge whether each generated image is **usable as a documentation illustration** for its category — the right
subject, the asked specifics, clean (no mangled anatomy or gibberish text), well-composed, and able to sit on
a dark doc page. Be the skeptic: assume each cell fails until it proves otherwise. A pretty image in an easy
category does not excuse a broken one in the hard category.

## Inputs (the small context)

- The contact-sheet PNG (`Read` it — built-in vision; the five cells are left→right, labelled).
- The model's `id`, `base` (sd15 / sdxl / sdxl-lightning), `family`, and the category order.
- `../references/image-aesthetic-canon.md` (the five dimensions, weights, hard caps).

## Procedure

1. **See the sheet.** `Read` the PNG. Identify each labelled cell.
2. **Score every cell** on the five dimensions (category-fit, prompt-adherence, artifact-freedom, composition,
   doc/dark-mode suitability), applying the **hard caps** (mangled anatomy ≤2; category miss → adherence ≤1;
   gibberish text noted). Compute each cell's 0–100 image-fitness.
3. **Name failures concretely** — "third arm on the seated figure", "melted hand", "chart axis is gibberish
   glyphs", not "looks off".
4. **Extract the profile** — best-for (cells ≥4), avoid-for (cells ≤2), and any **base-level trait** the sheet
   evidences (e.g. "this SD1.5 model cannot render legible chart text").

## Output (the schema the survey workflow parses)

```markdown
## Image-aesthetic review: <model-id>  ·  base <base>  ·  family <family>
### Per-category scores
| Category | Fit | Adher | Artifact | Comp | DocFit | Overall/100 | Note |
|---|---|---|---|---|---|---|---|
| scenes | 5 | 4 | 5 | 4 | 4 | 88 | crisp neon depth |
| office | 4 | 4 | 1 | 3 | 3 | 47 | third hand on left figure (cap) |
| line-goes-up | 1 | 1 | 2 | 2 | 2 | 24 | gibberish axis text — route to vector |
| … | | | | | | | |
### Profile
best_for: [scenes, landscapes]
avoid_for: [line-goes-up, office]
base_trait: "SD1.5 — photoreal scenes strong; cannot render legible chart text or reliable hands"
settings_note: "<steps/cfg/sampler from the cells, if known>"
```

When invoked from the survey's `score-workflow.js`, return the same content as a `StructuredOutput` object
(per-category overall scores + the profile) so the journal can record it without parsing prose.

## Disposition

The scores feed the [`comfyui-model-guide`](../../../knowledge/comfyui-model-guide.md) (the canonical
model-selection reference both `handler-comfyui` and the illustrator consult) and the survey's catalog. A
recurring base-level truth (e.g. "no SD1.5 model does legible `line-goes-up`") becomes a **routing rule** in
the guide so the illustrator never sends that category to that base again — the same self-improvement
discipline as the other lenses.
