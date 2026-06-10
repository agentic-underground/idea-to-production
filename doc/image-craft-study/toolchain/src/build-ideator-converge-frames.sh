#!/usr/bin/env bash
# IDEATOR — scattered fragments converge into a build-ready IDEA package, then the challenger stamps READY.
# Four loose fragments (PROBLEM, USERS, CRITERIA, SCOPE) drift in from the corners and DOCK one-by-one into
# a central package frame; each docked fragment turns teal (knowledge-parity reached on that axis). When all
# four are locked the challenger's READY stamp lands (amber → settles teal). Motion TEACHES: IDEATE refines a
# scattered idea to knowledge-parity until the package is unambiguous, then hands off. Dark-mode canon.
set -euo pipefail
OUT="${1:-/tmp/ideator-converge-frames}"; mkdir -p "$OUT"

W=1280; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; GROUND="#1e1e2e"
CX=$((W/2)); CY=170
# central package frame geometry (a tidy 2x2 grid of docked slots)
BW=300; BH=130                 # package box half-extents-ish (full width/height of the grid)
GX0=$((CX-BW)); GY0=$((CY-BH)) # top-left of grid
GW=$((BW)); GH=$((BH))         # half cell span
# slot centres (2x2): each docked fragment's resting place
declare -a SX=( $((CX-150)) $((CX+150)) $((CX-150)) $((CX+150)) )
declare -a SY=( $((CY-58))  $((CY-58))  $((CY+58))  $((CY+58)) )
# off-screen origins (corners the fragments drift in from)
declare -a OX=( 70           $((W-70))   90          $((W-90)) )
declare -a OY=( 60           70          $((H-40))   $((H-30)) )
declare -a LBL=( "PROBLEM" "USERS" "CRITERIA" "SCOPE" )
declare -a SUB=( "the pain, sharp" "named actors" "testable success" "explicit edges" )

# linear interpolate a..b by t (t in 0..100), integer
lerp() { echo $(( $1 + ( ($2 - $1) * $3 ) / 100 )); }

# $1 = number of fragments docked so far (0..4 progressively)
# $2 = travel progress (0..100) of the CURRENTLY-arriving fragment (the (docked+1)th)
# $3 = stamp phase: 0 none, 1 land (amber), 2 settle (teal)
# $4 = path
emit() {
  local docked=$1 prog=$2 stamp=$3 path=$4 i x y col tcol op fr
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="%s"/>\n' "$GROUND"
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="46" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="%s" text-anchor="middle">IDEATE · scattered fragments → one build-ready IDEA package</text>\n' "$CX" "$TXTL"

    # the package frame: a dim scaffold that fills with teal as axes reach knowledge-parity
    printf '<rect x="%d" y="%d" width="%d" height="%d" rx="16" fill="none" stroke="%s" stroke-width="2.5" opacity="0.7"/>\n' \
      "$((CX-BW+20))" "$((CY-BH+8))" "$((2*BW-40))" "$((2*BH-16))" "$DIM"
    # parity meter: how many axes are locked (docked count, with the arriving one partially counted)
    local filled=$(( docked*100 + prog ))   # 0..400
    local meterw=$(( ((2*BW-40-24) * filled) / 400 ))
    printf '<rect x="%d" y="%d" width="%d" height="6" rx="3" fill="%s" opacity="0.25"/>\n' "$((CX-BW+32))" "$((CY+BH-22))" "$((2*BW-40-24))" "$TEAL"
    [ "$meterw" -gt 0 ] && printf '<rect x="%d" y="%d" width="%d" height="6" rx="3" fill="%s"/>\n' "$((CX-BW+32))" "$((CY+BH-22))" "$meterw" "$TEAL"

    # four dim target slots (where fragments dock)
    for i in 0 1 2 3; do
      printf '<rect x="%d" y="%d" width="120" height="46" rx="9" fill="none" stroke="%s" stroke-width="1.6" stroke-dasharray="5 5" opacity="0.55"/>\n' \
        "$(( ${SX[$i]} - 60 ))" "$(( ${SY[$i]} - 23 ))" "$DIM"
    done

    # draw fragments. docked ones sit in their slot (teal, solid). The arriving one travels from its origin.
    local arriving=$docked
    for i in 0 1 2 3; do
      if [ "$i" -lt "$docked" ]; then
        x=${SX[$i]}; y=${SY[$i]}; col="$TEAL"; tcol="$TXTL"; op=1.0; fr=1
      elif [ "$i" -eq "$arriving" ] && [ "$arriving" -lt 4 ]; then
        x=$(lerp "${OX[$i]}" "${SX[$i]}" "$prog")
        y=$(lerp "${OY[$i]}" "${SY[$i]}" "$prog")
        # colour eases from dim → amber (in-flight, attention) → teal as it nears the dock
        if [ "$prog" -ge 80 ]; then col="$TEAL"; else col="$AMBER"; fi
        tcol="$TXTL"; op=$(awk "BEGIN{printf \"%.2f\", 0.55 + 0.45*$prog/100}"); fr=0
      else
        x=${OX[$i]}; y=${OY[$i]}; col="$DIM"; tcol="$TXTD"; op=0.85; fr=0
      fi
      # connective filament from slot to a docked/arriving fragment (shows it being pulled into parity)
      if [ "$fr" -eq 1 ] || { [ "$i" -eq "$arriving" ] && [ "$prog" -ge 35 ]; }; then
        printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1.4" opacity="0.35"/>\n' "$CX" "$CY" "$x" "$y" "$TEAL"
      fi
      # the fragment card
      printf '<g opacity="%s">\n' "$op"
      printf '<rect x="%d" y="%d" width="120" height="46" rx="9" fill="%s" opacity="0.16" filter="url(#ns)"/>\n' "$((x-60))" "$((y-23))" "$col"
      printf '<rect x="%d" y="%d" width="120" height="46" rx="9" fill="none" stroke="%s" stroke-width="2"/>\n' "$((x-60))" "$((y-23))" "$col"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="700" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((y-1))" "$col" "${LBL[$i]}"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="10.5" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((y+15))" "$TXTD" "${SUB[$i]}"
      printf '</g>\n'
    done

    # central label of what is forming
    local clab="IDEA package" ccol="$TXTD"
    [ "$docked" -ge 4 ] && ccol="$TEAL"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="12.5" font-weight="600" fill="%s" text-anchor="middle" opacity="0.85">%s</text>\n' "$CX" "$CY" "$ccol" "$clab"

    # the challenger READY stamp — lands once all four are locked
    if [ "$stamp" -ge 1 ]; then
      local scol="$AMBER" sscale rot
      [ "$stamp" -ge 2 ] && scol="$TEAL"
      # land = slightly oversized & rotated, settle = tidy
      if [ "$stamp" -eq 1 ]; then rot="-13"; else rot="-7"; fi
      printf '<g transform="translate(%d %d) rotate(%s)">\n' "1085" "$CY" "$rot"
      printf '<rect x="-74" y="-30" width="148" height="60" rx="9" fill="none" stroke="%s" stroke-width="4"/>\n' "$scol"
      printf '<text x="0" y="9" font-family="DejaVu Sans, Arial, sans-serif" font-size="29" font-weight="800" fill="%s" text-anchor="middle" letter-spacing="2">READY</text>\n' "$scol"
      printf '<text x="0" y="30" font-family="DejaVu Sans, Arial, sans-serif" font-size="11" font-weight="600" fill="%s" text-anchor="middle" opacity="0.85">the challenger</text>\n' "$scol"
      printf '</g>\n'
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" fill="%s" text-anchor="middle">challenger signs off · knowledge-parity reached → hand off to FOUNDRY</text>\n' "$CX" "$((H-22))" "$scol"
    else
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" fill="%s" text-anchor="middle">adversarial dialogue pulls each axis to knowledge-parity</text>\n' "$CX" "$((H-22))" "$TXTD"
    fi

    printf '</svg>\n'
  } > "$path"
}

