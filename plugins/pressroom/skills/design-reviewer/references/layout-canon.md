# The layout canon — the at-a-glance legibility floor

> The fourth design lens, beside [`typography-canon.md`](typography-canon.md) (the page),
> [`dataviz-canon.md`](dataviz-canon.md) (the chart), and [`image-aesthetic-canon.md`](image-aesthetic-canon.md)
> (the generative image). This one is not graded taste — it is a **pass/fail FLOOR**: the layout defects a
> human spots in half a second (text past a border, text on a line, crowded padding, a label cut off the
> bottom, a diagram so wide it renders as a smear inline). A finding is *"the value-flow caption renders at
> ~2.85px inline — below the 9px floor"*, not *"the text feels small"*. This canon is the **single source of
> truth** for the checklist; the `layout-reviewer` agent and both aesthetic reviewers (PRESSROOM's
> `image-aesthetic-reviewer`, ATELIER's `ui-design-reviewer`) cite it rather than restate it.

## 1. The mandate — a floor, gated before taste

Layout is **pass/fail**, and it is gated **BEFORE any taste dimension is scored**. A clean, on-prompt,
award-tier image whose caption is clipped at the canvas edge is **broken**, not "strong-with-a-nit": the
reader cannot read it. So the layout pass runs first, and **any** triggered item is an automatic
`NEEDS_REVISION` (or `BLOCK` on a hard clip), citing the **specific frame/route** — no taste score is even
computed until the floor is clean. These are the defects a maintainer keeps catching *by eye* that a
taste-focused reviewer waves through; this canon exists to make the eye's catch mechanical.

## 2. The render-first dependency

**Every item is judged on rendered pixels — never source.** The defects here are *invisible in the SVG/markup*
and appear only once rasterised: a `<text>` whose maths fit can still be eaten by a node fill drawn after it;
a caption legible at full-res is a smear at GitHub's inline width. So the artefact is always the **render**
(`rsvg-convert -b "#0b0b12" fig.svg -o fig.png`, the Playwright screenshot, or the `magick montage` frame-strip
for animation) — and, for the inline-legibility items, the **downscaled inline strip** (~640px) the reader
actually sees, not the full-res frame. A verdict reasoned from source is invalid. Source is opened *last*,
only to locate the cause of a defect the pixels already proved.

## 3. The cost-tier doctrine — vision on suspicion, never by default

Machine vision is the **expensive** action; spend it only when something cheap has already flagged a tile.
The order is fixed:

1. **`layout-check.sh` — SVG-math (free).** A deterministic awk pass over the generator/`.svg`: horizontal
   bounds, vertical bounds, the inline-legibility rule (§5), and the aspect advisory. Catches every class the
   geometry can see, at zero tokens. *See* [`layout-check.sh`](../../../../../doc/image-craft-study/toolchain/src/layout-check.sh).
2. **`raster-lint.sh` — cheap per-tile heuristics (free).** Token-free ImageMagick heuristics on the inline
   render, tiled into blocks: edge-clip-by-pixel, ink/edge crowding density, thin-stroke-through-text /
   occlusion. Emits the list of **SUSPECT tiles** + an exit code. *See* [`raster-lint.sh`](../../../../../doc/image-craft-study/toolchain/src/raster-lint.sh).
   These are *suspicion* heuristics — false positives are fine; the lint only decides **whether** to spend the eye.
3. **A vision Read — ONLY when a tile trips.** Clean lint → the reviewer **skips vision** (cost saved).
   Suspect tile → escalate: Read the full render / the suspect crops, run the 8-item checklist, and list
   **every** triggered item. One vision backstop pass on the poster/champion frame is still taken even on a
   clean lint, to bound missed defects — but the expensive action is never the *default*.

**Vision on suspicion, never by default.** A reviewer that opens vision on every tile has spent the budget the
two free tiers exist to protect.

## 4. The checklist — eight items

Each item names *what it is*, *why it hurts the reader*, and *how it is detected* (machine `layout-check.sh` /
raster-lint / vision). Items 1–3 are the original step-3 checklist; 4–8 extend it.

1. **Edge-clip** — text clipped at the canvas edge, or crossing a border/box it is meant to sit *inside*.
   *Why:* the reader loses a word, or the diagram looks broken/unproofed. *Detect:* **machine** (horizontal +
   vertical bounds); a glyph past the inner box is **raster-lint → vision**.
2. **Overlap** — text overlapping a line, arc, node, control, or other text. *Why:* the collision is
   unreadable and signals a layout the maker never looked at. *Detect:* **raster-lint** suspect tile →
   **vision** (the maths cannot see element-on-element collision).
3. **Crowding** — a bordered element with **< 10px internal padding**. *Why:* cramped text reads as
   unprofessional and is harder to scan. *Detect:* **raster-lint** ink/edge density in the tile → **vision**.
4. **Inline-illegibility** — a caption/label illegible at GitHub's ~640px inline width; check the
   **downscaled strip**, not the full-res frame. *Why:* the reader sees the inline render, not your 2246px
   canvas. *Detect:* **machine** — the inline-legibility rule (§5).
5. **Vertical clipping** — text whose `y` falls outside `[0, H]` (cut at top or bottom). *Why:* a label
   pushed off the bottom of the canvas simply isn't there for the reader. *Detect:* **machine** (vertical
   bounds). Exemplar it must catch: the market-scanner DISCOVER label pushed off the canvas bottom.
6. **Z-index / occlusion** — a foreground element hidden behind/under another (a label under a node fill):
   present in the source, invisible or half-eaten in the render. *Why:* the data is in the file but not on the
   reader's screen — the worst kind, because source review passes it. *Detect:* **raster-lint → vision**;
   **vision-only** for a flat PNG with no SVG to parse.
