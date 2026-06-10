#!/usr/bin/env bash
# foundry flagship: the test-first value conveyor.
# An IDEA token rides a fixed line of value-stations: IDEA ▸ EARS ▸ TESTS ▸ IMPL ▸ GREEN ▸ SHIP.
# The MOTIVATED motion teaches the red→green test-first spine: the TESTS gate lights RED *first*
# (a failing test written before code), and only when the token reaches IMPL does TESTS flip
# red→green — proof arrives before code, code turns proof green. Each cleared gate latches teal;
# the token rides on; GREEN + SHIP settle; then the line holds as a complete poster.
# Dark-mode canon: ground #1e1e2e; teal #5eead4 done/green; amber #fbbf24 current; red failing test;
# dim #3a3a55 pending; muted #6b7280 text.
set -euo pipefail
OUT="${1:-/tmp/foundry-conveyor-frames}"; mkdir -p "$OUT"
STAGES=(IDEA EARS TESTS IMPL GREEN SHIP)
N=${#STAGES[@]}
W=1280; H=320; PAD=110; CY=176; GAP=$(( (W - 2*PAD) / (N-1) ))
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; RED="#f87171"; TXTD="#6b7280"; TXTL="#e8e8ef"
# emit $1=token_at (0..N-1, which gate the IDEA token currently sits on; N means past the end / settled)
#      $2=tests_green (0/1 — has the TESTS gate flipped red→green yet?)
#      $3=path
emit() {
  local at=$1 tg=$2 path=$3 i x col r tcol op lab glow tx
  local tests_idx=2 impl_idx=3
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="48" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="#e8e8ef" text-anchor="middle">the test-first value conveyor · idea ▸ product</text>\n' "$((W/2))"
    # the conveyor rail
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="6"/>\n' "$PAD" "$CY" "$((W-PAD))" "$CY"
    # teal fill of rail up to the token (cleared track)
    if [ "$at" -ge 1 ]; then
      local railend=$(( at < N ? PAD + at*GAP : W-PAD ))
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="6" opacity="0.45"/>\n' "$PAD" "$CY" "$railend" "$CY" "$TEAL"
    fi
    for i in $(seq 0 $((N-1))); do
      x=$((PAD + i*GAP))
      glow=""
      if [ "$i" -lt "$at" ]; then
        # already cleared by the token → latched teal (done)
        col="$TEAL"; r=18; tcol="$TXTL"; op=0.95
      elif [ "$i" -eq "$at" ]; then
        # the gate the token currently sits on → current/amber
        col="$AMBER"; r=23; tcol="$TXTL"; op=1.0
      else
        col="$DIM"; r=14; tcol="$TXTD"; op=0.85
      fi
      # TESTS gate special-cases the red→green spine:
      if [ "$i" -eq "$tests_idx" ]; then
        if [ "$tg" -eq 1 ]; then
          # has flipped green
          col="$TEAL"; tcol="$TXTL"; op=0.95
          [ "$i" -ge "$at" ] && r=18
        elif [ "$at" -ge "$tests_idx" ]; then
          # token has reached/passed TESTS but impl not done → failing test glows RED
          col="$RED"; tcol="$TXTL"; op=1.0; r=23
          glow="$RED"
        fi
      fi
      # soft glow ring for the active / red gate
      if [ -n "$glow" ]; then
        printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="3" opacity="0.35"/>\n' "$x" "$CY" "$((r+9))" "$glow"
      fi
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s" filter="url(#ns)"/>\n' "$x" "$CY" "$r" "$col" "$op"
      # check-mark inside latched-teal gates
      if [ "$col" = "$TEAL" ]; then
        printf '<path d="M %d %d l %d %d l %d %d" stroke="#0f2e28" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>\n' \
          "$((x-7))" "$((CY+1))" "5" "6" "10" "-13"
      fi
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="17" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((CY-42))" "$tcol" "${STAGES[$i]}"
    done
    # the IDEA token — a bright marker riding the rail
    if [ "$at" -lt "$N" ]; then
      tx=$((PAD + at*GAP))
      printf '<circle cx="%d" cy="%d" r="7" fill="#1e1e2e" stroke="#e8e8ef" stroke-width="2.5"/>\n' "$tx" "$CY"
    fi
    # the spine caption — names what the motion teaches, changes with state
    if [ "$tg" -eq 1 ]; then
      lab="● TESTS flipped red ▸ green — code turned the failing proof green"; tx="$TEAL"
    elif [ "$at" -ge "$tests_idx" ]; then
      lab="● a failing TEST is written FIRST (red) — before any IMPL exists"; tx="$RED"
    else
      lab="● value rides one vertical slice: each gate latches green as it clears"; tx="$TXTD"
    fi
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="19" font-weight="500" fill="%s" text-anchor="middle">%s</text>\n' "$((W/2))" "$((CY+86))" "$tx" "$lab"
    printf '</svg>\n'
  } > "$path"
}
f=0
mk(){ emit "$1" "$2" "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); }
# 1) token rides IDEA → EARS (gates latch green as cleared)
mk 0 0
mk 0 0          # hold: long caption needs time to read
mk 0 0
mk 0 0
mk 1 0
mk 1 0          # hold: long caption needs time to read
mk 1 0
mk 1 0
# 2) token reaches TESTS — failing test lights RED (test-first: red before code)
mk 2 0
mk 2 0
mk 2 0          # hold the red beat — 64-char caption needs 4 frames
mk 2 0
# 3) token advances to IMPL — code is written against the red proof
mk 3 0
mk 3 0          # hold: still red, long caption
mk 3 0
# 4) the spine: with IMPL in place, TESTS flips red → green
mk 3 1          # flip beat
mk 3 1
mk 3 1          # hold the green-flip beat — 64-char caption needs 4 frames
mk 3 1
# 5) token rides on through GREEN → SHIP, everything latched teal
mk 4 1
mk 4 1          # hold GREEN
mk 4 1
mk 5 1
mk 5 1          # hold SHIP
mk 5 1
# 6) settle: token past the end, full line complete — hold as poster (loop reads as "settled")
mk 6 1
mk 6 1
mk 6 1
mk 6 1
mk 6 1
echo "emitted $f frames into $OUT"
