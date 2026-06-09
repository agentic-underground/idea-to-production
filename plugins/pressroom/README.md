# PRESSROOM — Publishing & Documentation

> Turn a codebase into something people want to read — articles, diagrams, and print-quality PDFs.

PRESSROOM mines a project's artefacts (git history, docs, code) for narrative signal and produces
publication-grade output: articles that land, standalone diagrams that stay legible, and
print-quality PDFs with embedded figures.

It works on **any** project, standalone. It is also the **PUBLISHING companion** the
[`foundry`](../foundry/) plugin hands off to: foundry's value artefact is markdown, and when
PRESSROOM is installed it can upgrade that markdown into richer published artefacts via `/publish`.
When PRESSROOM is absent, foundry simply delivers markdown (*graceful enhancement* — no hard
dependency).

## What's inside

| Component | Does | Entry |
|---|---|---|
| **/publish** | the front door: write → diagram → render → **design-review** (markdown / pdf / diagrams) | `/publish [source] [format]` |
| **/illustrate** | trawl docs → find the highest-impact figure-sites → SPEC → **two options** → an A/B-until-best design review → an embedded **dark-mode, transparent** asset (one file, the current doc, or a `/loop` trawl of the whole tree) | `/illustrate [docs\|this\|{filename}\|{content area}]` |
| **writer** | mines git history & docs → articles (origin story, deep dive, retrospective, release notes) with an adversarial prose REVIEWER loop | skill (triggers on "write an article…") |
| **diagram-studio** | standalone, legible diagrams (Graphviz + Mermaid) → SVG/PNG/PDF for any target | skill (triggers on "diagram this…") |
| **mermaid-specialist** | the Mermaid-native producer — the full diagram taxonomy (sequence, state, sankey, quadrant, timeline…), theming, and the ELK layout engine | skill (triggers on "mermaid…", "sequence/state/sankey…") |
| **rich-pdf-with-diagrams** | print-quality PDF articles with embedded, A4-legible figures (Typst/LaTeX + Graphviz/Mermaid) | skill (triggers on "rich PDF", "print edition") |
| **design-reviewer** | adversarial **visual** quality gate — typography (Bringhurst/grids) + data-viz (Tufte/Cleveland/Bertin) — scores the rendered artefact and drives a convergent loop (and a comparative A/B mode for the illustrator) | skill (triggers on "review this PDF/chart") |
| **illustrator** | the documentation-illustration studio — ranks figure-sites by impact, specs each, has a graphical **value handler** (Graphviz / Mermaid / chart / composition / ComfyUI) render two options, and runs the A/B-until-best review; every figure dark-mode + transparent by default | skill (triggers on "illustrate this doc…", "what figures does this need") |
| **model-survey** | a loop-driven experiment that explores the ComfyUI backend's checkpoints across five objectives, scores them (image-aesthetic lens), and writes the [`comfyui-model-guide`](knowledge/comfyui-model-guide.md) so the illustrator + `handler-comfyui` pick models on evidence | skill (run under `/loop`; no command) |

## How the pieces compose

![PRESSROOM publishing pipeline: /publish drives writer (prose) → diagram-studio / mermaid-specialist (figures) → render, which branches into three outputs (markdown + inline SVG, PDF via rich-pdf-with-diagrams, diagrams-only); the whole render→outputs stage is wrapped by the adversarial design-reviewer gate (typography + data-viz) that applies HIGH+MED and re-builds until the artefact clears the 4×9 rubric — converging, no ping-pong.](diagrams/01-pieces-compose.png)

`writer` produces the words; `diagram-studio` + `mermaid-specialist` produce the figures;
`rich-pdf-with-diagrams` produces a whole typeset document; `design-reviewer` is the adversarial gate that
**critiques and converges** the rendered result. All share **one legibility discipline** — the 4×9 charting
matrix — so a figure is never an unreadable wall of micro-text, whether it lands in a README or on a printed
A4 page. The maker↔reviewer loop **measurably improves** the artefact rather than ping-ponging.

## Install

```
/plugin marketplace add whatbirdisthat/idea-to-production
/plugin install pressroom@idea-to-production
```

## Design principles

- **Signal over noise** — a project may have 200 commits; an article has one spine. Find it.
- **Legibility is non-negotiable** — every diagram composes within the charting matrix or is
  decomposed until it does.
- **Self-improving** — every piece of diagram feedback is generalised into the shared
  charting-matrix lessons log, so the same composition error never recurs (across both the
  standalone and print pipelines).
- **Standalone** — PRESSROOM never assumes another plugin is installed; its writer carries its
  own commit convention.

See [ROADMAP.md](ROADMAP.md) for planned capabilities (slide decks, multi-format export,
citations, web publishing).

## ♻️ Self-improvement covenant — halve the distance to perfection

Every component of PRESSROOM carries the SOLID self-improvement covenant: each iteration must **at
least halve the remaining distance to perfection** — every piece of diagram feedback is generalised
into the shared charting-matrix so the same composition error never recurs, and recurring gaps are
fixed *upstream, once*. This is the shared discipline of the idea-to-production marketplace.

## License

Dual-licensed under **MIT OR Apache-2.0**.