f=0
nf() { printf '%s/f%03d.svg' "$OUT" "$f"; }

# B1 timing: emit each DISTINCT visual state ONCE and record its role + hold count in TIMING.tsv
# (one row per emitted frame, in order: <frame_index>\t<role>\t<holds>, TAB-separated). reslow.sh reads
# this to give pure transitions a flick and the meaning beats their "Ah-HA!" dwell — no faked repeats.
#   transition=3 · label=7 · caption=14 · long=21 · dense=28 · poster=48
# Ah-HA floor (≥24): the convergence-to-package beat and the READY caption are this figure's core meaning.
TIMING="$OUT/TIMING.tsv"
: > "$TIMING"
# $1 docked  $2 prog  $3 stamp  $4 role  $5 holds  — emit one distinct state, log its timing row
step() {
  emit "$1" "$2" "$3" "$(nf)"
  printf '%d\t%s\t%d\n' "$f" "$4" "$5" >> "$TIMING"
  f=$((f+1))
}

# Phase 1: each fragment travels in (transitions, flick by) and DOCKS — the dock locks one axis to
# knowledge-parity (a teal label reveal → label role, 7 holds, ≤20 chars).
for d in 0 1 2 3; do
  step "$d"  25 0 transition 3
  step "$d"  60 0 transition 3
  step "$d" 100 0 label      7
done
# all four docked, no stamp — the scattered fragments have CONVERGED into one IDEA package. This is the
# core "Ah-HA!" of the figure → dense, 28 holds (≥24): time to see the package come together and read it.
step 4 0 0 dense 28
# Phase 2: the challenger's READY stamp lands (amber) — the meaning beat (knowledge-parity → hand off).
# The 68-char teaching caption is the sequence's payoff → dense, 28 holds (≥24).
step 4 0 1 dense 28
# Phase 3: the stamp settles teal — the complete, build-ready poster the loop rests on → poster, 48 holds.
step 4 0 2 poster 48

echo "emitted $f frames into $OUT (TIMING.tsv: $(grep -c '' "$TIMING") rows)"
