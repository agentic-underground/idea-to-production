# Cached review — PRESSROOM handler-composite

**Target file:** `plugins/pressroom/agents/handler-composite.md`  
**Unit:** `handler-composite`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Fallback ladder names gifsicle as a GIF encoder — it cannot encode PNG frames; drifts from the cited canon

**Evidence:** Line 28-29: "Walk the **fallback ladder** (gifski→ffmpeg→gifsicle; magick→vips)." The canon this handler declares as its knowledge base (plugins/pressroom/knowledge/raster-toolchain.md, tools table lines 21-22) defines frames→GIF as `gifski` primary, `ffmpeg palettegen+paletteuse` fallback, and **no third encoder**; gifsicle appears only as the *optimiser* of an already-encoded GIF ("GIF optimise | gifsicle -O3 … | (skip — ship gifski output)"). gifsicle reads/writes GIF only — it cannot assemble the PNG frame-series this handler produces (Recipe 4: "frames f000.png..fNNN.png").

**Recommendation:** Correct the ladder to match the canon and tool reality: encoding ladder gifski→ffmpeg(palettegen/paletteuse)→ship-static-poster; gifsicle is a post-encode optimisation step only. An agent following the current text in a gifski+ffmpeg-absent environment will attempt an impossible gifsicle invocation instead of degrading to the static poster as the prime directive intends.

### 2. [HIGH] Security directive contradicts the SPEC contract: blend layer paths are caller-supplied, not "your own controlled paths", and untrusted-SVG risk is unaddressed

**Evidence:** Lines 40-41: "Validate numeric params (fps, quality, crop offsets) as integers; filenames are your own controlled paths." But the SPEC schema this handler consumes (spec-schema.md lines 28, 50) defines `layers: [{kind: raster, src: <path>}, {kind: vector, src: <svg>}]` — src paths arrive **from the SPEC** and are fed directly to magick/rsvg-convert (Draft, lines 51-53). No path validation exists: no repo-confinement, no rejection of `..`/absolute paths, no existence/type check. A vector layer src is rendered by librsvg, which processes xi:include and external file references — path-traversal file reads are a documented attack class (CVE-2023-38633, librsvg URL-parser disagreement; see librsvg security guide).

**Recommendation:** Add an input-hardening directive: (1) every `layers[].src` must resolve, after realpath, inside the project tree (reject absolute paths outside it and any `..` component); (2) render only SVGs the handler authored itself or that already live in-repo — never a fetched or third-party SVG; (3) verify the raster src is actually an image (`magick identify`/`vips header`) before compositing; (4) note the librsvg ≥2.48 floor for any externally-sourced SVG.

### 3. [MEDIUM] SPEC contract allows output_format webp for composite motion; the handler (and its canon) cannot produce it

**Evidence:** spec-schema.md line 34/53: "`gif`/`apng`/`mp4`/`webp` for a `handler-composite` animation". The handler's frontmatter (line 6) claims "output_format gif|apng|mp4|png" and the body (line 21) handles only "`output_format: gif|apng|mp4`"; raster-toolchain.md has no WebP recipe at all. A schema-valid SPEC requesting webp has no defined behaviour. (Frontmatter also omits `jpg`, which the body ships for blends at lines 53 and 58.)

**Recommendation:** Either add an animated-WebP recipe (see capability gap 4 — ffmpeg `libwebp_anim` is in the already-required toolchain) and list webp in frontmatter/body, or strike webp from spec-schema.md's allowed formats. Align the frontmatter format list with the body (add jpg).

### 4. [MEDIUM] Hand-back omits the rendered-from sources, violating the SPEC return contract item 2

**Evidence:** Lines 69-71 (Hand-back): "Return the asset path(s) incl. the poster, the recipe/fallback actually used, the final byte size, and a one-line self-critique". spec-schema.md "What the handler returns" item 2 (lines 60-63) mandates returning "the source it rendered from … so the reviewer's fixes are applied to *source*, not pixels". The composite's sources — the overlay SVG of a blend, the parametrised frame-series SVGs of an animation — are never required in the hand-back, so the A/B reviewer can only critique pixels and the loop's "fully reproducible" promise breaks for this handler.

**Recommendation:** Add to Hand-back: "and the source(s) you rendered from — the overlay SVG (blend) or the frame-series SVG template + parameters (animation) — so reviewer fixes land on source, not pixels." Persist the frame-series SVG template even though intermediate rasterised frames/ are gitignored.

