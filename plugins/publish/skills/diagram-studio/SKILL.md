---
name: diagram-studio
description: >
  Author standalone, legible diagrams (Graphviz DOT and Mermaid) and render them to SVG, PNG, or
  PDF for embedding in ANY target — markdown docs, READMEs, web pages, slides, or print. Use this
  skill whenever the user wants "a diagram", "a chart", "an architecture diagram", "a flowchart",
  "render this as a graph", or wants a figure for documentation that is NOT necessarily a full
  print PDF. Carries the same A4/page-legibility discipline as rich-pdf-with-diagrams (the 4×9
  charting matrix) so figures stay readable at their target size. For full print-quality PDF
  ARTICLES with embedded figures, defer to rich-pdf-with-diagrams instead. Self-improving: shares
  and feeds the charting-matrix lessons log.
metadata:
  type: producer
  output: svg | png | pdf (single diagram, embeddable)
  engines: [graphviz (dot), mermaid (mmdc)]
  shares: ../rich-pdf-with-diagrams/references/charting-matrix.md
model: inherit
---

# DIAGRAM-STUDIO

A diagram is worth a thousand words *only if it's legible*. DIAGRAM-STUDIO produces single,
standalone figures — decoupled from the LaTeX/PDF article pipeline — that drop cleanly into
markdown, READMEs, web pages, or slides. It inherits the legibility discipline of
`rich-pdf-with-diagrams` (the 4×9 charting matrix) so a diagram is never a wall of micro-text.

> **Where this fits:** `rich-pdf-with-diagrams` owns *print-quality PDF articles with embedded
> figures*. DIAGRAM-STUDIO owns *individual, embeddable diagrams in any format*. WRITER produces
> *prose*. `/publish` ties them together. Use DIAGRAM-STUDIO when the deliverable is the figure
> itself, not a whole document.

---

## Quick start

```bash
# describe what you want; the skill picks engine + pattern, renders, and shows it
"diagram the request flow: browser → API → service → db, with a cache aside the service"
```

Outputs default to `<doc-dir>/diagrams/NN-name.{svg,pdf}` (SVG for web/markdown, PDF for print,
PNG only when a raster is explicitly required).

---

## Engine choice

| Engine | Best for | Output |
|---|---|---|
| **Graphviz (`dot`)** | structured graphs: architectures, pipelines, dependency/flow graphs, state machines | `dot -Tsvg` / `-Tpdf` |
| **Mermaid (`mmdc`)** | sequence diagrams, gantt, class diagrams, simple flowcharts that live *inline in markdown* | `mmdc -i in.mmd -o out.svg` |

