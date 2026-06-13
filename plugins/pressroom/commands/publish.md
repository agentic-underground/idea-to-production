---
description: Publish project material as an article, diagrams, or a print-quality PDF — the single front door to PRESSROOM (writer + diagram-studio + rich-pdf).
---

Orchestrate the PRESSROOM pipeline to turn project material into publication-grade output.

Parse `$ARGUMENTS` for **source** and **target format**:
- **source** — a topic/angle, an existing markdown file path, or nothing (then discover from the
  project: git history, docs/, README — per the WRITER skill's Phase 1).
- **format** — `markdown` (default), `pdf` (print-quality), `docx` (Microsoft Word), or `diagrams` (figures only).

Pipeline:

1. **Write / refine** — invoke the **writer** skill: discover source material, agree the
   article brief, draft with the REVIEWER loop, output markdown to `doc/articles/<slug>.md`.
   (If the source is already a finished markdown file and only a format conversion is wanted,
   skip drafting.)
2. **Diagrams (if the piece needs figures or `format=diagrams`)** — invoke **diagram-studio**:
   compose legible figures under `doc/articles/<slug>/diagrams/`, rendered to SVG for markdown or PDF for
   print, all obeying the 4×9 charting matrix. For **Mermaid-specific** work — choosing among the full
   diagram taxonomy (sequence, state, sankey, quadrant, timeline…), theming to a palette, or driving the
   ELK layout — defer to the **mermaid-specialist** skill (its peer).
3. **Render to target:**
   - `markdown` → deliver the `.md` (with embedded SVG figures if any).
   - `pdf` → defer to **rich-pdf-with-diagrams**: typeset the article with embedded figures via
     `scripts/build-pdf.sh [--engine=auto|typst|latex]` (dual-engine — Typst single-pass, or LaTeX
     three-pass; it also renders `*.mmd` via `mmdc`), output `doc/articles/<slug>.pdf`.
   - `docx` → defer to the **`handler-docx`** value-handler: convert the article markdown to a
     Microsoft Word `.docx` (pandoc-first with a reference-doc template, python-docx for fine control),
     validate the produced OOXML structurally (styles, heading outline, tables, metadata, alt text)
     before hand-back, output `doc/articles/<slug>.docx`.
   - `diagrams` → deliver the figures only.
4. **Design review (convergent loop)** — for `pdf` or `diagrams`, run the **design-reviewer** skill:
   rasterise the PDF (`build-pdf.sh --raster` → `review/page-*.png`) or read the figure images, score the
   artefact on the design-fitness rubric (typography + data-viz canon), apply the HIGH+MED findings, and
   re-build — until **CONVERGED** / **DIMINISHING-RETURNS** / **CAP** (it improves the artefact, it does not
   ping-pong).
   **Figure↔data integrity is NON-SKIPPABLE** whenever a figure encodes quantities or carries a legend:
   the artefact is not "done" until it has been rasterised **and** the reviewer has visually verified the
   render against the **source data** — hand the reviewer the numbers, because a legend/colour/bar that
   contradicts the data is a lie-factor≠1 failure (a backwards-decoded chart legend once shipped precisely
   because a source self-review skipped this). Layout/aesthetic polish stays advisory — the user may opt
   out of *that*, never of the integrity check.
5. **Commit** — follow `skills/writer/references/commit-format.md` (article commits only).

Report the output path(s), word count, the design-review **fitness score** (and any accepted residual),
and — if a recurring composition failure surfaced — that the lesson was folded into the shared
charting-matrix via the rich-pdf self-improvement protocol.

This command is also what the `foundry` plugin hands off to (when PRESSROOM is installed) to
upgrade its markdown deliverables into richer published artefacts.

## Product lifecycle (by capability)

When publication-grade output is produced (the release is documented and out), and the **i2p** plugin is installed, mark the **PUBLISH** phase done so the marketplace
product lifecycle and the status line advance to OPERATE (the living phase, owned by `mission-control`):

```bash
/i2p-lifecycle done PUBLISH   # order-safe & idempotent — a no-op unless a lifecycle is running at PUBLISH
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