### 5. [MEDIUM] Mandated self-review (frame-strip via magick montage) has no path in the vips-only environment the fallback ladder permits

**Evidence:** Lines 60-62: "**Build a frame-strip** (Recipe 5: `magick montage` of sampled frames) and **Read it**". The prime directive's own ladder (line 29, "magick→vips") allows compositing to proceed when magick is absent and only vips exists, but Recipe 5 has no vips fallback (raster-toolchain.md Recipe 5 is montage-only) and the self-review section defines no degraded alternative — the mandatory adversarial pass silently becomes impossible.

**Recommendation:** Define the degraded review path: when montage is unavailable, `vips arrayjoin "f000.png f004.png f008.png" strip.png --across 1` (or Read 3 sampled individual frames: first, middle, last) and declare the weaker review in the hand-back, mirroring degradation-honesty.

### 6. [MEDIUM] No malformed-SPEC decline protocol — only absent-tool degradation is specified

**Evidence:** Lines 28-31 cover exactly one failure family: "If **no** motion tooling exists and the SPEC asked for motion, ship the **static poster frame**…". Nothing defines behaviour for a malformed or contradictory SPEC: motion requested with `frames` absent/0, a blend with `layers` missing the raster+vector pair, a layer src that does not exist, or `output_format: gif` with `layers` set and `motion: null`. The sibling handler-comfyui.md (line 74) shows the house pattern: "**decline** and tell the orchestrator" — handler-composite has no equivalent.

**Recommendation:** Add a SPEC-validation gate before Draft: enumerate the required fields per mode (blend needs ≥1 raster + ≥1 vector layer that resolve on disk; motion needs kind/frames≥2/fps); on failure, decline cleanly with the named defect so the illustrator fixes the SPEC, exactly like handler-comfyui's offline decline.

### 7. [MEDIUM] Integer validation without range bounds lets crash-valid params through

**Evidence:** Lines 40-41: "Validate numeric params (fps, quality, crop offsets) as integers". The canon's `int()` helper (raster-toolchain.md lines 38-39) accepts fps=0 (ffmpeg `-framerate 0` fails), fps=1000 (gifski rejects >100), quality=0/999, and zero/oversized crop dims. The canon itself defers the fix: "Phase-5 ships these as a vetted recipe library with EARS bounds" (line 42) — meaning today's handler doctrine has no bounds at all.

**Recommendation:** Pull the bounds forward into this handler now: 1 ≤ fps ≤ 50, 1 ≤ quality ≤ 100, 2 ≤ frames ≤ 120, 16 ≤ W,H ≤ 4096 (and even, for the MP4 path), crop offsets ≥ 0 and inside the source raster's identify'd dimensions. Reject out-of-range with the same decline-with-named-defect protocol.

### 8. [MEDIUM] Missing SUBJECT_MATTER_UNDERSTANDING contract carried by every other VALUE_HANDLER class

**Evidence:** The marketplace contract requires every agent to carry the KAIZEN covenant and the SUBJECT_MATTER_UNDERSTANDING contract. FOUNDRY value handlers do — e.g. plugins/foundry/agents/handler-ansible.md line 10: "Carries the KAIZEN self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." handler-composite.md carries only the KAIZEN covenant (lines 73-77); `grep -r SUBJECT_MATTER plugins/pressroom/agents/` returns nothing — the omission is pressroom-wide, but this file is still in breach for itself.

