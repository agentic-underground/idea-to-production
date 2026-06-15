#!/usr/bin/env bash
# raster-lint.sh — the CHEAP raster tier between SVG-math (layout-check.sh) and expensive machine vision.
#
# WHY THIS EXISTS ----------------------------------------------------------------------------------------
# A reviewer's vision Read is expensive (tokens + latency). layout-check.sh already catches everything the
# SVG geometry can prove (horizontal overflow, vertical bounds, inline-legibility) for FREE. But a class of
# defects is *vision-only*: they live in PIXELS, not in the SVG numbers — content sheared at the canvas
# frame, ink packed so tight it overlaps, a bright stroke laid across a text label (occlusion / z-index).
# This script rasterises the figure and runs deterministic, token-free ImageMagick heuristics to decide the
# ONE question that saves the most money: does any tile look suspicious enough to be worth a vision Read?
#
#   CLEAN  → exit 0  → the reviewer SKIPS vision (cost saved).
#   SUSPECT→ exit 1  → the reviewer ESCALATES to a vision Read of the full render / the suspect crops.
#
# These are SUSPICION heuristics. FALSE POSITIVES ARE ACCEPTABLE — vision confirms or dismisses. The gate is
# still the reviewer's eye; this lint only decides *whether* to spend it. (Per plan PHASE 1 → raster-lint.)
#
# USAGE -------------------------------------------------------------------------------------------------
#   bash raster-lint.sh <fig.svg | fig.png | fig.gif> [inline_w]      (inline_w default 640)
#     • .svg → rasterised with rsvg-convert (the figure's own dark-mode ground is kept; canon is #1e1e2e).
#     • .gif → coalesced; the LAST (poster) frame is linted (the settled, fully-revealed state).
#     • .png → used directly.
#   The figure is rendered TWICE: an inline-width (~640px) copy for legibility-relevant checks, and a
#   full-resolution copy for the pixel-precise edge check.
#
# HEURISTICS SHIPPED (tuned against real committed renders so they actually discriminate) ---------------
#   [1] EDGE-CLIP-BY-PIXEL  (SOLID) — ink in the outermost 3px border strip of the canvas. Real figures read
#       0.000 on every edge; a label sheared past the frame reads >0.01. Floor: EDGE_FRAC=0.01.
#   [2] CROWDING / DENSITY  (advisory-grade) — per-tile ink fraction on an 8×4 grid. Flags a tile packed
#       beyond any legitimate fill. A figure's OWN solid fills (mockup placeholder blocks, filled bars) are
#       legitimately dense — the committed corpus reaches 0.69 on such a block — and ink fraction alone
#       cannot separate a solid fill from pathological overlap. Floor: CROWD_FRAC=0.72, above the corpus's
#       legitimate solid-fill maximum, so only a near-solid region beyond any expected fill trips. Subtler
#       overlap is deliberately conceded to the vision-backstop.
#   [3] THIN-BRIGHT-LINE-THROUGH-TEXT / OCCLUSION  (SOLID for HORIZONTAL; partial for vertical) — a thin
#       bright stroke is isolated with a long line-morphology open, then required to cross a genuinely
#       TEXT-DENSE tile (ink ≥ OCC_TEXT) while being a MINORITY of that tile's ink (line ≤ OCC_RATIO × ink)
#       across a contiguous run (≥ OCC_RUN tiles) on a 16×8 grid. The minority rule is what discriminates a
#       stroke laid ACROSS text (line ≈ 8–15% of local ink) from a figure's OWN structural bright element —
#       a bar, banner, conveyor rail, radar spine, or connector arrow — which IS essentially all the ink in
#       its tile (line ≈ 60–100% of local ink) and so reads as line+text under a naive coincidence test. A
#       textless bright bar fails the OCC_TEXT floor outright; a bar the label sits BESIDE fails OCC_RATIO.
#
# WHAT STAYS VISION-ONLY (documented honestly) ----------------------------------------------------------
#   • SUBTLE VERTICAL occlusion (a thin vertical line crossing a small label) — a single vertical stroke
#     rarely spans enough text-dense tiles to clear the FP-safe run threshold. Strong vertical lines through
#     dense text DO trip; subtle ones are left to the reviewer's eye.
#   • SEMANTIC overlap (two labels that touch but neither tile is fully packed), z-order where the occluder
#     matches the background, and any "is this the RIGHT content" judgement — all the reviewer's eye.
#   • SUBTLE crowding/overlap below the solid-fill floor — see [2]; ink fraction cannot tell it from a
#     legitimate solid fill, so it is conceded to the vision-backstop rather than always-SUSPECTed.
#   • CROWDING is a proxy for packing, NOT for tiny-text: tiny-but-spaced text is layout-check.sh's
#     inline-legibility rule, not this tier.
#
# magick-GUARDED: if `magick` is absent this prints a notice and exits 0 — it NEVER blocks a build.
# 0-GPU, deterministic, pure bash + ImageMagick. No tokens.
set -euo pipefail

