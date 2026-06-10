#!/usr/bin/env bash
# contact-sheets.sh — one labelled A/B review PNG per objective (its techniques side by side), 0 GPU,
# 0 model tokens. The SCORE phase reads ONE sheet per objective so a single agent judges the whole A/B
# (baseline vs treatment) and names the gain. Local ImageMagick 7 (`magick montage`).
#
# Usage: CRAFT_DIR=doc/image-craft-study/craft bash contact-sheets.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_root() { local d="$HERE"; while [ "$d" != / ]; do [ -f "$d/.claude-plugin/marketplace.json" ] && { echo "$d"; return; }; d="$(dirname "$d")"; done; echo "$PWD"; }
CRAFT_DIR="${CRAFT_DIR:-$(find_root)/doc/image-craft-study/craft}"
MANIFEST="$CRAFT_DIR/manifest.json"
OUT="$CRAFT_DIR/contact-sheets"; mkdir -p "$OUT"
command -v magick >/dev/null || { echo "magick (ImageMagick 7) required" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "no manifest" >&2; exit 2; }

n_obj=$(jq '.objectives | length' "$MANIFEST")
made=0
for oi in $(seq 0 $((n_obj-1))); do
  OBJ=$(jq -c ".objectives[$oi]" "$MANIFEST")
  oid=$(jq -r '.id' <<<"$OBJ")
  args=(); n=0
  for tid in $(jq -r '.techniques[]' <<<"$OBJ"); do
    img="$CRAFT_DIR/thumbs/$oid/$tid.png"; [ -f "$img" ] || img="$CRAFT_DIR/images/$oid/$tid.png"
    [ -f "$img" ] || continue
    lbl=$(jq -r --arg t "$tid" '.techniques[$t].label // $t' "$MANIFEST")
    args+=( -label "$tid: $lbl" "$img" ); n=$((n+1))
  done
  [ "$n" -gt 0 ] || { echo "  $oid: no images yet"; continue; }
  gain=$(jq -r '.gain_under_test // ""' <<<"$OBJ")
  magick montage "${args[@]}" \
    -tile "${n}x1" -geometry +8+8 -background '#11111b' -fill '#e8e8ef' \
    -font DejaVu-Sans -pointsize 13 \
    -title "$oid  —  gain under test: $gain" \
    "$OUT/$oid.png" 2>/dev/null \
    && { echo "  sheet: $oid ($n cells)"; made=$((made+1)); } \
    || echo "  $oid: montage failed"
done
echo "contact sheets: $made objective(s) → $OUT"
