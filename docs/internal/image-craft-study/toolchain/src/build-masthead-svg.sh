#!/usr/bin/env bash
# build-masthead-svg.sh — emit the ANIMATED SVG masthead (fully vector, SMIL; 0-GPU, deterministic).
#
# The hero of the root README. A rich, dimensional dark banner (vignette + wordmark glow-seat + embossed
# rail groove + receding rails — never a flat band) over the eight-phase value conveyor. Motion (one ~14s
# loop, SMIL — plays in GitHub README SVGs; if a viewer strips SVG animation it shows a coherent start
# frame, not a broken one):
#   1. FORWARD SWEEP  — an eased amber value-spark (light-throwing bloom) rides the rail DISCOVER→OPERATE;
#      each node LIGHTS (dim→glossy teal) as the spark passes and STAYS lit.
#   2. FEEDBACK BEAT  — the spark travels BACK along the amber feedback arc (ASSURE & SECURE → DESIGN &
#      BUILD); the arc + its (chipped) label glow; DESIGN/BUILD pulse amber.
#   3. RETURN BEAT    — a teal spark rides the return loop OPERATE→DISCOVER; the arc + its label glow;
#      DISCOVER/OPERATE pulse teal.
#   4. GRACEFUL RESET — the lit nodes fade out in a right→left wave (no jarring snap), then the loop repeats.
# Dark-mode canon: ground #0a0a11, teal #5eead4 (done/active), amber #fbbf24 (current/feedback), text #e8e8ef.
# Depth recipe (in-SVG only — sheen+pool+rim+drop-shadow, no raster composite) ported from diagram-primitives.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
OUT="${1:-$ROOT/docs/images/masthead.svg}"

python3 - "$OUT" <<'PY'
import sys
OUT = sys.argv[1]

W, H, CY, R = 1320, 420, 235, 18
STAGES = ["DISCOVER","IDEATE","DESIGN","BUILD","ASSURE","SECURE","PUBLISH","OPERATE"]
OWNERS = ["scanner","ideator","atelier","foundry","foundry","sentinel","pressroom","mission"]
N, PAD = 8, 110
xs = [round(PAD + i*(W-2*PAD)/(N-1)) for i in range(N)]

TEAL="#5eead4"; AMBER="#fbbf24"; DIM="#3a3a55"; INK="#e8e8ef"; SUB="#cdd2e3"; OWN="#6b7488"
SWEEP_END = 0.50
FB  = (0.55, 0.72)
RET = (0.76, 0.95)
DUR = "14s"
EASE = "0.42 0 0.2 1"   # ease-in-out cubic

def anim(attr, values, keytimes, **kw):
    extra = "".join(f' {k.replace("_","-")}="{v}"' for k,v in kw.items())
    return (f'<animate attributeName="{attr}" values="{values}" keyTimes="{keytimes}" '
            f'dur="{DUR}" repeatCount="indefinite" calcMode="linear"{extra}/>')

P = []
P.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" font-family="DejaVu Sans, Arial, sans-serif">')
P.append('<title>idea → production — a Claude Code plugin marketplace</title>')
P.append('<desc>Animated banner (SMIL): the wordmark "idea → production" over the eight-phase value '
         'conveyor on a rich dark band. An amber value-spark sweeps the rail DISCOVER→OPERATE, lighting each '
         'glossy teal phase node as it passes; then it travels back along the amber feedback arc (ASSURE &amp; '
         'SECURE send work back to DESIGN &amp; BUILD) and a teal spark rides the return loop (OPERATE’s '
         'learnings re-enter DISCOVER), each with its label, before the lit nodes fade out in a wave and the '
         'cycle repeats. Framed by the i2p front door and concierge greeter. If animation is unavailable the '
         'banner shows a coherent start frame.</desc>')

