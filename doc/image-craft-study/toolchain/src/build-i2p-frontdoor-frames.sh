#!/usr/bin/env bash
# i2p front door: the meta-surface that ROUTES. An i2p core sits at center; the eight specialist
# plugins ring it. A dispatch beam sweeps the ring, lighting each plugin teal in turn (i2p dispatching
# to every capability when present), the core pulsing amber as the conductor. Once the ring is whole,
# the loop "closes" — all spokes lit, core green — and holds: i2p is the one front door that drives them all.
# Dark-mode canon: ground #1e1e2e, teal=lit/active, amber=current/conductor, dim=pending, muted labels.
set -euo pipefail
OUT="${1:-i2p-frontdoor-frames}"; mkdir -p "$OUT"

# Eight specialist plugins ringing the i2p core (i2p itself is the hub, not a spoke).
NODES=(market-scanner ideator atelier foundry sentinel pressroom mission-control concierge)
N=${#NODES[@]}

W=1280; H=360
CX=$((W/2)); CY=$((H/2 + 12))
R=100                  # ring radius
NR=19                  # node radius
HUB=33                 # hub radius
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; TRACK="#2a2a40"

# Precompute node positions (start at top, clockwise). awk for float trig (no bc on this box).
declare -a NX NY LX LY ANCH
for i in $(seq 0 $((N-1))); do
  # rotate the whole ring by half a step so NO node lands dead-top/dead-bottom (keeps the
  # vertical centerline clear for the title + caption; labels fall into the diagonal gutters).
  read -r nx ny lx ly anch < <(awk -v i="$i" -v n="$N" -v cx="$CX" -v cy="$CY" -v r="$R" 'BEGIN{
    a = -1.5707963 + 3.1415927/n + i*6.2831853/n; c=cos(a); s=sin(a);
    printf "%.0f %.0f %.0f %.0f %s\n", cx+r*c, cy+r*s, cx+(r+50)*c, cy+(r+50)*s,
      (c>0.25?"start":(c<-0.25?"end":"middle"));
  }')
  NX[$i]=$nx; NY[$i]=$ny; LX[$i]=$lx; LY[$i]=$ly; ANCH[$i]=$anch
done

emit() { # $1 = number of nodes lit so far (0..N) ; $2 = current/active index (-1=none) ; $3 = whole(0/1) ; $4 path
  local lit=$1 cur=$2 whole=$3 path=$4 i col tcol nr beamcol
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="40" font-family="DejaVu Sans, Arial, sans-serif" font-size="24" font-weight="700" fill="#e8e8ef" text-anchor="middle">i2p · the front door that dispatches to every plugin</text>\n' "$CX"

    # ring track
    printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="3"/>\n' "$CX" "$CY" "$R" "$TRACK"

    # spokes (hub→node): lit teal when that node is lit, else dim
    for i in $(seq 0 $((N-1))); do
      if [ "$i" -lt "$lit" ]; then col="$TEAL"; printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="3" opacity="0.55"/>\n' "$CX" "$CY" "${NX[$i]}" "${NY[$i]}" "$col"
      else printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2" opacity="0.35"/>\n' "$CX" "$CY" "${NX[$i]}" "${NY[$i]}" "$TRACK"; fi
    done

    # dispatch beam: a bright spoke to the current node being dispatched (amber), drawn over the lit spokes
    if [ "$cur" -ge 0 ]; then
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="5" opacity="0.95" stroke-linecap="round"/>\n' "$CX" "$CY" "${NX[$cur]}" "${NY[$cur]}" "$AMBER"
    fi

    # nodes
    for i in $(seq 0 $((N-1))); do
      if [ "$i" -eq "$cur" ]; then col="$AMBER"; tcol="$TXTL"; nr=$((NR+4))
      elif [ "$i" -lt "$lit" ]; then col="$TEAL"; tcol="$TXTL"; nr=$NR
      else col="$DIM"; tcol="$TXTD"; nr=$((NR-3)); fi
      # subtle halo on the active node
      [ "$i" -eq "$cur" ] && printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="0.18"/>\n' "${NX[$i]}" "${NY[$i]}" "$((nr+10))" "$AMBER"
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" filter="url(#ns)"/>\n' "${NX[$i]}" "${NY[$i]}" "$nr" "$col"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="600" fill="%s" text-anchor="%s">%s</text>\n' "${LX[$i]}" "$((${LY[$i]}+4))" "$tcol" "${ANCH[$i]}" "${NODES[$i]}"
    done

    # hub: amber while dispatching, green when the ring is whole
    local hubcol="$AMBER" hubglow="$AMBER"
    [ "$whole" -eq 1 ] && { hubcol="$TEAL"; hubglow="$TEAL"; }
    printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="0.16"/>\n' "$CX" "$CY" "$((HUB+12))" "$hubglow"
    printf '<circle cx="%d" cy="%d" r="%d" fill="%s" filter="url(#ns)"/>\n' "$CX" "$CY" "$HUB" "$hubcol"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="20" font-weight="800" fill="#1e1e2e" text-anchor="middle">i2p</text>\n' "$CX" "$((CY+7))"

    # status caption under the hub
    local cap; if [ "$whole" -eq 1 ]; then cap="all powers routed — one front door, every plugin lit"
      elif [ "$cur" -ge 0 ]; then cap="dispatching → ${NODES[$cur]}"
      else cap="i2p · meta-surface"; fi
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" fill="%s" text-anchor="middle">%s</text>\n' "$CX" "$((H-18))" "$( [ "$whole" -eq 1 ] && echo "$TEAL" || echo "$TXTD" )" "$cap"

    printf '</svg>\n'
  } > "$path"
}

f=0
fp() { printf '%03d' "$1"; }
# 1) build-up: sweep the ring, lighting each plugin in turn (i2p dispatching to each specialist).
#    each reveal held 3 frames (medium caption "dispatching → <name>") so the sweep reads as a
#    deliberate routing pass, not a flicker.
for i in $(seq 0 $((N-1))); do
  emit "$i" "$i" 0 "$OUT/f$(fp $f).svg"; f=$((f+1))
  emit "$i" "$i" 0 "$OUT/f$(fp $f).svg"; f=$((f+1))
  emit "$i" "$i" 0 "$OUT/f$(fp $f).svg"; f=$((f+1))
done
# 2) the last node lands, ring becomes whole — beam releases, all lit, hub still amber (a beat)
emit "$N" -1 0 "$OUT/f$(fp $f).svg"; f=$((f+1))
emit "$N" -1 0 "$OUT/f$(fp $f).svg"; f=$((f+1))
# 3) the ring closes: hub goes green, everything lit — settled poster, held 5 frames (long caption
#    "all powers routed — one front door, every plugin lit") so the loop reads as done
for _ in 1 2 3 4 5; do emit "$N" -1 1 "$OUT/f$(fp $f).svg"; f=$((f+1)); done
echo "emitted $f frames into $OUT"
