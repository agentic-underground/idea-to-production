# Raster toolchain — local finish, blend, composite & animate (the post-render stage)

> The pressroom render pipeline is **SVG-first + one ComfyUI PNG**. This doc is the **local post-render
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
wordmark/tagline as `<text>`, and an optional thin frame. **Proven** end-to-end in
`doc/image-craft-study/toolchain/` (`out/masthead-blend.jpg`).

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
Proven in `doc/image-craft-study/toolchain/` (`src/build-pipeline-frames.sh` → `out/pipeline.{gif,apng,mp4}`).

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
