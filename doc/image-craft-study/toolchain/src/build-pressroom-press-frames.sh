#!/usr/bin/env bash
# PRESSROOM press: the illustrate→review→publish craft animated.
# A SPEC card emits TWO options (A/B); the adversarial design-reviewer sweeps both,
# scores them, picks BEST (B wins, A dims); the chosen figure flies into a doc page
# and the page's figure-slot goes green/settled. Then hold. Dark-mode canon.
set -euo pipefail
OUT="${1:-/tmp/pressroom-press-frames}"; mkdir -p "$OUT"
W=1280; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"
GROUND="#1e1e2e"; PANEL="#26263a"; HAIR="#2a2a40"
FONT='font-family="DejaVu Sans, Arial, sans-serif"'

# layout columns
SPEC_X=70;  SPEC_W=210
OPT_X=360;  OPT_W=200          # option A top, option B below
REV_X=720                       # reviewer scan column (gutter between options and doc)
DOC_X=1000; DOC_W=210           # published doc page

# Stage drives the whole story. emit <stage> <path>
# stages: 0..N renders progressive richness; we use explicit phase tokens.
emit() {
  local phase=$1 path=$2
  # phase ∈ spec | optA | optB | scanA | scanB | pickB | fly1 | fly2 | land | hold
  local fig_fly_x fig_fly_y
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="%s"/>\n' "$GROUND"
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.13"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<radialGradient id="dga" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#fbbf24" stop-opacity="0.06"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dga)" filter="url(#bgb)"/>\n' "$((W/2))" "$((H/2))" "$((W*46/100))" "$((H*26/100))"
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$((H/2))" "$((W*42/100))" "$((H*22/100))"
    printf '<text x="%d" y="40" %s font-size="24" font-weight="700" fill="%s" text-anchor="middle">PRESSROOM · illustrate → review → publish</text>\n' "$((W/2))" "$FONT" "$TXTL"

    # ---- column captions ----
    printf '<text x="%d" y="76" %s font-size="14" font-weight="600" fill="%s" text-anchor="middle">SPEC</text>\n' "$((SPEC_X+SPEC_W/2))" "$FONT" "$TXTD"
    printf '<text x="%d" y="76" %s font-size="14" font-weight="600" fill="%s" text-anchor="middle">TWO OPTIONS · A/B</text>\n' "$((OPT_X+OPT_W/2))" "$FONT" "$TXTD"
    printf '<text x="%d" y="76" %s font-size="14" font-weight="600" fill="%s" text-anchor="middle">DOC</text>\n' "$((DOC_X+DOC_W/2))" "$FONT" "$TXTD"

    # ---- SPEC card (always present once we start) ----
    printf '<rect x="%d" y="92" width="%d" height="150" rx="10" fill="%s" stroke="%s" stroke-width="1.5" filter="url(#ns)"/>\n' "$SPEC_X" "$SPEC_W" "$PANEL" "$HAIR"
    printf '<text x="%d" y="120" %s font-size="14" font-weight="700" fill="%s">figure spec</text>\n' "$((SPEC_X+18))" "$FONT" "$TXTL"
    local sy=144
    for lbl in "subject: pipeline" "style: dark · 4×9" "must read at A4"; do
      printf '<circle cx="%d" cy="%d" r="3.5" fill="%s"/>\n' "$((SPEC_X+22))" "$((sy-4))" "$TEAL"
      printf '<text x="%d" y="%d" %s font-size="12.5" fill="%s">%s</text>\n' "$((SPEC_X+34))" "$sy" "$FONT" "#c4c4d4" "$lbl"
      sy=$((sy+26))
    done
    # arrow spec -> options
    printf '<path d="M %d 167 L %d 167" stroke="%s" stroke-width="2.5" marker-end="url(#ah)" opacity="0.8"/>\n' "$((SPEC_X+SPEC_W+6))" "$((OPT_X-14))" "$TEAL"

    # ---- option card renderer: draw_opt <y> <revealed?> <accent> <dim?> <crown?> <label> ----
    draw_opt() {
      local oy=$1 shown=$2 acc=$3 dimd=$4 crown=$5 olbl=$6
      [ "$shown" -eq 0 ] && return
      local op=1.0 stroke="$HAIR" sw=1.5
      [ "$dimd" -eq 1 ] && op=0.32
      [ "$acc" = "win" ] && { stroke="$TEAL"; sw=3; }
      printf '<g opacity="%s">\n' "$op"
      printf '<rect x="%d" y="%d" width="%d" height="92" rx="9" fill="%s" stroke="%s" stroke-width="%s" filter="url(#ns)"/>\n' "$OPT_X" "$oy" "$OPT_W" "$PANEL" "$stroke" "$sw"
      printf '<text x="%d" y="%d" %s font-size="13" font-weight="700" fill="%s">option %s</text>\n' "$((OPT_X+14))" "$((oy+22))" "$FONT" "$TXTL" "$olbl"
      # a tiny chart glyph inside (bars) — richer for the winner
      local bx=$((OPT_X+16)) by=$((oy+78))
      local h1 h2 h3 h4
      if [ "$acc" = "win" ]; then h1=18 h2=34 h3=26 h4=42; else h1=22 h2=16 h3=30 h4=12; fi
      local bcol="$TXTD"; [ "$acc" = "win" ] && bcol="$TEAL"
      local bi=0
      for hh in $h1 $h2 $h3 $h4; do
        printf '<rect x="%d" y="%d" width="14" height="%d" rx="2" fill="%s"/>\n' "$((bx+bi*22))" "$((by-hh))" "$hh" "$bcol"
        bi=$((bi+1))
      done
      # baseline
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>\n' "$bx" "$((by+2))" "$((bx+4*22-8))" "$((by+2))" "$HAIR"
      [ "$crown" -eq 1 ] && printf '<text x="%d" y="%d" %s font-size="13" font-weight="700" fill="%s" text-anchor="end">★ BEST</text>\n' "$((OPT_X+OPT_W-14))" "$((oy+22))" "$FONT" "$TEAL"
      printf '</g>\n'
    }

    # decide option visibility/state by phase
    local showA=0 showB=0 dimA=0 winB=0 crownB=0
    case "$phase" in
      spec)              ;;
      optA)              showA=1 ;;
      optB|scanA|scanB)  showA=1; showB=1 ;;
      pickB|fly1|fly2|land|hold) showA=1; showB=1; dimA=1; winB=1; crownB=1 ;;
    esac
    draw_opt 92  "$showA" "norm" "$dimA" 0      "A"
    draw_opt 196 "$showB" "$([ "$winB" -eq 1 ] && echo win || echo norm)" 0 "$crownB" "B"

    # ---- reviewer scan beam (sweeps A then B) ----
    case "$phase" in
      scanA) printf '<rect x="%d" y="88" width="%d" height="100" rx="9" fill="none" stroke="%s" stroke-width="2.5" stroke-dasharray="7 5"/>\n' "$OPT_X" "$OPT_W" "$AMBER"
             printf '<text x="%d" y="%d" %s font-size="13" font-weight="600" fill="%s" text-anchor="middle">design-reviewer scans A…</text>\n' "$REV_X" 150 "$FONT" "$AMBER" ;;
      scanB) printf '<rect x="%d" y="192" width="%d" height="100" rx="9" fill="none" stroke="%s" stroke-width="2.5" stroke-dasharray="7 5"/>\n' "$OPT_X" "$OPT_W" "$AMBER"
             printf '<text x="%d" y="%d" %s font-size="13" font-weight="600" fill="%s" text-anchor="middle">…scans B · scores both</text>\n' "$REV_X" 150 "$FONT" "$AMBER" ;;
      pickB) printf '<text x="%d" y="%d" %s font-size="13" font-weight="700" fill="%s" text-anchor="middle">B clears the 4×9 rubric ✓</text>\n' "$REV_X" 150 "$FONT" "$TEAL" ;;
    esac

    # reviewer-to-doc arrow (appears from pick onward)
    case "$phase" in
      pickB|fly1|fly2|land|hold)
        printf '<path d="M %d 242 L %d 242" stroke="%s" stroke-width="2.5" marker-end="url(#ah)" opacity="0.85"/>\n' "$((OPT_X+OPT_W+6))" "$((DOC_X-14))" "$TEAL" ;;
    esac

    # ---- DOC page (publish target) ----
    printf '<rect x="%d" y="92" width="%d" height="200" rx="10" fill="%s" stroke="%s" stroke-width="1.5"/>\n' "$DOC_X" "$DOC_W" "#222236" "$HAIR"
    printf '<text x="%d" y="118" %s font-size="13" font-weight="700" fill="%s">README.md</text>\n' "$((DOC_X+16))" "$FONT" "$TXTL"
    # text lines (prose)
    local ly=132
    for wln in 150 170 120; do
      printf '<rect x="%d" y="%d" width="%d" height="6" rx="3" fill="%s" opacity="0.7"/>\n' "$((DOC_X+16))" "$ly" "$wln" "$HAIR"
      ly=$((ly+14))
    done
    # figure slot in the doc
    local slot_filled=0
    case "$phase" in land|hold) slot_filled=1 ;; esac
    if [ "$slot_filled" -eq 1 ]; then
      printf '<rect x="%d" y="184" width="%d" height="68" rx="7" fill="%s" stroke="%s" stroke-width="2.5"/>\n' "$((DOC_X+16))" "$((DOC_W-32))" "$PANEL" "$TEAL"
      # mini winner chart settled in the slot
      local fbx=$((DOC_X+34)) fby=243
      local fbi=0
      for hh in 18 34 26 42; do
        printf '<rect x="%d" y="%d" width="12" height="%d" rx="2" fill="%s"/>\n' "$((fbx+fbi*20))" "$((fby-hh))" "$hh" "$TEAL"
        fbi=$((fbi+1))
      done
      printf '<text x="%d" y="%d" %s font-size="11" font-weight="600" fill="%s" text-anchor="end">published ✓</text>\n' "$((DOC_X+DOC_W-16))" 200 "$FONT" "$TEAL"
    else
      # empty dashed figure slot waiting
      printf '<rect x="%d" y="184" width="%d" height="68" rx="7" fill="none" stroke="%s" stroke-width="2" stroke-dasharray="6 5"/>\n' "$((DOC_X+16))" "$((DOC_W-32))" "$DIM"
      printf '<text x="%d" y="222" %s font-size="12" fill="%s" text-anchor="middle">figure slot</text>\n' "$((DOC_X+DOC_W/2))" "$FONT" "$TXTD"
    fi
    # remaining prose line under figure
    printf '<rect x="%d" y="266" width="%d" height="6" rx="3" fill="%s" opacity="0.7"/>\n' "$((DOC_X+16))" 140 "$HAIR"

    # ---- the chosen figure FLYING from option B toward the doc slot ----
    case "$phase" in
      fly1) fig_fly_x=$((OPT_X+OPT_W+40)); fig_fly_y=200 ;;
      fly2) fig_fly_x=$((DOC_X-90));       fig_fly_y=196 ;;
    esac
    case "$phase" in
      fly1|fly2)
        printf '<g transform="translate(%d %d)" opacity="0.96">\n' "$fig_fly_x" "$fig_fly_y"
        printf '<rect x="0" y="0" width="78" height="56" rx="7" fill="%s" stroke="%s" stroke-width="2.5" filter="url(#ns)"/>\n' "$PANEL" "$TEAL"
        local cbi=0
        for hh in 14 26 20 32; do
          printf '<rect x="%d" y="%d" width="10" height="%d" rx="2" fill="%s"/>\n' "$((12+cbi*16))" "$((46-hh))" "$hh" "$TEAL"
          cbi=$((cbi+1))
        done
        printf '</g>\n'
        # motion trail
        printf '<path d="M %d %d L %d %d" stroke="%s" stroke-width="2" stroke-dasharray="3 6" opacity="0.5"/>\n' "$((OPT_X+OPT_W))" 242 "$fig_fly_x" "$((fig_fly_y+28))" "$TEAL"
        ;;
    esac

    # arrowhead marker def
    printf '<defs><marker id="ah" markerWidth="9" markerHeight="9" refX="7" refY="4.5" orient="auto"><path d="M0 0 L9 4.5 L0 9 z" fill="%s"/></marker></defs>\n' "$TEAL"
    printf '</svg>\n'
  } > "$path"
}

