#!/usr/bin/env bash
# mission-control OPERATE telemetry strip: golden-signal sparklines pulse calm (OBSERVE), an incident
# spikes the line amber and trips an alert (RESPOND), a mitigation pulls it back to teal/healthy (RECOVER),
# then a learning arcs back to DISCOVER (↻ ITERATE) and the loop closes. Motion teaches observe→respond→
# iterate→loop. Dark-mode canon: ground #1e1e2e, teal=healthy/done, amber=incident/attention, dim=pending.
set -euo pipefail
OUT="${1:-/tmp/mission-control-operate-frames}"; mkdir -p "$OUT"
W=1280; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; GRID="#2a2a40"
# telemetry plot box
PX=70; PY=96; PW=$((W-2*PX)); PH=136; PBOT=$((PY+PH))
BASE=$((PY+PH-46))   # calm baseline y (lower number = higher on canvas)

# Build the sparkline polyline points for a given phase.
# phase: observe | spike | respond | healed   ; prog 0..100 sweep of the incident position
spark() { # $1 phase  $2 prog(0..100)  -> echoes "x,y x,y ..."
  local phase=$1 prog=$2 i n=64 x y amp inc center
  local pts=""
  center=$(( prog * n / 100 ))
  for i in $(seq 0 $n); do
    x=$(( PX + i * PW / n ))
    # calm wave: small sinusoidal jitter via cheap integer pseudo-osc
    amp=$(( ( (i*53 + prog*7) % 13 ) - 6 ))   # -6..6 calm ripple
    y=$(( BASE + amp/2 ))
    # incident bump centred at 'center', width ~10 samples
    local d=$(( i - center )); [ $d -lt 0 ] && d=$(( -d ))
    if [ "$phase" = "spike" ] && [ $d -le 8 ]; then
      inc=$(( (9 - d) * (9 - d) ))            # parabolic spike up to ~81 px
      y=$(( BASE - inc - 8 ))
    elif [ "$phase" = "respond" ] && [ $d -le 8 ]; then
      # decaying bump as response takes hold (prog drives recovery)
      local resid=$(( (9 - d) * (9 - d) * (100 - prog) / 100 ))
      y=$(( BASE - resid - 6 ))
    fi
    [ $y -lt $((PY+8)) ] && y=$((PY+8))
    [ $y -gt $((PBOT-8)) ] && y=$((PBOT-8))
    pts="$pts $x,$y"
  done
  echo "$pts"
}