# --- tunables (corpus-calibrated; override via env for re-calibration) ---------------------------------
INLINE_W="${2:-${INLINE_W:-640}}"   # inline render width for legibility-relevant checks
GROUND="${GROUND:-#1e1e2e}"         # dark-mode canon ground; transparent figures are flattened onto it
FUZZ="${FUZZ:-12%}"                 # colour tolerance separating ink from ground
EDGE_PX="${EDGE_PX:-3}"             # width of the border strip sampled for edge-clip
EDGE_FRAC="${EDGE_FRAC:-0.01}"      # ink fraction in a border strip that counts as a clip
GRID_C="${GRID_C:-8}"              # crowding grid columns
GRID_R="${GRID_R:-4}"              # crowding grid rows
CROWD_FRAC="${CROWD_FRAC:-0.72}"    # per-tile ink fraction that counts as packed. A figure's own SOLID
                                   # FILLS (mockup placeholder blocks, filled bars) are legitimately dense
                                   # — the committed corpus tops out at 0.69 on such a block — and ink
                                   # fraction alone cannot tell a solid fill from pathological overlap. So
                                   # the floor sits ABOVE the corpus's legitimate solid-fill maximum: only
                                   # a near-solid region beyond any expected fill trips. Subtler overlap is
                                   # deliberately left to the vision-backstop (see WHAT STAYS VISION-ONLY).
OCC_C="${OCC_C:-16}"               # occlusion grid columns (finer, to localise a thin stroke)
OCC_R="${OCC_R:-8}"                # occlusion grid rows
OCC_BRIGHT="${OCC_BRIGHT:-68%}"    # brightness threshold isolating a bright stroke from coloured ink
OCC_KERN="${OCC_KERN:-71}"         # line-morphology kernel length (px) a stroke must survive
OCC_LINE="${OCC_LINE:-0.02}"       # per-tile bright-line-survivor fraction counted as "line present"
OCC_TEXT="${OCC_TEXT:-0.18}"       # per-tile ink fraction required to call a tile genuinely TEXT-DENSE
OCC_RATIO="${OCC_RATIO:-0.35}"     # line-ink must be < this fraction of the tile's ink (a stroke CROSSING
                                   # text, not a structural bar/banner that IS the ink). Genuine occlusion
                                   # runs ~0.08–0.15; a bright bar/banner/connector runs ~0.6–1.0.
OCC_RUN="${OCC_RUN:-5}"            # contiguous tiles a line-through-text run must span to be SUSPECT

# --- magick guard (graceful — never blocks) ------------------------------------------------------------
if ! command -v magick >/dev/null 2>&1; then
  echo "raster-lint: magick absent, skipping (no cheap tier)"
  exit 0
fi

IN="${1:-}"
[ -n "$IN" ] || { echo "usage: bash raster-lint.sh <fig.svg|fig.png|fig.gif> [inline_w]" >&2; exit 2; }
[ -f "$IN" ] || { echo "raster-lint: no such file: $IN" >&2; exit 2; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- 1. obtain a FULL-RES PNG of the figure (or the GIF poster frame) -----------------------------------
ext="${IN##*.}"; ext="${ext,,}"
FULL="$TMP/full.png"
case "$ext" in
  svg)
    rsvg-convert "$IN" -o "$FULL" || { echo "raster-lint: rsvg-convert failed on $IN" >&2; exit 2; }
    ;;
  gif)
    # Coalesce and keep the LAST (poster) frame — the settled, fully-revealed state of the animation.
    magick "$IN" -coalesce "$TMP/coal_%04d.png" || { echo "raster-lint: gif coalesce failed" >&2; exit 2; }
    LAST="$(ls "$TMP"/coal_*.png 2>/dev/null | sort | tail -1)"
    [ -n "$LAST" ] || { echo "raster-lint: no frames in $IN" >&2; exit 2; }
    cp "$LAST" "$FULL"
    ;;
  png)
    cp "$IN" "$FULL"
    ;;
  *)
    echo "raster-lint: unsupported input .$ext (need svg|png|gif)" >&2; exit 2 ;;
esac

