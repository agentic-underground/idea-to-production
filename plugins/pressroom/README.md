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
| **/publish** | the front door: write → diagram → render (markdown / pdf / diagrams) | `/publish [source] [format]` |
| **writer** | mines git history & docs → articles (origin story, deep dive, retrospective, release notes) with an adversarial REVIEWER loop | skill (triggers on "write an article…") |
| **diagram-studio** | standalone, legible diagrams (Graphviz + Mermaid) → SVG/PNG/PDF for any target | skill (triggers on "diagram this…") |
| **rich-pdf-with-diagrams** | print-quality PDF articles with embedded, A4-legible figures (LaTeX + Graphviz) | skill (triggers on "rich PDF", "print edition") |

## How the pieces compose

```
/publish ──▶ writer (prose) ──▶ diagram-studio (figures) ──▶ render
                                                              ├─ markdown (+ SVG)
                                                              ├─ pdf  → rich-pdf-with-diagrams
                                                              └─ diagrams only
```

`writer` produces the words; `diagram-studio` produces individual embeddable figures;
`rich-pdf-with-diagrams` produces a whole typeset document. All three share **one legibility
discipline** — the 4×9 charting matrix — so a figure is never an unreadable wall of micro-text,
whether it lands in a README or on a printed A4 page.

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
