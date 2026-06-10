#!/usr/bin/env bash
# Phase-8 proof: generate an animated "idea → production" lifecycle pipeline that lights up
# stage-by-stage. Emits per-frame SVGs, rasterises each via rsvg-convert, then the caller
# assembles GIF/APNG/MP4. Dark-mode canon: deep surface ground, teal→amber colour script,
# dual-ground legibility not required for an intentionally-dark animated masthead.
set -euo pipefail
OUT="${1:-frames}"; mkdir -p "$OUT"
STAGES=(DISCOVER DEFINE DESIGN BUILD SECURE SHIP OPERATE)
N=${#STAGES[@]}
W=1280; H=300; PAD=70; GAP=$(( (W - 2*PAD) / (N-1) ))
DIM="#3a3a55"; LIT_A="#5eead4"; LIT_B="#fbbf24"; TXT_DIM="#6b7280"; TXT_LIT="#e5e7eb"
# colour script: a stage lights teal, the "current" stage flares amber, trailing stages dim.
emit_frame() { # $1 = active count (0..N), $2 = output path
  local active=$1 path=$2 i x cx cy=130 col tcol r lab op
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="#1e1e2e"/>\n'
    # connecting track
    printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2a2a40" stroke-width="6"/>\n' "$PAD" "$cy" "$((W-PAD))" "$cy"
    # lit portion of the track
    if [ "$active" -gt 1 ]; then
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="6" opacity="0.55"/>\n' \
        "$PAD" "$cy" "$((PAD + (active-1)*GAP))" "$cy" "$LIT_A"
    fi
    for i in $(seq 0 $((N-1))); do
      x=$((PAD + i*GAP))
      if [ "$i" -lt "$active" ]; then
        if [ "$i" -eq "$((active-1))" ]; then col="$LIT_B"; r=26; tcol="$TXT_LIT"; op=1.0   # current = amber flare
        else col="$LIT_A"; r=20; tcol="$TXT_LIT"; op=0.92; fi                                # done = teal
      else col="$DIM"; r=16; tcol="$TXT_DIM"; op=0.8; fi                                      # pending = dim
      printf '<circle cx="%d" cy="%d" r="%d" fill="%s" opacity="%s"/>\n' "$x" "$cy" "$r" "$col" "$op"
      printf '<text x="%d" y="%d" font-family="DejaVu Sans, Arial, sans-serif" font-size="20" font-weight="600" fill="%s" text-anchor="middle">%s</text>\n' \
        "$x" "$((cy+62))" "$tcol" "${STAGES[$i]}"
    done
    printf '<text x="%d" y="48" font-family="DejaVu Sans, Arial, sans-serif" font-size="26" font-weight="700" fill="#e5e7eb" text-anchor="middle">idea → production</text>\n' "$((W/2))"
    printf '</svg>\n'
  } > "$path"
}
# Reveal frames (1..N), then a hold of the full pipeline.
f=0
for a in $(seq 1 "$N"); do
  emit_frame "$a" "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1))
done
for _ in 1 2 3 4; do emit_frame "$N" "$OUT/f$(printf '%03d' $f).svg"; f=$((f+1)); done
echo "emitted $f SVG frames in $OUT"
