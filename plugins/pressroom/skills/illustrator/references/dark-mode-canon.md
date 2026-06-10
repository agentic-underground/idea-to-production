# The dark-mode & transparency canon — figures that live anywhere

> The companion to the [4×9 charting matrix](../../rich-pdf-with-diagrams/references/charting-matrix.md).
> The matrix governs *composition* (does it fit, is it legible at size); this canon governs *colour and
> ground* (is it readable on whatever surface it lands on). Every SVG a PRESSROOM graphical value handler
> emits obeys **both**. A figure embedded in a README is viewed in light mode by some readers and dark mode
> by others, on GitHub, a docs site, a slide — so it must default to **transparent ground, dark-tuned, and
> legible on both**. This is a single source of truth; the handlers reference it, they do not restate it.

## §1 — The contract (inviolable)

1. **Transparent background by default.** No opaque full-bleed backdrop. The figure inherits the host's
   page colour so it never paints a white slab onto a dark page (or vice-versa).
2. **Dark-tuned, not inverted.** Re-pick colours for a dark ground; never `filter: invert()` a light figure.
   Inversion wrecks hues, photos, and semantic colour (red/green stop meaning stop/go).
3. **Legible on BOTH grounds (GATE).** Because the ground is transparent and unknown, every stroke, fill,
   and glyph must stay readable on **both a near-black and a near-white** host. This is the hard gate the
   design-reviewer checks (§5). A figure that vanishes on one ground is **not done**.
4. **Never signal by colour alone.** Pair colour with shape, label, position, or weight — the meaning must
   survive greyscale and colour-blindness (shared with the [`design-reviewer`](../../design-reviewer/SKILL.md)).

## §2 — The dark-surface palette (named tokens)

One restrained palette, tuned for a dark ground but chosen so the **strokes and text also read on white**.
Hex only (Graphviz and Mermaid both reject colour names in themes).

| Token | Hex | Use |
|---|---|---|
| `ground` | *(transparent)* | the page — never painted |
| `surface` | `#1e1e2e` | node/box fill (a dark slab the host rarely matches exactly) |
| `surface-raised` | `#2a2a3c` | emphasis fill, headers, the one node that matters |
| `stroke` | `#9aa2c0` | borders, edges, connectors — **mid-tone: reads on black AND white** |
| `text` | `#e6e9f0` | primary labels on `surface` |
| `text-dim` | `#b8bed0` | secondary/caption text |
| `accent-1` | `#7aa2f7` | primary accent (blue) — action/flow |
| `accent-2` | `#9ece6a` | success/positive (green) |
| `accent-3` | `#e0af68` | sentinel/attention (amber) |
| `accent-4` | `#f7768e` | failure/stop (red) |
| `accent-5` | `#bb9af7` | reviewer/secondary (purple) |

> **Why mid-tone strokes.** Pure-white strokes (`#fff`) vanish on a white host; pure-black (`#000`) vanish
> on a dark host. The `stroke`/text-on-transparent elements use mid-tones (L\* ≈ 65–75) so they clear the
> contrast gate on **both** grounds. Fills sit on the dark `surface` slab, so their text can be brighter.
> The accents are the colour-blind-distinguishable set already used by the Graphviz patterns — re-tuned a
> shade lighter for the dark ground.

## §3 — Contrast gates (measurable, not vibes)

- **Text on `surface`** ≥ **4.5:1** (WCAG 2.2 AA body) — `text` on `surface` clears this by design; verify
  if you deviate.
- **Stroke / unfilled-node text on transparent ground** ≥ **3:1 against BOTH `#000000` and `#ffffff`**. This
  is the gate that makes "lives anywhere" true. `stroke` (`#9aa2c0`) clears ~4.8:1 on black and ~3.1:1 on
  white. Anything thinner or paler fails — thicken or darken until it clears both.
- **Accents never carry meaning alone** — they ride on shape/label (gate from §1.4).

## §4 — Per-engine recipes

### Graphviz (`handler-graphviz`)
```dot
digraph {
  bgcolor="transparent"
  node [style="filled", fillcolor="#1e1e2e", color="#9aa2c0", fontcolor="#e6e9f0",
        fontname="Inter", penwidth=1.4]
  edge [color="#9aa2c0", fontcolor="#b8bed0", penwidth=1.2]
  // emphasis: fillcolor="#2a2a3c"; accent borders via color="#7aa2f7"
}
```
Key: `bgcolor="transparent"` (NOT `"white"`); filled nodes give text a dark slab to sit on; edges/labels use
the mid-tone `stroke`/`text-dim` so they survive a white host.

