#!/usr/bin/env bash
# build-figure.sh — the canonical per-figure pipeline, so all 11 README figures rebuild identically.
#
# A diagram generator (build-*-frames.sh) emits f000.svg, f001.svg, … into an output dir (and, in Wave 2,
# a TIMING.tsv alongside them). This orchestrator carries one figure from generator to shipped GIF:
#   generate SVGs → rasterise (rsvg-convert) → composite depth (C2) → assemble base GIF (gifski) →
#   re-time (reslow.sh, TIMING.tsv-aware) → frame-strip proof.
# 0-GPU, deterministic. Each external tool is guarded; it fails LOUDLY if the generator emits no SVGs.
#
# Usage: bash build-figure.sh <generator.sh> <output.gif> [fps]   (fps default 13)
set -euo pipefail

GEN="${1:?usage: build-figure.sh <generator.sh> <output.gif> [fps]}"
OUT="${2:?usage: build-figure.sh <generator.sh> <output.gif> [fps]}"
FPS="${3:-13}"
HERE="$(cd "$(dirname "$0")" && pwd)"

[ -f "$GEN" ] || { echo "build-figure: generator not found: $GEN" >&2; exit 2; }
command -v rsvg-convert >/dev/null || { echo "build-figure: rsvg-convert required" >&2; exit 2; }
GIFSKI="${GIFSKI:-$HOME/.cargo/bin/gifski}"
if ! command -v gifski >/dev/null 2>&1 && [ ! -x "$GIFSKI" ]; then
  echo "build-figure: gifski required (not on PATH and not at $GIFSKI)" >&2; exit 2
fi
command -v magick >/dev/null || { echo "build-figure: magick required (for strip + reslow)" >&2; exit 2; }

GROUND='#1e1e2e'
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# 1. generate the SVG frames.
echo "build-figure: generating frames via $(basename "$GEN") → $TMP"
bash "$GEN" "$TMP"

shopt -s nullglob
SVGS=("$TMP"/f*.svg)
shopt -u nullglob
[ "${#SVGS[@]}" -gt 0 ] || { echo "build-figure: generator emitted 0 SVGs into $TMP — aborting" >&2; exit 3; }
echo "build-figure: $(printf '%s\n' "${SVGS[@]}" | wc -l) SVG frame(s) emitted"

# 2. rasterise every f*.svg → same-name .png. SVGs carry their own opaque ground; pass -b for safety.
for svg in "${SVGS[@]}"; do
  png="${svg%.svg}.png"
  rsvg-convert "$svg" -b "$GROUND" -o "$png"
done
shopt -s nullglob
PNGS=("$TMP"/f*.png)
shopt -u nullglob
[ "${#PNGS[@]}" -gt 0 ] || { echo "build-figure: rasterise produced 0 PNGs — aborting" >&2; exit 3; }

# 3. (no raster compositing) — frames stay flat SVG per the maintainer's call:
#    the composite-depth vignette/backdrop was rejected. Frames go straight to assembly.

# 4. assemble the base GIF.
echo "build-figure: assembling base GIF → $OUT @ ${FPS}fps"
if command -v gifski >/dev/null 2>&1; then
  gifski --fps "$FPS" --quality 90 -o "$OUT" "$TMP"/f*.png >/dev/null 2>&1
else
  "$GIFSKI" --fps "$FPS" --quality 90 -o "$OUT" "$TMP"/f*.png >/dev/null 2>&1
fi
[ -f "$OUT" ] || { echo "build-figure: gifski did not produce $OUT" >&2; exit 3; }

# 5. re-time. Pass TIMING.tsv if the generator emitted one; reslow falls back to uniform if not / mismatch.
TIMING="$TMP/TIMING.tsv"
echo "build-figure: re-timing via reslow.sh"
if [ -f "$TIMING" ]; then
  bash "$HERE/reslow.sh" "$OUT" "$FPS" "$TIMING"
else
  echo "build-figure: no TIMING.tsv from generator — reslow will use uniform mode"
  bash "$HERE/reslow.sh" "$OUT" "$FPS"
fi

# 6. frame-strip proof: sample first / 25% / 50% / 75% / last of the FINAL coalesced gif → 1×5 montage.
PROOFDIR="$HERE/../proof"
mkdir -p "$PROOFDIR"
BASE="$(basename "$OUT" .gif)"
STRIP="$PROOFDIR/${BASE}-strip.png"
STMP="$(mktemp -d)"
magick "$OUT" -coalesce "$STMP/c_%04d.png"
mapfile -t CF < <(ls "$STMP"/c_*.png | sort)
NC=${#CF[@]}
if [ "$NC" -gt 0 ]; then
  i0=0
  i1=$(( (NC - 1) * 25 / 100 ))
  i2=$(( (NC - 1) * 50 / 100 ))
  i3=$(( (NC - 1) * 75 / 100 ))
  i4=$(( NC - 1 ))
  magick montage "${CF[$i0]}" "${CF[$i1]}" "${CF[$i2]}" "${CF[$i3]}" "${CF[$i4]}" \
    -tile 1x5 -geometry 640x150+6+6 -background "#0b0b12" \
    -title "$BASE: frames $i0,$i1,$i2,$i3,$i4 of $NC" "$STRIP"
else
  echo "build-figure: WARNING — final gif coalesced to 0 frames; no strip written" >&2
fi
rm -rf "$STMP"

# 7. report.
FC="$(magick identify "$OUT" 2>/dev/null | wc -l)"
SZ="$(stat -c%s "$OUT")"
echo "build-figure: DONE"
echo "  gif:    $OUT"
echo "  frames: $FC"
echo "  bytes:  $SZ"
[ -f "$STRIP" ] && echo "  strip:  $STRIP"
