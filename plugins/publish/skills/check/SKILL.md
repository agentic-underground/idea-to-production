---
name: check
description: >
  Verify PUBLISH's typesetting/rendering tools are installed and reachable — typesetters (typst,
  pdflatex), diagram renderers (dot, mmdc), and DTP/conversion tools (pdfinfo, gs, pandoc, libreoffice).
  Trigger with /publish:check (or "check publish prerequisites", "can I render a PDF?"). Reports which
  PDF engine(s) are available. Advisory; --strict fails on a missing required tool.
metadata:
  phase: [cross-cut]
  type: diagnostic
  output: a ✓/✗ tooling table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# PUBLISH — Dependency Check

Reports which typesetting engine(s) and renderers are present, so `/publish` and
`rich-pdf-with-diagrams` choose a working path instead of failing mid-build. Installs nothing.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

## What it checks

[`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):

- **required** — `git`, `bash`.
- **recommended** — at least one PDF engine (**`typst`** or **`pdflatex`**), plus `pdfinfo`, `dot`,
  `pandoc`, `gs`.
- **optional** — `lualatex`, `mmdc`, `soffice`, `rsvg-convert`, `qpdf`, `inkscape`, `magick`, `ffmpeg`,
  `vips`, `gifsicle`, `gifski` (the last four power the local raster/motion finish — composite, blend,
  animate; `handler-composite` degrades gracefully without them).

## Interpreting the result

PUBLISH is **dual-engine**: you only need **one** typesetter. If `typst ✓` but `pdflatex ✗`, the
builder simply uses Typst (`build-pdf.sh --engine=auto` handles this). A missing diagram renderer
narrows figure options, it does not block the article. Each `✗` prints its install hint (the local
source of truth is this skill's `requirements.tsv`).

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
