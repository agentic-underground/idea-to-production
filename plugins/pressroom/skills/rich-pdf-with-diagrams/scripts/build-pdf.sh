#!/usr/bin/env bash
# build-pdf.sh — build a rich-PDF article from sources in this directory.
#
# Dual-engine: Typst or LaTeX. Both are first-class; pick per article.
#
# Usage:   bash build-pdf.sh [--engine=auto|typst|latex] [--raster] [article-name]
#   --engine=auto   (default) use Typst if a *.typ exists, else LaTeX if a *.tex exists
#   --engine=typst  compile <article-name>.typ  with `typst compile`
#   --engine=latex  compile <article-name>.tex  with `pdflatex` (three passes)
#   --raster        also rasterise the final PDF to review/page-NN.png (150 dpi) so the
#                   design-reviewer (Claude vision) can SEE every page. Uses the first of
#                   pdftoppm / gs / magick that is present.
#
# Expects:
#   .          — contains <article-name>.typ (typst) or <article-name>.tex (latex)
#   diagrams/  — optional; *.dot (Graphviz) and *.mmd (Mermaid) files rendered to the format
#                the engine embeds best (LaTeX → .pdf, Typst → .svg) when `dot` / `mmdc` exist
#
# Produces:
#   diagrams/*.{pdf,svg}  — rendered diagrams (vector)
#   <article-name>.pdf    — final article
#   review/page-NN.png    — (with --raster) one PNG per page for the design-reviewer

set -euo pipefail

engine="auto"
article_name=""
raster=0
for arg in "$@"; do
  case "$arg" in
    --engine=*) engine="${arg#--engine=}" ;;
    --raster)   raster=1 ;;
    *)          article_name="$arg" ;;
  esac
done

have() { command -v "$1" >/dev/null 2>&1; }
shopt -s nullglob   # an unmatched glob expands to nothing, not to the literal pattern

# Resolve engine ---------------------------------------------------------------
if [ "$engine" = "auto" ]; then
  if [ -n "$article_name" ] && [ -f "${article_name}.tex" ] && [ ! -f "${article_name}.typ" ]; then
    engine="latex"                       # explicit name with only a .tex → honour the old contract
  elif [ -n "$article_name" ] && [ -f "${article_name}.typ" ]; then
    engine="typst"
  elif compgen -G "*.typ" >/dev/null;   then engine="typst"
  elif compgen -G "*.tex" >/dev/null;   then engine="latex"
  else echo "No *.typ or *.tex source found in $(pwd)."; exit 1
  fi
fi

ext="tex"; [ "$engine" = "typst" ] && ext="typ"

# Discover article name if not supplied ---------------------------------------
if [ -z "$article_name" ]; then
  src_files=( *."$ext" )
  if [ "${#src_files[@]}" -eq 0 ]; then
    echo "No .$ext source found for engine=${engine} in $(pwd)."; exit 1
  elif [ "${#src_files[@]}" -ne 1 ]; then
    echo "Found ${#src_files[@]} .$ext files; please pass the article name explicitly."
    exit 1
  fi
  article_name="${src_files[0]%.$ext}"
fi

echo "==> Building article: ${article_name}  (engine: ${engine})"

# Step 1 — render diagrams (Graphviz .dot + Mermaid .mmd), in the engine's best format --
if [ -d diagrams ]; then
  diag_fmt="pdf"; [ "$engine" = "typst" ] && diag_fmt="svg"
  pushd diagrams >/dev/null
  if have dot; then
    for f in *.dot; do
      [ -e "$f" ] || continue
      dot -T"$diag_fmt" "$f" -o "${f%.dot}.${diag_fmt}"
      echo "    rendered ${f%.dot}.${diag_fmt} (graphviz)"
    done
  elif compgen -G "*.dot" >/dev/null; then
    echo "    Graphviz 'dot' not installed — skipping .dot render (Typst embeds .svg/.png; LaTeX needs .pdf)."
  fi
  if have mmdc; then
    for f in *.mmd; do
      [ -e "$f" ] || continue
      mmdc -i "$f" -o "${f%.mmd}.${diag_fmt}" >/dev/null 2>&1 \
        && echo "    rendered ${f%.mmd}.${diag_fmt} (mermaid)" \
        || echo "    ⚠ mmdc failed on ${f} — embed the source or fix the diagram."
    done
  elif compgen -G "*.mmd" >/dev/null; then
    echo "    mermaid-cli 'mmdc' not installed — skipping .mmd render (emit the fenced source instead)."
  fi
  popd >/dev/null
else
  echo "    no diagrams/ folder found, skipping diagram render"
fi

# Step 2 — compile -------------------------------------------------------------
case "$engine" in
  typst)
    have typst || { echo "ERROR: engine=typst but 'typst' is not installed. See PREREQUISITES/30-pressroom.md"; exit 127; }
    echo "==> typst compile"
    typst compile "${article_name}.typ" "${article_name}.pdf"
    ;;
  latex)
    have pdflatex || { echo "ERROR: engine=latex but 'pdflatex' is not installed. See PREREQUISITES/30-pressroom.md"; exit 127; }
    for pass in 1 2 3; do
      echo "==> pdflatex pass ${pass}/3"
      pdflatex -interaction=nonstopmode -halt-on-error "${article_name}.tex" >/dev/null
    done
    ;;
  *) echo "Unknown engine: ${engine} (use auto|typst|latex)"; exit 2 ;;
esac

# Step 3 — rasterise for the design-reviewer (optional) ------------------------
if [ "$raster" -eq 1 ]; then
  mkdir -p review
  if have pdftoppm; then
    pdftoppm -png -r 150 "${article_name}.pdf" review/page >/dev/null 2>&1
    echo "==> rasterised pages → review/page-*.png (pdftoppm)"
  elif have gs; then
    gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r150 -o "review/page-%02d.png" "${article_name}.pdf" >/dev/null 2>&1
    echo "==> rasterised pages → review/page-*.png (ghostscript)"
  elif have magick; then
    magick -density 150 "${article_name}.pdf" review/page.png >/dev/null 2>&1
    echo "==> rasterised pages → review/page*.png (imagemagick)"
  else
    echo "==> --raster requested but no rasteriser (pdftoppm/gs/magick) found — see PREREQUISITES/30-pressroom.md"
  fi
  echo "    the design-reviewer reads these PNGs with built-in vision (no API key)."
fi

# Step 4 — report --------------------------------------------------------------
if have pdfinfo; then
  pages=$(pdfinfo "${article_name}.pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
fi
size=$(du -h "${article_name}.pdf" | awk '{print $1}')
echo "==> SUCCESS: ${article_name}.pdf  (${pages:-?} pages, ${size})"
echo "    canonical location: copy this PDF up one directory to publish"