**Recommendation:** Add the SUBJECT_MATTER_UNDERSTANDING line to the description/covenant section (the handler's subject matter: the doc being illustrated and the figure's intent/message — it must reach knowledge-parity with the SPEC's intent before drafting). Flag the same gap on the five sibling pressroom handlers via their self-improve loop.

### 9. [LOW] Budget check has no remediation ladder when the asset exceeds 2 MB

**Evidence:** Line 65: "**Budget & format:** `ls -la` the asset; under 2 MB?" — detection only. The handler is forbidden to invent commands ("never assemble an arbitrary shell command", line 24), yet over-budget recovery is left to improvisation; the canon's levers (gifsicle --lossy, fewer/shorter frames, smaller geometry, format switch) are not ordered into a doctrine.

**Recommendation:** Add an explicit shrink ladder: (1) gifsicle -O3 --lossy=80→120; (2) drop fps / sample fewer frames; (3) reduce pixel geometry to the width budget; (4) switch format (GIF→MP4-as-alt with GIF teaser, or GIF→animated WebP); re-measure after each rung, stop at the first pass.

### 10. [LOW] Blend self-review never runs the canon's dual-ground legibility proof

**Evidence:** Lines 63-64 review the blend by Reading the composite once, on its shipped ground. raster-toolchain.md Recipe 1 (lines 44-50) exists precisely so "the design-reviewer can confirm it reads on any host (the dark-mode canon contract)" — but handler-composite's self-review section never invokes it, and blends with transparent-PNG output can land on either GitHub theme.

**Recommendation:** For any blend shipped with alpha (PNG), add Recipe 1 to the self-review: rasterise onto #000 and #fff and Read both; for opaque JPG blends, note the ground is baked and the check is N/A.

## Capability-uplift proposals

### 1. Linear-light (gamma-correct) compositing and resizing doctrine

**Proposal:** Add to Prime directives: "**Composite in linear light.** sRGB-encoded pixel math darkens antialiased edges — the dark fringe where crisp vector strokes meet a raster ground. Composite and resize via linear RGB and re-encode at the end: `magick base.png overlay.png -colorspace RGB -compose over -composite -colorspace sRGB blend.png`; same for downscales (`-colorspace RGB -resize … -colorspace sRGB`). Gamma-encode only as the final step — never mid-pipeline. Self-review check: zoom the vector-edge boundary in the composite; a dark halo around antialiased type means the blend ran in sRGB."

**Rationale:** ImageMagick assumes linear maths only in RGB colorspace and its own color-management docs say most processing algorithms assume linear; Snibgo's colour-fringe study documents exactly this edge artefact. The handler's whole identity is 'vector layer stays razor-sharp' — fringed antialiasing is its most likely systematic quality defect, currently invisible to its doctrine. Sources: https://imagemagick.org/script/color-management.php, https://im.snibgo.com/colfring.htm, https://learnopengl.com/Advanced-Lighting/Gamma-Correction

### 2. Palette-craft doctrine for the ffmpeg GIF path (and gifsicle tuning)

**Proposal:** Extend the Draft/animation step: "When encoding GIF via ffmpeg, palette quality is the whole game: `palettegen=max_colors=128:stats_mode=diff` when the build-up shares a static background (palette weight goes to what *moves*), `stats_mode=full` for scene-changing loops; pair with `paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle` (bayer_scale 1-2 for flat vector fills to avoid crosshatch noise, 4-5 for gradient-rich rasters); always `flags=lanczos` for any scale step. For vector frame-series, fewer colours (max_colors=64-128) often *improves* flat-fill crispness while halving size."

**Rationale:** The canon's current fallback (raster-toolchain.md lines 89-90) uses bare `palettegen=stats_mode=diff` + `paletteuse=dither=bayer` with no bayer_scale, diff_mode, max_colors, or scaler guidance — the documented high-quality-GIF technique is substantially richer and directly reduces both artefacts and bytes. Sources: https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html, https://www.mux.com/articles/create-gifs-from-video-clips-with-ffmpeg

### 3. Easing and choreography doctrine for build-up motion (variable frame timing, stagger, terminal hold)

**Proposal:** Add a 'Motion choreography' directive: "A build-up is choreography, not a metronome. (1) **Stagger** element entrances — one structural element per beat, ordered to lead the eye along the diagram's reading direction; never pop everything at once. (2) **Ease-out arrivals** — when an element slides/grows over multiple frames, space its positions decelerating (e.g. 0%, 55%, 85%, 100% of travel), not linearly. (3) **Hold the completed state** 2-3× longer than any step so the takeaway lands, and pause before a loop restarts. gifski is fixed-fps — for variable timing encode uniform frames then retime per-frame with `gifsicle -d` (e.g. `gifsicle anim.gif -d12 "#0-9" -d100 "#10" -o anim.gif`, delays in 1/100 s), or duplicate the final frame N times in the series. Step beats ≈ 250-400 ms; micro-movements ≈ 100-200 ms."

**Rationale:** Material Design's duration/easing guidance (100-200 ms micro-interactions, 300-500 ms transitions, decelerate-on-entry) and design-system literature on stagger ('shift people's gaze in a specified direction') are the established craft for explanatory motion; the handler currently says only 'motion is motivated' with zero timing doctrine, and its fixed-fps recipes structurally forbid the terminal hold every explanatory GIF needs. Sources: https://m3.material.io/styles/motion/easing-and-duration, https://www.designsystems.com/5-steps-for-including-motion-design-in-your-system/, https://fluent2.microsoft.design/motion

