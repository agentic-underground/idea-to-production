---
name: check
description: >
  Verify that PRESSROOM's typesetting and rendering tools are installed and reachable — the
  dual-engine typesetters (typst / pdflatex), diagram renderers (dot, mmdc), and DTP/conversion
  tools (pdfinfo, gs, pandoc, libreoffice). Trigger with /pressroom:check (or "check pressroom
  prerequisites", "can I render a PDF?"). Runs a fast ✓/✗ probe grouped by tier and tells you which
  PDF engine(s) are available so /publish can pick a working one. Advisory by default; --strict to
  fail on a missing required tool. Reads the canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ tooling table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# PRESSROOM — Dependency Check

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
- **optional** — `lualatex`, `mmdc`, `soffice`, `rsvg-convert`, `qpdf`, `inkscape`, `magick`.

## Interpreting the result

PRESSROOM is **dual-engine**: you only need **one** typesetter. If `typst ✓` but `pdflatex ✗`, the
builder simply uses Typst (`build-pdf.sh --engine=auto` handles this). A missing diagram renderer
narrows figure options, it does not block the article. Each `✗` prints its install hint (the local
source of truth is this skill's `requirements.tsv`); fuller guidance + Ansible fragments are in the
marketplace `PREREQUISITES/30-pressroom.md` when run from the marketplace source tree.

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