# NB: `magick ... info:` emits NO trailing newline, so `read` returns 1 at EOF — tolerate it (|| true).
read -r FW FH < <(magick "$FULL" -format "%w %h" info:) || true
{ [ "${FW:-0}" -gt 0 ] && [ "${FH:-0}" -gt 0 ]; } || { echo "raster-lint: could not read dimensions of render" >&2; exit 2; }

# --- 2. inline-width render for the legibility-relevant (tile) checks -----------------------------------
INLINE="$TMP/inline.png"
if [ "$FW" -gt "$INLINE_W" ]; then
  magick "$FULL" -resize "${INLINE_W}x" "$INLINE"
else
  cp "$FULL" "$INLINE"
fi
read -r IW IH < <(magick "$INLINE" -format "%w %h" info:) || true

# --- 3. fixed-width (1280px) render for the occlusion pass --------------------------------------------
# Occlusion is a pixel-precision defect: a thin bright stroke survives downscaling poorly, and the line
# morphology kernel must mean a consistent length regardless of the figure's native size. So normalise to a
# fixed working width (only ever downscaling a larger figure; small figures upscale to keep the stroke).
OCCW="${OCCW:-1280}"
OCCIMG="$TMP/occ.png"
magick "$FULL" -background "$GROUND" -flatten -alpha off -resize "${OCCW}x" "$OCCIMG"
read -r OW OH < <(magick "$OCCIMG" -format "%w %h" info:) || true

# --- ink-mask helper: flatten onto GROUND, drop alpha, fuzz-separate ink (white) from ground (black) ----
# Emitting MIFF on stdout so callers can pipe. Works for both opaque #1e1e2e figures and transparent ones.
inkmask() { magick "$1" -background "$GROUND" -flatten -alpha off -fuzz "$FUZZ" \
              -fill black -opaque "$GROUND" -fill white +opaque black miff:- ; }

SUSPECTS=0
report() { echo "SUSPECT $*"; SUSPECTS=$((SUSPECTS+1)); }

# ========================================================================================================
# HEURISTIC 1 — EDGE-CLIP-BY-PIXEL  (run on the FULL-RES render; the frame edge is pixel-exact there)
# ========================================================================================================
EMASK="$TMP/edgemask.miff"; inkmask "$FULL" > "$EMASK"
S="$EDGE_PX"
declare -A EGEOM=(
  [top]="${FW}x${S}+0+0"
  [bot]="${FW}x${S}+0+$((FH-S))"
  [left]="${S}x${FH}+0+0"
  [right]="${S}x${FH}+$((FW-S))+0"
)
for side in top bot left right; do
  frac=$(magick "$EMASK" -crop "${EGEOM[$side]}" +repage -alpha off -format "%[fx:mean]" info:)
  if awk -v f="$frac" -v t="$EDGE_FRAC" 'BEGIN{exit !(f>t)}'; then
    case "$side" in
      top)   bbox="0,0,${FW},${S}" ;;
      bot)   bbox="0,$((FH-S)),${FW},${S}" ;;
      left)  bbox="0,0,${S},${FH}" ;;
      right) bbox="$((FW-S)),0,${S},${FH}" ;;
    esac
    report "edge-clip tile=${side},- bbox=${bbox} (ink_frac=$(printf '%.4f' "$frac") > ${EDGE_FRAC})"
  fi
done

# ========================================================================================================
# HEURISTIC 2 — CROWDING / DENSITY ANOMALY  (per-tile ink on an 8×4 grid of the inline render)
# Box-resize the ink mask to GRID_C×GRID_R: each output pixel's value/255 is that tile's ink fraction.
# ========================================================================================================
inkmask "$INLINE" | magick - -alpha off -filter box -resize "${GRID_C}x${GRID_R}!" -depth 8 txt:- \
  | grep -v '^#' \
  | sed -E 's/^([0-9]+),([0-9]+): \(([0-9]+).*/\1 \2 \3/' \
  | while read -r c r val; do
      frac=$(awk -v v="$val" 'BEGIN{printf "%.4f", v/255}')
      if awk -v f="$frac" -v t="$CROWD_FRAC" 'BEGIN{exit !(f>t)}'; then
        tw=$((IW/GRID_C)); th=$((IH/GRID_R))
        echo "SUSPECT crowding tile=${r},${c} bbox=$((c*tw)),$((r*th)),${tw},${th} (ink_frac=${frac} > ${CROWD_FRAC})"
      fi
    done > "$TMP/crowd.out"
if [ -s "$TMP/crowd.out" ]; then cat "$TMP/crowd.out"; SUSPECTS=$((SUSPECTS + $(grep -c '^SUSPECT' "$TMP/crowd.out" || true))); fi

