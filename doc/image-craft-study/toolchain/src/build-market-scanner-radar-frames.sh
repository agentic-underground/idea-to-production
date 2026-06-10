#!/usr/bin/env bash
# MARKET-SCANNER radar: a sweep over a market field. An amber beam rotates across scattered
# candidate dots; each is SURFACED (brightens) as the beam passes. Weak ideas then FADE (killed
# early, struck out); one strong opportunity is KEPT — ringed teal and upheld with a verdict.
# Motion teaches DISCOVER + kill-weak-early. Dark-mode canon: teal=kept, amber=scanning, dim=pending.
set -euo pipefail
OUT="${1:-/tmp/market-scanner-radar-frames}"; mkdir -p "$OUT"
W=1280; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; GROUND="#1e1e2e"
CX=200; CY=176; R=128   # radar centre + radius (left dial)

# Candidate field: id  x   y   angle(deg, 0=up sweeping clockwise)  fate(kill/keep)  label
# angle is the sweep position at which the beam crosses the dot (when it gets surfaced)
CAND=(
  "0|340|96|28|kill|thin demand"
  "1|470|150|70|kill|crowded space"
  "2|560|220|122|keep|underserved niche"
  "3|690|110|158|kill|no pricing power"
  "4|800|200|196|kill|hard to reach"
  "5|930|130|232|kill|weak severity"
)
NC=${#CAND[@]}

# beam sweeps 0..270 over the reveal; PI-ish geometry kept simple in shell via precomputed dx/dy per angle
# We render the beam as a wedge from centre toward angle A (clockwise from up).
beam_xy() { # $1 angle deg ; echoes "x y" tip of beam at radius R
  local a=$1
  awk -v a="$a" -v cx="$CX" -v cy="$CY" -v r="$R" 'BEGIN{
    rad=(a)*3.14159265/180.0;
    x=cx + r*sin(rad);
    y=cy - r*cos(rad);
    printf "%d %d\n", x, y;
  }'
}

