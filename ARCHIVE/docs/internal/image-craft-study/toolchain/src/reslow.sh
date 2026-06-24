#!/usr/bin/env bash
# reslow.sh — universal, generator-agnostic re-timer for the animated README figures.
# Implements the house Motion canon — see plugins/pressroom/knowledge/raster-toolchain.md '## Motion canon'
# (that doc is the source of truth; this script is its implementation). In short: SLOWER pace, LINGER on each
# frame with a gentle brightness breathe (the PULSE, never a flicker), per-frame holds from a TIMING.tsv for
# organic meter (dense "Ah-HA!" beats linger, transitions flick), and a long settled dwell before the loop.
# Operates on the FINISHED gif (coalesce -> re-time -> reassemble), so it works on every figure regardless of
# how its generator emits frames. 0-GPU, deterministic, parameter-only.
#
# Two timing modes (B2 — organic meter & linger):
#   * TIMING.tsv mode — when a TIMING.tsv is given as $3 (or env TIMING_TSV) AND it exists AND its row count
#     equals the coalesced frame count of the gif: use its PER-FRAME hold counts so info-dense beats linger
#     ("Ah-HA!") and pure transitions flick by. The gentle PULSE breathe is still applied WITHIN each frame's
#     hold window (PULSE index = position-within-hold modulo PULSE length). No separate FINAL_HOLD is added —
#     the poster frame's long dwell is already encoded as that row's holds value.
#   * uniform mode (fallback) — no TIMING.tsv (absent / not given / row-count mismatch): EXACTLY the original
#     behaviour — HOLDLEN frames per source frame, plus FINAL_HOLD calm frames on the last frame.
# A one-line note states which mode ran (and, on mismatch, why).
#
# Usage: bash reslow.sh <path/to/figure.gif> [fps] [TIMING.tsv]
set -euo pipefail
GIF="$1"; FPS="${2:-13}"; TIMING_TSV="${3:-${TIMING_TSV:-}}"
[ -f "$GIF" ] || { echo "no gif: $GIF" >&2; exit 2; }
GIFSKI="${GIFSKI:-$HOME/.cargo/bin/gifski}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
command -v magick >/dev/null || { echo "magick required" >&2; exit 2; }

magick "$GIF" -coalesce "$TMP/c_%04d.png"
mapfile -t FRAMES < <(ls "$TMP"/c_*.png | sort)
[ "${#FRAMES[@]}" -gt 0 ] || { echo "no frames extracted" >&2; exit 2; }
NFRAMES=${#FRAMES[@]}
LAST="${FRAMES[-1]}"

# per-hold breathe (one soft rise-and-fall per state — a slow pulse, never a per-frame flicker)
PULSE=(100 102 104 102)
HOLDLEN=${#PULSE[@]}
FINAL_HOLD=26          # frames of calm dwell on the settled final frame before the loop restarts

OUTD="$TMP/out"; mkdir -p "$OUTD"; n=0
emit() { magick "$1" -modulate "$2" "$OUTD/$(printf '%05d' "$n").png"; n=$((n+1)); }

# Decide timing mode. TIMING.tsv mode requires: a path given, the file exists, and its row count == frame count.
USE_TIMING=0
if [ -n "$TIMING_TSV" ]; then
  if [ -f "$TIMING_TSV" ]; then
    TROWS=$(grep -c '' "$TIMING_TSV" 2>/dev/null || echo 0)
    if [ "$TROWS" -eq "$NFRAMES" ]; then
      USE_TIMING=1
    else
      echo "reslow: TIMING.tsv has $TROWS rows but gif coalesces to $NFRAMES frames — falling back to uniform"
    fi
  else
    echo "reslow: TIMING.tsv path given ($TIMING_TSV) but file not found — falling back to uniform"
  fi
fi

if [ "$USE_TIMING" -eq 1 ]; then
  echo "reslow: TIMING.tsv mode — per-frame holds from $(basename "$TIMING_TSV") ($NFRAMES frames)"
  # Parse holds column (3rd, TAB-separated) in emission order. Default any unreadable/<1 hold to 1.
  mapfile -t HOLDS < <(awk -F'\t' '{ h=$3+0; if (h<1) h=1; print h }' "$TIMING_TSV")
  total_out=0
  for ((i=0; i<NFRAMES; i++)); do
    h="${HOLDS[$i]:-1}"
    for ((k=0; k<h; k++)); do
      emit "${FRAMES[$i]}" "${PULSE[$((k % HOLDLEN))]}"
    done
    total_out=$((total_out + h))
  done
  echo "reslow: emitted $total_out output frames from $NFRAMES source frames (sum of holds)"
else
  echo "reslow: uniform mode — ${HOLDLEN}× each of $NFRAMES frames + ${FINAL_HOLD}-frame final dwell"
  # every original frame lingers HOLDLEN frames with the gentle breathe → slower, alive, not frozen
  for f in "${FRAMES[@]}"; do for b in "${PULSE[@]}"; do emit "$f" "$b"; done; done
  # long, calm dwell on the final frame (continues the slow breathe so it is not a dead freeze) → then loops
  for ((k=0;k<FINAL_HOLD;k++)); do emit "$LAST" "${PULSE[$((k % HOLDLEN))]}"; done
fi

if [ -x "$GIFSKI" ]; then "$GIFSKI" --fps "$FPS" --quality 90 -o "$GIF" "$OUTD"/*.png >/dev/null 2>&1
else magick -delay $((100/FPS)) "$OUTD"/*.png "$GIF"; fi
command -v gifsicle >/dev/null && gifsicle --colors 200 --lossy=40 -O3 -b "$GIF" >/dev/null 2>&1
echo "$(basename "$GIF"): $(magick identify "$GIF" 2>/dev/null | wc -l) frames, $(stat -c%s "$GIF") bytes"
