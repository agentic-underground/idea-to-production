#!/usr/bin/env bash
# Phase-10 flagship: the marketplace lifecycle (DISCOVER→IDEATE→DESIGN→BUILD→ASSURE→SECURE→PUBLISH→OPERATE ↻)
# animated as a build-up that lights each phase, then the return arc glows (OPERATE loops to DISCOVER), then
# the cycle holds and repeats. Dark-mode canon ground; teal "done" / amber "current" / dim "pending" script.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=diagram-primitives.sh
source "$HERE/diagram-primitives.sh"
OUT="${1:-lc-frames}"; mkdir -p "$OUT"
STAGES=(DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE)
N=${#STAGES[@]}
W=1320; H=300; PAD=80; CY=150; GAP=$(( (W - 2*PAD) / (N-1) ))
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"
# Named elements (motion-language.md): NODE×8 phase stations · RAIL lifecycle spine ·
# ARC the OPERATE→DISCOVER return loop (glow-on) · HALO attention on the current phase.
# Crafted forms come from diagram-primitives.sh; geometry/positions/timing are unchanged.
emit() { # $1 active (0..N) ; $2 arc_on(0/1) ; $3 path
  local active=$1 arc=$2 path=$3 i x col r tcol op state
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    prim_defs
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="44" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="#e8e8ef" text-anchor="middle">idea → production · the value cycle</text>\n' "$((W/2))"
    # RAIL — the lifecycle spine: base track + a "cleared" teal overlay up to the active phase.
    if [ "$active" -gt 1 ]; then
      prim_rail "$PAD" "$CY" "$((W-PAD))" "#2a2a40" 5 "$((PAD+(active-1)*GAP))" "$TEAL"
    else
      prim_rail "$PAD" "$CY" "$((W-PAD))" "#2a2a40" 5
    fi
    # ARC — return loop (OPERATE ↻ DISCOVER), glow-on when arc=1.
    local arc_d arc_state arc_glow=0
    arc_d="M $((W-PAD)) $((CY+18)) C $((W-PAD)) $((CY+92)), $PAD $((CY+92)), $PAD $((CY+18))"
    if [ "$arc" -eq 1 ]; then arc_state="done"; arc_glow=1; else arc_state="railbase"; fi
    if [ "$arc_state" = "railbase" ]; then
      printf '<path d="%s" fill="none" stroke="#2a2a40" stroke-width="4" opacity="0.9" stroke-dasharray="6 6"/>\n' "$arc_d"
    else
      prim_arc "$arc_d" "$arc_state" "$arc_glow" 4 "6 6"
    fi
    [ "$arc" -eq 1 ] && printf '<text x="%d" y="%d" font-family="DejaVu Sans" font-size="20" fill="%s" text-anchor="middle">↻ OPERATE'"'"'s learnings re-enter DISCOVER</text>\n' "$((W/2))" "$((CY+108))" "$TEAL"
    for i in $(seq 0 $((N-1))); do
      x=$((PAD + i*GAP))
      if [ "$i" -lt "$active" ]; then
        if [ "$i" -eq "$((active-1))" ] && [ "$arc" -eq 0 ]; then state="current"; col="$AMBER"; r=22; tcol="$TXTL"; op=1.0
        else state="done"; col="$TEAL"; r=17; tcol="$TXTL"; op=0.92; fi
      else state="pending"; col="$DIM"; r=14; tcol="$TXTD"; op=0.8; fi
      # HALO — attention-pulse on the current (amber) phase only.
      [ "$state" = "current" ] && prim_halo "$x" "$CY" "$((r+13))" "$AMBER"
      # NODE — a crafted material disc (state→colour); done phases carry a ✓ glyph.
      prim_node "$x" "$CY" "$r" "$state"
      [ "$state" = "done" ] && prim_node_check "$x" "$CY" "$r"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="16" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((CY-32))" "$tcol" "${STAGES[$i]}"
    done
    printf '</svg>\n'
  } > "$path"
}
# --- B1/B3 explicit tagged timing -------------------------------------------------------------------
# Emit each DISTINCT visual state exactly ONCE (no faked-by-repeat holds), and record one TIMING.tsv row
# per frame: <frame_index>\t<role>\t<holds>. The dwell is encoded HERE; reslow.sh reads it. roles/holds:
#   transition=3 · label=7 · caption=14 · long=21 · dense=28 · poster=48.
# Ah-HA floor (≥24): the eight phase-arrival beats TEACH the product cycle — each is a concept/relationship
# frame → dense=28. The loop-close (OPERATE→↻ re-enters DISCOVER) is the settled full-cycle reveal and the
# teaching core → poster=48 (comfortably clears the ≥24 loop-close floor).
: > "$OUT/TIMING.tsv"
f=0
tag() { printf '%d\t%s\t%d\n' "$f" "$1" "$2" >> "$OUT/TIMING.tsv"; }
# reveal each phase, one distinct state per arrival — every arrival is an Ah-HA teaching beat (dense=28)
for a in $(seq 1 "$N"); do
  emit "$a" 0 "$OUT/f$(printf '%03d' $f).svg"; tag dense 28; f=$((f+1))
done
# loop-close: the return arc glows (OPERATE's learnings re-enter DISCOVER) — settled full-cycle poster=48
emit "$N" 1 "$OUT/f$(printf '%03d' $f).svg"; tag poster 48; f=$((f+1))
echo "emitted $f distinct frames (TIMING.tsv: $(grep -c '' "$OUT/TIMING.tsv") rows)"