Default to **Graphviz** for anything with non-trivial layout (it composes to the charting matrix
cleanly via `rankdir`/clusters). Use **Mermaid** when the diagram will live as a fenced
```` ```mermaid ```` block inside markdown that a renderer (GitHub, docs site) draws itself — in
that case emit the Mermaid source, not a rendered file.

> **Deep Mermaid work → the `handler-mermaid` value-handler.** When the job is Mermaid-specific — picking
> the right type from the full taxonomy (sequence, state, sankey, quadrant, timeline, journey…), theming to a
> palette, or driving the **ELK** layout — route to / spawn the
> [`handler-mermaid`](../../agents/handler-mermaid.md) value-handler, the single authoritative home for
> Mermaid authoring (the Mermaid peer to `handler-graphviz`, reached exactly as Graphviz is). The full
> Mermaid taxonomy lives in
> [`../rich-pdf-with-diagrams/references/mermaid-taxonomy.md`](../rich-pdf-with-diagrams/references/mermaid-taxonomy.md)
> and theming/ELK in
> [`../rich-pdf-with-diagrams/references/mermaid-theming.md`](../rich-pdf-with-diagrams/references/mermaid-theming.md);
> the handler shares this same charting-matrix — one legibility discipline, two engines, one handler each.

> **Both renderers are optional external CLIs** — `dot` (Graphviz) and `mmdc` (mermaid-cli) — and
> may be absent on a given machine. `/publish:check` reports which are present; use the per-row
> install hints. When the diagram
> targets a **Typst** PDF and Graphviz is unavailable, prefer **SVG** output (`dot -Tsvg`) — or author
> the figure in **Typst-native** drawing (`cetz`) — since Typst embeds SVG directly; LaTeX wants PDF.

---

## Workflow

### Phase A — Compose (same discipline as the charting matrix)
1. State the **semantic content**: what does this diagram convey, in one sentence?
2. **Count the boxes.** Sketch every node/cluster/edge. Verify it fits **≤4 columns × ≤9 rows**
   at the target size (read `../rich-pdf-with-diagrams/references/charting-matrix.md`). If it
   doesn't fit, **decompose into multiple diagrams**.
3. Pick a **pattern** from `../rich-pdf-with-diagrams/references/graphviz-patterns.md` (vertical
   chain, multi-phase cluster, fan-out wrapped to rows, staggered ladder, message-bus).
4. Default `rankdir=TB`; use `LR` only when ≤4 boxes wide and semantically horizontal.

### Phase B — Render
1. Write the source to `<doc-dir>/diagrams/NN-name.dot` (or `.mmd`).
2. Render to the **target format**:
   - markdown/web embed → **SVG** (`dot -Tsvg`), crisp at any zoom;
   - print/PDF embed → **PDF** (`dot -Tpdf`), vector;
   - raster-only sink → **PNG** at ≥2× (`dot -Tpng -Gdpi=192`).
3. Apply box margins (`margin="0.20,0.13"` min), `nodesep`/`ranksep` for breathing room.

### Phase C — Verify
Scan the rendered figure against the failure catalogue in
`../rich-pdf-with-diagrams/references/charting-matrix.md §6`: boxes <5mm, text touching edges,
overflow, illegible fan-outs. Fix before delivering.

---

## Target-aware sizing

The matrix's "A4 page" generalises to *whatever the figure's render box is*:

| Target | Effective width budget | Format |
|---|---|---|
| README / GitHub markdown | ~800px content column | SVG |
| Docs site | container width | SVG |
| Slide (16:9) | wider, shorter → favour `LR`, fewer rows | SVG/PNG |
| Print PDF article | A4 text block | PDF (defer to rich-pdf for the whole doc) |

Pick `rankdir` and decomposition to match the target's aspect ratio — a tall TB graph that's
perfect in a README is wrong on a 16:9 slide.

---

## Embedding

- **Markdown (rendered file):** `![Request flow](diagrams/01-request-flow.svg)`
- **Markdown (Mermaid, renderer-drawn):** a fenced ```` ```mermaid ```` block with the source.
- **HTML:** inline the SVG (`<svg>…`) for styleable, accessible figures; add `<title>`/`<desc>`.
- **Accessibility:** every figure ships with alt text / `<title>` stating the diagram's intent,
  not just "diagram".

---

## Self-improvement covenant

DIAGRAM-STUDIO **shares** `rich-pdf-with-diagrams`'s charting-matrix and lessons log — it does
not fork them. When diagram feedback arrives, follow
`../rich-pdf-with-diagrams/references/self-improvement.md`: generalise the lesson, update the
shared charting-matrix, log it. A lesson learned here improves the print pipeline too, and
vice-versa. One legibility discipline, two delivery surfaces.

## References

| Document | Purpose |
|---|---|
| `../rich-pdf-with-diagrams/references/charting-matrix.md` | The 4×9 legibility rules + failure catalogue (shared) |
| `../rich-pdf-with-diagrams/references/graphviz-patterns.md` | DOT recipes per diagram type (shared) |
| `../rich-pdf-with-diagrams/references/self-improvement.md` | Feedback-absorption protocol (shared) |
| `references/mermaid-patterns.md` | Mermaid recipes (sequence, class, gantt, flowchart) and when to prefer Mermaid |
| `../rich-pdf-with-diagrams/references/mermaid-taxonomy.md` | The full Mermaid diagram taxonomy + "when each fits" (the `handler-mermaid` authority, shared) |
| `../rich-pdf-with-diagrams/references/mermaid-theming.md` | `%%{init}%%` theming, `themeVariables`, the ELK layout engine, accessibility (shared) |