7. **General minimum text size** — *any* text rendering below the legible floor at its **own embed width**
   (generalises #4 beyond captions to every text element). *Why:* a 6px tick label is decorative, not
   informative. *Detect:* **machine** (the §5 rule applied per `<text>`).
8. **Aspect / inline-legibility** — a figure too wide for its text to survive the inline downscale. *Why:* a
   2.4:1+ diagram shrinks to fit the column and takes its text below the floor with it. *Detect:* **machine**
   (the aspect advisory, §6) feeding the §5 floor; soft on its own, hard when it drives a text element under
   the floor.

## 5. The inline-legibility rule

The formal heart of items 4, 7, 8. A text element's **rendered height at the reader's inline width** is:

```
min_rendered_text_height = font_size × INLINE_W / svg_width   ≥   FLOOR
```

`INLINE_W = 640` (GitHub's ~640px column). The floor is a **two-band** number, both `-v`-overridable on
`layout-check.sh`:

- **`FLOOR = 6` — the shipped machine default**, the *clear-illegibility* gate. The current corpus sits at
  6.5–8.5px inline (13–17px labels in ~1280px canvases), so a 9px hard gate would fail the whole corpus at
  once; 6px catches the egregiously-tiny without that mass false-positive.
- **`FLOOR = 9` — the comfortable target** (and VSCode's narrower render is stricter still). The corpus text is
  *below* this on purpose-pending: tightening the machine floor to 9 is gated on the line-art/text uplift (the
  motion-language + primitive work), after which the gate ratchets up. Until then 9 is the reviewer's eye-bar.

Worked examples:

- **value-flow** — a 10px label in a **2246px** canvas renders inline at `10 × 640 / 2246 ≈ 2.85px` → **FAIL**
  at *both* bands: the figure is too wide for its own text.
- **masthead** — the wordmark is huge, so `font_size × 640 / svg_width` stays **above** the floor → **PASS**.
  This is the *self-exemption*: the masthead is exempt because **the maths exempts it**, not by a special case.
- *Corpus signal:* that the corpus only clears 6 (not 9) is itself a logged finding — the text is too small for
  comfort and is scheduled for uplift; the machine recording it is the covenant (§7) working.

This is the **SCREEN** sibling of the **PRINT** law in the charting matrix: the 4×9-grid "too-wide" rule
([`charting-matrix.md`](../../rich-pdf-with-diagrams/references/charting-matrix.md) — §1 *The grid*, Rule 1
*Max 4 boxes across*, F1 *text < 8pt* in §6 *The failure catalogue*) fixes legibility against the **A4 page**;
the inline-legibility rule fixes it against the **reader's column**. Link, don't overload its name — the print
rule is the charting matrix's; this is its screen cross-reference.

**How to apply — author above the floor, don't fix below it.** The §5 rule is a detector; this is the
authoring discipline that keeps it green. Size every caption and label so it clears the floor at the figure's
**embed width** *before* assembly — for a ~1280px-wide figure that means `font-size ≥ ~13` (→ ≥6.5px inline);
solve `font_size ≥ FLOOR × svg_width / 640` for whatever your canvas width actually is. Never ship a sub-floor
caption, and run `layout-check.sh` before assembly so the smallest text element is proven above the floor at
source-time — not caught after it has already rendered as a smear.

## 6. Exemptions — measured, not vibe

- **Masthead** — self-exempts via large text. The §5 maths leaves its wordmark above the floor; **no
  special-case** exists or is needed.
- **Banners** (4.8:1, e.g. 1920×400) and **hero / masthead GIFs** (3.1–4.4:1) — class-whitelisted from the
  **aspect advisory only** (§4 item 8 / the `banner|masthead|hero|cycle` filename class). They are *meant* to
  be wide; the advisory would only cry wolf.
- **The per-text height floor still applies** to any small text a whitelisted file contains. An exemption from
  the *aspect advisory* is **never** an exemption from §5: a banner with a 6px footnote still fails item 7.

## 7. The self-improvement covenant

Carries the KAIZEN self-improvement covenant, as the sibling canons do. **A layout bug that slipped this
checklist is a CANON GAP** — the failure is not "the reviewer missed it" but "this canon did not yet name the
class." Do not patch the one figure and move on: **generalise the rule HERE**, in one sentence, so every future
review inherits the catch. Especially for an **expensive (vision) finding** — the budget that found it is only
repaid if the lesson becomes a free machine/raster check or a named checklist item before the next build: *the
bar rises once, every future build inherits it.* A reviewer that re-discovers the same defect twice has not
honoured the covenant.

---

> **Cross-references:** [`charting-matrix.md`](../../rich-pdf-with-diagrams/references/charting-matrix.md) (the
> PRINT 4×9 too-wide law — §1, Rule 1, F1 — the print sibling of the §5 screen rule);
> [`layout-check.sh`](../../../../../doc/image-craft-study/toolchain/src/layout-check.sh) (the free SVG-math
> tier — horizontal + vertical bounds, the inline-legibility rule, the aspect advisory);
> [`raster-lint.sh`](../../../../../doc/image-craft-study/toolchain/src/raster-lint.sh) (the free cheap-raster
> tier — suspect-tile heuristics for overlap / crowding / edge-clip / occlusion). The other three lenses:
> [`typography-canon.md`](typography-canon.md), [`dataviz-canon.md`](dataviz-canon.md),
> [`image-aesthetic-canon.md`](image-aesthetic-canon.md). Cite the item by name in every finding so the maker
> can verify the fix removed it.
