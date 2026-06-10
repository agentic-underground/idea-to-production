#!/usr/bin/env bash
# Root masthead — the OUTWARD-FACING front door of the idea-to-production marketplace.
# SELF-CONTAINED builder (0-GPU): emits keyframe SVGs -> rasterises -> generates true CROSS-DISSOLVE tween
# frames with `magick -morph` (the fades) -> assembles a slow, lingering GIF -> writes the reduced-motion
# poster + the frame-strip proof.
#
# Motion design (revised per art-direction note — "the build-up was too much"):
#  - SLOW + LINGERING: each phase node arrives, then a gentle slow-PULSE (breathe) before it FADES to the next.
#  - FADES, not hard cuts: every transition is a magick -morph cross-dissolve.
#  - TWO feedback loops, each in its own beat so nothing crowds:
#      1. the QUALITY/SECURITY feedback arc — ASSURE & SECURE can send work BACK to DESIGN & BUILD (amber, above
#         the deeper loop), highlighted on its own beat;
#      2. the RETURN loop — OPERATE's learnings re-enter DISCOVER (teal, full width), on its own beat.
#  - The settled POSTER shows BOTH loops, calm, no competing labels.
# Dark-mode canon: ground #1e1e2e, text #e8e8ef. teal=done/active, amber=current/feedback, dim=pending.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"   # repo root
OUT="${1:-/tmp/masthead-cycle-build}"; KF="$OUT/kf"; FR="$OUT/fr"; rm -rf "$OUT"; mkdir -p "$KF" "$FR"
GIF="$ROOT/doc/images/masthead-cycle.gif"
POSTER="$ROOT/doc/images/masthead-cycle-poster.png"
STRIP="$ROOT/doc/image-craft-study/toolchain/proof/masthead-cycle-strip.png"
GIFSKI="${GIFSKI:-$HOME/.cargo/bin/gifski}"
M=2          # cross-dissolve tween frames inserted between consecutive keyframes (the fade)
FPS=13

