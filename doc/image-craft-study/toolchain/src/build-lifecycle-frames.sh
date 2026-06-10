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
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s"/>\n' "$x" "$CY" "$r" "$col" "$op"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="16" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((CY-32))" "$tcol" "${STAGES[$i]}"
    done
    printf '</svg>\n'
  } > "$path"
}
f=0
for a in $(seq 1 "$N"); do emit "$a" 0 "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); done   # reveal each phase
for _ in 1 2; do emit "$N" 0 "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); done             # hold full pipeline
for _ in 1 2 3; do emit "$N" 1 "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); done           # the cycle arc glows
echo "emitted $f frames"
