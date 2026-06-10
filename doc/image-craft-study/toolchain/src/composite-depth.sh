#!/usr/bin/env bash
# composite-depth.sh — give flat dark-mode diagram frames real "lightbox" depth so bright elements POP.
#
# The frames have an OPAQUE `#1e1e2e` ground, so compositing them OVER a backdrop is a no-op. Instead, per
# PNG frame: cut the bright elements off the ground, lay them back as a CRISP top layer over a DIM,
# heavily-BLURRED halo of themselves, on a slightly-DARKENED plate, then a vignette for shadow weight.
# Result: bright teal/amber/text elements sit SHARP over their own soft glow on a darker field — real
# depth, weighted shadows. 0-GPU, deterministic, parameter-only.
#
# Usage: bash composite-depth.sh <frames_dir> [ground_hex]
#   ground_hex default #1e1e2e. Operates on every *.png in frames_dir, OVERWRITING each in place.
#
# Pipeline insertion: run AFTER rsvg-convert, BEFORE the first gifski (so reslow's coalesce+modulate
# preserves the look and no double-application occurs).
#
# magick-guarded: if `magick` is absent it skips cleanly (exit 0) and leaves frames flat — must NOT break
# the build.
set -euo pipefail

DIR="${1:?usage: composite-depth.sh <frames_dir> [ground_hex]}"
GROUND="${2:-#1e1e2e}"

if ! command -v magick >/dev/null 2>&1; then
  echo "composite-depth: magick absent, skipping (frames left flat)"
  exit 0
fi

[ -d "$DIR" ] || { echo "composite-depth: not a directory: $DIR" >&2; exit 2; }

shopt -s nullglob
PNGS=("$DIR"/*.png)
shopt -u nullglob
if [ "${#PNGS[@]}" -eq 0 ]; then
  echo "composite-depth: no *.png in $DIR — nothing to do"
  exit 0
fi

count=0
for f in "${PNGS[@]}"; do
  tmp="$(mktemp --suffix=.png)"
  cut="$(mktemp --suffix=.png)"
  # 1. cut: bright elements off the ground onto transparency.
  magick "$f" -fuzz 10% -transparent "$GROUND" "$cut"
  # 2-4. plate (darker backing) → screen the dim heavily-blurred halo → lay the crisp cut over → vignette.
  #   - plate: the whole frame pushed 30% toward the ground colour → a darker field.
  #   - halo: the cut blurred 0x18 and dimmed to 60% brightness, +15% saturation so the colour reads
  #     through the glow; screened on so it lifts the plate locally around each element without a hard edge.
  #   - cut: composited OVER at full crispness → the sharp top layer that pops.
  #   - vignette: corner shadow weight so the lit centre reads as raised off a darker frame.
  #   - vignette: drawn against a near-ground (not pure black) backing so corners darken toward the field
  #     instead of punching transparent holes; flattened back to OPAQUE so the frame stays solid for gifski.
  magick "$f" -fill "$GROUND" -colorize 30% \
    \( "$cut" -blur 0x18 -modulate 60,115,100 \) -compose screen -composite \
    \( "$cut" \) -compose over -composite \
    -alpha off \
    -background "#0a0a12" -vignette 0x14+8+8 \
    -background "#0a0a12" -flatten -alpha off \
    "$tmp"
  mv -f "$tmp" "$f"
  rm -f "$cut"
  count=$((count + 1))
done

echo "composite-depth: applied lightbox depth to $count frame(s) in $DIR (ground $GROUND)"
