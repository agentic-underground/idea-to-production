# 30 — PRESSROOM prerequisites

PRESSROOM is **dual-engine**: it can typeset with **Typst** *or* **LaTeX**, and renders diagrams with
**Graphviz** / **Mermaid** (the **mermaid-specialist** skill covers the full Mermaid taxonomy + theming +
ELK). The builder `scripts/build-pdf.sh --engine=auto|typst|latex [--raster]` auto-selects whichever engine
is present, renders both `*.dot` and `*.mmd`, and — with `--raster` — rasterises the PDF to page PNGs so the
**design-reviewer** (Claude vision) can critique typography and charts. Install one typesetter at minimum.

## Typesetting engines (install ≥ 1)

| Tool | Tier | Probe | Notes | Install |
|---|---|---|---|---|
| `typst` | recommended | `typst --version` | Fast, single-pass, **no TeX install**; default when present. 0.14.x validated. Template: [`typst-template.md`](../plugins/pressroom/skills/rich-pdf-with-diagrams/references/typst-template.md). | `cargo install typst-cli` or release binary |
| `pdflatex` | recommended | `pdflatex --version` | Maximum typographic control; the original engine. | `apt install texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended` |
| `lualatex` | optional | `lualatex --version` | LaTeX alternative (system fonts). | `apt install texlive-luatex` |

> On the validated machine **only `typst` is present** (no TeX), so Typst is the working default
> there. Install the `texlive-*` set to enable the LaTeX path too.

## Diagram renderers

| Tool | Tier | Probe | Output | Install |
|---|---|---|---|---|
| `dot` (Graphviz) | recommended | `dot -V` | SVG (Typst) / PDF (LaTeX) / PNG | `apt install graphviz` |
| `mmdc` (mermaid-cli) | optional | `mmdc --version` | SVG/PNG from Mermaid | `npm i -g @mermaid-js/mermaid-cli` |

## DTP / conversion / post-processing

| Tool | Tier | Probe | Use | Install |
|---|---|---|---|---|
| `pdfinfo` (poppler) | recommended | `pdfinfo -v` | verify page count / size (used by `build-pdf.sh`) | `apt install poppler-utils` |
| `pdftoppm` (poppler) | recommended | `pdftoppm -v` | rasterise PDF pages → PNG for the **design-reviewer** (`build-pdf.sh --raster`); `gs`/`magick` are fallbacks | `apt install poppler-utils` |
| `gs` (Ghostscript) | recommended | `gs --version` | PDF optimise / merge / downsample; rasteriser fallback | `apt install ghostscript` |
| `libreoffice` / `soffice` | optional | `soffice --version` | convert docx/odt/pptx ⇄ PDF | `apt install libreoffice` |
| `pandoc` | recommended | `pandoc --version` | universal markup conversion (md⇄docx⇄html⇄…) | `apt install pandoc` |
| `rsvg-convert` (librsvg) | optional | `rsvg-convert --version` | SVG→PDF/PNG (sharp, scriptable) | `apt install librsvg2-bin` |
| `inkscape` | optional | `inkscape --version` | heavy-duty SVG→PDF, editing | `apt install inkscape` |
| `qpdf` | optional | `qpdf --version` | lossless PDF transform / linearise | `apt install qpdf` |
| `magick` (ImageMagick) | optional | `magick -version` | raster conversion / thumbnails | `apt install imagemagick` |

Already present on the validated box: `typst`, `gs`, `pdfinfo`, `libreoffice`/`soffice`, 168 fonts.
Missing there: `pdflatex`, `dot`, `mmdc`, `pandoc`, `rsvg-convert`, `qpdf`, `magick`.

Ansible: [`ansible/apt.yml`](ansible/apt.yml) (texlive/graphviz/poppler/ghostscript/libreoffice/pandoc/…),
[`ansible/cargo.yml`](ansible/cargo.yml) (typst), [`ansible/npm.yml`](ansible/npm.yml) (mermaid-cli).

> **No MCP applies.** PRESSROOM renders through local engines (typst/LaTeX, Graphviz, pandoc) — there is
> no MCP server to add; the binaries above *are* the model.
