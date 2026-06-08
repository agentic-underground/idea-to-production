# The image-aesthetic canon — judging generative raster output

> The third design lens, beside [`typography-canon.md`](typography-canon.md) (the page) and
> [`dataviz-canon.md`](dataviz-canon.md) (the chart). This one judges **generative raster images** — what a
> ComfyUI checkpoint produces — so the marketplace can choose models on evidence, not vibes. Used by the
> [image-aesthetic reviewer](../agents/image-aesthetic-reviewer.md) to score a model's contact-sheet and by
> the [model survey](../../model-survey/SKILL.md) to build the
> [`comfyui-model-guide`](../../../knowledge/comfyui-model-guide.md). Unlike typography/data-viz, there is no
> "honesty" gate — but there are **hard failure modes** (mangled anatomy, illegible intent) that cap a score
> regardless of polish.

## The five dimensions (each 0–5)

| Dim | Weight | 5 = exemplary | 0–1 = broken |
|---|---:|---|---|
| **Category-fit** | 24 | unmistakably the asked category (a *landscape* reads as a landscape; a *mascot* as a mascot) | wrong subject entirely; the prompt's category is unrecognisable |
| **Prompt-adherence** | 22 | the specific elements asked for are present (the *upward line*, the *team around a laptop*, the *neon market*) | ignores the prompt's specifics; generic filler |
| **Artifact-freedom** | 22 | clean anatomy, coherent geometry, no melted/duplicated forms, no garbled pseudo-text | extra limbs, fused faces, melted hands, broken perspective, gibberish glyphs |
| **Composition & aesthetic** | 18 | balanced framing, clear focal point, pleasing light/colour, intentional | flat, cluttered, muddy, no focal point, amateur |
| **Doc/dark-mode suitability** | 14 | works as a doc illustration — restrained, embeddable, sits on a dark page; or cleanly subjectable | garish, busy, hard-baked bright ground that fights a dark doc ([dark-mode canon](../../illustrator/references/dark-mode-canon.md)) |

**Weighted total = the image-fitness score (0–100).** Score **per category cell** on the contact-sheet, then
report the per-model profile.

## Hard caps (no amount of polish overrides)
- **Mangled human anatomy** (extra/missing limbs, fused or distorted faces, broken hands) in a cell where
  people are central (e.g. `office`) caps that cell at **≤ 2** — a beautiful-but-deformed stock photo is
  unusable.
- **Category miss** (the image is not recognisably the asked category) caps **prompt-adherence ≤ 1** for that
  cell.
- **Illegible "text" attempt** — if the category invites text/labels (`line-goes-up`) and the model bakes
  gibberish glyphs, note it explicitly: it is the signal that this model/base must **not** be routed that
  category (the vector handlers own it instead).

## The per-model profile (what the survey extracts)
For each model, from its five scored cells:
- **best-for** — the 1–2 categories it scores ≥ 4 on (its sweet spot).
- **avoid-for** — categories it scores ≤ 2 on.
- **base trait** — note recurring base-level truths (e.g. *SD1.5 cannot render legible chart text*;
  *SDXL photoreal models nail office-stock but are slower*; *lightning models trade fidelity for ~3× speed*).
- **settings** — the steps/cfg/sampler the cell used (so the guide can recommend them).

## Stance
Adversarial and concrete, like the other lenses: name the failure ("melted left hand; third arm on the
seated figure"), don't say "looks off". A model earns a high score; it is not given one for being pretty in
the easy categories while failing the hard one.
