# Raster toolchain — local finish, blend, composite & animate (the post-render stage)

> The publish render pipeline is **SVG-first + one ComfyUI PNG**. This doc is the **local post-render
> stage** that *finishes* what a handler produced: composite onto grounds, **blend SVG↔raster**, enhance a
> generative PNG, and **assemble animated figures** — all on the worker (0-GPU). It is the knowledge behind
> [`handler-composite`](../agents/handler-composite.md) and the optional finish call in the other handlers.
> Pairs with the [dark-mode canon](../skills/illustrator/references/dark-mode-canon.md) (legibility law) and
> the [art-direction canon](../skills/design-reviewer/references/image-aesthetic-canon.md) (the taste bar —
> including the **Medium-richness** dimension this stage exists to satisfy).

## The tools & the graceful fallback ladder

All are **optional** deps (declared in `skills/check/requirements.tsv`). **Probe before use; degrade, never
block** — exactly like `handler-comfyui` declining when the rig is down. Verified versions on a reference
worker: ImageMagick 7.1.1, ffmpeg 7.1.4, libvips 8.16.1, gifsicle 1.96, gifski 1.34.0, rsvg-convert 2.60.

| Job | Primary | Fallback → | Last resort |
|---|---|---|---|
| **SVG → PNG** | `rsvg-convert -w W -h H` | `magick in.svg out.png` | `inkscape --export-type=png` |
| **composite layers** | `magick A B -compose over -composite` | `vips composite2 A B out over` | — |
| **frames → GIF** | `gifski --fps F --quality Q -o g.gif f*.png` | `ffmpeg palettegen`+`paletteuse` | — |
| **GIF optimise** | `gifsicle -O3 --colors 256 --lossy=N` | (skip — ship gifski output) | — |
| **frames → MP4** | `ffmpeg -c:v libx264 -pix_fmt yuv420p` | — | — |
| **frames → APNG** | `ffmpeg -f apng -plays 0` | `magick -dispose previous` | — |
| **fast batch resize / filters** | `vips` / `vipsthumbnail` | `magick` | — |
| **no motion tools at all** | — | — | **ship the static figure** (handler-composite says so) |

> **Detection one-liner** (handlers call this): `have(){ command -v "$1" >/dev/null || [ -x "$HOME/.cargo/bin/$1" ]; }`
> — note **gifski installs to `~/.cargo/bin`**, often off `$PATH`; resolve it explicitly.

## SECURITY — the recipe library is parameter-only

**Never interpolate caller/SPEC text into a shell command.** Filenames come from the handler's own
controlled paths; **every numeric param is validated before use** with this one helper; text that must
appear *in an image* (a wordmark) goes into an **SVG `<text>` node** (rasterised by rsvg), never onto a
command line. No `eval`, no caller-supplied `-vf`/`-fx`/convert-filter strings.
```bash
int(){ case "$1" in ''|*[!0-9]*) echo "reject non-integer param: $1" >&2; exit 2;; *) printf '%d' "$1";; esac; }
FPS=$(int "${SPEC_FPS:-4}"); Q=$(int "${SPEC_QUALITY:-90}"); W=$(int "$SPEC_W"); H=$(int "$SPEC_H")   # then use $FPS/$Q/$W/$H
```
This mirrors the comfyui **allowlisted-template** stance: a fixed recipe with filled, **type-checked** slots,
never an arbitrary graph or arbitrary shell. Phase-5 ships these as a vetted recipe library with EARS bounds.

## Recipe 1 — dual-ground composite (legibility proof)

Rasterise a transparent figure onto **both** `#000` and `#fff` so the design-reviewer can confirm it reads
on any host (the [dark-mode canon](../skills/illustrator/references/dark-mode-canon.md) contract):
```bash
for BG in 000000 ffffff; do rsvg-convert -b "#$BG" -o "/tmp/check-$BG.png" FIGURE.svg; done   # primary
# magick fallback:  magick -background "#$BG" FIGURE.svg "/tmp/check-$BG.png"
```

## Recipe 2 — SVG↔raster blend (the marketing-masthead pattern)

