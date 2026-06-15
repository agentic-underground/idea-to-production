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
# Source the shared crafted-primitive library (the home of the in-vector line-art uplift).
# Resolve its path relative to THIS generator so it works regardless of cwd.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=diagram-primitives.sh
source "$HERE/diagram-primitives.sh"
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
    # shared crafted <defs> (dg/bgb/ns + the uplift shading gradients) via the library
    prim_defs
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="48" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="#e8e8ef" text-anchor="middle">the test-first value conveyor · idea ▸ product</text>\n' "$((W/2))"
    # the conveyor RAIL — base track + lit top edge, plus the teal "cleared" overlay up to
    # the token (the lit/done track). Crafted via prim_rail (rail:lit-overlay).
    if [ "$at" -ge 1 ]; then
      local railend=$(( at < N ? PAD + at*GAP : W-PAD ))
      prim_rail "$PAD" "$CY" "$((W-PAD))" "$PRIM_RAILBASE" "$PRIM_SW_RAIL" "$railend" "$TEAL"
    else
      prim_rail "$PAD" "$CY" "$((W-PAD))"
    fi
    for i in $(seq 0 $((N-1))); do
      x=$((PAD + i*GAP))
      # state word (drives prim_node face colour) + the original per-state radius + an
      # optional attention HALO colour for the active/red gate.
      local st halo=""
      if [ "$i" -lt "$at" ]; then
        # already cleared by the token → latched teal (gate:latch — done)
        st="done"; r=18
      elif [ "$i" -eq "$at" ]; then
        # the gate the token currently sits on → current/amber (halo: attention-pulse)
        st="current"; r=23; halo="$AMBER"
      else
        st="pending"; r=14
      fi
      # TESTS gate special-cases the red→green spine (gate:flip):
      if [ "$i" -eq "$tests_idx" ]; then
        if [ "$tg" -eq 1 ]; then
          # has flipped green
          st="done"
          [ "$i" -ge "$at" ] && r=18
          [ "$i" -eq "$at" ] && halo="$TEAL"
        elif [ "$at" -ge "$tests_idx" ]; then
          # token has reached/passed TESTS but impl not done → failing test glows RED
          st="failing"; r=23; halo="$RED"
        fi
      fi
      # attention HALO ring for the active / red gate (kept just outside the disc edge)
      [ -n "$halo" ] && prim_halo "$x" "$CY" "$((r+9))" "$halo"
      # the crafted NODE — shaded disc, sheen, lit rim, soft shadow + its label
      prim_node "$x" "$CY" "$r" "$st" "${STAGES[$i]}"
      # check-mark inside latched / flipped-green gates (gate:latch ✓)
      [ "$st" = "done" ] && prim_node_check "$x" "$CY" "$r"
    done
    # the IDEA TOKEN — a bright ringed marker riding the rail (token:ride)
    if [ "$at" -lt "$N" ]; then
      tx=$((PAD + at*GAP))
      prim_token "$tx" "$CY"
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
: > "$OUT/TIMING.tsv"
# mk <token_at> <tests_green> <role> <holds> — emit ONE distinct visual state and tag its
# output-frame dwell. Each state is emitted exactly once; the holds count (consumed by reslow.sh
# via TIMING.tsv) gives organic meter so info-dense "Ah-HA!" beats linger and pure transitions flick.
mk(){
  local at=$1 tg=$2 role=$3 holds=$4
  emit "$at" "$tg" "$OUT/f$(printf '%03d' $f).svg"
  printf '%d\t%s\t%d\n' "$f" "$role" "$holds" >> "$OUT/TIMING.tsv"
  f=$((f+1))
}
# 1) token at IDEA — the spine concept is introduced (66-char teaching caption): the Ah-HA dense beat.
mk 0 0 dense 28
# token rides IDEA → EARS — node advances, caption unchanged: a pure transition.
mk 1 0 transition 3
# 2) token reaches TESTS — failing test lights RED, test-first (62-char teaching caption):
#    the MANDATORY red Ah-HA spine beat.
mk 2 0 dense 28
# 3) token advances to IMPL — still red, caption unchanged: a pure transition.
mk 3 0 transition 3
# 4) the spine flip: with IMPL in place, TESTS flips red → green (63-char teaching caption):
#    the MANDATORY green-flip Ah-HA spine beat.
mk 3 1 dense 28
# 5) token rides on through GREEN → SHIP, everything latched teal: pure transitions.
mk 4 1 transition 3
mk 5 1 transition 3
# 6) settle: token past the end, full line complete — the settled poster (loop reads as "settled").
mk 6 1 poster 48
echo "emitted $f frames into $OUT"