# ========================================================================================================
# HEURISTIC 3 — THIN-BRIGHT-LINE-THROUGH-TEXT / OCCLUSION  (fixed-width OCC render, 16×8 grid)
# A bright stroke is isolated by thresholding brightness then opening with a long line kernel (only a
# genuine spanning line survives). A tile is "line+text" when it has both a line survivor AND ink. We then
# look for a contiguous RUN of such tiles along a row (horizontal occluder) or column (vertical occluder).
# Runs on the fixed-width OCC render so the kernel length is scale-invariant and the thin stroke survives.
# ========================================================================================================
# text-ink per tile
inkmask "$OCCIMG" | magick - -alpha off -filter box -resize "${OCC_C}x${OCC_R}!" -depth 8 txt:- \
  | grep -v '^#' | sed -E 's/^([0-9]+),([0-9]+): \(([0-9]+).*/\1 \2 \3/' > "$TMP/occ_text.txt"
# bright-line survivor per tile (horizontal OR vertical line morphology, max-combined)
magick "$OCCIMG" -threshold "$OCC_BRIGHT" \
    \( -clone 0 -morphology Open "Rectangle:${OCC_KERN}x1" \) \
    \( -clone 0 -morphology Open "Rectangle:1x${OCC_KERN}" \) \
    -delete 0 -evaluate-sequence max -alpha off \
    -filter box -resize "${OCC_C}x${OCC_R}!" -depth 8 txt:- \
  | grep -v '^#' | sed -E 's/^([0-9]+),([0-9]+): \(([0-9]+).*/\1 \2 \3/' > "$TMP/occ_line.txt"

paste "$TMP/occ_text.txt" "$TMP/occ_line.txt" | awk \
  -v C="$OCC_C" -v R="$OCC_R" -v RUN="$OCC_RUN" \
  -v LINE="$OCC_LINE" -v TEXT="$OCC_TEXT" -v RATIO="$OCC_RATIO" \
  -v IW="$OW" -v IH="$OH" '
  { td[$2","$1]=$3/255; bl[$2","$1]=$6/255 }
  # A tile is "line-THROUGH-text" only when it (a) carries a surviving bright line, (b) is genuinely
  # text-DENSE (ink ≥ TEXT — a textless bright bar fails here), and (c) the line is a MINORITY of that
  # ink (line ≤ RATIO × ink — a structural bar/banner/rail/spine/connector, where the bright element IS
  # the ink, fails here; only a thin stroke laid ACROSS dense text passes).
  function hit(key,   tf,lf) {
    tf=td[key]; lf=bl[key]
    return (lf>LINE && tf>TEXT && lf <= RATIO*tf)
  }
  END {
    tw=int(IW/C); th=int(IH/R)
    # horizontal occluders: contiguous run of line-through-text tiles along a row
    for (r=0;r<R;r++){
      run=0; start=-1
      for (c=0;c<=C;c++){
        h=(c<C && hit(r","c))
        if (h){ if(run==0)start=c; run++ }
        else { if(run>=RUN) printf "SUSPECT occlusion tile=%d,%d bbox=%d,%d,%d,%d (h-line-through-text run=%d)\n", r,start, start*tw, r*th, run*tw, th, run; run=0 }
      }
    }
    # vertical occluders: contiguous run of line-through-text tiles along a column
    for (c=0;c<C;c++){
      run=0; start=-1
      for (r=0;r<=R;r++){
        h=(r<R && hit(r","c))
        if (h){ if(run==0)start=r; run++ }
        else { if(run>=RUN) printf "SUSPECT occlusion tile=%d,%d bbox=%d,%d,%d,%d (v-line-through-text run=%d)\n", start,c, c*tw, start*th, tw, run*th, run; run=0 }
      }
    }
  }' > "$TMP/occ.out"
if [ -s "$TMP/occ.out" ]; then cat "$TMP/occ.out"; SUSPECTS=$((SUSPECTS + $(grep -c '^SUSPECT' "$TMP/occ.out" || true))); fi

# --- summary + exit ------------------------------------------------------------------------------------
NAME="$(basename "$IN")"
if [ "$SUSPECTS" -eq 0 ]; then
  echo "raster-lint CLEAN: $NAME — full ${FW}x${FH}, inline ${IW}x${IH}, 0 suspect tiles → reviewer may SKIP vision"
  exit 0
else
  echo "raster-lint SUSPECT: $NAME — $SUSPECTS suspect region(s) → reviewer should ESCALATE to a vision Read of the full render / the suspect crops"
  exit 1
fi
