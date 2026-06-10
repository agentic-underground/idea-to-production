#!/usr/bin/env bash
# Root masthead: the OUTWARD-FACING front door of the idea-to-production marketplace.
# A real wordmark "idea → production" sits dominant up top (the old banner had a wordmark
# but no motion); beneath it the nine-plugin value cycle IGNITES — eight phase nodes light
# teal left-to-right as a build-up (the current node pulses amber), then the return loop-arc
# (OPERATE ↻ DISCOVER) glows teal so the cycle visibly CLOSES, framed by the two cross-cutting
# front-door plugins (i2p · concierge). The motion teaches the marketplace's shape: a directed
# left-to-right journey that loops — discovery is fed by what you learned in operation.
# Dark-mode canon: ground #1e1e2e, text #e8e8ef. teal=done/active, amber=current, dim=pending.
set -euo pipefail
OUT="${1:-/tmp/masthead-cycle-frames}"; mkdir -p "$OUT"

# Eight phases of the cycle + their plugin owners (kept terse for legibility).
STAGES=(DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE)
OWNERS=(scanner ideator atelier foundry foundry sentinel pressroom mission)
N=${#STAGES[@]}

W=1320; H=344
PAD=92; CY=222; GAP=$(( (W - 2*PAD) / (N-1) ))
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"
IDEA="#7aa2f7"   # cool idea-blue, carried from the proven banner wordmark

# emit: $1 active(0..N)  $2 arc_glow(0/1)  $3 pulse_phase(0..2 amber-breath)  $4 path
emit() {
  local active=$1 arc=$2 pulse=$3 path=$4 i x col r tcol op
  # amber pulse radius for the "current" node (gentle breath so it reads alive, not jumpy)
  local pr=23; case "$pulse" in 0) pr=22;; 1) pr=24;; 2) pr=23;; esac
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'

    # ---- microline + WORDMARK (the dominant front-door mark) ----
    printf '<text x="%d" y="40" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="700" letter-spacing="4" fill="#9aa2c0" text-anchor="middle">A  CLAUDE  CODE  PLUGIN  MARKETPLACE</text>\n' "$((W/2))"
    printf '<text x="%d" y="96" font-family="DejaVu Sans, Arial, sans-serif" font-size="54" font-weight="700" text-anchor="middle">' "$((W/2))"
    printf '<tspan fill="%s">idea</tspan><tspan fill="#9aa2c0">  →  </tspan><tspan fill="%s">production</tspan></text>\n' "$IDEA" "$AMBER"
    printf '<text x="%d" y="132" font-family="DejaVu Sans, Arial, sans-serif" font-size="17" letter-spacing="1" fill="#e6e9f0" text-anchor="middle">nine composable plugins carry VALUE from the spark of an idea to a shipped product</text>\n' "$((W/2))"

    # ---- baseline rail (the conveyor) ----
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="5"/>\n' "$PAD" "$CY" "$((W-PAD))" "$CY"
    # lit portion of the rail grows with the build-up
    [ "$active" -gt 1 ] && printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="5" opacity="0.55"/>\n' \
      "$PAD" "$CY" "$((PAD+(active-1)*GAP))" "$CY" "$TEAL"

    # ---- the return loop-arc (OPERATE ↻ DISCOVER): closes the cycle when it glows ----
    local acol="#2a2a40" aop=0.85 alab="#3a3a55"
    [ "$arc" -eq 1 ] && { acol="$TEAL"; aop=0.9; alab="$TEAL"; }
    printf '<path d="M %d %d C %d %d, %d %d, %d %d" fill="none" stroke="%s" stroke-width="4" opacity="%s" stroke-dasharray="7 7"/>\n' \
      "$((W-PAD))" "$((CY+16))" "$((W-PAD+34))" "$((CY+78))" "$((PAD-34))" "$((CY+78))" "$PAD" "$((CY+16))" "$acol" "$aop"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" fill="%s" text-anchor="middle">↻  OPERATE'"'"'s learnings re-enter DISCOVER — the loop closes</text>\n' \
      "$((W/2))" "$((CY+98))" "$alab"

    # ---- the eight phase nodes ----
    for i in $(seq 0 $((N-1))); do
      x=$((PAD + i*GAP))
      if [ "$i" -lt "$active" ]; then
        if [ "$i" -eq "$((active-1))" ] && [ "$arc" -eq 0 ]; then col="$AMBER"; r=$pr; tcol="$TXTL"; op=1.0
        else col="$TEAL"; r=17; tcol="$TXTL"; op=0.94; fi
      else col="$DIM"; r=14; tcol="$TXTD"; op=0.8; fi
      # amber halo behind the current node so the "attention" reads
      if [ "$i" -eq "$((active-1))" ] && [ "$arc" -eq 0 ] && [ "$active" -le "$N" ]; then
        printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="0.16"/>\n' "$x" "$CY" "$((r+14))" "$AMBER"
      fi
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s"/>\n' "$x" "$CY" "$r" "$col" "$op"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' \
        "$x" "$((CY-34))" "$tcol" "${STAGES[$i]}"
      # plugin owner under each node, lit only once the phase is reached
      local ocol="$TXTD"; [ "$i" -lt "$active" ] && ocol="#8b9bb4"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="11" fill="%s" text-anchor="middle">%s</text>\n' \
        "$x" "$((CY+30))" "$ocol" "${OWNERS[$i]}"
    done

    # ---- front-door framing: i2p (left) and concierge (right) cross-cut everything ----
    local fcol="#6b7280"; [ "$active" -ge "$N" ] && fcol="#9aa2c0"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="12" font-weight="600" fill="%s" text-anchor="start">i2p · front door</text>\n' "$((PAD-50))" "$((CY-70))" "$fcol"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="12" font-weight="600" fill="%s" text-anchor="end">concierge · greeter</text>\n' "$((W-PAD+50))" "$((CY-70))" "$fcol"

    printf '</svg>\n'
  } > "$path"
}

f=0
seq_emit() { emit "$1" "$2" "$3" "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); }

# build-up: reveal each phase left-to-right, current node pulsing amber
p=0
for a in $(seq 1 "$N"); do seq_emit "$a" 0 "$p"; p=$(( (p+1) % 3 )); done
# settle: hold the full pipeline a beat (last node still amber, breathing)
seq_emit "$N" 0 1
seq_emit "$N" 0 2
# ignite the return loop-arc — the cycle CLOSES (OPERATE ↻ DISCOVER glows teal)
seq_emit "$N" 1 0
seq_emit "$N" 1 0
# poster hold: complete, settled, looped
seq_emit "$N" 1 0
seq_emit "$N" 1 0
echo "emitted $f frames into $OUT"
