# Visual Quality Overhaul — Reviewers That See Pixels, Diagrams That Linger, Heroes That Brand

> Working plan, persisted so it survives a restart. Companion copy lives at
> `~/.claude/plans/the-reviewer-is-too-proud-pebble.md`.

## OUTCOME (2026-06-11, branch `visual-quality-overhaul`, PR #30)

- **A — Reviewers SEE pixels: SHIPPED.** RENDER-FIRST protocol + layout-defect checklist + AI-slop/photoreal
  taste caps in both reviewers; photoreal trap in the canon; `layout-check.sh` pre-flight (passes all 10 diagram
  generators, 0 violations); `gate-reviewer-calibration.md` authored and **armed (status OPEN — first calibration
  run pending)**.
- **B — Organic meter & linger: SHIPPED.** `TIMING.tsv` per generator (each distinct state emitted once, holds
  by role, teaching beats ≥24 "Ah-HA" floor); `reslow.sh` reads it; `build-figure.sh` orchestrator. The
  maintainer **kept** these timings.
- **C — Composite depth: REVERTED by maintainer call.** The vignette/backdrop read BAD. Frames are flat SVG
  ("how it was"): `composite-depth.sh` deleted, calls removed from `build-figure.sh` + masthead, `dg` glow
  restored to 0.05, amber focal radial dropped. Real layout fixes found during the depth pass were **kept**
  (market-scanner off-canvas DISCOVER + corner clipping; i2p caption-band height 360→408).
- **D — Stylized art direction: SHIPPED.** `comfyui-model-guide` stylized/bas-relief class now PRIMARY for
  heroes/banners (photoreal demoted); `prompt-craft` banner-atmosphere-band recipes per style.
- **E — Banner heroes: BUILT, WIRING HELD.** `build-plugin-banners.sh` + 9 stylized banners generated from the
  rig (all ≤389KB, none photoreal) exist as files; **README wiring + ledger update held at the maintainer's
  request** pending a banner-direction decision.
- **Verification:** layout gate PASS · all 11 GIFs ≤584KB (budget 2MB) · `verify-prereqs.sh` PASS (incl. links).

## Context

The maintainer skimmed the repo and spotted, **at a glance**, defects the adversarial reviewers had
passed: text over lines, text past borders, crowded padding, overlap. Root cause: the reviewers are
**text-only** — they read SPECs and generator bash, never the rendered pixels. Separately:

- **Frame-linger is mechanical.** `reslow.sh` applies a uniform 4× hold to every frame, so a 2-word
  transition and an 80-char teaching caption get the same ~0.3s. The reader gets no time to travel to
  the new element, read it, and *get it* ("Ah-HA!"). METER and LINGER are absent.
- **The depth backgrounds never landed visibly.** The `c71692f` glow is `stop-opacity="0.05"` — invisible.
  The maintainer wants a genuine **composite depth** effect: a dim/dark blurred backing under the diagram
  so shadows gain weight and elements *pop*.
- **The ComfyUI heroes are AI-slop.** Photorealism ("look, a lighthouse!") reads as shoddy. The
  maintainer's taste is **stylized**: line-art, sketch, cartoon, sculptural/bas-relief, painterly.
- **The heroes are the wrong artifact.** They're big near-square pictures (1280×876). Heroes should be
  **wide-short branding BANNERS** (~1920×400) that capture the *spirit* of each plugin — marketing, not
  decoration.
- **The reviewers' taste itself is too low.** They must be **adversarially reviewed and calibrated** so
  they reliably demote entry-level/AI-slop and catch layout bugs *before* output reaches the user.

**Intended outcome:** every diagram is legible and layout-clean (machine-verified), lingers with organic
meter, and has real composite depth; every plugin opens with a stylized, meaningful branding banner; and
the reviewers provably catch what the maintainer caught by eye.

