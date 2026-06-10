#!/usr/bin/env bash
# reslow.sh — universal, generator-agnostic re-timer for the animated README figures.
# Implements the house motion policy (art-direction note, 2026-06-10): SLOWER pace, LINGER on each frame with
# the slightest pulse (a gentle brightness breathe, not a flicker), and STAY on the final frame a lot longer
# before looping. Operates on the FINISHED gif (coalesce -> re-time -> reassemble), so it works on every figure
# regardless of how its generator emits frames. 0-GPU, deterministic, parameter-only.
#
# Usage: bash reslow.sh <path/to/figure.gif> [fps]
set -euo pipefail
GIF="$1"; FPS="${2:-13}"
[ -f "$GIF" ] || { echo "no gif: $GIF" >&2; exit 2; }
GIFSKI="${GIFSKI:-$HOME/.cargo/bin/gifski}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
command -v magick >/dev/null || { echo "magick required" >&2; exit 2; }

magick "$GIF" -coalesce "$TMP/c_%04d.png"
mapfile -t FRAMES < <(ls "$TMP"/c_*.png | sort)
[ "${#FRAMES[@]}" -gt 0 ] || { echo "no frames extracted" >&2; exit 2; }
LAST="${FRAMES[-1]}"

# per-hold breathe (one soft rise-and-fall per state — a slow pulse, never a per-frame flicker)
PULSE=(100 102 104 102)
HOLDLEN=${#PULSE[@]}
FINAL_HOLD=26          # frames of calm dwell on the settled final frame before the loop restarts

OUTD="$TMP/out"; mkdir -p "$OUTD"; n=0
emit() { magick "$1" -modulate "$2" "$OUTD/$(printf '%05d' "$n").png"; n=$((n+1)); }

# every original frame lingers HOLDLEN frames with the gentle breathe → slower, alive, not frozen
for f in "${FRAMES[@]}"; do for b in "${PULSE[@]}"; do emit "$f" "$b"; done; done
# long, calm dwell on the final frame (continues the slow breathe so it is not a dead freeze) → then loops
for ((k=0;k<FINAL_HOLD;k++)); do emit "$LAST" "${PULSE[$((k % HOLDLEN))]}"; done

if [ -x "$GIFSKI" ]; then "$GIFSKI" --fps "$FPS" --quality 90 -o "$GIF" "$OUTD"/*.png >/dev/null 2>&1
else magick -delay $((100/FPS)) "$OUTD"/*.png "$GIF"; fi
command -v gifsicle >/dev/null && gifsicle --colors 200 --lossy=40 -O3 -b "$GIF" >/dev/null 2>&1
echo "$(basename "$GIF"): $(magick identify "$GIF" 2>/dev/null | wc -l) frames, $(stat -c%s "$GIF") bytes"