### 4. Animated-WebP output (closes the spec-schema webp hole) plus a sharpened format decision table

**Proposal:** Add to the animation recipe set and frontmatter: "**WebP:** `ffmpeg -y -framerate $FPS -i frames/f%03d.png -c:v libwebp_anim -lossless 0 -q:v 80 -loop 0 anim.webp` (lossless 1 for flat vector fills). Decision: GIF = universal inline compatibility, 1-bit alpha, biggest bytes; **animated WebP renders inline on GitHub `![]()`, has full alpha, and is typically 60-80% smaller than the equivalent GIF** — prefer it when the host is GitHub/modern docs and the budget bites; APNG = full alpha, lossless, when fidelity on a transparent ground beats size; MP4 = `<video>`-only, the high-quality alt for long/rich motion."

**Rationale:** spec-schema.md already promises webp for this handler (finding 3) and the toolchain already requires ffmpeg, so the capability is one recipe away. Real-world comparisons show GIF 2.26 MB / APNG 2.46 MB vs WebP 740 KB for the same animation — the single biggest lever on the handler's own ≤2 MB budget. Sources: https://akshayranganath.github.io/Comparing_Animated_Image_Formats/, https://webp-to-png.tools/blog/animated-images-in-2025-webp-vs-apng-vs-gif-real-world-use-cases/

### 5. Input-hardening: layer-path confinement, untrusted-SVG policy, EARS-bounded numeric ranges

**Proposal:** Extend the Security directive: "(1) **Confine layer paths.** Every `layers[].src` must realpath-resolve inside the project tree; reject absolute paths outside it and any `..` component; `magick identify`/`vips header` the raster src before compositing. (2) **Render only SVGs you authored or that live in-repo.** librsvg processes xi:include and external file references — rendering a fetched/third-party SVG is a file-read primitive (CVE-2023-38633 class); require librsvg ≥ 2.48 for anything not self-authored. (3) **Bound every numeric param**, not just type-check: 1≤fps≤50 · 1≤quality≤100 · 2≤frames≤120 · 16≤W,H≤4096 (even, for yuv420p) · crop offsets ≥0 and inside the source's identified dimensions. Out-of-range ⇒ decline with the named defect."

**Rationale:** The librsvg security guide documents external-reference processing and path-traversal attacks on SVG→PNG rendering (Canva's CVE-2023-38633 writeup shows /etc/passwd exfiltration via rsvg-convert), and the handler today feeds SPEC-supplied paths to exactly that tool with type-only validation (findings 2 and 7). Sources: https://gnome.pages.gitlab.gnome.org/librsvg/devel-docs/security.html, https://www.canva.dev/blog/engineering/when-url-parsers-disagree-cve-2023-38633/

### 6. Reduced-motion-aware embedding doctrine: finite loops, poster-first embeds, tiered budgets

**Proposal:** Add an 'Embed & accessibility' directive: "Markdown `![]()` cannot honour `prefers-reduced-motion`, so the handler compensates at the asset level: (1) ship **finite loops** for decorative/breathing motion — `gifsicle --loopcount=3 anim.gif` (ffmpeg `-loop 3` for WebP) — so the page comes to rest; infinite loops are reserved for figures whose meaning *is* the cycle; (2) hand back a ready **embed snippet pair**: the `![alt](anim.gif)` line *and* a poster-first `<picture>`/`<details>` alternative plus the `<video poster=… muted playsinline loop>` form for MP4 hosts; (3) budget tiers: ≤2 MB hard ceiling, **target ≤1 MB for an inline diagram GIF and ≤300 KB for a vector build-up** (reference vector build: 27 KB — being near 2 MB on vector work means the choreography, not the budget, is wrong)."

**Rationale:** Accessibility guidance is unanimous that animations must respect prefers-reduced-motion (vestibular disorders), but GitHub markdown offers no media-query hook — finite loop counts and poster-first embeds are the available mitigations; GitHub README best-practice guides also push well below the platform's soft limits for load performance. The handler currently treats 'a poster exists next to the file' as the whole answer. Sources: https://gist.github.com/uxderrick/07b81ca63932865ef1a7dc94fbe07838, https://www.w3tutorials.net/blog/how-to-display-an-animated-gif-in-a-github-readme-file/, https://m3.material.io/styles/motion/overview/how-it-works
