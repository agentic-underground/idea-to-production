#!/usr/bin/env bash
# contact-sheets.sh — deterministic per-model review grids (Typst → PDF → PNG). ZERO model tokens.
#
# For every model in the manifest, lays out its 5 category thumbnails in a labelled row on a dark ground and
# rasterises to a single PNG the image-aesthetic reviewer reads (one image per model → token-batched scoring).
# Missing cells (a model/category that failed to generate) render as a labelled "—" placeholder.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
SURVEY_DIR="${SURVEY_DIR:-$(find_root)/comfyui-experiment}"
MANIFEST="$SURVEY_DIR/manifest.json"
OUT="$SURVEY_DIR/contact-sheets"; mkdir -p "$OUT"
command -v typst >/dev/null || { echo "typst not found" >&2; exit 2; }

cats=$(jq -r '.categories[].id' "$MANIFEST")
n_models=$(jq '.models | length' "$MANIFEST")

for mi in $(seq 0 $((n_models-1))); do
  mid=$(jq -r ".models[$mi].id"     "$MANIFEST")
  base=$(jq -r ".models[$mi].base"  "$MANIFEST")
  fam=$(jq -r ".models[$mi].family" "$MANIFEST")
  typ="$OUT/$mid.typ"
  {
    echo '#set page(width: auto, height: auto, margin: 10pt, fill: rgb("#1e1e2e"))'
    echo '#set text(fill: rgb("#e6e9f0"), font: ("DejaVu Sans", "Liberation Sans"), size: 9pt)'
    printf '#text(size: 13pt, weight: "bold")[%s] #h(6pt) #text(fill: rgb("#9aa2c0"))[%s · %s]\n\n' "$mid" "$base" "$fam"
    printf '#grid(columns: %s, gutter: 8pt,\n' "$(echo "$cats" | wc -l)"
    while IFS= read -r cid; do
      th="thumbs/$mid/$cid.png"
      if [ -f "$SURVEY_DIR/$th" ]; then
        printf '  stack(spacing: 4pt, image("../%s", width: 230pt), align(center)[%s]),\n' "$th" "$cid"
      else
        printf '  stack(spacing: 4pt, box(width: 230pt, height: 150pt, fill: rgb("#2a2a3c"), align(center+horizon)[—]), align(center)[%s]),\n' "$cid"
      fi
    done <<<"$cats"
    echo ')'
  } > "$typ"
  # --root the survey dir so the ../thumbs/ image paths (outside the .typ's own folder) are permitted.
  if typst compile --root "$SURVEY_DIR" "$typ" "$OUT/$mid.pdf" 2>/dev/null; then
    pdftoppm -png -r 110 -singlefile "$OUT/$mid.pdf" "$OUT/$mid" && echo "  sheet: $mid.png"
  else
    echo "  typst failed for $mid" >&2
  fi
done
echo "contact sheets in $OUT"