emit() { # $1 phase  $2 prog  $3 alert(0/1)  $4 respond_dot(0/1)  $5 arc(0/1)  $6 caption  $7 path
  local phase=$1 prog=$2 alert=$3 rdot=$4 arc=$5 cap=$6 path=$7
  local pts; pts=$(spark "$phase" "$prog")
  local stroke="$TEAL"
  case "$phase" in spike|respond) stroke="$AMBER" ;; esac
  # status pip colours: OBSERVE / RESPOND / ITERATE markers along the bottom
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$((PY+PH/2))" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="46" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="%s" text-anchor="middle">mission-control · OPERATE the live product</text>\n' "$((W/2))" "$TXTL"
    # plot frame + gridlines
    printf '<rect x="%d" y="%d" width="%d" height="%d" fill="#16161f" stroke="%s" stroke-width="1.5" rx="8"/>\n' "$PX" "$PY" "$PW" "$PH" "$GRID"
    local g
    for g in 1 2 3; do
      local gy=$(( PY + g*PH/4 ))
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1" opacity="0.5"/>\n' "$PX" "$gy" "$((PX+PW))" "$gy" "$GRID"
    done
    # signal label
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" fill="%s">golden signals · latency · errors · saturation</text>\n' "$((PX+10))" "$((PY-10))" "$TXTD"
    # the telemetry sparkline (glow underlay + crisp line)
    printf '<polyline points="%s" fill="none" stroke="%s" stroke-width="7" opacity="0.18" stroke-linejoin="round" stroke-linecap="round"/>\n' "$pts" "$stroke"
    printf '<polyline points="%s" fill="none" stroke="%s" stroke-width="2.6" stroke-linejoin="round" stroke-linecap="round"/>\n' "$pts" "$stroke"
    # health chip top-right
    local chip="$TEAL" clab="HEALTHY"
    if [ "$phase" = "spike" ]; then chip="$AMBER"; clab="INCIDENT"; fi
    if [ "$phase" = "respond" ]; then chip="$AMBER"; clab="MITIGATING"; fi
    printf '<circle cx="%d" cy="%d" r="7" fill="%s"/>\n' "$((PX+PW-150))" "$((PY+22))" "$chip"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="700" fill="%s">%s</text>\n' "$((PX+PW-135))" "$((PY+27))" "$chip" "$clab"
    # alert burst marker at the spike
    if [ "$alert" -eq 1 ]; then
      local ax=$(( PX + prog*PW/100 ))
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="22" fill="%s" text-anchor="middle">⚠</text>\n' "$ax" "$((PY+22))" "$AMBER"
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1.4" stroke-dasharray="4 4" opacity="0.7"/>\n' "$ax" "$((PY+30))" "$ax" "$PBOT" "$AMBER"
    fi
    # mitigation dot sweeping in (RESPOND)
    if [ "$rdot" -eq 1 ]; then
      local dx=$(( PX + prog*PW/100 ))
      printf '<circle cx="%d" cy="%d" r="6" fill="%s" filter="url(#ns)"/>\n' "$dx" "$BASE" "$TEAL"
      printf '<circle cx="%d" cy="%d" r="13" fill="none" stroke="%s" stroke-width="2" opacity="0.5"/>\n' "$dx" "$BASE" "$TEAL"
    fi
    # phase pips row: OBSERVE -> RESPOND -> ITERATE  (lit by current phase)
    local lx=$((PX+10)); local ly=$((PBOT+44))
    pip() { # $1 x  $2 lit(teal/amber/dim)  $3 label
      printf '<circle cx="%d" cy="%d" r="6" fill="%s"/>\n' "$1" "$ly" "$2"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="600" fill="%s">%s</text>\n' "$(($1+14))" "$((ly+5))" "$2" "$3"
    }
    local cO="$DIM" cR="$DIM" cI="$DIM"
    case "$phase" in
      observe) cO="$TEAL" ;;
      spike)   cO="$TEAL"; cR="$AMBER" ;;
      respond) cO="$TEAL"; cR="$AMBER" ;;
      healed)  cO="$TEAL"; cR="$TEAL"; [ "$arc" -eq 1 ] && cI="$TEAL" ;;
    esac
    pip "$lx" "$cO" "OBSERVE"
    pip "$((lx+330))" "$cR" "RESPOND"
    pip "$((lx+700))" "$cI" "ITERATE ↻"
    # closing learning arc: from ITERATE pip back to OBSERVE (re-enter DISCOVER).
    # Caption sits in its own band ABOVE the dashed arc (≥10px gap, arc kept on-canvas).
    if [ "$arc" -eq 1 ]; then
      local sx=$((lx+700)); local ex=$((lx+6))
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" fill="%s" text-anchor="middle">↻ what production teaches re-enters DISCOVER</text>\n' "$(( (sx+ex)/2 ))" "$((ly+23))" "$TEAL"
      printf '<path d="M %d %d C %d %d, %d %d, %d %d" fill="none" stroke="%s" stroke-width="2.4" stroke-dasharray="6 6" opacity="0.9"/>\n' \
        "$sx" "$((ly+33))" "$sx" "$((ly+38))" "$ex" "$((ly+38))" "$ex" "$((ly+33))" "$TEAL"
    fi
    # caption
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" fill="%s" text-anchor="end">%s</text>\n' "$((W-PX))" "$((PBOT+48))" "$TXTD" "$cap"
    printf '</svg>\n'
  } > "$path"
}

f=0
nf() { printf '%s/f%03d.svg' "$OUT" "$f"; }

# B1 organic-meter holds by role. role ∈ {transition,label,caption,long,dense,poster}.
# transition=3 · label=7 · caption=14 · long=21 · dense=28 · poster=48.
# Ah-HA rule: any concept/relationship/meaning-revealing beat ≥24 (use 28 = "dense").
hold_for() { case "$1" in
  transition) echo 3 ;; label) echo 7 ;; caption) echo 14 ;;
  long) echo 21 ;; dense) echo 28 ;; poster) echo 48 ;; *) echo 14 ;;
esac; }

: > "$OUT/TIMING.tsv"
# step() emits one DISTINCT visual state once, then records its TIMING row (index, role, holds).
step() { # $1 role  rest = emit() args (phase prog alert rdot arc caption)
  local role=$1; shift
  emit "$@" "$(nf)"
  printf '%d\t%s\t%s\n' "$f" "$role" "$(hold_for "$role")" >> "$OUT/TIMING.tsv"
  f=$((f+1))
}

# 1) OBSERVE — calm telemetry, healthy. Pure sweep drift → transitions (each distinct: prog 8/20/32).
step transition observe  8 0 0 0 "observe — golden signals nominal"
step transition observe 20 0 0 0 "observe — golden signals nominal"
step transition observe 32 0 0 0 "observe — golden signals nominal"
# 2) INCIDENT — the spike trips the alert. Reveals the incident relationship → Ah-HA (dense, 28).
step dense spike 50 1 0 0 "respond — incident detected, alert fires"
# 3) MITIGATE — "mitigate first, then diagnose" is the teaching core of RESPOND → Ah-HA (dense, 28).
step dense   respond 30 1 1 0 "respond — mitigate first, then diagnose"
step caption respond 55 1 1 0 "respond — mitigation taking hold"
step caption respond 80 0 1 0 "respond — error budget recovering"
step label   respond 96 0 1 0 "respond — back inside SLO"
# 4) HEALED + ITERATE arc — the watch→respond→iterate loop closes (re-enter DISCOVER). Settled poster=48
#    (≥24, so the captioned ITERATE arc beat lands as the teaching climax).
step poster healed 100 0 0 1 "iterate — learning re-enters the cycle ↻"
echo "emitted $f frames into $OUT"