# ---- defs ----
P.append('<defs>')
P.append('<radialGradient id="bgvig" cx="50%" cy="42%" r="82%"><stop offset="0%" stop-color="#1b1b2b"/><stop offset="62%" stop-color="#11111b"/><stop offset="100%" stop-color="#08080e"/></radialGradient>')
P.append('<radialGradient id="wmglow" cx="50%" cy="50%" r="50%"><stop offset="0%" stop-color="#7aa2f7" stop-opacity="0.5"/><stop offset="100%" stop-color="#7aa2f7" stop-opacity="0"/></radialGradient>')
P.append('<radialGradient id="wmglow2" cx="50%" cy="50%" r="50%"><stop offset="0%" stop-color="#fbbf24" stop-opacity="0.5"/><stop offset="100%" stop-color="#fbbf24" stop-opacity="0"/></radialGradient>')
P.append('<radialGradient id="sheen" cx="38%" cy="30%" r="74%"><stop offset="0%" stop-color="#ffffff" stop-opacity="0.34"/><stop offset="44%" stop-color="#ffffff" stop-opacity="0.08"/><stop offset="100%" stop-color="#ffffff" stop-opacity="0"/></radialGradient>')
P.append('<radialGradient id="pool" cx="50%" cy="72%" r="62%"><stop offset="0%" stop-color="#000000" stop-opacity="0"/><stop offset="70%" stop-color="#000000" stop-opacity="0"/><stop offset="100%" stop-color="#000000" stop-opacity="0.30"/></radialGradient>')
P.append('<filter id="ns" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="3" stdDeviation="3.2" flood-color="#000000" flood-opacity="0.6"/></filter>')
P.append('<linearGradient id="shelf" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#ffffff" stop-opacity="0.07"/><stop offset="52%" stop-color="#ffffff" stop-opacity="0.018"/><stop offset="100%" stop-color="#000000" stop-opacity="0.14"/></linearGradient>')
P.append('<filter id="glow" x="-150%" y="-150%" width="400%" height="400%"><feGaussianBlur stdDeviation="6"/></filter>')
P.append('<filter id="softblur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.4"/></filter>')
P.append('</defs>')

cx = W//2
# ---- rich dark banner background: base + vignette + wordmark glow-seat + node shelf + receding rails ----
P.append(f'<rect x="0" y="0" width="{W}" height="{H}" rx="14" fill="#08080e"/>')
P.append(f'<rect x="0" y="0" width="{W}" height="{H}" rx="14" fill="url(#bgvig)"/>')
P.append(f'<ellipse cx="560" cy="80" rx="300" ry="62" fill="url(#wmglow)" opacity="0.18"/>')
P.append(f'<ellipse cx="820" cy="84" rx="240" ry="52" fill="url(#wmglow2)" opacity="0.06"/>')
# the conveyor sits on a seated shelf — soft drop shadow beneath + a gradient ledge (survives downscale)
P.append(f'<rect x="66" y="260" width="{W-132}" height="22" rx="11" fill="#000000" opacity="0.4" filter="url(#softblur)"/>')
P.append(f'<rect x="60" y="192" width="{W-120}" height="82" rx="16" fill="url(#shelf)"/>')
# receding vertical rails (closer to centre = a touch brighter; edges fade)
P.append('<g stroke="#5eead4" stroke-width="1">')
for x in xs:
    op = 0.07 - 0.004*abs(x-cx)/100
    P.append(f'<line x1="{x}" y1="42" x2="{x}" y2="374" opacity="{max(op,0.025):.3f}"/>')
P.append('</g>')

# ---- microline + wordmark + subtitle ----
P.append(f'<text x="{cx}" y="36" font-size="14" font-weight="700" letter-spacing="4" fill="#9aa2c0" text-anchor="middle">A  CLAUDE  CODE  PLUGIN  MARKETPLACE</text>')
P.append(f'<text x="{cx}" y="92" font-size="52" font-weight="700" text-anchor="middle"><tspan fill="#7aa2f7">idea</tspan><tspan fill="#9aa2c0">  &#8594;  </tspan><tspan fill="{AMBER}">production</tspan></text>')
P.append(f'<text x="{cx}" y="126" font-size="16" letter-spacing="1" fill="{SUB}" text-anchor="middle">nine composable plugins carry VALUE from the spark of an idea to a shipped product</text>')

# ---- front-door / greeter terminals (i2p & concierge — the plugins that bracket the flow) ----
P.append(f'<circle cx="54" cy="{CY}" r="7.5" fill="none" stroke="#a78bfa" stroke-width="2.5"/>')
P.append(f'<circle cx="54" cy="{CY}" r="2.5" fill="#a78bfa"/>')
P.append(f'<circle cx="{W-54}" cy="{CY}" r="7.5" fill="none" stroke="#a78bfa" stroke-width="2.5"/>')
P.append(f'<circle cx="{W-54}" cy="{CY}" r="2.5" fill="#a78bfa"/>')
# labels lifted into the clear band above the rail so the wide "concierge" never crowds OPERATE
P.append(f'<text x="54" y="160" font-size="12" font-weight="700" fill="#bba6f5" text-anchor="middle">i2p</text>')
P.append(f'<text x="{W-54}" y="160" font-size="12" font-weight="700" fill="#bba6f5" text-anchor="middle">concierge</text>')
P.append(f'<text x="54" y="174" font-size="9" fill="#8f86ad" text-anchor="middle">front door</text>')
P.append(f'<text x="{W-54}" y="174" font-size="9" fill="#8f86ad" text-anchor="middle">greeter</text>')