STAGES=(DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE)
OWNERS=(scanner ideator atelier foundry foundry sentinel pressroom mission)
N=${#STAGES[@]}
W=1320; H=360; PAD=92; CY=214; GAP=$(( (W - 2*PAD) / (N-1) ))
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; IDEA="#7aa2f7"
xof(){ echo $(( PAD + $1*GAP )); }

# emit_kf <active> <hlnode> <halo> <fb> <ret> <path>
#   active : nodes 0..active-1 are "reached"
#   hlnode : index shown amber as the CURRENT node (-1 = none, all reached read teal)
#   halo   : extra radius of the amber attention-halo (the breathe peak)
#   fb     : feedback arc state — 0 dim · 1 glow+label · 2 calm-visible (poster)
#   ret    : return  arc state — 0 dim · 1 glow+label · 2 calm-visible (poster)
emit_kf() {
  local active=$1 hl=$2 halo=$3 fb=$4 ret=$5 path=$6 i x
  local x2 x3 x5 fbmid; x2=$(xof 2); x3=$(xof 3); x5=$(xof 5); fbmid=$(( (x2+x5)/2 ))
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    # ---- depth layer: gradient glow + filters ----
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%%%" cy="55%%%%" r="50%%%%"><stop offset="0%%%%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%%%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%%%" y="-100%%%%" width="300%%%%" height="300%%%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%%%" y="-40%%%%" width="180%%%%" height="180%%%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$CY" "$((W*42/100))" "$((H*22/100))"
    # ---- microline + dominant WORDMARK + subtitle (static) ----
    printf '<text x="%d" y="40" font-family="DejaVu Sans, Arial, sans-serif" font-size="14" font-weight="700" letter-spacing="4" fill="#9aa2c0" text-anchor="middle">A  CLAUDE  CODE  PLUGIN  MARKETPLACE</text>\n' "$((W/2))"
    printf '<text x="%d" y="96" font-family="DejaVu Sans, Arial, sans-serif" font-size="54" font-weight="700" text-anchor="middle"><tspan fill="%s">idea</tspan><tspan fill="#9aa2c0">  &#8594;  </tspan><tspan fill="%s">production</tspan></text>\n' "$((W/2))" "$IDEA" "$AMBER"
    printf '<text x="%d" y="132" font-family="DejaVu Sans, Arial, sans-serif" font-size="17" letter-spacing="1" fill="#e6e9f0" text-anchor="middle">nine composable plugins carry VALUE from the spark of an idea to a shipped product</text>\n' "$((W/2))"
    # ---- baseline rail + lit portion ----
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="5"/>\n' "$PAD" "$CY" "$((W-PAD))" "$CY"
    [ "$active" -gt 1 ] && printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="5" opacity="0.5"/>\n' "$PAD" "$CY" "$(xof $((active-1)))" "$CY" "$TEAL"

    # ---- (1) QUALITY/SECURITY feedback arc: ASSURE & SECURE -> DESIGN & BUILD (shallow, amber) ----
    local fbcol fbop fblab; case "$fb" in
      1) fbcol="$AMBER"; fbop=0.95;; 2) fbcol="#9a7430"; fbop=0.6;; *) fbcol="#2a2a40"; fbop=0.5;; esac
    printf '<path d="M %d %d C %d %d, %d %d, %d %d" fill="none" stroke="%s" stroke-width="3.5" opacity="%s" stroke-dasharray="6 6"/>\n' \
      "$x5" "$((CY+12))" "$x5" "$((CY+54))" "$x2" "$((CY+54))" "$x2" "$((CY+12))" "$fbcol" "$fbop"
    # arrowhead returning into DESIGN/BUILD
    printf '<path d="M %d %d l 9 5 l -9 5 z" fill="%s" opacity="%s"/>\n' "$((x2-5))" "$((CY+13))" "$fbcol" "$fbop"
    if [ "$fb" -eq 1 ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" font-weight="600" fill="%s" text-anchor="middle">&#8617; ASSURE &amp; SECURE gates can send work back to DESIGN &amp; BUILD</text>\n' "$fbmid" "$((CY+72))" "$AMBER"
    fi

    # ---- (2) RETURN loop: OPERATE -> DISCOVER (deep, teal, full width) ----
    local rcol rop; case "$ret" in
      1) rcol="$TEAL"; rop=0.92;; 2) rcol="#2f7468"; rop=0.6;; *) rcol="#2a2a40"; rop=0.5;; esac
    printf '<path d="M %d %d C %d %d, %d %d, %d %d" fill="none" stroke="%s" stroke-width="4" opacity="%s" stroke-dasharray="7 7"/>\n' \
      "$((W-PAD))" "$((CY+16))" "$((W-PAD+34))" "$((CY+92))" "$((PAD-34))" "$((CY+92))" "$PAD" "$((CY+16))" "$rcol" "$rop"
    if [ "$ret" -eq 1 ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" fill="%s" text-anchor="middle">&#8635; OPERATE&#39;s learnings re-enter DISCOVER &#8212; the loop closes</text>\n' "$((W/2))" "$((CY+112))" "$TEAL"
    fi
    # poster caption (both loops settled, no per-arc labels competing)
    if [ "$fb" -eq 2 ] && [ "$ret" -eq 2 ]; then
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="13" fill="#9aa2c0" text-anchor="middle">a cycle <tspan fill="%s">with feedback</tspan> &#8212; gates send work back, operation reopens discovery</text>\n' "$((W/2))" "$((CY+122))" "$AMBER"
    fi

    # ---- the eight phase nodes ----
    for i in $(seq 0 $((N-1))); do
      x=$(xof "$i")
      local col r tcol op
      if [ "$i" -lt "$active" ]; then
        if [ "$i" -eq "$hl" ]; then
          col="$AMBER"; r=22; tcol="$TXTL"; op=1.0
          printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="0.16"/>\n' "$x" "$CY" "$((r+8+halo))" "$AMBER"
        else col="$TEAL"; r=17; tcol="$TXTL"; op=0.94; fi
      else col="$DIM"; r=14; tcol="$TXTD"; op=0.8; fi
      # feedback beat: ring DESIGN/BUILD/ASSURE/SECURE amber; return beat: ring DISCOVER/OPERATE teal
      if [ "$fb" -eq 1 ] && { [ "$i" -ge 2 ] && [ "$i" -le 5 ]; }; then
        printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="2" opacity="0.8"/>\n' "$x" "$CY" "$((r+6))" "$AMBER"
      fi
      if [ "$ret" -eq 1 ] && { [ "$i" -eq 0 ] || [ "$i" -eq 7 ]; }; then
        printf '<circle cx="%d" cy="%d" r="%d" fill="none" stroke="%s" stroke-width="2" opacity="0.8"/>\n' "$x" "$CY" "$((r+6))" "$TEAL"
      fi
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s" filter="url(#ns)"/>\n' "$x" "$CY" "$r" "$col" "$op"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="15" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((CY-34))" "$tcol" "${STAGES[$i]}"
      local ocol="$TXTD"; [ "$i" -lt "$active" ] && ocol="#8b9bb4"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="11" fill="%s" text-anchor="middle">%s</text>\n' "$x" "$((CY+30))" "$ocol" "${OWNERS[$i]}"
    done
    # front-door framing
    local fcol="#6b7280"; [ "$active" -ge "$N" ] && fcol="#9aa2c0"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="12" font-weight="600" fill="%s" text-anchor="start">i2p &#183; front door</text>\n' "$((PAD-50))" "$((CY-72))" "$fcol"
    printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="12" font-weight="600" fill="%s" text-anchor="end">concierge &#183; greeter</text>\n' "$((W-PAD+50))" "$((CY-72))" "$fcol"
    printf '</svg>\n'
  } > "$path"
}