**Resolved with the maintainer:**
- Banners = **crisp SVG branding (wordmark + spirit-motif + tagline) composited over a stylized ComfyUI
  atmosphere band** (line-art/sculptural/painterly — never photoreal); degrades to pure-vector if the rig
  is offline. · Banners are **static**. · **All 9 plugins** get one.

---

## Step 0 — Branch hygiene (preserve the 3 polish commits, start clean)

PR #29 (the whole image-craft program) is already merged to `main`. The local branch
`research/image-craft-taste` carries **3 commits ahead of `origin/main`** that must be preserved:
`c71692f` (depth-glow + timing + padding), `021eb6e` (SVG escaping fix), `4b72e67` (mission-control fix).

```bash
git fetch origin
git rebase origin/main                       # replay the 3 unmerged commits on post-#29 main
git branch -m visual-quality-overhaul        # rename current branch (captures the 3 commits)
git push -u origin visual-quality-overhaul   # push as a NEW branch
gh pr create --base main --title "Visual quality overhaul" --body "…"   # one PR that follows this branch
```

All new work below lands on `visual-quality-overhaul` (one branch, one PR, tidy graph). The stale
`origin/research/image-craft-taste` can be deleted after the PR is open. Untracked `.claude/wf-*.js`
helper scripts are left out of the PR (add to `.gitignore` or leave untracked).

---

## Workstream A — Reviewers must SEE the pixels (the core fix)

### A1. RENDER-FIRST protocol (mandatory, before any verdict)
Rewrite the procedure section of both reviewers:
- `plugins/pressroom/skills/design-reviewer/agents/image-aesthetic-reviewer.md`
- `plugins/atelier/agents/ui-design-reviewer.md`

New first step, **non-skippable**:
1. Render representative frames to PNG (`rsvg-convert`); for animated figures sample first / 25% / 50% /
   75% / last and build a 1×5 frame-strip via `magick montage` (reuse `raster-toolchain.md` Recipe 5,
   bg `#0b0b12`).
2. **Read (vision) the rendered pixels** — *before* reading any SPEC or generator code.
3. Run the **layout-defect checklist** (any trigger → automatic `NEEDS_REVISION`, cite the frame):
   - text clipped/cut at the SVG edge, or crossing a border/box it belongs inside;
   - text overlapping a line, arc, node, or other text;
   - any bordered element with < 10px internal padding (crowded);
   - caption illegible at GitHub's inline width (~640px) — check the downscaled strip.
4. Only then read the script for timing/spec compliance.

### A2. Programmatic layout pre-flight — `layout-check.sh` (new)
`docs/internal/image-craft-study/toolchain/src/layout-check.sh <generator.sh>`:
- emit one sample frame set, parse every `<text>` (x, `text-anchor`, `font-size`, content);
- estimate width ≈ `chars × font-size × 0.55`; compute left/right extent from the anchor;
- **fail (non-zero exit)** if any text extent crosses the SVG bounds or the element it sits in;
- print the first violation (`file:element: "text…" extends to x=NNN > bound=MMM`).

This becomes the **first step of every rebuild** — the machine catches horizontal overflow before a GIF
is ever assembled. (Overlap/crowding that maths can't see is caught by A1's pixel review.)

### A3. Adversarial reviewer calibration gate (new)
`docs/internal/image-craft-study/gates/gate-reviewer-calibration.md` — the "review the reviewers" proof:
- **Grade-ranking test:** feed the reviewer one figure per grade (broken / competent-but-generated /
  strong / award-tier). PASS only if it ranks all four correctly.
- **Planted-defect test:** feed a clean-but-flat figure AND a figure with a deliberate text-past-border
  overflow. PASS only if it (a) demotes the flat one on Composition/Richness *and names the lift*, and
  (b) flags the overflow as a layout defect → `NEEDS_REVISION`.
- Persist the verdict; if the reviewer ever passes entry-level/AI-slop or misses the planted overflow,
  calibration **fails** and the reviewer must be re-tuned before the next production cycle.

