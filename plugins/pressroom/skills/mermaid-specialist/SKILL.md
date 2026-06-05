---
name: mermaid-specialist
description: >
  Author and render Mermaid diagrams across Mermaid's full diagram taxonomy — the Mermaid-native peer to
  the Graphviz/Typst producers. Use this skill when the deliverable is a Mermaid diagram, when the right
  diagram type isn't obvious (sequence? state? sankey? quadrant? timeline?), when a diagram needs THEMING
  to a brand or to look professional, or when a large graph needs the ELK layout engine. Knows all ~25+
  Mermaid diagram types and when each fits, themes diagrams to a disciplined palette, holds the shared 4×9
  charting-matrix legibility law, and emits accessible (accTitle/accDescr) output — as inline source where
  the target renders Mermaid, or rendered SVG/PNG via mmdc where it doesn't. Self-improving: shares and
  feeds the charting-matrix lessons log.
metadata:
  type: producer
  output: mermaid source (fenced) or rendered svg | png (single diagram, embeddable)
  engine: mermaid (mmdc)
  shares: ../rich-pdf-with-diagrams/references/charting-matrix.md
model: inherit
---

# MERMAID-SPECIALIST

The Mermaid-native producer. Where `diagram-studio` reaches for **Graphviz** for precise-layout graphs,
this skill is the specialist for everything **Mermaid does best** — and Mermaid does far more than
flowcharts. It picks the *right diagram type* for the meaning, themes it so it looks composed rather than
default, keeps it legible, and renders it for the target.

> **Where this fits.** `diagram-studio` is the general front door (Graphviz **or** Mermaid); this skill is
> the deep Mermaid peer it (and `/publish`) defer to when the work is Mermaid-specific — choosing among the
> full taxonomy, theming, or driving the ELK layout. It **shares** the charting-matrix and lessons log with
> `rich-pdf-with-diagrams` — it does not fork them. One legibility discipline, many diagram types.

## 1. Pick the right diagram type FIRST

The most common Mermaid mistake is forcing a flowchart where a *sequence*, *state*, *timeline*, or
*sankey* would carry the meaning honestly. Mermaid supports a large taxonomy — match the diagram to the
**structure of the idea**, not to habit. The full catalogue + "when each fits" is in
[`references/mermaid-taxonomy.md`](references/mermaid-taxonomy.md). The short version:

| The idea is about… | Use |
|---|---|
| Messages/calls between actors over time | **sequenceDiagram** |
| Lifecycle / modes & transitions | **stateDiagram-v2** |
| Process with decisions | **flowchart** (TB docs / LR slides) |
| Entities & relationships (schema) | **erDiagram** or **classDiagram** |
| Schedule / plan over dates | **gantt** |
| Ordered events without dates | **timeline** |
| Flow/throughput between stages | **sankey-beta** |
| 2×2 strategic positioning | **quadrantChart** |
| Trends / quantities to compare | **xychart-beta** (or hand off bar/line to a data-viz tool) |
| Hierarchy / brainstorm | **mindmap** |
| Cloud/service topology | **architecture-beta** / **C4** |
| Multi-dimension comparison | **radar** |

> **Don't over-reach.** Mermaid's chart types (pie, xychart) are fine for *simple* quantitative asides,
> but for serious **data visualisation** the [`design-reviewer`](../design-reviewer/SKILL.md) holds the
> Tufte/Cleveland/Bertin canon — heed its rubric, and prefer a real charting tool for dense quantitative
> work. A diagram explains *structure*; a chart explains *quantity*. Know which you're making.

## 2. Compose to the legibility law (shared, not forked)

The 4×9 charting-matrix intuition governs Mermaid too: keep the node/participant count modest and
**decompose** rather than sprawl (read
[`../rich-pdf-with-diagrams/references/charting-matrix.md`](../rich-pdf-with-diagrams/references/charting-matrix.md)).
Mermaid-specific ceilings: **sequence ≤6 participants** (else `box … end` grouping or split);
**flowchart ≤~12 nodes** per figure; **gantt ≤~15 tasks**; **state ≤~8 states** before composite-state
nesting. When a graph is genuinely large, switch to the **ELK** layout engine for better routing rather
than cramming the default renderer (see [`references/mermaid-theming.md`](references/mermaid-theming.md)).

## 3. Theme it — default Mermaid looks like default Mermaid

A diagram that ships with the stock theme reads as unconsidered. Theme to a disciplined palette via an
`%%{init}%%` directive and `themeVariables` (base theme + a few overrides; **hex only** — `'#2563eb'`, not
`'blue'`). Match the document/brand, keep contrast legible, let one accent carry emphasis. Recipes and the
full `themeVariables` surface are in [`references/mermaid-theming.md`](references/mermaid-theming.md).

## 4. Render for the target (graceful)

| Target | Output |
|---|---|
| Markdown a renderer draws (GitHub/GitLab/docs) | **inline source** in a fenced ```` ```mermaid ```` block — don't pre-render. |
| Markdown/web that won't draw Mermaid | `mmdc -i in.mmd -o out.svg` (vector) or `-o out.png -s 2` (2× raster). |
| Typst PDF | SVG (Typst embeds SVG); LaTeX PDF | `mmdc … -o out.pdf` or via the SVG→PDF path. |

`mmdc` (mermaid-cli) is an **optional** external CLI — `/pressroom:check` reports it. **When `mmdc` is
absent, emit the Mermaid source** in a fenced block and say the rendered image was skipped (graceful
degradation). Never block on it.

## 5. Accessibility — never optional

Every diagram carries `accTitle:` (a short name) and `accDescr:` (what it shows) so it isn't opaque to
screen readers; `mmdc` emits `<title>`/`<desc>` into the SVG from them. A diagram without an accessible
description is not done.

## Self-improvement covenant

Shares `rich-pdf-with-diagrams`'s charting-matrix and lessons log — does **not** fork them. A legibility
lesson learned here (a participant ceiling, a theming rule, an ELK threshold) is generalised via
[`../rich-pdf-with-diagrams/references/self-improvement.md`](../rich-pdf-with-diagrams/references/self-improvement.md)
and improves the Graphviz/print pipeline too. New diagram-type recipes go in
[`references/mermaid-taxonomy.md`](references/mermaid-taxonomy.md).

## References

| Document | Purpose |
|---|---|
| [`references/mermaid-taxonomy.md`](references/mermaid-taxonomy.md) | Every Mermaid diagram type, when each fits, a syntax cue, and the legibility ceiling |
| [`references/mermaid-theming.md`](references/mermaid-theming.md) | `%%{init}%%` theming, `themeVariables`, the ELK layout engine, config & accessibility |
| `../rich-pdf-with-diagrams/references/charting-matrix.md` | The shared 4×9 legibility law + failure catalogue |
| `../rich-pdf-with-diagrams/references/self-improvement.md` | The shared feedback-absorption protocol |
