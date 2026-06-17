---
name: design-reviewer
description: >
  Adversarially review the VISUAL design of a rendered document or chart — the print/DTP and data-viz
  quality gate of PUBLISH. Trigger with /publish:design-review (or "review this PDF's typography",
  "critique this chart", "is this figure well-designed", "check the layout of the print edition"). It
  rasterises a built PDF's pages (or reads a diagram/chart image) so Claude vision can SEE them, then scores
  them on a design-fitness rubric against the named canon — typography (Bringhurst, grids, measure/leading,
  widows/orphans) and data-viz (Tufte, Cleveland–McGill, Bertin, ColorBrewer) — returning prioritised,
  principle-citing findings that drive a convergent designer↔reviewer loop until the artefact clears the
  rubric. Complements WRITER's prose reviewer (which owns the words); this owns the page and the figure.
metadata:
  type: reviewer
  output: a scored, prioritised design critique + a loop verdict (CONVERGED / CONTINUE / HALT)
  reviews: rendered PDF pages, diagrams, charts (rasterised to PNG so vision can see them)
model: inherit
---

# PUBLISH — DESIGN REVIEWER

The visual quality gate. WRITER's prose `reviewer` makes the *words* undeniable; this skill makes the
*page and the figure* undeniable — typographically sound, visually balanced, and (for charts) honest. It
is adversarial by stance and grounded by named canon, and it drives a loop that **measurably converges**
rather than ping-ponging.

> **Stance — adversarial, grounded, terminating.** Assume the artefact is wrong until each canon lens fails
> to break it; a clean pass is *earned*. Every finding names a principle — *"measure is 96 chars, past
> Bringhurst's 75 ceiling → tiring"*, *"a 3-D pie hides the comparison; Cleveland ranks angle/area near the
> bottom — use a bar"* — never "looks off". (The convergent loop, with its rubric and stop conditions, is
> [`references/design-critique-loop.md`](references/design-critique-loop.md).)

## See the artefact (rasterise so vision can read it)

Claude vision reads **PNG** directly; a PDF must be rasterised first. The `build-pdf.sh --raster` flag
emits `review/page-NN.png` for every page; or do it yourself with the first available tool:

```bash
pdftoppm -png -r 150 article.pdf review/page    # poppler (preferred)
# or: gs -sDEVICE=png16m -r150 -o review/page-%02d.png article.pdf
# or: magick -density 150 article.pdf review/page.png
```

