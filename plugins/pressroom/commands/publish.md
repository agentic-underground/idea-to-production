---
description: Publish project material as an article, diagrams, or a print-quality PDF — the single front door to PRESSROOM (writer + diagram-studio + rich-pdf).
---

Orchestrate the PRESSROOM pipeline to turn project material into publication-grade output.

Parse `$ARGUMENTS` for **source** and **target format**:
- **source** — a topic/angle, an existing markdown file path, or nothing (then discover from the
  project: git history, docs/, README — per the WRITER skill's Phase 1).
- **format** — `markdown` (default), `pdf` (print-quality), or `diagrams` (figures only).

Pipeline:

1. **Write / refine** — invoke the **writer** skill: discover source material, agree the
   article brief, draft with the REVIEWER loop, output markdown to `doc/articles/<slug>.md`.
   (If the source is already a finished markdown file and only a format conversion is wanted,
   skip drafting.)
2. **Diagrams (if the piece needs figures or `format=diagrams`)** — invoke **diagram-studio**:
   compose legible figures (Graphviz/Mermaid) under `doc/articles/<slug>/diagrams/`, rendered to
   SVG for markdown or PDF for print, all obeying the 4×9 charting matrix.
3. **Render to target:**
   - `markdown` → deliver the `.md` (with embedded SVG figures if any).
   - `pdf` → defer to **rich-pdf-with-diagrams**: typeset the article with embedded figures via
     `scripts/build-pdf.sh [--engine=auto|typst|latex]` (dual-engine — Typst single-pass, or LaTeX
     three-pass), output `doc/articles/<slug>.pdf`.
   - `diagrams` → deliver the figures only.
4. **Commit** — follow `skills/writer/references/commit-format.md` (article commits only).

Report the output path(s), word count, and — if a PDF — note any diagram feedback should be fed
back via the rich-pdf self-improvement protocol before re-rendering.

This command is also what the `foundry` plugin hands off to (when PRESSROOM is installed) to
upgrade its markdown deliverables into richer published artefacts.
