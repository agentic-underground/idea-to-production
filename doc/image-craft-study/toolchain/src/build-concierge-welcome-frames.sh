#!/usr/bin/env bash
# CONCIERGE welcome card: the arrival layer assembling.
# A two-line status bar builds itself widget-by-widget — ◆ lifecycle · ◇ session · ◈ life · ⚔ caught
# tick from dim→teal as each instrument comes online — then a welcome greeting line UNFURLS beneath
# (a left→right wipe), as concierge greets whoever opened the repo. Ends on a complete, settled card.
# Dark-mode canon: ground #1e1e2e; teal #5eead4 done/active; amber #fbbf24 current/greeting; dim #3a3a55 pending.
set -euo pipefail
OUT="${1:-/tmp/concierge-welcome-frames}"; mkdir -p "$OUT"

W=1280; H=320
DIM="#3a3a55"; TEAL="#5eead4"; AMBER="#fbbf24"; TXTD="#6b7280"; TXTL="#e8e8ef"; GROUND="#1e1e2e"
FONT='DejaVu Sans, Arial, sans-serif'

# Card geometry
CX=70; CW=$((W-140))           # card x and width
CARD_Y=78; CARD_H=170
L1_Y=140                        # widgets row baseline
L2_Y=205                        # greeting row baseline

# Four widgets evenly placed across line 1
WID_X=(150 470 760 1010)
WID_GLYPH=("◆" "◇" "◈" "⚔")
WID_LABEL=("lifecycle" "session" "life" "caught")
WID_VAL=("BUILD" "12.4k tok" "94% est" "7")

# The greeting that unfurls (char-revealed)
GREET="welcome — concierge has the door. what brings you in: operate, or evolve?"

