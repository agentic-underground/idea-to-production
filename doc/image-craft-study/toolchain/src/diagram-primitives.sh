#!/usr/bin/env bash
# diagram-primitives.sh — the shared, crafted diagram-primitive library.
#
# The home of the in-vector LINE-ART UPLIFT for the animated-diagram generators
# (build-foundry-conveyor-frames.sh · build-lifecycle-frames.sh ·
#  build-sentinel-gate-frames.sh · …). Generators `source` this file so they stop
# hand-rolling SVG and copy-pasting the same `<defs>` 12×, and so the craft tier
# (shading, rim light, layered strokes, soft shadow) lands ONCE and every generator
# inherits it.
#
# === THE UPLIFT — IN-VECTOR ONLY ===
# The flat originals draw a node as a single-stroke `<circle>` with one solid fill
# (#1e1e2e family) and a flat stroke — no gradient, no shading, no material, no depth.
# This library makes the line-art DIMENSIONAL using pure SVG craft:
#   · in-shape gradients (implied top-left light — a sheen, not a glow)
#   · thin inner-highlight arcs / bevel edges (a lit rim)
#   · layered strokes (a soft wide stroke under a crisp thin one)
#   · soft drop-shadows (the `ns` filter — the element sits *above* the ground)
# It is NOT a full-frame raster effect. A raster composite-depth / vignette pass was
# TRIED and REJECTED by the maintainer ("the vignette is BAD — no background, no
# composite, just SVG"). So every gram of depth here lives in the SVG itself.
# House look is preserved: FLAT dark-mode, #1e1e2e ground, teal #5eead4, amber #fbbf24,
# legible, TASTEFUL (subtle, premium — not muddy, not heavy, not a glow-bomb).
#
# === ELEMENT REGISTRY (names match motion-language.md) ===
#   NODE · TOKEN · GATE · RAIL · ARC · SWEEP · STAMP · HALO
# Each emitter is parametrised (x/y, size, state→colour, label) and writes one SVG
# fragment to stdout. The generator owns the `<svg>` wrapper, the ground `<rect>`, the
# masthead text and the `<defs>` (via `prim_defs`).
#
# Constraints honoured: pure SVG craft · 0-GPU · deterministic · `bash -n` clean.
# Source-only: this file defines functions + constants and runs nothing at source time.

# ---------------------------------------------------------------------------------
# House constants — the palette + default geometry. A generator may override any of
# these AFTER sourcing (they are plain shell vars), but the defaults ARE the house.
# ---------------------------------------------------------------------------------
: "${PRIM_GROUND:=#1e1e2e}"   # dark-mode ground
: "${PRIM_TEAL:=#5eead4}"     # done / green / sealed / cleared
: "${PRIM_AMBER:=#fbbf24}"    # current / scanning-now
: "${PRIM_RED:=#f87171}"      # failing / red test
: "${PRIM_DIM:=#3a3a55}"      # pending
: "${PRIM_TXTL:=#e8e8ef}"     # light text (on-element / active)
: "${PRIM_TXTD:=#6b7280}"     # dim text (pending / supporting)
: "${PRIM_RAILBASE:=#2a2a40}" # the unlit track

# default radii / stroke widths (px)
: "${PRIM_R_NODE:=18}"        # node radius (pending; current is larger, see prim_node)
: "${PRIM_R_TOKEN:=7}"        # token core radius
: "${PRIM_SW_RAIL:=6}"        # rail stroke width
: "${PRIM_SW_ARC:=4}"         # arc crisp stroke width
: "${PRIM_FONT:=DejaVu Sans, Arial, sans-serif}"

# Map a state word → its house colour. States: done current pending failing.
prim_color() {
  case "$1" in
    done|teal)       printf '%s' "$PRIM_TEAL" ;;
    current|amber)   printf '%s' "$PRIM_AMBER" ;;
    failing|red)     printf '%s' "$PRIM_RED" ;;
    pending|dim|*)   printf '%s' "$PRIM_DIM" ;;
  esac
}

