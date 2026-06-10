#!/usr/bin/env bash
# SENTINEL — the security gate animated: a scan sweep crosses the artifact, each of four lenses
# (PII · SECRETS · SUPPLY-CHAIN · SAST) seals green as the sweep reaches it, the verdict flips to
# PASS, and the gate barrier lifts — "cleared to expose". Motion teaches certify-BEFORE-exposure.
# Dark-mode canon ground; teal "sealed/clear" / amber "scanning now" / dim "pending".
set -euo pipefail
OUT="${1:-sentinel-gate-frames}"; mkdir -p "$OUT"

LENSES=(PII SECRETS "SUPPLY-CHAIN" SAST)
NL=${#LENSES[@]}
W=1300; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; GROUND="#1e1e2e"

# layout: artifact box at left, four lens chips stacked at center, gate barrier at right
ART_X=110; ART_Y=120; ART_W=150; ART_H=120     # the artifact under review
CHIP_X=380; CHIP_W=300; CHIP_H=44; CHIP_GAP=14; CHIP_Y0=96
GATE_X=820; GATE_W=360                          # the gate channel
SWEEP_MIN=$((ART_X-10)); SWEEP_MAX=$((CHIP_X+CHIP_W+30))

chip_y() { echo $(( CHIP_Y0 + $1*(CHIP_H+CHIP_GAP) )); }

emit() { # $1 sealed_count(0..NL) ; $2 sweep_x (-1 = off) ; $3 gate_lift(0..100) ; $4 verdict(0 none/1 PASS)
  local sealed=$1 sweep=$2 lift=$3 verdict=$4 i cy col tcol icon op
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="%s"/>\n' "$GROUND"
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.13"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<radialGradient id="dga" cx="50%%" cy="50%%" r="50%%"><stop offset="0%%" stop-color="#fbbf24" stop-opacity="0.06"/><stop offset="100%%" stop-color="#fbbf24" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$((H/2))" "$((W*42/100))" "$((H*22/100))"
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dga)" filter="url(#bgb)"/>\n' "$((W/2))" "$((H/2))" "$((W*30/100))" "$((H*16/100))"
    printf '<text x="%d" y="42" font-family="DejaVu Sans, Arial, sans-serif" font-size="24" font-weight="700" fill="%s" text-anchor="middle">SENTINEL · certify before exposure</text>\n' "$((W/2))" "$TXTL"

    # ---- the artifact under review ----
    local art_col="#2a2a40" art_stroke="$TXTD"
    [ "$sealed" -ge "$NL" ] && art_stroke="$TEAL"
    printf '<rect x="%d" y="%d" width="%d" height="%d" rx="10" fill="%s" stroke="%s" stroke-width="2.5" filter="url(#ns)"/>\n' "$ART_X" "$ART_Y" "$ART_W" "$ART_H" "$art_col" "$art_stroke"
    # code-line glyphs inside the artifact
    for r in 0 1 2 3; do
      local ly=$(( ART_Y + 26 + r*22 )); local lw=$(( 60 + (r*37)%70 ))
      printf '<rect x="%d" y="%d" width="%d" height="6" rx="3" fill="%s" opacity="0.7"/>\n' "$((ART_X+22))" "$ly" "$lw" "$TXTD"
    done
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="600" fill="%s" text-anchor="middle">artifact</text>\n' "$((ART_X+ART_W/2))" "$((ART_Y+ART_H+24))" "$TXTD"

    # ---- the four lens chips ----
    for i in $(seq 0 $((NL-1))); do
      cy=$(chip_y "$i")
      if [ "$i" -lt "$sealed" ]; then col="$TEAL"; tcol="$TXTL"; icon="check"; op=1.0
      elif [ "$i" -eq "$sealed" ] && [ "$sweep" -ge 0 ]; then col="$AMBER"; tcol="$TXTL"; icon="scan"; op=1.0
      else col="$DIM"; tcol="$TXTD"; icon="dot"; op=0.85; fi
      printf '<rect x="%d" y="%d" width="%d" height="%d" rx="9" fill="#23233a" stroke="%s" stroke-width="2.5" opacity="%s" filter="url(#ns)"/>\n' "$CHIP_X" "$cy" "$CHIP_W" "$CHIP_H" "$col" "$op"
      # status badge (left of chip)
      local bx=$((CHIP_X+26)) byc=$((cy+CHIP_H/2))
      if [ "$icon" = "check" ]; then
        printf '<circle cx="%d" cy="%d" r="13" fill="%s"/>\n' "$bx" "$byc" "$TEAL"
        printf '<path d="M %d %d l 4 5 l 8 -10" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>\n' "$((bx-6))" "$byc" "$GROUND"
      elif [ "$icon" = "scan" ]; then
        printf '<circle cx="%d" cy="%d" r="13" fill="none" stroke="%s" stroke-width="2.6"/>\n' "$bx" "$byc" "$AMBER"
        printf '<circle cx="%d" cy="%d" r="4" fill="%s"/>\n' "$bx" "$byc" "$AMBER"
      else
        printf '<circle cx="%d" cy="%d" r="13" fill="none" stroke="%s" stroke-width="2.2"/>\n' "$bx" "$byc" "$DIM"
      fi
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="17" font-weight="600" fill="%s">%s</text>\n' "$((CHIP_X+54))" "$((byc+6))" "$tcol" "${LENSES[$i]}"
      # right-side state word
      local sw="pending"; [ "$i" -lt "$sealed" ] && sw="sealed"; { [ "$i" -eq "$sealed" ] && [ "$sweep" -ge 0 ]; } && sw="scanning…"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="12.5" fill="%s" text-anchor="end">%s</text>\n' "$((CHIP_X+CHIP_W-16))" "$((byc+5))" "$col" "$sw"
    done

    # ---- the scan sweep line ----
    if [ "$sweep" -ge 0 ]; then
      printf '<defs><linearGradient id="sw" x1="0" y1="0" x2="1" y2="0">\n'
      printf '<stop offset="0" stop-color="%s" stop-opacity="0"/><stop offset="0.7" stop-color="%s" stop-opacity="0.35"/><stop offset="1" stop-color="%s" stop-opacity="0.9"/></linearGradient></defs>\n' "$AMBER" "$AMBER" "$AMBER"
      printf '<rect x="%d" y="68" width="46" height="218" fill="url(#sw)"/>\n' "$((sweep-46))"
      printf '<line x1="%d" y1="64" x2="%d" y2="290" stroke="%s" stroke-width="3"/>\n' "$sweep" "$sweep" "$AMBER"
    fi

    # ---- the gate (right): two barrier leaves that lift apart as lift→100 ----
    local gcx=$((GATE_X+GATE_W/2)) gtop=86 gbot=288 gh=$((288-86))
    # channel frame
    printf '<rect x="%d" y="%d" width="%d" height="%d" rx="10" fill="none" stroke="#2a2a40" stroke-width="2.5"/>\n' "$GATE_X" "$gtop" "$GATE_W" "$gh"
    # barrier leaves: each retracts by lift% toward the frame edge
    local leaf=$(( (gh/2) * (100-lift) / 100 ))
    local barcol="$AMBER"; [ "$verdict" -eq 1 ] && barcol="$TEAL"
    [ "$sealed" -lt "$NL" ] && barcol="$DIM"
    if [ "$leaf" -gt 2 ]; then
      printf '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" opacity="0.85"/>\n' "$((GATE_X+4))" "$gtop" "$((GATE_W-8))" "$leaf" "$barcol"
      printf '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" opacity="0.85"/>\n' "$((GATE_X+4))" "$((gbot-leaf))" "$((GATE_W-8))" "$leaf" "$barcol"
    fi
    # verdict stamp in the gate opening
    if [ "$verdict" -eq 1 ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="40" font-weight="800" fill="%s" text-anchor="middle">PASS</text>\n' "$gcx" "$((gtop+gh/2-2))" "$TEAL"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="600" fill="%s" text-anchor="middle">cleared to expose →</text>\n' "$gcx" "$((gtop+gh/2+28))" "$TEAL"
    else
      local wv="$sealed/$NL lenses"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' "$gcx" "$((gtop+gh/2+5))" "$TXTD" "$wv"
    fi
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="600" fill="%s" text-anchor="middle">the gate</text>\n' "$gcx" "$((gbot+18))" "$TXTD"

    printf '</svg>\n'
  } > "$5"
}

# wrapper that writes a DISTINCT state once, and records its role+holds in TIMING.tsv (B1).
# Each emitted frame is a unique visual state — no faked-by-repeat holds; reslow.sh applies the
# per-frame dwell from TIMING.tsv (transition=3 · label=7 · caption=14 · long=21 · dense=28 · poster=48).
declare -A HOLD=( [transition]=3 [label]=7 [caption]=14 [long]=21 [dense]=28 [poster]=48 )
: > "$OUT/TIMING.tsv"
frame() { # $1 sealed  $2 sweep_x  $3 gate_lift  $4 verdict  $5 role
  local p="$OUT/f$(printf '%03d' "$FIDX").svg"
  emit "$1" "$2" "$3" "$4" "$p"
  printf '%d\t%s\t%d\n' "$FIDX" "$5" "${HOLD[$5]}" >> "$OUT/TIMING.tsv"
  FIDX=$((FIDX+1))
}
FIDX=0

# 1) idle: artifact present, gate closed, nothing scanned — establishing context, let it read.
frame 0 -1 0 0 caption

# 2) sweep crosses, sealing each lens in turn (sweep marches center across the chips).
#    The two sweep positions are pure motion (transition); the sealed-green chip is a new short
#    label state ("sealed") that the reader should register.
for i in $(seq 0 $((NL-1))); do
  cy_mid=$(( CHIP_X + 120 ))
  frame "$i" "$cy_mid" 0 0 transition          # scanning lens i (amber, sweep mid)
  frame "$i" "$((CHIP_X+CHIP_W))" 0 0 transition   # sweep reaches end of lens
  frame "$((i+1))" -1 0 0 label                # lens i sealed green, sweep off
done

# 3) all four sealed, gate still closed — "4/4 lenses, security cleared". A settling beat the
#    reader needs to absorb before the verdict resolves.
frame "$NL" -1 0 0 caption

# 4) the teaching payoff (Ah-HA, ≥24): the label resolves to the PASS stamp — security cleared
#    BECOMES cleared-to-expose. Gate begins to open as the PASS verdict lands. dense=28.
frame "$NL" -1 18 1 dense
# the gate continues opening — pure motion carrying the now-revealed PASS to its settled pose.
for l in 42 68 88 100; do frame "$NL" -1 "$l" 1 transition; done

# 5) the settled poster (gate fully open, PASS, cleared to expose) — long dwell before the loop.
frame "$NL" -1 100 1 poster

echo "emitted $FIDX frames"
