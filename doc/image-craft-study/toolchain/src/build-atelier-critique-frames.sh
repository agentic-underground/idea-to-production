#!/usr/bin/env bash
# ATELIER flagship: the designer<->reviewer critique LOOP that converges.
# A rough wireframe (left) is reviewed; findings flag amber on a fitness rubric (right). The designer
# refines; findings clear one by one as the rubric bars rise; the loop re-reviews and CONVERGES to a
# polished, accessible screen — the design-fitness GATE goes green. Motivated motion: it teaches the
# bounded, measurable loop (no HIGH findings, a11y clear, score>=target => stop), not decoration.
# Dark-mode canon: ground #1e1e2e, teal=done/pass, amber=current finding, dim=pending, muted text.
set -euo pipefail
OUT="${1:-atelier-critique-frames}"; mkdir -p "$OUT"

W=1300; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; PANEL="#26263a"; LINE="#2a2a40"
GROUND="#1e1e2e"

# Screen mock-up geometry (left panel) and rubric (right panel)
SX=70; SY=92; SW=480; SH=190                 # screen frame
RX=720; RY=92; RW=510                          # rubric block

# Five rubric criteria — the design-fitness rubric. Each resolves over the loop.
CRIT=("Visual hierarchy" "Contrast / WCAG AA" "Touch targets · Fitts" "Consistency · Jakob" "Delight · Norman")
NC=${#CRIT[@]}

# emit: $1 iter-label  $2 passcount(0..NC)  $3 amber_idx(-1 none / which crit currently flagged)
#       $4 refine_level(0..3 = wireframe roughness reducing)  $5 gate(0/1)  $6 sweep(0/1 reviewer scan)  $7 path
emit() {
  local label=$1 pass=$2 amber=$3 refine=$4 gate=$5 sweep=$6 path=$7
  local i cy bx col tcol icon scy
  local CY=$(( H/2 ))
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="%s"/>\n' "$GROUND"
    # Depth: defs (gradients + filters) + ambient glow ellipse
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.13"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<radialGradient id="dga" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#fbbf24" stop-opacity="0.06"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dga)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*46/100))" "$((H*26/100))"
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    # Title
    printf '<text x="%d" y="42" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="%s" text-anchor="middle">the design critique loop · designer ↔ reviewer · converges to fit</text>\n' "$((W/2))" "$TXTL"
    printf '<text x="%d" y="68" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" fill="%s" text-anchor="middle">%s</text>\n' "$((W/2))" "$TXTD" "$label"

    # ---- LEFT: the screen under design (gets more refined / accessible) ----
    printf '<rect x="%d" y="%d" width="%d" height="%d" rx="10" fill="%s" stroke="%s" stroke-width="2" filter="url(#ns)"/>\n' "$SX" "$SY" "$SW" "$SH" "$PANEL" "$LINE"
    # window chrome dots
    printf '<circle cx="%d" cy="%d" r="4" fill="%s"/>\n' "$((SX+18))" "$((SY+18))" "$TXTD"
    printf '<circle cx="%d" cy="%d" r="4" fill="%s"/>\n' "$((SX+34))" "$((SY+18))" "$TXTD"
    printf '<circle cx="%d" cy="%d" r="4" fill="%s"/>\n' "$((SX+50))" "$((SY+18))" "$TXTD"

    # As refine rises 0->3: rough greys become structured teal-accented, balanced layout.
    local accent stroke fill1 op
    case "$refine" in
      0) accent="$DIM"; fill1="#33334d"; op="0.85" ;;
      1) accent="#5b6b78"; fill1="#384055"; op="0.9" ;;
      2) accent="#6fae9e"; fill1="#3a4a52"; op="0.95" ;;
      3) accent="$TEAL"; fill1="#2f4a48"; op="1.0" ;;
    esac
    # header bar of the mock screen
    printf '<rect x="%d" y="%d" width="%d" height="16" rx="4" fill="%s" opacity="%s"/>\n' "$((SX+22))" "$((SY+40))" "$((SW-44))" "$accent" "$op"
    # content blocks — get tidier / aligned as refine rises
    local pad=$(( 6 - refine*1 ))
    printf '<rect x="%d" y="%d" width="%d" height="44" rx="6" fill="%s" opacity="%s"/>\n' "$((SX+22))" "$((SY+66))" "$(( (SW-44)*6/10 ))" "$fill1" "$op"
    printf '<rect x="%d" y="%d" width="%d" height="44" rx="6" fill="%s" opacity="%s"/>\n' "$(( SX+22+(SW-44)*6/10+12 ))" "$((SY+66))" "$(( (SW-44)*4/10-12 ))" "$fill1" "$op"
    # text lines
    printf '<rect x="%d" y="%d" width="%d" height="9" rx="4" fill="%s" opacity="%s"/>\n' "$((SX+22))" "$((SY+122))" "$(( (SW-44)*8/10 ))" "$TXTD" "0.7"
    printf '<rect x="%d" y="%d" width="%d" height="9" rx="4" fill="%s" opacity="%s"/>\n' "$((SX+22))" "$((SY+138))" "$(( (SW-44)*5/10 ))" "$TXTD" "0.5"
    # primary action button — goes teal & well-sized as it refines (Fitts/contrast)
    local btnw=$(( 80 + refine*16 )); local btncol="$accent"
    [ "$refine" -ge 2 ] && btncol="$TEAL"
    printf '<rect x="%d" y="%d" width="%d" height="22" rx="6" fill="%s" opacity="%s"/>\n' "$((SX+22))" "$((SY+156))" "$btnw" "$btncol" "$op"

    # reviewer scan sweep — a vertical scan line crossing the screen
    if [ "$sweep" -eq 1 ]; then
      local scanx=$(( SX + 60 + (refine*110) ))
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="3" opacity="0.55"/>\n' "$scanx" "$((SY+8))" "$scanx" "$((SY+SH-8))" "$AMBER"
      printf '<circle cx="%d" cy="%d" r="5" fill="%s"/>\n' "$scanx" "$((SY+SH/2))" "$AMBER"
    fi
    # converged badge on the screen when gate is green
    if [ "$gate" -eq 1 ]; then
      printf '<circle cx="%d" cy="%d" r="15" fill="%s" filter="url(#ns)"/>\n' "$((SX+SW-26))" "$((SY+26))" "$TEAL"
      printf '<path d="M %d %d l 5 6 l 10 -12" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>\n' "$((SX+SW-34))" "$((SY+26))" "$GROUND"
    fi

    # ---- arrow between designer screen and reviewer rubric ----
    local acol="$TXTD"
    [ "$sweep" -eq 1 ] && acol="$AMBER"
    [ "$gate" -eq 1 ] && acol="$TEAL"
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="3" opacity="0.8"/>\n' "$((SX+SW+12))" "$((SY+SH/2))" "$((RX-14))" "$((SY+SH/2))" "$acol"
    printf '<path d="M %d %d l -11 -6 l 0 12 z" fill="%s"/>\n' "$((RX-14))" "$((SY+SH/2))" "$acol"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans" font-size="12" fill="%s" text-anchor="middle">review</text>\n' "$(( SX+SW+12 + (RX-14-(SX+SW+12))/2 ))" "$((SY+SH/2-10))" "$acol"

    # ---- RIGHT: the design-fitness rubric, criteria resolving to green ----
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="700" fill="%s">design-fitness rubric</text>\n' "$RX" "$((RY+2))" "$TXTL"
    for i in $(seq 0 $((NC-1))); do
      cy=$(( RY + 22 + i*34 ))
      bx=$(( RX + 250 ))
      if [ "$i" -lt "$pass" ]; then col="$TEAL"; tcol="$TXTL"; icon="check"
      elif [ "$i" -eq "$amber" ]; then col="$AMBER"; tcol="$TXTL"; icon="flag"
      else col="$DIM"; tcol="$TXTD"; icon="dot"; fi
      # criterion label
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="600" fill="%s">%s</text>\n' "$RX" "$((cy+5))" "$tcol" "${CRIT[$i]}"
      # score bar track
      printf '<rect x="%d" y="%d" width="%d" height="12" rx="6" fill="%s"/>\n' "$bx" "$((cy-4))" "240" "$LINE"
      # filled portion: pass=full, amber=partial, pending=small
      local fillw=40
      [ "$i" -eq "$amber" ] && fillw=150
      [ "$i" -lt "$pass" ] && fillw=240
      printf '<rect x="%d" y="%d" width="%d" height="12" rx="6" fill="%s"/>\n' "$bx" "$((cy-4))" "$fillw" "$col"
      # status glyph
      if [ "$icon" = "check" ]; then
        printf '<circle cx="%d" cy="%d" r="9" fill="%s"/>\n' "$((RX-18))" "$cy" "$TEAL"
        printf '<path d="M %d %d l 3 4 l 6 -8" fill="none" stroke="%s" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>\n' "$((RX-23))" "$cy" "$GROUND"
      elif [ "$icon" = "flag" ]; then
        printf '<circle cx="%d" cy="%d" r="9" fill="%s"/>\n' "$((RX-18))" "$cy" "$AMBER"
        printf '<text x="%d" y="%d" font-family="DejaVu Sans" font-size="13" font-weight="800" fill="%s" text-anchor="middle">!</text>\n' "$((RX-18))" "$((cy+5))" "$GROUND"
      else
        printf '<circle cx="%d" cy="%d" r="7" fill="%s"/>\n' "$((RX-18))" "$cy" "$DIM"
      fi
    done

    # ---- GATE strip along the bottom ----
    local gy=$(( H - 34 ))
    local gcol="$DIM" gtxt="gate: pending — HIGH findings open" gtc="$TXTD"
    if [ "$gate" -eq 1 ]; then gcol="$TEAL"; gtxt="design-fitness gate: PASS — no HIGH findings · WCAG AA clear · score ≥ target"; gtc="$GROUND"; fi
    printf '<rect x="%d" y="%d" width="%d" height="26" rx="13" fill="%s" opacity="%s"/>\n' "$SX" "$((gy-6))" "$((W-2*SX))" "$gcol" "$( [ "$gate" -eq 1 ] && echo 1.0 || echo 0.22 )"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="700" fill="%s" text-anchor="middle">%s</text>\n' "$((W/2))" "$((gy+11))" "$gtc" "$gtxt"

    printf '</svg>\n'
  } > "$path"
}