# Darken a hex colour toward black by a 0..100 percentage — used to derive the
# bottom-of-gradient shade from the element's face colour (deterministic, no GPU).
prim_shade() {
  local hex="${1#\#}" pct="$2" r g b
  r=$(( 16#${hex:0:2} * (100 - pct) / 100 ))
  g=$(( 16#${hex:2:2} * (100 - pct) / 100 ))
  b=$(( 16#${hex:4:2} * (100 - pct) / 100 ))
  printf '#%02x%02x%02x' "$r" "$g" "$b"
}

# ---------------------------------------------------------------------------------
# prim_defs — emit the shared <defs> block ONCE. Keeps the EXISTING filter ids
# (dg / bgb / ns) so generators that only partially adopt the library don't break,
# and ADDS the new shading gradients the uplift needs. Call once, inside the <svg>,
# before any element. Idempotent within a single SVG is the caller's concern
# (emit it once per frame).
# ---------------------------------------------------------------------------------
prim_defs() {
  cat <<'DEFS'
<defs>
<!-- existing house defs (kept byte-compatible so partial adopters don't break) -->
<radialGradient id="dg" cx="50%" cy="55%" r="50%"><stop offset="0%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%" stop-color="#000000" stop-opacity="0"/></radialGradient>
<filter id="bgb" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="22"/></filter>
<filter id="ns" x="-40%" y="-40%" width="180%" height="180%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>
<!-- NEW uplift defs — in-vector shading only (no raster) -->
<!-- node-sheen: implied top-left light across a disc/plate. Subtle white-to-transparent. -->
<radialGradient id="sheen" cx="38%" cy="32%" r="72%">
  <stop offset="0%" stop-color="#ffffff" stop-opacity="0.30"/>
  <stop offset="42%" stop-color="#ffffff" stop-opacity="0.07"/>
  <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
<!-- plate-grad: gentle vertical light→dark for a raised rounded-rect (the gate/station). -->
<linearGradient id="plate" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0%" stop-color="#ffffff" stop-opacity="0.12"/>
  <stop offset="14%" stop-color="#ffffff" stop-opacity="0.04"/>
  <stop offset="100%" stop-color="#000000" stop-opacity="0.22"/>
</linearGradient>
<!-- node-core darken: a soft floor shade pooled at the bottom of a disc (grounds it). -->
<radialGradient id="pool" cx="50%" cy="72%" r="62%">
  <stop offset="0%" stop-color="#000000" stop-opacity="0"/>
  <stop offset="70%" stop-color="#000000" stop-opacity="0"/>
  <stop offset="100%" stop-color="#000000" stop-opacity="0.28"/>
</radialGradient>
<!-- arc-glow: a fat soft blur for the under-stroke of a glowing arc. -->
<filter id="arcglow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="4"/></filter>
<!-- sweep falloff: leading bright edge → trailing transparent (the radar wedge / scan). -->
<linearGradient id="sweepfade" x1="0" y1="0" x2="1" y2="0">
  <stop offset="0%" stop-color="#fbbf24" stop-opacity="0"/>
  <stop offset="72%" stop-color="#fbbf24" stop-opacity="0.30"/>
  <stop offset="100%" stop-color="#fbbf24" stop-opacity="0.85"/>
</linearGradient>
<!-- halo falloff: a soft attention ring, bright at the rim, fading inward+outward. -->
<radialGradient id="halofade" cx="50%" cy="50%" r="50%">
  <stop offset="0%" stop-color="#ffffff" stop-opacity="0"/>
  <stop offset="66%" stop-color="#ffffff" stop-opacity="0"/>
  <stop offset="84%" stop-color="#ffffff" stop-opacity="0.34"/>
  <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
</defs>
DEFS
}

# ---------------------------------------------------------------------------------
# prim_node — a crafted "material" disc. NOT a flat single-fill circle.
# Layers (bottom→top): drop-shadow body fill · grounding floor pool · top-left sheen
# · a thin inner-highlight arc (lit top rim) · a crisp outer rim stroke.
# Args: x y radius state [label] [label_dy]
#   state ∈ done|current|pending|failing  (drives face colour)
#   label  optional — drawn above the node in the state's text colour
#   label_dy optional — label baseline offset above centre (default 42)
# ---------------------------------------------------------------------------------
prim_node() {
  local x=$1 y=$2 r=$3 state=$4 label=${5:-} ldy=${6:-42}
  local face rim hi tcol
  face=$(prim_color "$state")
  rim=$(prim_shade "$face" 28)              # darker outer rim = a lit edge above a shaded one
  hi=$(prim_shade "$face" 0)                # face tone for the highlight arc base
  case "$state" in
    pending|dim) tcol="$PRIM_TXTD" ;;
    *)           tcol="$PRIM_TXTL" ;;
  esac
  # body (shadowed) + grounding pool + sheen
  printf '<circle cx="%d" cy="%d" r="%d" fill="%s" filter="url(#ns)"/>\n' "$x" "$y" "$r" "$face"
  printf '<circle cx="%d" cy="%d" r="%d" fill="url(#pool)"/>\n' "$x" "$y" "$r"
  printf '<circle cx="%d" cy="%d" r="%d" fill="url(#sheen)"/>\n' "$x" "$y" "$r"
  # thin inner-highlight arc across the top-left (the lit rim) — drawn just inside the edge
  local ri=$(( r - 2 ))
  printf '<path d="M %d %d A %d %d 0 0 1 %d %d" fill="none" stroke="%s" stroke-width="1.5" stroke-opacity="0.55" stroke-linecap="round"/>\n' \
    "$(( x - ri * 70 / 100 ))" "$(( y - ri * 70 / 100 ))" "$ri" "$ri" \
    "$(( x + ri * 70 / 100 ))" "$(( y - ri * 70 / 100 ))" "#ffffff"
  # crisp outer rim — a 1px dark ring grounds the disc against the sheen
  printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="1" stroke-opacity="0.7"/>\n' "$x" "$y" "$r" "$rim"
  if [ -n "$label" ]; then
    printf '<text x="%d" y="%d" font-family="%s" font-size="17" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' \
      "$x" "$(( y - ldy ))" "$PRIM_FONT" "$tcol" "$label"
  fi
}

# Emit just the check-mark glyph centred in a node (for a latched/done node).
# Args: x y [radius]
prim_node_check() {
  local x=$1 y=$2 r=${3:-$PRIM_R_NODE} s
  s=$(( r * 38 / 100 ))
  printf '<path d="M %d %d l %d %d l %d %d" stroke="#0f2e28" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>\n' \
    "$(( x - s ))" "$(( y + 1 ))" "$(( s * 7 / 10 ))" "$(( s * 9 / 10 ))" "$(( s * 14 / 10 ))" "$(( - s * 18 / 10 ))"
}

# ---------------------------------------------------------------------------------
# prim_token — the riding marker: a bright core + a tight halo ring.
# Args: x y [radius] [core_color] [ring_color]
# Default core is the ground (a hollow bright-edged bead, like the originals) with a
# light ring; pass a bright core for a lit token.
# ---------------------------------------------------------------------------------
prim_token() {
  local x=$1 y=$2 r=${3:-$PRIM_R_TOKEN} core=${4:-$PRIM_GROUND} ring=${5:-$PRIM_TXTL}
  # tight halo ring (the attention rim of the marker)
  printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.35"/>\n' "$x" "$y" "$(( r + 4 ))" "$ring"
  # bead body + rim
  printf '<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="2.5"/>\n' "$x" "$y" "$r" "$core" "$ring"
  # a tiny top-left sheen dot — the lit highlight on the bead
  printf '<circle cx="%d" cy="%d" r="%d" fill="#ffffff" fill-opacity="0.6"/>\n' "$(( x - r/3 ))" "$(( y - r/3 ))" "$(( r * 3 / 10 + 1 ))"
}

# ---------------------------------------------------------------------------------
# prim_gate — a raised rounded-rect plate (a gate / station), NOT a flat box.
# Layers: shadowed body fill · vertical plate gradient (light top → dark bottom)
# · a 1px inner bevel highlight on the TOP edge (the lit lip) · a crisp rim stroke.
# Args: x y w h state [label] [rx]
#   state drives the rim/accent colour; the body stays a dark plate (#23233a family).
# ---------------------------------------------------------------------------------
prim_gate() {
  local x=$1 y=$2 w=$3 h=$4 state=$5 label=${6:-} rx=${7:-9}
  local accent body tcol
  accent=$(prim_color "$state")
  body="#23233a"
  case "$state" in
    pending|dim) tcol="$PRIM_TXTD" ;;
    *)           tcol="$PRIM_TXTL" ;;
  esac
  # shadowed plate body
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="%s" filter="url(#ns)"/>\n' "$x" "$y" "$w" "$h" "$rx" "$body"
  # vertical light→dark plate gradient
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="url(#plate)"/>\n' "$x" "$y" "$w" "$h" "$rx"
  # top-edge inner bevel highlight (a thin lit lip 1px below the top)
  printf '<path d="M %d %d h %d" stroke="#ffffff" stroke-width="1" stroke-opacity="0.18" fill="none"/>\n' \
    "$(( x + rx ))" "$(( y + 2 ))" "$(( w - 2*rx ))"
  # crisp coloured rim (the state accent)
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="none" stroke="%s" stroke-width="2.5"/>\n' "$x" "$y" "$w" "$h" "$rx" "$accent"
  if [ -n "$label" ]; then
    printf '<text x="%d" y="%d" font-family="%s" font-size="17" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' \
      "$(( x + w/2 ))" "$(( y + h/2 + 6 ))" "$PRIM_FONT" "$tcol" "$label"
  fi
}

# ---------------------------------------------------------------------------------
# prim_rail — the track line PLUS a thin lighter highlight line just above it (a lit
# edge) → depth without raster. Optionally a coloured "cleared" overlay up to a point.
# Args: x1 y x2 [base_color] [width] [cleared_x] [cleared_color]
#   draws horizontal rail from x1→x2 at baseline y. If cleared_x given (> x1), a
#   semi-opaque coloured rail is laid x1→cleared_x (the lit / done track).
# ---------------------------------------------------------------------------------
prim_rail() {
  local x1=$1 y=$2 x2=$3 base=${4:-$PRIM_RAILBASE} sw=${5:-$PRIM_SW_RAIL} cx=${6:-} ccol=${7:-$PRIM_TEAL}
  # base track
  printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="%s" stroke-linecap="round"/>\n' "$x1" "$y" "$x2" "$y" "$base" "$sw"
  # lit top edge — a thin lighter highlight 1px above the track (the catch of light)
  printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#ffffff" stroke-width="1" stroke-opacity="0.12" stroke-linecap="round"/>\n' \
    "$x1" "$(( y - sw/2 ))" "$x2" "$(( y - sw/2 ))"
  if [ -n "$cx" ] && [ "$cx" -gt "$x1" ]; then
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="%s" stroke-opacity="0.5" stroke-linecap="round"/>\n' "$x1" "$y" "$cx" "$y" "$ccol" "$sw"
    # a brighter lit edge along the cleared portion
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1.2" stroke-opacity="0.5" stroke-linecap="round"/>\n' \
      "$x1" "$(( y - sw/2 ))" "$cx" "$(( y - sw/2 ))" "$ccol"
  fi
}

# ---------------------------------------------------------------------------------
# prim_arc — a smooth path with a soft glow stroke UNDER a crisp stroke (glow-on
# capable). Pass a full SVG path-data string (the caller owns the geometry).
# Args: path_d state [glow_on(0/1)] [width] [dash]
#   glow_on=1 lays a blurred fat under-stroke before the crisp top stroke.
# ---------------------------------------------------------------------------------
prim_arc() {
  local d=$1 state=$2 glow=${3:-0} sw=${4:-$PRIM_SW_ARC} dash=${5:-}
  local col da=''
  col=$(prim_color "$state")
  [ -n "$dash" ] && da=" stroke-dasharray=\"$dash\""
  if [ "$glow" -eq 1 ]; then
    printf '<path d="%s" fill="none" stroke="%s" stroke-width="%d" stroke-opacity="0.6" stroke-linecap="round" filter="url(#arcglow)"%s/>\n' \
      "$d" "$col" "$(( sw + 4 ))" "$da"
  fi
  printf '<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round"%s/>\n' "$d" "$col" "$sw" "$da"
}

# ---------------------------------------------------------------------------------
# prim_sweep — the scan / radar wedge with a gradient falloff (leading bright edge,
# trailing transparent). Two forms:
#   linear (default): a vertical scan band ending in a bright leading line at x.
#     Args: linear x y_top y_bot [band_w]
#   wedge: a rotating radar wedge from a centre.
#     Args: wedge cx cy radius angle_deg [span_deg]
# ---------------------------------------------------------------------------------
prim_sweep() {
  local form=$1
  if [ "$form" = "wedge" ]; then
    local cx=$2 cy=$3 rad=$4 ang=$5 span=${6:-34}
    # build the wedge as a path: centre → arc(ang-span → ang). Uses awk for trig (deterministic).
    read -r x0 y0 x1 y1 < <(awk -v cx="$cx" -v cy="$cy" -v r="$rad" -v a="$ang" -v s="$span" 'BEGIN{
      d=atan2(0,-1)/180; a0=(a-s)*d; a1=a*d;
      printf "%d %d %d %d", cx+r*cos(a0), cy+r*sin(a0), cx+r*cos(a1), cy+r*sin(a1) }')
    printf '<path d="M %d %d L %d %d A %d %d 0 0 1 %d %d Z" fill="url(#sweepfade)"/>\n' \
      "$cx" "$cy" "$x0" "$y0" "$rad" "$rad" "$x1" "$y1"
    # the crisp leading edge
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2" stroke-opacity="0.9"/>\n' "$cx" "$cy" "$x1" "$y1" "$PRIM_AMBER"
  else
    local x=$2 yt=$3 yb=$4 bw=${5:-46}
    printf '<rect x="%d" y="%d" width="%d" height="%d" fill="url(#sweepfade)"/>\n' "$(( x - bw ))" "$yt" "$bw" "$(( yb - yt ))"
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="3"/>\n' "$x" "$(( yt - 4 ))" "$x" "$(( yb + 4 ))" "$PRIM_AMBER"
  fi
}

# ---------------------------------------------------------------------------------
# prim_stamp — a verdict badge (PASS / READY) with a subtle inner bevel + check.
# A rounded plate (state-coloured rim, dark inset face), a bevel highlight, the
# verdict word, and a leading check glyph.
# Args: cx cy verdict_text [state] [scale]
# ---------------------------------------------------------------------------------
prim_stamp() {
  local cx=$1 cy=$2 word=$3 state=${4:-done} sc=${5:-100}
  local accent w h
  accent=$(prim_color "$state")
  w=$(( 132 * sc / 100 )); h=$(( 52 * sc / 100 ))
  local x=$(( cx - w/2 )) y=$(( cy - h/2 ))
  # plate body + gradient + shadow
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="12" fill="#192033" filter="url(#ns)"/>\n' "$x" "$y" "$w" "$h"
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="12" fill="url(#plate)"/>\n' "$x" "$y" "$w" "$h"
  # inner bevel: a thin inset lighter rect 3px in (the raised inset face)
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="9" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.10"/>\n' \
    "$(( x + 3 ))" "$(( y + 3 ))" "$(( w - 6 ))" "$(( h - 6 ))"
  # coloured rim
  printf '<rect x="%d" y="%d" width="%d" height="%d" rx="12" fill="none" stroke="%s" stroke-width="2.5"/>\n' "$x" "$y" "$w" "$h" "$accent"
  # leading check glyph
  local kx=$(( x + 22 )) ky=$(( cy ))
  printf '<path d="M %d %d l 5 6 l 11 -14" fill="none" stroke="%s" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>\n' \
    "$(( kx - 6 ))" "$ky" "$accent"
  printf '<text x="%d" y="%d" font-family="%s" font-size="%d" font-weight="800" fill="%s" text-anchor="middle">%s</text>\n' \
    "$(( cx + 14 ))" "$(( cy + 8 ))" "$PRIM_FONT" "$(( 26 * sc / 100 ))" "$accent" "$word"
}

# ---------------------------------------------------------------------------------
# prim_halo — the attention-pulse ring around an element (a soft gradient ring, not a
# hard stroke). Bright at the rim, fading inward+outward → reads as a pulse, not a band.
# Args: x y radius [color]
#   color tints a thin accent ring laid over the soft white falloff.
# ---------------------------------------------------------------------------------
prim_halo() {
  local x=$1 y=$2 r=$3 col=${4:-$PRIM_AMBER}
  # soft gradient falloff ring (the pulse body)
  printf '<circle cx="%d" cy="%d" r="%d" fill="url(#halofade)"/>\n' "$x" "$y" "$r"
  # a thin tinted accent stroke at the rim for state colour
  printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="2" stroke-opacity="0.40"/>\n' "$x" "$y" "$(( r * 84 / 100 ))" "$col"
}