For a standalone diagram/chart, render it to PNG and read that (`mmdc -i fig.mmd -o fig.png -s 2`, or
`dot -Tpng -Gdpi=192`; `-s` is mermaid-cli's raster scale and applies to PNG, not SVG). Then `Read` each
PNG — no API key, built-in vision.

## The lenses (assign one, or run several)

| Lens | Agent | Reads | Holds |
|---|---|---|---|
| **Layout / legibility** | [`agents/layout-reviewer.md`](agents/layout-reviewer.md) | each rendered **figure** (the inline ~640px strip + full-res) | the at-a-glance **gate** — edge-clip, overlap, crowding, vertical clipping, z-index/occlusion, min-text-size, inline-legibility at ~640px — **run BEFORE taste** ([`references/layout-canon.md`](references/layout-canon.md)) |
| **Typography / DTP** | [`agents/typographic-reviewer.md`](agents/typographic-reviewer.md) | the rendered **page** | measure, leading, modular scale, baseline grid, widows/orphans, hierarchy, figure-page balance, tables, **document accessibility (PDF/UA + WCAG 2.2 — a hard gate)** ([`references/typography-canon.md`](references/typography-canon.md)) |
| **Data-viz / charting** | [`agents/dataviz-reviewer.md`](agents/dataviz-reviewer.md) | each **figure/chart** | data-ink, chartjunk, the Cleveland–McGill perception ranking, Bertin's visual variables, colour-blind-safe palettes ([`references/dataviz-canon.md`](references/dataviz-canon.md)) |
| **Image-aesthetic / generative** | [`agents/image-aesthetic-reviewer.md`](agents/image-aesthetic-reviewer.md) | a **generative raster** (ComfyUI output / contact-sheet) | category-fit, prompt-adherence, artifact-freedom (anatomy/geometry/gibberish-text), composition, dark-mode/doc suitability ([`references/image-aesthetic-canon.md`](references/image-aesthetic-canon.md)) — feeds the [model survey](../model-survey/SKILL.md) + [`comfyui-model-guide`](../../knowledge/comfyui-model-guide.md) |

The **Layout / legibility** lens is a **gate, not graded taste**: it runs **first**, and the three taste
lenses score a figure only after its floor passes — a clean, on-prompt image whose caption is clipped is
*broken*, not "strong-with-a-nit", so no taste score is computed until the layout gate is clean. The taste
lenses share the **4×9 charting-matrix** legibility law with the diagram producers (not forked) and feed the
same lessons log. The lenses also run in a **comparative (A/B) mode** when the [`illustrator`](../illustrator/SKILL.md)
hands them *two* options instead of one — score each, crown a winner, and refuse to call it the *best* until
it earns it (the [`references/ab-comparative-loop.md`](references/ab-comparative-loop.md), sibling to the
convergent loop below). That comparative loop is **bounded to `MAX_TURNS = 4` rounds**: it **accepts early**
when the champion's fitness score meets `TARGET (85/100)` **OR** the verdict is `BEST` (`PASS`), and **on the
cap ships the best-scoring draft** with a logged `CAP` note rather than spinning past the bound. The reviewer
owns the score and the verdict; the orchestrator owns the carry-forward and the cap — see the loop reference
for the exact `signal: BEST | LEAST-WORSE | CAP` schema.

## How to run

1. **Recover intent.** What is this document/figure *for*, and for whom? An academic print edition, a
   release-notes PDF, and a pitch chart have different bars — review against the right one.
2. **Rasterise & see** (above). One PNG per page; one per figure.
3. **Critique through the lens(es)** — typography first for documents, data-viz for each chart. For every
   finding record **(a) principle · (b) violation · (c) reader cost · (d) concrete fix (a `.typ`/`.tex`/
   `.dot`/`.mmd` change) · (e) rubric dimension**. Score the **design-fitness rubric**
   ([`references/design-critique-loop.md`](references/design-critique-loop.md)).
4. **Run the convergent loop** — return prioritised findings → the producer applies HIGH+MED and re-builds
   → re-score. **Stop** on CONVERGED (no HIGH, score ≥ target) / DIMINISHING-RETURNS (surface the impasse,
   ask) / CAP. Never spin past the point of measurable improvement.
5. **Report** — the final score, the trajectory, the residual (accepted/deferred), and — for a recurring
   composition failure — fold the lesson into the shared charting-matrix via
   [`../rich-pdf-with-diagrams/references/self-improvement.md`](../rich-pdf-with-diagrams/references/self-improvement.md).

## Boundaries (compose, don't duplicate)

- **WRITER's `reviewer`** owns the *prose* (clarity, accuracy, punchiness). This skill never re-edits words
  — it reviews how they're *set and laid out*.
- **The diagram producers** (`diagram-studio`, `mermaid-specialist`, `rich-pdf-with-diagrams`) *make* the
  figures; this skill *judges* them and hands back the fix. The loop closes between maker and judge.
- This is PUBLISH's print/data-viz analogue of ATELIER's screen reviewer — **same loop shape**, different
  canon. When both plugins are present, a lesson learned in one is offered to the other.

## Self-improvement covenant

Carries the KAIZEN covenant. A figure that passed this review yet still misled a reader is a **canon or
rubric gap** — generalise it (a tighter typography rule, a re-weighted data-viz dimension) and land it via
the shared self-improvement protocol, so every future review catches it.