# ---- explicit tagged timing (B1/B3) ----------------------------------------------------------------
# Each DISTINCT visual state is emitted exactly ONCE; per-frame dwell comes from TIMING.tsv holds, no
# longer from repeating identical calls. Roles & holds per the B1 table:
#   transition=3 · label=7 · caption=14 · long=21 · dense=28 · poster=48
# Ah-HA floor (≥24): frames that teach the loop or reveal convergence/the gate message get dense(28).
f=0
: > "$OUT/TIMING.tsv"
# fr <role> <holds> <label> <pass> <amber> <refine> <gate> <sweep>
fr() {
  local role=$1 holds=$2; shift 2
  emit "$@" "$OUT/f$(printf '%03d' $f).svg"
  printf '%d\t%s\t%d\n' "$f" "$role" "$holds" >> "$OUT/TIMING.tsv"
  f=$((f+1))
}

# Loop iteration 1: rough wireframe, reviewer sweeps, first finding flags amber.
fr caption    14  "iteration 1 · first wireframe drafted"            0 -1 0 0 0
fr caption    14  "iteration 1 · reviewer crawls the screen"         0  0 0 0 1
# Ah-HA: review PRODUCES findings — the loop mechanic is revealed here.
fr dense      28  "iteration 1 · finding: weak visual hierarchy"     1  1 0 0 1
# Iteration 2: designer refines, re-review, finding clears as the next flags.
fr caption    14  "iteration 2 · designer refines, re-renders"       2  2 1 0 0
fr caption    14  "iteration 2 · finding: contrast below WCAG AA"    2  2 1 0 1
fr caption    14  "iteration 2 · contrast fixed, target enlarged"    3  3 2 0 0
# Iteration 3: re-review, last findings clear.
fr caption    14  "iteration 3 · re-review · consistency check"      3  3 2 0 1
fr caption    14  "iteration 3 · aligned to Jakob's law"             4  4 3 0 0
fr caption    14  "iteration 3 · last pass · emotional polish"       4  4 3 0 1
# Ah-HA: the loop CONVERGES — the screen passes the rubric, the gate goes green.
fr dense      28  "converged · polished, accessible screen"          5 -1 3 1 0
# Settled poster: the design-fitness gate message dwells (previously under-dwelling per the plan).
fr poster     48  "design-fitness gate is green — loop closes"       5 -1 3 1 0
echo "emitted $f frames"