### A4. Taste caps written into both reviewers
- **AI-slop / entry-level cap (the Dunning-Kruger cap):** "Would a professional designer call this
  'AI-made' or 'student-portfolio'? If yes → Composition & Art-direction ≤ 3 regardless of other
  dimensions." Technically-correct ≠ professionally-excellent.
- **Photorealism trap:** clean photoreal with correct anatomy can still score ≤ 3 on Composition if it
  lacks a distinctive graphic voice; for docs, stylized/illustrated/sculptural work that commits to a
  clear visual language outscores competent photorealism. (Add to `image-aesthetic-canon.md`.)

---

## Workstream B — Organic meter & linger (variable timing)

### B1. `TIMING.tsv` per generator
Each generator emits, alongside its SVG frames, a `TIMING.tsv` mapping `frame → hold-count`, tagged by
informational significance — **not** uniform:

| Frame role | Hold | ≈ @13fps | When |
|---|---|---|---|
| Pure transition (no new text) | 2–3 | 0.15–0.23s | a node moves, a sweep advances |
| Short label ≤20 chars | 6–8 | 0.46–0.62s | "READY", "PASS" |
| Medium caption 20–40 chars | 12–16 | 0.9–1.2s | a phase label |
| Long sentence 40–60 chars | 18–24 | 1.4–1.9s | a teaching caption |
| Very long / multi-element 60–80 | 26–34 | 2.0–2.6s | the dense info beat |
| Poster / settled final | 44–52 | 3.4–4.0s | loop reset |

**"Ah-HA!" rule (mandatory):** any frame that introduces a new concept, teaches a relationship, or
reveals the meaning of the sequence gets **≥ 24 holds** — enough to travel to the element, read the
caption, and connect the two before advancing.

### B2. `reslow.sh` reads `TIMING.tsv` (backwards-compatible)
`docs/internal/image-craft-study/toolchain/src/reslow.sh`: when a `TIMING.tsv` is present, use its per-frame hold
counts (still applying the gentle PULSE breathe *within* each hold window); when absent, fall back to the
current uniform 4× behaviour. Masthead (self-contained) keeps using its `HOLDS[]` array — just raise the
info beats: phase-arrive 2→3, FEEDBACK 14→18, RETURN 12→16, POSTER 26→36.

### B3. Annotate holds in all 11 generators
Tag every frame call by role (transition / inform / poster) and set its hold per B1. The diagrams already
identified as under-dwelling (foundry-conveyor TESTS caption, atelier gate message, lifecycle arc) get
their info beats raised to the ≥24 "Ah-HA!" floor.

---

## Workstream C — Composite depth (make elements POP)

**Technique (corrected):** frames have an *opaque* `#1e1e2e` ground, so compositing them *over* a backdrop
is a no-op. Instead, per frame: **cut the bright elements off the ground, lay them back as a crisp top
layer over a dim, heavily-blurred halo of themselves on a slightly-darkened plate**, then a vignette for
shadow weight. Bright teal/amber/text elements then sit sharp over their own soft glow on a darker field —
real depth, weighted shadows, "lightbox" pop.

### C1. `composite-depth.sh` (new)
`docs/internal/image-craft-study/toolchain/src/composite-depth.sh <frames_dir> [ground]` — per PNG frame:
1. cut elements: `magick frame -fuzz 10% -transparent <ground>` → elements on transparency;
2. halo: blur the cut `0x18`, dim+slightly-saturate (`-modulate 60,115,100`);
3. plate: darken the original ground a touch (`-fill <ground> -colorize 30%`);
4. compose: plate → (screen the halo) → (crisp cut over) → optional `-vignette` for edge shadow.
Exact magick flags tuned at build time; output overwrites each frame in place. `magick`-guarded with a
clean skip if absent (graceful — diagrams still build, just flat).