Raster atmosphere (a ComfyUI hero/texture) **under** a crisp vector layer (wordmark, frame, callouts, data).
Each layer plays to its medium — the type stays razor-sharp, the atmosphere stays rich. Legibility scrim
lives **in the SVG** as a gradient rect:
```bash
magick HERO.jpg -gravity north -crop ${W}x${H}+0+${YOFF} +repage base.png    # raster band
rsvg-convert -w $W -h $H overlay.svg -o overlay.png                          # vector layer (transparent + scrim)
magick base.png overlay.png -compose over -composite blend.png               # blend  (fallback: vips composite2 base.png overlay.png blend.png over)
magick blend.png -quality 88 blend.jpg                                       # ship (JPG for photographic grounds)
```
The overlay SVG carries: a bottom-up `linearGradient` scrim rect (≈0→0.82 alpha) for text legibility, the
wordmark/tagline as `<text>`, and an optional thin frame. **Proven** end-to-end.

## Recipe 3 — post-ComfyUI finish (enhance · cutout · colour-script · optimise)

After `handler-comfyui` downloads its PNG, an **optional** finish (probe first):
```bash
magick in.png -modulate 100,108,100 -unsharp 0x0.8+0.6+0.008 enhanced.png      # gentle saturation + micro-contrast
magick in.png -fuzz 8% -transparent "#1e1e2e" cutout.png                        # flat-ground cutout → transparent
vips thumbnail in.png small.png 1280                                            # fast high-quality downscale
magick in.png -strip -quality 86 ship.jpg                                       # strip metadata, ship
```
Keep finishes **subtle and named** — the goal is the [art-direction canon](../skills/design-reviewer/references/image-aesthetic-canon.md)'s colour-script/clean-edge bar, not a filter look.

## Recipe 4 — animated figure assembly (frames → GIF / APNG / MP4)