### Mermaid (`handler-mermaid`)
```
%%{init: {'theme':'base','themeVariables':{
  'background':'transparent',
  'primaryColor':'#1e1e2e','primaryBorderColor':'#9aa2c0','primaryTextColor':'#e6e9f0',
  'secondaryColor':'#2a2a3c','tertiaryColor':'#2a2a3c',
  'lineColor':'#9aa2c0','fontFamily':'Inter, ui-sans-serif, system-ui','fontSize':'15px'
}}}%%
```
Start from `base` (the only customisable built-in — see [`mermaid-theming.md`](../../mermaid-specialist/references/mermaid-theming.md)),
set `background:'transparent'`. Do **not** use the built-in `dark` theme: it paints a dark slab and assumes
a dark host, failing on a white one.

### Hand SVG (`handler-composition`)
- No `<rect width="100%" height="100%" fill="…"/>` backdrop. The root `<svg>` ground stays transparent.
- Explicit fills from §2; text uses `text`/`text-dim`; strokes use `stroke`.
- Optional progressive enhancement: a `<style>` with `@media (prefers-color-scheme: light)` may nudge a few
  values for light hosts — but the **base** colours must already clear both gates (don't rely on the media
  query, many renderers ignore it).

### Charts (`handler-chart`)
- Transparent plot area; axes/gridlines in `stroke`/`text-dim`, minimal (data-ink — drop heavy grids).
- Categorical series → the §2 accents (≤7); ordered data → a sequential ramp built from `accent-1`
  light→dark; never a rainbow for ordered data. Labels in `text`.

### ComfyUI raster (`handler-comfyui`)
- Vector handlers honour transparency natively; raster cannot inherit a host ground. Two options, in order:
  1. **Alpha PNG** — when the workflow template supports a transparent VAE / background-removal node, emit
     RGBA so the PNG itself is groundless (best — behaves like the SVGs).
  2. **Dark-key composition** — otherwise steer the prompt to a dark, low-key background that reads as
     "intentional dark figure" on most hosts, and record in the SPEC that this asset assumes a dark-ish host.

## §5 — Verification (how the gate is enforced)

A handler does not hand back an SVG it has not *seen on both grounds*:

```bash
# rasterise the emitted SVG onto BOTH a black and a white card, then Read both PNGs
for bg in "#000000" "#ffffff"; do
  rsvg-convert -b "$bg" -o "/tmp/check-${bg//[#]/}.png" figure.svg   # or: magick -background "$bg" ...
done
```
Then `Read` `/tmp/check-000000.png` and `/tmp/check-ffffff.png` with vision: **every stroke, label, and node
must be legible in both.** A stroke that disappears on white, or text that disappears on black, is a HIGH
finding (it trips the §3 gate) — the design-reviewer treats it exactly like a legibility/accessibility gate
failure. A cheap structural lint catches the most common miss:

```bash
# flag an opaque full-bleed background rect (the #1 transparency violation)
grep -Eq '<rect[^>]*width="100%?"[^>]*height="100%?"[^>]*fill="#(fff|ffffff|000|000000)' figure.svg \
  && echo "VIOLATION: opaque full-bleed background — remove it (ground must stay transparent)"
```

### §5b — Raster & motion figures (handler-composite)

A **blended raster** (a ComfyUI atmosphere under a vector layer) can't go transparent, so prove legibility a
different way — composite it onto both grounds and confirm the **vector layer + scrim** still read:
```bash
for bg in 000000 ffffff; do magick figure.png -background "#$bg" -flatten "/tmp/check-$bg.png"; done   # vips fallback: vips flatten figure.png /tmp/check.png --background "0,0,0"
```
The **legibility scrim** (a bottom-up `linearGradient` rect inside the vector overlay) is what keeps text
readable over a busy generative ground — it is the raster analogue of "every label legible on both grounds".

**Animated figures:** ship a **static poster frame** beside every animation (reduced-motion hosts and the
`![]()`-can't-animate case both fall back to it), keep loops short and **motivated** (a reveal that teaches,
not decoration), and verify the motion by Reading a **frame-strip montage** (build it with `magick montage`).
Full recipes: the [raster-toolchain canon](../../../knowledge/raster-toolchain.md).

## §6 — Self-improvement

A recurring colour/ground failure (a host that keeps eating a hue, a stroke weight that keeps failing the
white gate) generalises into this canon via the shared
[self-improvement protocol](../../rich-pdf-with-diagrams/references/self-improvement.md) — add a token, tune
a value, or extend §5 — so every SVG handler inherits the fix at once. Composition lessons still go to the
charting-matrix; *colour and ground* lessons live here.