# ---- rail: embossed groove (highlight + base + shadow) + teal lit overlay (grows with the spark, eased) ----
P.append(f'<line x1="{xs[0]}" y1="{CY+3}" x2="{xs[-1]}" y2="{CY+3}" stroke="#000000" stroke-width="3" opacity="0.45" filter="url(#softblur)"/>')
P.append(f'<line x1="{xs[0]}" y1="{CY-2}" x2="{xs[-1]}" y2="{CY-2}" stroke="#ffffff" stroke-width="1" opacity="0.06"/>')
P.append(f'<line x1="{xs[0]}" y1="{CY}" x2="{xs[-1]}" y2="{CY}" stroke="#2a2a40" stroke-width="5"/>')
P.append(f'<line x1="{xs[0]}" y1="{CY}" x2="{xs[0]}" y2="{CY}" stroke="{TEAL}" stroke-width="5" opacity="0.5">'
         + f'<animate attributeName="x2" values="{xs[0]};{xs[-1]};{xs[-1]}" keyTimes="0;{SWEEP_END};1" dur="{DUR}" repeatCount="indefinite" calcMode="spline" keySplines="{EASE};0 0 1 1"/>' + '</line>')

# ---- feedback arc (amber): SECURE -> DESIGN ----
fb_kt = f"0;{FB[0]-0.01:.2f};{FB[0]+0.03:.2f};{FB[1]:.2f};{FB[1]+0.03:.2f};1"
fb_val = "0.2;0.2;0.95;0.95;0.2;0.2"
P.append(f'<path d="M {xs[5]} 247 C {xs[5]} 291, {xs[2]} 291, {xs[2]} 247" fill="none" stroke="{AMBER}" stroke-width="3" stroke-dasharray="6 6">' + anim("opacity", fb_val, fb_kt) + '</path>')
P.append(f'<path d="M {xs[2]-5} 248 l 9 5 l -9 5 z" fill="{AMBER}">' + anim("opacity", fb_val, fb_kt) + '</path>')

# ---- return arc (teal): OPERATE -> DISCOVER ----
ret_kt = f"0;{RET[0]-0.01:.2f};{RET[0]+0.03:.2f};{RET[1]:.2f};1"
ret_val = "0.2;0.2;0.9;0.9;0.2"
P.append(f'<path d="M {xs[7]} 249 C {xs[7]+60} 350, {xs[0]-60} 350, {xs[0]} 249" fill="none" stroke="{TEAL}" stroke-width="3.5" stroke-dasharray="7 7">' + anim("opacity", ret_val, ret_kt) + '</path>')

# ---- nodes: dim base + glossy teal that LIGHTS as the spark passes, then fades out in a right→left wave ----
def lit_stack(x):
    ri = R-2; off = round(ri*0.7,1)
    return (f'<circle cx="{x}" cy="{CY}" r="{R}" fill="{TEAL}" filter="url(#ns)"/>'
            f'<circle cx="{x}" cy="{CY}" r="{R}" fill="url(#pool)"/>'
            f'<circle cx="{x}" cy="{CY}" r="{R}" fill="url(#sheen)"/>'
            f'<path d="M{x-off} {CY-off} A{ri} {ri} 0 0 1 {x+off} {CY-off}" fill="none" stroke="#ffffff" stroke-width="1.5" stroke-opacity="0.5" stroke-linecap="round"/>'
            f'<circle cx="{x}" cy="{CY}" r="{R}" fill="none" stroke="#0a0a12" stroke-width="1" stroke-opacity="0.55"/>')

for i,x in enumerate(xs):
    f = round(SWEEP_END * i/(N-1), 3)
    fade0 = round(0.90 + (N-1-i)*0.008, 3)     # OPERATE fades first, DISCOVER last → right→left wave
    fade1 = round(min(fade0+0.03, 0.998), 3)
    P.append(f'<circle cx="{x}" cy="{CY}" r="13" fill="{DIM}" opacity="0.85"/>')
    P.append(f'<g opacity="0">{lit_stack(x)}'
             + anim("opacity", "0;0;1;1;0;0", f"0;{f};{min(f+0.03,0.5):.3f};{fade0};{fade1};1") + '</g>')
    P.append(f'<text x="{x}" y="205" font-size="15" font-weight="600" fill="{INK}" text-anchor="middle">{STAGES[i]}</text>')
    P.append(f'<text x="{x}" y="268" font-size="11" fill="{OWN}" text-anchor="middle">{OWNERS[i]}</text>')

# ---- node pulse rings tied to the beats ----
def ring(x, color, kt, val):
    return (f'<circle cx="{x}" cy="{CY}" r="{R+6}" fill="none" stroke="{color}" stroke-width="2.5" opacity="0">' + anim("opacity", val, kt) + '</circle>')
