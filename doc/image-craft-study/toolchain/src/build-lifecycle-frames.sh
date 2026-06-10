#!/usr/bin/env bash
# Phase-10 flagship: the marketplace lifecycle (DISCOVER→IDEATE→DESIGN→BUILD→ASSURE→SECURE→PUBLISH→OPERATE ↻)
# animated as a build-up that lights each phase, then the return arc glows (OPERATE loops to DISCOVER), then
# the cycle holds and repeats. Dark-mode canon ground; teal "done" / amber "current" / dim "pending" script.
set -euo pipefail
OUT="${1:-lc-frames}"; mkdir -p "$OUT"
STAGES=(DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE)
N=${#STAGES[@]}
W=1320; H=300; PAD=80; CY=150; GAP=$(( (W - 2*PAD) / (N-1) ))
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"
emit() { # $1 active (0..N) ; $2 arc_on(0/1) ; $3 path
  local active=$1 arc=$2 path=$3 i x col r tcol op
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.13"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<radialGradient id="dga" cx="50%%" cy="55%%" r="42%%"><stop offset="0%%" stop-color="#fbbf24" stop-opacity="0.06"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dga)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*34/100))" "$((H*18/100))"
    printf '<text x="%d" y="44" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="#e8e8ef" text-anchor="middle">idea → production · the value cycle</text>\n' "$((W/2))"
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="5"/>\n' "$PAD" "$CY" "$((W-PAD))" "$CY"
    [ "$active" -gt 1 ] && printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="5" opacity="0.5"/>\n' "$PAD" "$CY" "$((PAD+(active-1)*GAP))" "$CY" "$TEAL"
    # return arc (OPERATE ↻ DISCOVER) — glows when arc=1
    local acol="#2a2a40" aop=0.9
    [ "$arc" -eq 1 ] && { acol="$TEAL"; aop=0.85; }
    printf '<path d="M %d %d C %d %d, %d %d, %d %d" fill="none" stroke="%s" stroke-width="4" opacity="%s" stroke-dasharray="6 6"/>\n' \
      "$((W-PAD))" "$((CY+18))" "$((W-PAD))" "$((CY+92))" "$PAD" "$((CY+92))" "$PAD" "$((CY+18))" "$acol" "$aop"
    [ "$arc" -eq 1 ] && printf '<text x="%d" y="%d" font-family="DejaVu Sans" font-size="20" fill="%s" text-anchor="middle">↻ OPERATE'"'"'s learnings re-enter DISCOVER</text>\n' "$((W/2))" "$((CY+82))" "$TEAL"
    for i in $(seq 0 $((N-1))); do
      x=$((PAD + i*GAP))
      if [ "$i" -lt "$active" ]; then
        if [ "$i" -eq "$((active-1))" ] && [ "$arc" -eq 0 ]; then col="$AMBER"; r=22; tcol="$TXTL"; op=1.0
        else col="$TEAL"; r=17; tcol="$TXTL"; op=0.92; fi
      else col="$DIM"; r=14; tcol="$TXTD"; op=0.8; fi
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s" filter="url(#ns)"/>\n' "$x" "$CY" "$r" "$col" "$op"
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
