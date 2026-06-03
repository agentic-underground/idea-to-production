#!/usr/bin/env bash
# build-pdf.sh — build a rich-PDF article from sources in this directory.
#
# Dual-engine: Typst or LaTeX. Both are first-class; pick per article.
#
# Usage:   bash build-pdf.sh [--engine=auto|typst|latex] [article-name]
#   --engine=auto   (default) use Typst if a *.typ exists, else LaTeX if a *.tex exists
#   --engine=typst  compile <article-name>.typ  with `typst compile`
#   --engine=latex  compile <article-name>.tex  with `pdflatex` (three passes)
#
# Expects:
#   .          — contains <article-name>.typ (typst) or <article-name>.tex (latex)
#   diagrams/  — optional; *.dot files rendered to the format the engine embeds best
#                (LaTeX → .pdf, Typst → .svg) when Graphviz `dot` is available
#
# Produces:
#   diagrams/*.{pdf,svg}  — rendered diagrams (vector)
#   <article-name>.pdf    — final article

set -euo pipefail

engine="auto"
article_name=""
for arg in "$@"; do
  case "$arg" in
    --engine=*) engine="${arg#--engine=}" ;;
    *)          article_name="$arg" ;;
  esac
done

have() { command -v "$1" >/dev/null 2>&1; }

# Resolve engine ---------------------------------------------------------------
if [ "$engine" = "auto" ]; then
  if compgen -G "*.typ" >/dev/null;   then engine="typst"
  elif compgen -G "*.tex" >/dev/null; then engine="latex"
  else echo "No *.typ or *.tex source found in $(pwd)."; exit 1
  fi
fi

ext="tex"; [ "$engine" = "typst" ] && ext="typ"

# Discover article name if not supplied ---------------------------------------
if [ -z "$article_name" ]; then
  src_files=( *."$ext" )
  if [ "${#src_files[@]}" -ne 1 ]; then
    echo "Found ${#src_files[@]} .$ext files; please pass the article name explicitly."
    exit 1
  fi
  article_name="${src_files[0]%.$ext}"
fi

echo "==> Building article: ${article_name}  (engine: ${engine})"

# Step 1 — render diagrams (Graphviz), in the format the engine embeds best ----
if [ -d diagrams ]; then
  if have dot; then
    diag_fmt="pdf"; [ "$engine" = "typst" ] && diag_fmt="svg"
    pushd diagrams >/dev/null
    for f in *.dot; do
      [ -e "$f" ] || continue
      dot -T"$diag_fmt" "$f" -o "${f%.dot}.${diag_fmt}"
      echo "    rendered ${f%.dot}.${diag_fmt}"
    done
    popd >/dev/null
  else
    echo "    Graphviz 'dot' not installed — skipping .dot render."
    echo "    (Typst can embed pre-made .svg/.png; LaTeX needs the .pdf diagrams.)"
  fi
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

# Step 3 — report --------------------------------------------------------------
if have pdfinfo; then
  pages=$(pdfinfo "${article_name}.pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
fi
size=$(du -h "${article_name}.pdf" | awk '{print $1}')
echo "==> SUCCESS: ${article_name}.pdf  (${pages:-?} pages, ${size})"
echo "    canonical location: copy this PDF up one directory to publish"