emit() { # $1 sweep_angle (0..270, or -1 = none) ; $2 phase: scan|kill|keep|hold ; $3 path
  local sa=$1 phase=$2 path=$3
  local tip i id cx2 cy2 ang fate lab col r op
  read -r tx ty < <(beam_xy "$sa")
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="%s"/>\n' "$GROUND"
    printf '<text x="40" y="46" font-family="DejaVu Sans, Arial, sans-serif" font-size="25" font-weight="700" fill="%s">MARKET-SCANNER · sweep the field, kill weak early</text>\n' "$TXTL"

    # --- radar dial (concentric rings + crosshair) ---
    printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="#2a2a40" stroke-width="2"/>\n' "$CX" "$CY" "$R"
    printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="#2a2a40" stroke-width="2"/>\n' "$CX" "$CY" "$((R*2/3))"
    printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="#2a2a40" stroke-width="2"/>\n' "$CX" "$CY" "$((R/3))"
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="2"/>\n' "$CX" "$((CY-R))" "$CX" "$((CY+R))"
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="2"/>\n' "$((CX-R))" "$CY" "$((CX+R))" "$CY"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans" font-size="14" fill="%s" text-anchor="middle">DISCOVER</text>\n' "$CX" "$((CY+R+30))" "$TXTD"

    # --- the sweeping beam (amber wedge + leading edge), only during scan ---
    if [ "$sa" -ge 0 ]; then
      # faint trailing wedge: a soft sector approximated by a translucent triangle to the tip
      printf '<path d="M %d %d L %d %d L %d %d Z" fill="%s" opacity="0.10"/>\n' \
        "$CX" "$CY" "$CX" "$((CY-R))" "$tx" "$ty" "$AMBER"
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="3" opacity="0.95"/>\n' "$CX" "$CY" "$tx" "$ty" "$AMBER"
      printf '<circle cx="%d" cy="%d" r="5" fill="%s"/>\n' "$tx" "$ty" "$AMBER"
    fi
    printf '<circle cx="%d" cy="%d" r="6" fill="%s"/>\n' "$CX" "$CY" "$TXTL"

    # --- candidate field (right of dial) + a small blip echoed on the dial ---
    for i in $(seq 0 $((NC-1))); do
      IFS='|' read -r id cx2 cy2 ang fate lab <<< "${CAND[$i]}"
      # state of this candidate
      local surfaced=0
      if [ "$sa" -ge 0 ] && [ "$sa" -ge "$ang" ]; then surfaced=1; fi
      if [ "$phase" = kill ] || [ "$phase" = keep ] || [ "$phase" = hold ]; then surfaced=1; fi

      if [ "$fate" = keep ]; then
        # the strong one
        if [ "$phase" = keep ] || [ "$phase" = hold ]; then
          # KEPT: teal ring + filled + upheld
          printf '<circle cx="%d" cy="%d" r="20" fill="none" stroke="%s" stroke-width="3"/>\n' "$cx2" "$cy2" "$TEAL"
          printf '<circle cx="%d" cy="%d" r="11" fill="%s"/>\n' "$cx2" "$cy2" "$TEAL"
          printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="16" font-weight="700" fill="%s">%s</text>\n' "$((cx2+30))" "$((cy2+5))" "$TXTL" "$lab"
        elif [ "$surfaced" = 1 ]; then
          col="$AMBER"; r=11; op=1.0
          printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s"/>\n' "$cx2" "$cy2" "$r" "$col" "$op"
          printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" fill="%s">%s</text>\n' "$((cx2+24))" "$((cy2+5))" "$TXTL" "$lab"
        else
          printf '<circle cx="%d" cy="%d" r="8" fill="%s" opacity="0.8"/>\n' "$cx2" "$cy2" "$DIM"
        fi
      else
        # a weak one
        if [ "$phase" = kill ] || [ "$phase" = keep ] || [ "$phase" = hold ]; then
          # KILLED: dimmed + struck through
          printf '<circle cx="%d" cy="%d" r="8" fill="%s" opacity="0.35"/>\n' "$cx2" "$cy2" "$DIM"
          printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2" opacity="0.6"/>\n' "$((cx2-12))" "$((cy2-12))" "$((cx2+12))" "$((cy2+12))" "$TXTD"
          printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" fill="%s" opacity="0.5" text-decoration="line-through">%s</text>\n' "$((cx2+22))" "$((cy2+5))" "$TXTD" "$lab"
        elif [ "$surfaced" = 1 ]; then
          # surfaced by the beam — momentarily amber/lit
          printf '<circle cx="%d" cy="%d" r="10" fill="%s" opacity="0.95"/>\n' "$cx2" "$cy2" "$AMBER"
          printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" fill="%s" opacity="0.92">%s</text>\n' "$((cx2+22))" "$((cy2+5))" "$TXTL" "$lab"
        else
          printf '<circle cx="%d" cy="%d" r="8" fill="%s" opacity="0.8"/>\n' "$cx2" "$cy2" "$DIM"
        fi
      fi
    done

    # --- verdict caption (build up) ---
    if [ "$phase" = kill ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="18" font-weight="600" fill="%s" text-anchor="end">5 killed — cheap, early</text>\n' "$((W-40))" "$((H-30))" "$TXTD"
    elif [ "$phase" = keep ] || [ "$phase" = hold ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="18" font-weight="700" fill="%s" text-anchor="end">KEEP — the spark → ideator</text>\n' "$((W-40))" "$((H-30))" "$TEAL"
    elif [ "$sa" -ge 0 ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="18" font-weight="600" fill="%s" text-anchor="end">scoring on the market taxonomy…</text>\n' "$((W-40))" "$((H-30))" "$AMBER"
    fi
    printf '</svg>\n'
  } > "$path"
}

f=0
# 1) sweep reveal: beam rotates 0..272 surfacing candidates one by one
for sa in 0 24 48 72 96 120 144 168 196 224 252; do
  emit "$sa" scan "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1))
done
# 2) kill the weak (struck through), beam parked
emit -1 kill "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1))
emit -1 kill "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1))
# 3) the keep: teal ring upheld
emit -1 keep "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1))
# 4) hold the settled poster
for _ in 1 2 3; do emit -1 hold "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); done
echo "emitted $f frames"