# ---- keyframe list (with per-keyframe HOLD counts) ----
idx=0; HOLDS=()
addkf(){ # active hlnode halo fb ret hold
  emit_kf "$1" "$2" "$3" "$4" "$5" "$KF/$(printf '%03d' $idx).svg"
  rsvg-convert -o "$KF/$(printf '%03d' $idx).png" "$KF/$(printf '%03d' $idx).svg"
  HOLDS+=("$6"); idx=$((idx+1))
}
# each phase: arrive (normal) then breathe (halo peak) — the linger + slow-pulse
for i in $(seq 0 $((N-1))); do
  addkf $((i+1)) "$i" 0  0 0  2     # N_i  (arrive, hold)
  addkf $((i+1)) "$i" 14 0 0  2     # Br_i (breathe peak, hold)
done
addkf "$N" -1 0 0 0 2               # ALLCALM — all teal, both loops dim
addkf "$N" -1 0 1 0 14              # FEEDBACK beat (amber arc + label), linger
addkf "$N" -1 0 0 0 2               # back to calm
addkf "$N" -1 0 0 1 12              # RETURN beat (teal arc + label), linger
addkf "$N" -1 0 2 2 26              # POSTER — both loops settled, held a LOT longer before the loop resets
K=$idx

# ---- assemble: holds + cross-dissolve tweens, cyclic (seamless loop) ----
n=0
for ((i=0;i<K;i++)); do
  j=$(( (i+1)%K ))
  for ((h=0;h<HOLDS[i];h++)); do cp "$KF/$(printf '%03d' $i).png" "$FR/$(printf '%04d' $n).png"; n=$((n+1)); done
  magick "$KF/$(printf '%03d' $i).png" "$KF/$(printf '%03d' $j).png" -morph "$M" "$OUT/mph_%03d.png"
  for ((m=1;m<=M;m++)); do cp "$OUT/mph_$(printf '%03d' $m).png" "$FR/$(printf '%04d' $n).png"; n=$((n+1)); done
  rm -f "$OUT"/mph_*.png
done
echo "frames: $n  (keyframes $K, morph $M, fps $FPS)"

# ---- GIF (fallback ladder) + optimise ----
if [ -x "$GIFSKI" ]; then "$GIFSKI" --fps "$FPS" --quality 90 -o "$GIF" "$FR"/*.png
elif command -v ffmpeg >/dev/null; then
  ffmpeg -y -framerate "$FPS" -i "$FR/%04d.png" -vf "palettegen" "$OUT/pal.png" >/dev/null 2>&1
  ffmpeg -y -framerate "$FPS" -i "$FR/%04d.png" -i "$OUT/pal.png" -lavfi paletteuse "$GIF" >/dev/null 2>&1
else magick -delay $((100/FPS)) "$FR"/*.png "$GIF"; fi
command -v gifsicle >/dev/null && gifsicle --colors 200 --lossy=40 -O3 -b "$GIF"

# ---- reduced-motion poster (the settled both-loops frame) + frame-strip proof ----
cp "$KF/$(printf '%03d' $((K-1))).png" "$POSTER"
magick montage \
  "$FR/0006.png" "$FR/0024.png" "$FR/0042.png" "$KF/$(printf '%03d' $((K-4))).png" "$KF/$(printf '%03d' $((K-2))).png" "$KF/$(printf '%03d' $((K-1))).png" \
  -tile 3x2 -geometry +4+4 -background '#11111b' "$STRIP" 2>/dev/null || true

echo "gif:    $GIF  ($(stat -c%s "$GIF") bytes)"
echo "poster: $POSTER"
echo "strip:  $STRIP"
