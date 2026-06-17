#!/usr/bin/env bash
# build-catalog.sh — Phase E. Deterministic catalog.md + an EFFICIENT PDF. ZERO model tokens.
#   1. catalog.md  — every generated file on disk, grouped by model, with per-category scores from the journal.
#   2. catalog.typ — title + per-model thumb grid + score table → typst compile → raw PDF.
#   3. gs downsample/recompress the raw PDF → comfyui-model-survey.pdf (the efficient deliverable).
# Scores are read from journal "score" events if present; the image catalog builds with or without them.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
SURVEY_DIR="${SURVEY_DIR:-$(find_root)/docs/internal/comfyui-experiment}"
MANIFEST="$SURVEY_DIR/manifest.json"; JOURNAL="$SURVEY_DIR/journal.jsonl"
MD="$SURVEY_DIR/catalog.md"; TYP="$SURVEY_DIR/catalog.typ"
RAW="$SURVEY_DIR/.catalog-raw.pdf"; PDF="$SURVEY_DIR/comfyui-model-survey.pdf"
command -v typst >/dev/null || { echo "typst not found" >&2; exit 2; }
cats=$(jq -r '.categories[].id' "$MANIFEST"); n_models=$(jq '.models|length' "$MANIFEST")

# score lookup: latest "score" event for model+category → "overall" (or "—")
score_of() { jq -s -r --arg m "$1" --arg c "$2" \
  '[.[]|select(.event=="score" and .model==$m and .category==$c)]|last|(.overall // "—")|tostring' "$JOURNAL" 2>/dev/null; }

# ── catalog.md ───────────────────────────────────────────────────────────────
{
  echo "# ComfyUI model survey — catalog"
  echo
  echo "Generated images live on disk under \`images/\` (full) and \`thumbs/\` (downscaled); they are **not**"
  echo "tracked by git. This catalog and \`comfyui-model-survey.pdf\` are the tracked record. Scores are the"
  echo "design team's image-aesthetic verdict (0–5); see \`../../plugins/publish/knowledge/comfyui-model-guide.md\`."
  echo
  echo "| Model | Base | Family | $(echo "$cats" | paste -sd'|' -) |"
  echo "|---|---|---|$(echo "$cats" | sed 's/.*/---/' | paste -sd'|' -)|"
  for mi in $(seq 0 $((n_models-1))); do
    mid=$(jq -r ".models[$mi].id" "$MANIFEST"); base=$(jq -r ".models[$mi].base" "$MANIFEST"); fam=$(jq -r ".models[$mi].family" "$MANIFEST")
    row="| \`$mid\` | $base | $fam |"
    while IFS= read -r cid; do row+=" $(score_of "$mid" "$cid") |"; done <<<"$cats"
    echo "$row"
  done
  echo
  echo "## Files on disk"
  for mi in $(seq 0 $((n_models-1))); do
    mid=$(jq -r ".models[$mi].id" "$MANIFEST")
    echo "### \`$mid\`"
    while IFS= read -r cid; do
      f="images/$mid/$cid.png"; [ -f "$SURVEY_DIR/$f" ] && echo "- \`$f\` — $cid (score $(score_of "$mid" "$cid"))" || echo "- _$cid — not generated_"
    done <<<"$cats"
  done
} > "$MD"
echo "wrote $MD"

# ── catalog.typ ──────────────────────────────────────────────────────────────
{
  echo '#set page(width: 210mm, height: 297mm, margin: 14mm, fill: rgb("#16161e"))'
  echo '#set text(fill: rgb("#e6e9f0"), font: ("DejaVu Sans", "Liberation Sans"), size: 9pt)'
  echo '#align(center)[#text(size: 22pt, weight: "bold")[ComfyUI Model Survey] #v(4pt) #text(fill: rgb("#9aa2c0"))[scenes · landscapes · office · line-goes-up · cute-mascot]]'
  echo '#v(10pt)'
  for mi in $(seq 0 $((n_models-1))); do
    mid=$(jq -r ".models[$mi].id" "$MANIFEST"); base=$(jq -r ".models[$mi].base" "$MANIFEST"); fam=$(jq -r ".models[$mi].family" "$MANIFEST")
    printf '#text(size: 13pt, weight: "bold")[%s] #h(6pt)#text(fill: rgb("#9aa2c0"))[%s · %s]\n#v(3pt)\n' "$mid" "$base" "$fam"
    printf '#grid(columns: %s, gutter: 5pt,\n' "$(echo "$cats"|wc -l)"
    while IFS= read -r cid; do
      th="thumbs/$mid/$cid.png"
      if [ -f "$SURVEY_DIR/$th" ]; then printf '  stack(spacing: 3pt, image("%s", width: 100%%), align(center)[#text(size:7pt)[%s · %s]]),\n' "$th" "$cid" "$(score_of "$mid" "$cid")"
      else printf '  stack(spacing: 3pt, box(height: 60pt, fill: rgb("#2a2a3c"), width: 100%%, align(center+horizon)[—]), align(center)[#text(size:7pt)[%s]]),\n' "$cid"; fi
    done <<<"$cats"
    echo ')'; echo '#v(10pt)'
  done
} > "$TYP"

typst compile "$TYP" "$RAW" || { echo "typst compile failed" >&2; exit 1; }
raw_sz=$(wc -c < "$RAW")
# Ghostscript downsample/recompress → efficient PDF (no Pillow/ImageMagick needed).
if gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/ebook \
      -dDownsampleColorImages=true -dColorImageResolution=120 \
      -dDownsampleGrayImages=true -dGrayImageResolution=120 \
      -dNOPAUSE -dBATCH -dQUIET -sOutputFile="$PDF" "$RAW" 2>/dev/null; then
  opt_sz=$(wc -c < "$PDF"); rm -f "$RAW"
  echo "PDF: $PDF  (raw ${raw_sz}B → optimized ${opt_sz}B)"
else
  mv "$RAW" "$PDF"; echo "PDF: $PDF (gs unavailable; shipped raw)"
fi