# ---- explicit tagged timing (B1/B3) ----------------------------------------------------------------
# Each DISTINCT visual state is emitted exactly ONCE; per-frame dwell comes from TIMING.tsv holds, no
# longer from repeating identical calls. Roles & holds per the B1 table:
#   transition=3 · label=7 · caption=14 · long=21 · dense=28 · poster=48
# Ah-HA floor (≥24): for illustrate→review→publish the teaching core is the ★BEST selection (pickB)
# and the publish payoff (land) — both get dense(28) so the reader can travel, read, and connect.
f=0
: > "$OUT/TIMING.tsv"
# fr <role> <holds> <phase>
fr() {
  local role=$1 holds=$2 phase=$3
  emit "$phase" "$OUT/f$(printf '%03d' $f).svg"
  printf '%d\t%s\t%d\n' "$f" "$role" "$holds" >> "$OUT/TIMING.tsv"
  f=$((f+1))
}

fr caption  14 spec     # spec card lands — the figure brief
fr caption  14 optA     # option A renders
fr caption  14 optB     # option B renders — now two options to weigh
fr caption  14 scanA    # reviewer sweeps A
fr caption  14 scanB    # reviewer sweeps B · scores both
# Ah-HA: the adversarial reviewer PICKS — B clears the rubric, ★BEST, A dims. The selection is taught here.
fr dense    28 pickB    # B clears rubric — picked BEST (teaching core)
fr transition 3 fly1    # chosen figure flies toward the doc
fr transition 3 fly2    # …still in flight
# Ah-HA: the publish payoff — the chosen figure lands in the doc slot and the slot goes green/published.
fr dense    28 land     # figure lands in doc slot → published (payoff core)
# Settled poster: the published page dwells before the loop resets.
fr poster   48 hold     # settle
echo "emitted $f frames"
