#!/usr/bin/env bash
# build-pdf.sh — build a rich-PDF article from sources in this directory.
#
# Usage:   bash build-pdf.sh [article-name]
# Default article-name: discovered as the only *.tex in cwd.
#
# Expects:
#   .       — contains <article-name>.tex
#   diagrams/  — contains *.dot files to render
#
# Produces:
#   diagrams/*.pdf  — rendered diagrams (vector)
#   <article-name>.pdf  — final article

set -euo pipefail

# Discover article name if not supplied
if [ "$#" -lt 1 ]; then
  tex_files=( *.tex )
  if [ "${#tex_files[@]}" -ne 1 ]; then
    echo "Found ${#tex_files[@]} .tex files; please pass the article name explicitly."
    exit 1
  fi
  article_name="${tex_files[0]%.tex}"
else
  article_name="$1"
fi

echo "==> Building article: ${article_name}"

# Step 1 — render all diagrams via Graphviz
if [ -d diagrams ]; then
  pushd diagrams >/dev/null
  for f in *.dot; do
    [ -e "$f" ] || continue
    dot -Tpdf "$f" -o "${f%.dot}.pdf"
    echo "    rendered ${f%.dot}.pdf"
  done
  popd >/dev/null
else
  echo "    no diagrams/ folder found, skipping diagram render"
fi

# Step 2 — compile LaTeX (three passes for TOC + cross-references)
for pass in 1 2 3; do
  echo "==> pdflatex pass ${pass}/3"
  pdflatex -interaction=nonstopmode -halt-on-error "${article_name}.tex" >/dev/null
done

# Step 3 — report
pages=$(pdfinfo "${article_name}.pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
size=$(du -h "${article_name}.pdf" | awk '{print $1}')
echo "==> SUCCESS: ${article_name}.pdf  (${pages:-?} pages, ${size})"
echo "    canonical location: copy this PDF up one directory to publish"