### C2. Pipeline insertion
Run `composite-depth.sh` on the rasterised PNG frame dir **after `rsvg-convert`, before the first
`gifski`** (so `reslow`'s coalesce+modulate preserves the look and no double-application occurs). For the
self-contained masthead, insert after the morph frames are assembled in `$FR`, before its `gifski`.

### C3. Keep the SVG glow as a cheap complement
Bump the existing `radialGradient id="dg"` stop from `0.05`→`0.13` and add a faint amber focal radial in
each generator's `<defs>` — a subtle in-vector base under the stronger raster depth from C1.

### C4. Size guard
Budget is **per-figure ≤2MB**; today's largest GIF is 464KB, so there's headroom. After compositing,
re-check each GIF; if any approaches budget, raise `gifsicle --lossy` and/or trim colours.

---

## Workstream D — Stylized art direction (kill photoreal)

### D1. `comfyui-model-guide.md` — stylized is now PRIMARY for heroes/banners
Add a **Stylized / Illustrated / Sculptural** class as the default for doc heroes & banner bands, above
photoreal (demoted to tertiary). Use real rig assets from `maintainer-recipes.md`:

| Style | Checkpoints | LoRA | Use |
|---|---|---|---|
| **Bas-relief / sculptural** | `oasisSDXL_v10`, `reproductionSDXL_2v12` | `BAS-RELIEF`@0.8 + `xl_more_art-full_v1`@0.4 | maintainer signature; timeless |
| **Line-art / ink** | `bluePencilXL_v050`, `nijianimesdxl_v10` | lineart LoRA, CFG 3.5 | precise, reads on both grounds |
| **Whimsical 3D / toy** | `LahCuteCartoonSDXL_alpha`, `nigi3d_v20` | `blindbox_v1_mix`@0.4 | warm, approachable |
| **Concept / painterly** | `dynavisionXLAllInOneStylized…`, `zavychromaxl_v12` | `CraigMullins`@0.5 + `xl_more_art-full_v1`@0.5 | rich texture, not photoreal |

**Routing rule for doc heroes / banners:** prefer Stylized/Bas-relief → acceptable Concept/painterly →
**avoid photoreal** (slop, no character) → **never** baked text (gibberish). Low CFG (3.5–4.5) per
maintainer recipes; `dpmpp_sde_gpu`/`dpmpp_3m_sde_gpu` + karras.

### D2. `prompt-craft.md` — add stylized banner-band recipes
Add a "banner atmosphere band" recipe block per style (negative prompts ban text/people/photoreal sheen;
positive anchors the stylized medium + dark-key + wide negative space for the wordmark to sit on).

---

## Workstream E — Banner heroes (all 9, vector-over-stylized-band, static, ~1920×400)

### E1. `build-plugin-banners.sh` (new) — the banner builder
`docs/internal/image-craft-study/toolchain/src/build-plugin-banners.sh` — reuses `docs/images/readme-banner.svg`
structure (card bg, wordmark tspans, tagline) parametrised per plugin. For each of the 9 plugins:
1. **Stylized atmosphere band (raster):** call `handler-comfyui` with the D1 stylized routing to render a
   wide band capturing the plugin's spirit; crop to ~1920×400, **dim + blur** it (it's atmosphere, not the
   subject). *Graceful degrade:* if the rig is unreachable, synthesise an SVG gradient/texture band so the
   banner still looks intentional (never blocks).
2. **Vector branding overlay (SVG):** plugin wordmark + a spirit-motif + tagline + a legibility scrim,
   transparent ground, ~1920×400.
3. **Blend:** `raster-toolchain.md` Recipe 2 — `magick band.png overlay.png -compose over -composite` →
   ship PNG (quality-88 JPG if size demands).
4. Run `layout-check.sh` on the overlay SVG first (no text past edges).