emit() { # $1 widgets_lit(0..4) ; $2 greet_chars(0..len) ; $3 settled(0/1) ; $4 path
  local lit=$1 gchars=$2 settled=$3 path=$4
  local i x glyph lab val gcol gop r breath
  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$W" "$H" "$W" "$H"
    printf '<rect width="100%%" height="100%%" fill="%s"/>\n' "$GROUND"
    # depth layer: radial glow gradient + blur/shadow filter definitions
    printf '<defs>\n'
    printf '<radialGradient id="dg" cx="50%%" cy="55%%" r="50%%"><stop offset="0%%" stop-color="#5eead4" stop-opacity="0.05"/><stop offset="100%%" stop-color="#000000" stop-opacity="0"/></radialGradient>\n'
    printf '<filter id="bgb" x="-100%%" y="-100%%" width="300%%" height="300%%"><feGaussianBlur stdDeviation="22"/></filter>\n'
    printf '<filter id="ns" x="-40%%" y="-40%%" width="180%%" height="180%%"><feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#000000" flood-opacity="0.35"/></filter>\n'
    printf '</defs>\n'
    # soft blurred glow behind main content — faint amber focal under the cooler teal halo (warm doorway depth)
    printf '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="url(#dg)" filter="url(#bgb)"/>\n' "$((W/2))" "$((CARD_Y + CARD_H/2))" "$((W*42/100))" "$((H*22/100))"
    # title
    printf '<text x="%d" y="46" font-family="%s" font-size="25" font-weight="700" fill="%s" text-anchor="middle">CONCIERGE · the repo greets whoever opens it</text>\n' "$((W/2))" "$FONT" "$TXTL"

    # the welcome card panel
    printf '<rect x="%d" y="%d" width="%d" height="%d" rx="14" fill="#23233a" stroke="#2f2f48" stroke-width="2" filter="url(#ns)"/>\n' "$CX" "$CARD_Y" "$CW" "$CARD_H"

    # left "door" accent bar — warms from dim to amber as the card completes (a lit doorway)
    local doorcol="$DIM" dop=0.6
    if [ "$settled" -eq 1 ]; then doorcol="$AMBER"; dop=0.9
    elif [ "$lit" -ge 3 ]; then doorcol="$AMBER"; dop=0.5; fi
    printf '<rect x="%d" y="%d" width="7" height="%d" rx="3" fill="%s" opacity="%s"/>\n' "$CX" "$CARD_Y" "$CARD_H" "$doorcol" "$dop"

    # line-1: the four status widgets
    for i in 0 1 2 3; do
      x=${WID_X[$i]}; glyph=${WID_GLYPH[$i]}; lab=${WID_LABEL[$i]}; val=${WID_VAL[$i]}
      if [ "$i" -lt "$lit" ]; then
        # lit: glyph teal (caught glyph amber), value bright
        local glc="$TEAL"
        [ "$i" -eq 3 ] && glc="$AMBER"
        printf '<text x="%d" y="%d" font-family="%s" font-size="26" fill="%s">%s</text>\n' "$x" "$L1_Y" "$FONT" "$glc" "$glyph"
        printf '<text x="%d" y="%d" font-family="%s" font-size="18" fill="%s">%s</text>\n' "$((x+34))" "$L1_Y" "$FONT" "$TXTD" "$lab"
        printf '<text x="%d" y="%d" font-family="%s" font-size="19" font-weight="600" fill="%s">%s</text>\n' "$((x+34))" "$((L1_Y+26))" "$FONT" "$TXTL" "$val"
        # tick-in flash ring on the most-recently-lit widget (before settle)
        if [ "$i" -eq "$((lit-1))" ] && [ "$settled" -eq 0 ] && [ "$gchars" -eq 0 ]; then
          printf '<circle cx="%d" cy="%d" r="20" fill="none" stroke="%s" stroke-width="2" opacity="0.55"/>\n' "$((x+9))" "$((L1_Y-8))" "$glc"
        fi
      else
        # pending placeholder
        printf '<text x="%d" y="%d" font-family="%s" font-size="26" fill="%s" opacity="0.5">%s</text>\n' "$x" "$L1_Y" "$FONT" "$DIM" "$glyph"
        printf '<text x="%d" y="%d" font-family="%s" font-size="18" fill="%s" opacity="0.6">%s</text>\n' "$((x+34))" "$L1_Y" "$FONT" "$DIM" "$lab"
        printf '<rect x="%d" y="%d" width="62" height="11" rx="4" fill="%s" opacity="0.45"/>\n' "$((x+34))" "$((L1_Y+15))" "$DIM"
      fi
    done

    # divider between the HUD row and the greeting row
    if [ "$lit" -ge 4 ]; then
      printf '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2f2f48" stroke-width="2"/>\n' "$((CX+24))" "$((L2_Y-32))" "$((CX+CW-24))" "$((L2_Y-32))"
    fi

    # line-2: the greeting unfurls left→right (character reveal)
    if [ "$gchars" -gt 0 ]; then
      local shown="${GREET:0:$gchars}"
      # escape XML-special chars
      shown="${shown//&/&amp;}"; shown="${shown//</&lt;}"; shown="${shown//>/&gt;}"
      # greeting in amber (the warm welcome), settled portion stays
      printf '<text x="%d" y="%d" font-family="%s" font-size="21" font-weight="500" fill="%s">%s</text>\n' "$((CX+30))" "$L2_Y" "$FONT" "$AMBER" "$shown"
      # blinking caret while still typing
      if [ "$gchars" -lt ${#GREET} ]; then
        local cx2=$(( CX+30 + gchars*11 ))
        printf '<rect x="%d" y="%d" width="9" height="22" fill="%s" opacity="0.8"/>\n' "$cx2" "$((L2_Y-17))" "$TEAL"
      fi
    fi

    # settled checkmark — the door is open, everything is go
    if [ "$settled" -eq 1 ]; then
      printf '<text x="%d" y="%d" font-family="%s" font-size="19" font-weight="700" fill="%s" text-anchor="end">✓ at the door</text>\n' "$((CX+CW-30))" "$L2_Y" "$FONT" "$TEAL"
    fi

    printf '</svg>\n'
  } > "$path"
}

# ---- explicit tagged timing (B1/B3) ----------------------------------------------------------------
# Each DISTINCT visual state is emitted exactly ONCE; per-frame dwell comes from TIMING.tsv holds, not
# from repeating identical calls. Roles & holds per the B1 table:
#   transition=3 · label=7 (≤20) · caption=14 (20–40) · long=21 (40–60) · dense=28 (60–80) · poster=48
# Ah-HA floor (≥24 → dense=28): for this figure the COMPLETED warm greeting is the meaning beat (the
# door is open, the visitor is welcomed); the SETTLED routing payoff (✓ at the door, the two lanes
# offered) is the poster. The typewriter character-reveal frames are pure transitions (holds=3, motion).
f=0
: > "$OUT/TIMING.tsv"
# fr <role> <holds> <lit> <greet_chars> <settled>
fr() {
  local role=$1 holds=$2; shift 2
  emit "$1" "$2" "$3" "$OUT/f$(printf '%03d' $f).svg"
  printf '%d\t%s\t%d\n' "$f" "$role" "$holds" >> "$OUT/TIMING.tsv"
  f=$((f+1))
}

GLEN=${#GREET}

# 1) empty card forming — establishing beat (short, just the frame appears)
fr label      7   0 0 0
# 2) the four status instruments tick online, one per beat — pure transitions (motion)
fr transition 3   1 0 0
fr transition 3   2 0 0
fr transition 3   3 0 0
fr transition 3   4 0 0
# 3) the full HUD settles — a readable medium beat before the greeting starts
fr caption    14  4 0 0
# 4) the greeting unfurls — typewriter character-reveal = pure transition holds (motion).
#    The reveal runs all the way to the LAST glyph so the next beat is a true settle, not a jump.
for frac in 12 24 38 52 66 80 92; do
  c=$(( GLEN * frac / 100 ))
  fr transition 3 4 "$c" 0
done
# 5) SETTLED POSTER — the single most important beat, emitted as ONE distinct settled state. The greeting
#    is now FULLY typed at full opacity AND the door is open (✓ at the door): a complete, legible, settled
#    card. It is held the LONGEST of any frame (poster dwell) so the key sentence settles and reads in full
#    BEFORE the loop restarts. (It is a SINGLE frame, not two identical ones — adjacent identical frames
#    would be de-duplicated by gifski and break the TIMING.tsv row=frame contract.) Every sampled / held
#    frame of this beat shows the complete greeting legibly.
# Ah-HA → payoff: the completed warm greeting lands, settled, and dwells.
fr poster     72  4 "$GLEN" 1
echo "emitted $f frames"