fbr_kt=f"0;{FB[0]:.2f};{(FB[0]+FB[1])/2:.2f};{FB[1]+0.03:.2f};1"; fbr_val="0;0;0.9;0;0"
P.append(ring(xs[2], AMBER, fbr_kt, fbr_val)); P.append(ring(xs[3], AMBER, fbr_kt, fbr_val))
rr_kt=f"0;{RET[0]:.2f};{(RET[0]+RET[1])/2:.2f};{RET[1]+0.03:.2f};1"; rr_val="0;0;0.9;0;0"
P.append(ring(xs[0], TEAL, rr_kt, rr_val)); P.append(ring(xs[7], TEAL, rr_kt, rr_val))

# ---- value sparks: a light-throwing bloom + ring + bright core (above nodes) ----
def spark(core, halo):
    return (f'<g><circle cx="0" cy="0" r="42" fill="{halo}" opacity="0.16" filter="url(#glow)"/>'
            f'<circle cx="0" cy="0" r="26" fill="{halo}" opacity="0.34" filter="url(#glow)"/>'
            f'<circle cx="0" cy="0" r="19" fill="none" stroke="{halo}" stroke-width="2.5" opacity="0.75"/>'
            f'<circle cx="0" cy="0" r="9" fill="{core}"/>'
            f'<circle cx="-2.5" cy="-2.5" r="3" fill="#ffffff" opacity="0.85"/></g>')

# forward spark (amber) — eased sweep along the rail
P.append('<g opacity="0">'
         + anim("opacity", "1;1;0;0", f"0;{SWEEP_END:.2f};{SWEEP_END+0.03:.2f};1")
         + f'<animateMotion path="M {xs[0]} {CY} L {xs[-1]} {CY}" dur="{DUR}" repeatCount="indefinite" '
           f'calcMode="spline" keyPoints="0;1;1" keyTimes="0;{SWEEP_END};1" keySplines="{EASE};0 0 1 1"/>'
         + spark("#ffe6a6", AMBER) + '</g>')
# feedback spark (amber) — eased ride SECURE->DESIGN
fbm_kt=f"0;{FB[0]:.2f};{FB[1]:.2f};1"
P.append('<g opacity="0">'
         + anim("opacity", "0;0;1;1;0;0", f"0;{FB[0]:.2f};{FB[0]+0.03:.2f};{FB[1]:.2f};{FB[1]+0.03:.2f};1")
         + f'<animateMotion path="M {xs[5]} 247 C {xs[5]} 291, {xs[2]} 291, {xs[2]} 247" dur="{DUR}" '
           f'repeatCount="indefinite" calcMode="spline" keyPoints="0;0;1;1" keyTimes="{fbm_kt}" keySplines="0 0 1 1;{EASE};0 0 1 1"/>'
         + spark("#ffe6a6", AMBER) + '</g>')
# return spark (teal) — eased ride OPERATE->DISCOVER
rm_kt=f"0;{RET[0]:.2f};{RET[1]:.2f};1"
P.append('<g opacity="0">'
         + anim("opacity", "0;0;1;1;0;0", f"0;{RET[0]:.2f};{RET[0]+0.03:.2f};{RET[1]:.2f};{RET[1]+0.03:.2f};1")
         + f'<animateMotion path="M {xs[7]} 249 C {xs[7]+60} 350, {xs[0]-60} 350, {xs[0]} 249" dur="{DUR}" '
           f'repeatCount="indefinite" calcMode="spline" keyPoints="0;0;1;1" keyTimes="{rm_kt}" keySplines="0 0 1 1;{EASE};0 0 1 1"/>'
         + spark("#bff4ea", TEAL) + '</g>')

# ---- feedback / return labels (LAST = on top; opaque chip; clear of the arc & owner row; fade in on beat) ----
def label(cx, cy, text, color, kt, val, wpx):
    x0 = cx - wpx//2
    return (f'<g opacity="0">' + anim("opacity", val, kt)
            + f'<rect x="{x0}" y="{cy-16}" width="{wpx}" height="24" rx="7" fill="#161a26" stroke="{color}" stroke-width="1.2"/>'
            + f'<text x="{cx}" y="{cy}" font-size="12.5" font-weight="600" fill="{color}" text-anchor="middle">{text}</text></g>')
fblab_kt=f"0;{FB[0]:.2f};{FB[0]+0.04:.2f};{FB[1]+0.02:.2f};{FB[1]+0.06:.2f};1"; fblab_val="0;0;1;1;0;0"
P.append(label(cx, 326, "↩ ASSURE &amp; SECURE gates send work back to DESIGN &amp; BUILD", AMBER, fblab_kt, fblab_val, 446))
retlab_kt=f"0;{RET[0]:.2f};{RET[0]+0.04:.2f};{RET[1]+0.01:.2f};1"; retlab_val="0;0;1;1;0"
P.append(label(cx, 398, "↻ OPERATE’s learnings re-enter DISCOVER — the loop closes", TEAL, retlab_kt, retlab_val, 446))

P.append('</svg>')
open(OUT,"w").write("\n".join(P)+"\n")
print(f"wrote {OUT}")
PY