### E2. Per-plugin spirit (wordmark + tagline + motif) — drawn from existing README taglines/alt-text
| Plugin | Tagline | Motif direction | Band style |
|---|---|---|---|
| i2p | "every plugin, one front door" | gateway arch / hub-spoke | bas-relief |
| concierge | "a warm light at the door" | lantern doorway | whimsical 3D |
| market-scanner | "sweep the field, kill weak early" | radar sweep | line-art |
| ideator | "scattered idea → build-ready package" | converging fragments | line-art |
| atelier | "screens become considered interfaces" | drafting table / blueprint | concept painterly |
| foundry | "test-first; value on one vertical slice" | conveyor / forge | bas-relief |
| sentinel | "certify before exposure" | gate / shield | line-art (mono ink) |
| pressroom | "illustrate → review → publish" | press / plates | concept painterly |
| mission-control | "watch, respond, iterate" | console ring / telemetry | concept painterly |

(Final taglines verified against each README before authoring; all dark-mode canon, legible on both grounds.)

### E3. Wire into READMEs
- Replace `diagrams/hero.jpg` at line 3 of the 5 plugins that have one with the new banner.
- Add the banner at the top of the 4 GIF-only plugins (ideator, foundry, pressroom, market-scanner),
  keeping their explainer GIF where it is.
- Update alt-text to the new, accurate, spirit-capturing description.
- Update `.pressroom/illustration-ledger.json` with each banner's style/score; delete the obsolete
  square-hero entries.

---

## Files (representative, not exhaustive)

**New**
- `docs/internal/image-craft-study/toolchain/src/layout-check.sh`
- `docs/internal/image-craft-study/toolchain/src/composite-depth.sh`
- `docs/internal/image-craft-study/toolchain/src/build-plugin-banners.sh`
- `docs/internal/image-craft-study/gates/gate-reviewer-calibration.md`

**Modify**
- `docs/internal/image-craft-study/toolchain/src/reslow.sh` (+ `TIMING.tsv` support)
- all 11 `build-*-frames.sh` (TIMING.tsv emit + hold re-tag + glow bump + composite-depth call)
- `plugins/pressroom/skills/design-reviewer/agents/image-aesthetic-reviewer.md`
- `plugins/atelier/agents/ui-design-reviewer.md`
- `plugins/pressroom/skills/design-reviewer/references/image-aesthetic-canon.md`
- `plugins/pressroom/knowledge/comfyui-model-guide.md`, `…/illustrator/references/prompt-craft.md`
- the 9 `plugins/*/README.md` (banner embeds + alt-text) · `.pressroom/illustration-ledger.json`

**Rebuild**
- all 11 GIFs (after timing + composite-depth) · 9 plugin banner PNGs

---

## Verification

1. **Layout gate:** `layout-check.sh` over every generator → zero violations before any rebuild.
2. **Pixel review:** Read each rendered frame-strip with vision — no text-over-line / past-border /
   crowding on any frame; banners legible at ~640px inline width.
3. **Linger audit:** for each info-dense beat, GIF frame-count × (1000/fps) ≥ its B1 threshold; the
   "Ah-HA!" beats clear ≥ 24 holds.
4. **Depth visible:** render a sample frame to PNG, pixel-sample centre vs. corner — measurable bloom on
   bright elements + darker edges; visually confirm "pop".
5. **Style gate:** run `image-aesthetic-reviewer` on an old photoreal hero vs. a new stylized banner —
   the banner must outscore on Composition & Art-direction.
6. **Reviewer calibration:** `gate-reviewer-calibration.md` PASS — correct grade ranking AND the planted
   overflow is caught as a layout defect.
7. **Graceful degrade:** with the rig unreachable, `build-plugin-banners.sh` still produces an
   intentional vector-band banner; `composite-depth.sh` skipped cleanly leaves a flat-but-valid GIF.
8. **Budget:** every GIF ≤2MB, every banner ≤ ~600KB.
9. **`scripts/verify-prereqs.sh` passes** (SOUL parity, internal links, frontmatter).
10. **GitHub render check** after push: banners + GIFs display inline on the rendered READMEs.
