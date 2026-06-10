# Gate 08 — local raster/motion capability (Phase 8)

**Date:** 2026-06-10 · **Branch:** `research/image-craft-taste` · **Scope:** prove the worker can *finish,
blend, composite, and animate* locally (0-GPU), grounded in commands that actually ran.

## What shipped

- NEW `plugins/pressroom/knowledge/raster-toolchain.md` — finishing/blend/animation canon: tool ladder +
  **parameter-only** recipe library (dual-ground composite · SVG↔raster blend · post-ComfyUI finish ·
  frames→GIF/APNG/MP4 · frame-strip montage · format/budget rules).
- NEW `plugins/pressroom/agents/handler-composite.md` — value-handler for blends + animated figures;
  probe→degrade; emits a static poster beside any animation.
- `requirements.tsv` — declared `ffmpeg`, `vips`, `gifsicle`, `gifski` (optional, graceful); `check.sh`
  (canonical, unedited) picks them up. UPDATE `handler-comfyui.md` (optional finish stage), `illustrator/`
  SKILL + `spec-schema.md` (`handler-composite`, `output_format`/`motion`/`layers`, routing),
  `dark-mode-canon.md` (§5b raster/motion legibility).

## Evidence (regenerable; small finals tracked under `toolchain/proof/`)

| Artifact | Proof | Size |
|---|---|---|
| `proof/pipeline-buildup.gif` | animated lifecycle diagram (idea→production lights up stage-by-stage) | 27 KB |
| `out/pipeline.{apng,mp4}` | same frames as APNG (35 KB) + MP4 (19 KB) — all four formats from one frame-series | — |
| `proof/masthead-blend.jpg` | SVG↔raster blend — i2p hero atmosphere + crisp vector wordmark/scrim/frame | 120 KB |
| `proof/frame-strip.png` | the reviewer's-eye montage of frames 0/2/4/6/8/10 — motion reads in one Read | 289 KB |
| `src/build-pipeline-frames.sh`, `src/masthead-overlay.svg` | the reusable, parameter-only generators | — |

**Timings (worker, 0-GPU):** 11 SVG frames rasterised in 0.23 s; gifski assemble 0.13 s. Vector animation is
tiny; rich raster animation is where the ≤2 MB budget bites.

## Graceful degradation — tested, not assumed

- **GIF ladder:** `gifski` (27 KB) → `ffmpeg` palettegen/paletteuse (36 KB) → `gifsicle --colors 256 --lossy`
  (24 KB) — all produced a valid animated GIF.
- **Composite ladder:** `magick … -compose over` and `vips composite2 … over` both produced the 1280×440
  blend.
- **No motion tools:** handler-composite ships the static poster and declares the degradation.

## Security

Recipe library is **parameter-only**: numeric params validated as integers; in-image text lives in SVG
`<text>` nodes (rasterised), never on a command line; no `eval`, no caller-supplied filter strings. Mirrors
the comfyui allowlisted-template stance. (Sentinel lens to confirm at Gate 5.)

## Adversarial panel verdict — NEEDS_REVISION → resolved (amber → green)

An independent reviewer prompted to *refute* the capability ran the full ladder in a scratch dir and
**reproduced the gate's exact byte sizes** (GIF 27527, MP4 18912, APNG 34988). Judgments: capability
**genuine** (every recipe ran), degrades **mostly** gracefully, **no shell-injection surface in practice**
(no SPEC text reaches a shell; in-image text is an SVG `<text>` node), proof images **good, not entry-level**
(razor-sharp vector wordmark over a rich raster atmosphere; the build-up reads as motion). It raised 5
findings; 4 are fixed in this commit:

1. **Security claim was prose, not code** → added a shared `int()` validator to `raster-toolchain.md` and
   wired it into the numeric recipes. *Tested:* rejects `4; rm -rf /` (exit 2), accepts integers.
2. **MP4 odd-dimension hard-crash** → added `-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2"` to the MP4 recipe.
   *Tested:* 1281×301 → 1280×300, no crash.
3. **Recipe 5 frame-strip drifted from the proof** → canon now matches the proof (frames 0,2,4,6,8,10 / 1×6).
4. **check/SKILL.md optional list was stale** → added ffmpeg/vips/gifsicle/gifski.
5. **(pre-existing, deferred to Phase 5)** `handler-comfyui.md` links `../../../comfyui-mcp/…` escape the
   plugin root (dead on standalone install). Not introduced here; folded into the Phase-5 template work.

## STEER

Green to proceed. Carry into Phase 9/10: keep the `int()`-validate + even-guard discipline in the
allowlisted recipe library (Phase 5), and fix the `comfyui-mcp` plugin-root escape when those templates
move in. Animation proven tiny for vector; watch the ≤2 MB budget when raster heroes animate (Phase 10).