Render **N frames** (the vector handlers can emit a frame-series; comfyui can batch seeds/denoise), then:
```bash
# frames f000.png..fNNN.png at one fixed size
gifski --fps 4 --quality 90 -o anim.gif frames/f*.png                          # primary GIF (truecolor, dithered)
gifsicle -O3 --colors 256 --lossy=80 anim.gif -o anim.min.gif                  # optimise (helps rich frames)
ffmpeg -y -framerate 4 -i frames/f%03d.png -f apng -plays 0 anim.apng          # APNG (true alpha, lossless)
ffmpeg -y -framerate 4 -i frames/f%03d.png -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p -movflags +faststart anim.mp4
# gifski-absent fallback:
ffmpeg -y -framerate 4 -i frames/f%03d.png -vf palettegen=stats_mode=diff /tmp/pal.png
ffmpeg -y -framerate 4 -i frames/f%03d.png -i /tmp/pal.png -lavfi paletteuse=dither=bayer anim.gif
```
The `scale=trunc(iw/2)*2:…` filter **auto-rounds to even dimensions** (yuv420p rejects odd width/height — an
unguarded MP4 hard-crashes; this makes any frame size just work). **Motion is motivated** (a build-up reveals structure; a loop
breathes) — never gratuitous; honour reduced-motion by always shipping a static poster frame alongside.
Proven.
**How an assembled animation is *paced*** — the dwell, the breathe, the linger — is governed by the
[Motion canon](#motion-canon--the-house-motion-policy-the-linger-directive) below; a Recipe-4 figure is built
**to** that canon (its generator emits a `TIMING.tsv`; `reslow.sh` applies it).

## Recipe 4b — animated SVG via SMIL (the vector-native loop)

The **fully-vector** motion path — a single `.svg` that animates itself, no raster framebuffer, no GIF. Use it
for crisp **README hero / diagram** motion (sharp at any zoom, tiny on disk, deterministic). GitHub renders
repo `.svg` via `<img>` **including gradients, filters, AND SMIL animation** — so an animated SVG plays inline.
Proven exemplar: `docs/images/masthead.svg`
(78→87→91/100 across three design-review passes).

**The shape of a loop.** One master period (`dur="14s" repeatCount="indefinite"`); every element animates over
that same clock via `<animate>` (state/opacity) or `<animateMotion>` (path travel), sliced with `values` +
`keyTimes` into **beats**. The masthead's three beats — *forward sweep · feedback · return* — are a good model:

- **Sequential reveal that HOLDS** — a node lights as the action passes it and **stays lit**: lit-overlay
  `opacity` `values="0;0;1;1;0;0"` with `keyTimes` placing the rise at the pass-fraction `f_i` and the hold
  out to the reset (not a per-cycle re-flicker).
- **A light-throwing spark** that *travels* — `<animateMotion>` along a `path` with `keyPoints`/`keyTimes`
  (ride during its beat, hold off-beat) + an `opacity` `<animate>` gating visibility. The spark THROWS light
  (wide blurred bloom + ring + hot core), it is never a flat moving dot (see motion-language §SPARK).
- **The spark rides BACK on feedback/return** — a second/third `<animateMotion>` group follows the *curved*
  feedback/return path (cubic `C…`), visible only during its beat.
- **EASED, not mechanical** — `calcMode="spline"` + `keySplines="0.42 0 0.2 1"` (ease-in-out) on motion;
  linear tweens read robotic. Linear is acceptable only for an instant reset segment (`0 0 1 1`).
- **GRACEFUL reset, never a snap** — at the loop seam the lit state fades out in a **staggered wave** (e.g.
  nodes dim right→left over the last ~1s) so the loop reads "settled, then repeats", not a jarring jump.
- **Coherent static fallback** — author the `t=0` state to be legible and meaningful (a dormant "start" frame),
  because **`prefers-reduced-motion` cannot be gated inside pure SMIL** and a few readers strip animation. State
  this limitation; the alt-text must describe the motion.

**Verify each beat DETERMINISTICALLY** (Chrome `--virtual-time-budget` mis-seeks SMIL — do not trust it).
Serve the SVG over `http://` and seek with the chrome-devtools MCP:
```js
const s = document.querySelector('svg'); s.pauseAnimations(); s.setCurrentTime(8.0);   // → screenshot
```
Screenshot at each beat, on **light AND dark**, and at **README downscale** (~520px, Recipe 1 + the
downscale-survival gate in `dark-mode-canon.md`). Build the SVG from a committed generator (a Python-in-bash
emitter like `build-masthead-svg.sh`), never hand-maintained — the per-element `keyTimes`/`keySplines` math is
generator work.

## Motion canon — the house motion policy (the linger directive)

The house policy for **how an animated figure moves in time**. Recipe 4 *assembles* frames; this canon decides
how long each frame **lingers**, how it **breathes**, and where the eye is allowed to **rest**. It is the source
of truth — `reslow.sh` is its implementation (the generator-agnostic re-timer), and every animated README figure is built **to** this canon. A motion/timing lesson generalises
**here**, so every future animation inherits it.

**SLOWER pace · LINGER · breathe.** Animation is for *teaching*, not for showing off frame-rate. Each frame
**lingers** — it stays long enough to be read, not flicked past. Within a frame's dwell, apply a gentle
brightness **PULSE breathe** (a slow rise-and-fall, e.g. `100 102 104 102` via `magick -modulate`) so a held
frame feels *alive*, not frozen — this is a breathe, **never** a per-frame flicker. **STAY much longer on the
settled final frame** before the loop restarts: the poster dwell is what lets a loop read as "settled / done",
not as a nervous churn.

**Organic meter via `TIMING.tsv`.** Uniform timing makes a dense teaching beat and a throwaway transition feel
the same — wrong. Instead, each generator emits **each DISTINCT visual state exactly once**, tagged with a
**role** whose dwell-tier sets its hold count (output frames it occupies):

| Role | Holds | What it is |
|---|---|---|
| `transition` | ≈2–3 | a node advances / a token rides, caption unchanged — flick by |
| `label` | ≈7 | a short word/marker appears |
| `caption` | ≈14 | a one-line caption to read |
| `long` | ≈21 | a longer caption / a small relationship |
| `dense` | ≈28 | an info-dense "Ah-HA!" beat (a new concept, a spine flip) |
| `poster` | ≈44–52 | the settled final frame — the long dwell before the loop |

The generator writes these as a `TIMING.tsv` (`frame ⇥ role ⇥ holds`, one row per distinct state, in emission
order). `reslow.sh` reads the **per-frame holds** and applies the **breathe within each hold window** (PULSE
index = position-within-hold modulo PULSE length). **Absent a `TIMING.tsv`** (not given, missing, or its row
count ≠ the coalesced frame count) `reslow.sh` falls back to a **uniform hold** (`HOLDLEN`× every frame plus a
`FINAL_HOLD` dwell on the last) — the same linger, just without the organic meter.

**The "Ah-HA!" floor (mandatory).** Any frame that **introduces a new concept**, **teaches a relationship**, or
**reveals the sequence's meaning** gets **≥24 holds** — enough time to travel the eye to the element, read the
caption, and *connect the two* before the animation advances. This is a floor, not a target: the `dense` tier
(≈28) clears it; a `transition` deliberately does not (it teaches nothing new). If a beat teaches, it lingers.

**SETTLE the key label before you fade it.** A typed, dissolved, or otherwise animated meaning-bearing label
must **come to rest at full opacity for a held beat** — at least its own caption/dense dwell tier — *before*
it fades out or the loop restarts. The reveal may animate; the **message must hold legibly**. Never present
the sentence the figure exists to say only mid-typewriter or mid-dissolve, where it reads as garbled — the
transition is the approach, the settled poster beat is the point. Every key label gets a full-opacity rest
stop.

**FADES, not hard cuts.** Transitions **cross-dissolve**, they do not jump-cut. The masthead does this with
`magick -morph` between keyframes (a clean cross-dissolve that rounds off seams). **Motion is MOTIVATED** — a
build-up reveals structure, a loop breathes, a token rides a path that *means* something — **never gratuitous**.

**Always ship a reduced-motion POSTER frame** beside the animation (the most-complete / settled frame as a
static PNG). It honours `prefers-reduced-motion`, gives the figure a legible still for reviewers and print, and
is the same frame whose `poster`-tier dwell ends the loop.

> **Forward note (Phase 3).** This linger directive is *frame-level* — "how long does this frame hold?". Its next
> development is the **element-level animation vocabulary**: named primitives with element-specific motion verbs
> (`node:breathe`, `token:ride`, `gate:latch`, `sweep:rotate-surface`, `arc:glow-on`, `stamp:resolve`) — "what
> kind of thing is this, and how does a thing of this kind move?". That lands in Phase 3's `motion-language.md`,
> which extends this canon from frame timing to element motion.

## Recipe 5 — frame-strip montage (so a reviewer can SEE motion in one Read)

A still reviewer can't watch a GIF. Sample key frames into one labelled strip it can Read — this is the
input the [image-aesthetic-reviewer](../skills/design-reviewer/agents/image-aesthetic-reviewer.md) scores
for the Medium-richness/motion criteria:
```bash
magick montage frames/f000.png frames/f002.png frames/f004.png frames/f006.png frames/f008.png frames/f010.png \
  -tile 1x6 -geometry 640x150+6+6 -background "#0b0b12" -title "build-up: frames 0,2,4,6,8,10" strip.png
```

## Format & size — what GitHub renders, and the budget

| Format | Inline in README `![]()`? | Alpha | Use for |
|---|---|---|---|
| **GIF** | ✅ animates inline | 1-bit | short looping/reveal diagrams, broad compatibility |
| **APNG** | ✅ animates inline (modern browsers) | ✅ full | animation needing soft alpha on a transparent ground |
| **MP4/WebM** | ⚠️ only via `<video>` (not `![]()`) | ✗ | longer/richer motion on doc sites; offer as the high-quality alt |
| **SVG** | ✅ static | ✅ | crisp vector, the blend's overlay layer |
| **JPG/PNG** | ✅ static | PNG ✅ | the blended masthead / hero |

**Size budget:** tracked animated assets **≤ 2 MB** (heroes/mastheads). Keep loops short, sample frames,
`gifsicle --lossy`. **Track** the final optimised asset; **gitignore** intermediate `frames/`. Reference
build sizes (a 11-frame vector pipeline @ 1280×300): GIF 27 KB · APNG 35 KB · MP4 19 KB — vector animations
are tiny; rich raster animation is where the budget bites.
