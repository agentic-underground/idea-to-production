# The data-visualisation canon — what the data-viz reviewer cites

> The named theory of encoding data so a reader reads it correctly and quickly. A finding is *"angle/area
> encoding ranks low in Cleveland–McGill — use length"*, not *"the pie is bad". Grounding makes the fix
> verifiable.

## 1. Graphical perception — the accuracy ranking (Cleveland & McGill, 1984)

People decode some visual channels far more accurately than others. *Graphical Perception: Theory,
Experimentation, and Application* established the ranking — encode the **most important quantity in the
most accurate channel available**:

1. **Position along a common scale** (aligned bars, scatter on shared axes) — most accurate
2. **Position on non-aligned scales**
3. **Length** (unaligned bars)
4. **Angle / slope** (pie slices, line slope)
5. **Area** (bubbles, treemaps)
6. **Volume / curvature** (3-D)
7. **Colour saturation / density** — least accurate

> **The most common chart crime:** encoding an important comparison in **angle/area** (pie, donut, 3-D) when
> **position/length** (a sorted bar chart) would be read accurately. Default to bars; reserve pie for
> part-to-whole with ≤~5 slices where precision doesn't matter.

## 2. Visual variables (Bertin, *Sémiologie Graphique*)

Bertin catalogued the marks' channels — **position, size, value (lightness), colour (hue), orientation,
shape, texture** — and their perceptual properties:

- **Selective** (can you isolate a group at a glance?), **associative** (group despite the variable),
  **ordered** (perceived as ranked), **quantitative** (read as ratios).
- **Match the variable to the data type:** quantitative → position/size/value (ordered & quantitative);
  ordinal → value/size; nominal → hue/shape (selective but **not** ordered). Encoding an *ordered* quantity
  in **hue** (a rainbow ramp) is a classic error — hue has no perceptual order; use a **sequential
  lightness** ramp.

## 3. Data-ink & integrity (Tufte, *The Visual Display of Quantitative Information*)

- **Data-ink ratio** — maximise the ink that encodes data; **erase non-data ink** (heavy gridlines, boxes,
  3-D, decorative fills, redundant legends) and redundant data-ink. Edward Tufte's core discipline.
- **Chartjunk** — moiré, gratuitous 3-D, ducks (decoration masquerading as data) — remove it.
- **The lie factor** = size of effect shown ÷ size of effect in data. Keep it ≈1: bars start at **zero**;
  don't truncate or expand axes to exaggerate; don't scale a 1-D quantity by 2-D area.
- **Figure↔data integrity (verify the render against the numbers).** A lie factor ≠ 1 also hides in the
  *encoding itself*: a legend/colour/bar-length that **contradicts the underlying data** (e.g. a legend
  labelling the tall bars "after" when they are the baseline), or a series so small it is **sub-pixel** on
  a linear axis (invisible — the comparison the chart exists to make can't be read). Checking this
  requires the reviewer be **handed the source numbers** and compare them to the rendered figure: a render
  reviewed with no data can confirm *aesthetics* but not *truth*. When the channel can't carry the
  comparison (no legend, no log scale, order-of-magnitude spread), the honest fix is a **table with a
  ratio column**, not a tuned chart.
- **Small multiples** — repeat a small chart across a dimension instead of overloading one chart; the eye
  compares like-with-like.
- **Above all** — show the data; tell the truth about it; let comparison be effortless.

## 4. Colour for data

- **Sequential** (single-hue lightness ramp) for ordered magnitudes; **diverging** (two ramps about a
  meaningful midpoint) for above/below; **categorical** (≤~7 distinct hues) for nominal classes — the
  **ColorBrewer** families are the reference, chosen for perceptual order and print/screen safety.
- **Colour-blind-safe** — ~8% of men have a colour-vision deficiency; never rely on red/green alone; pair
  colour with another channel (shape, label, position). Verify the palette survives greyscale.
- **Contrast & restraint** — enough contrast to read; one accent to carry emphasis; not a rainbow.

## 5. Choosing the chart (the grammar)

Think in the **grammar of graphics** (Wilkinson): a chart is *data → an encoding of variables onto visual
channels → a geometry*. Pick the geometry from the question — comparison (bars), trend over time (line),
relationship (scatter), distribution (histogram/box), part-to-whole (stacked bar, or bars of the parts),
flow (sankey). Diagrams (Mermaid/Graphviz) explain **structure**; charts explain **quantity** — don't
substitute one for the other.

## 6. Award-tier vs merely-competent — what to demote (the exemplar bar)

> *Sections 1–5 say how to encode honestly; this says how to tell **publication-grade** from **competent-but-flat**.
> A chart that is correct can still be demoted — the named theory below lets the reviewer say **why** and point at
> what award-winning work does instead. Cite **(a)** the principle, **(b)** the violation, **(c)** the exemplar.*

| Theory | DO — what award-winning work does | AVOID — the demote trigger |
|---|---|---|
| **Cleveland–McGill effectiveness ranking** | Encode the headline quantity in the **highest-accuracy channel** the question allows — a sorted bar / dot plot where the comparison *is* the geometry (cf. the *Financial Times* / *Economist* sorted bars). | The comparison lives in **angle/area/colour** (pie, donut, 3-D, treemap, heat-blob) when length on a common scale would read it — competent, but demoted to **length**. |
| **Tufte data-ink ratio** | Erase to the data: faint or no gridlines, direct labels over legends, no boxes/3-D/fills — the *signal* carries the ink (cf. *NYT* / Tufte's own redesigns). | Chartjunk earns its keep: heavy frames, moiré fills, redundant legends, decorative 3-D. Ink that doesn't encode data is the demote. |
| **Tufte small multiples** | A grid of *identical* small charts compared like-with-like across one dimension — the reader scans, not re-learns (cf. *NYT* climate-stripes grids). | One overloaded chart with 8 overlapping series / a triple-axis. The fix is to **facet**, not to add another axis. |
| **Bertin's visual variables** | Match channel to data type: quantitative → **position/length/value**; nominal → **hue/shape**; ordered → **sequential lightness**. Selective groups isolate at a glance. | An *ordered* quantity in **hue** (rainbow/jet ramp), or a nominal class in a *sequential* ramp — channel fights the data's type. |
| **Few's dashboard restraint** | One screen, no scroll; the *one* number that matters dominates; muted palette with a single accent; gauges/3-D banished (cf. Stephen Few's *Information Dashboard Design*). | Skeuomorphic gauges, traffic-light confetti, every-KPI-equal-weight, full-saturation everywhere — a dashboard that *decorates* instead of *informs*. |

> **The demote move:** a chart can be *truthful* (clears §1–§4) yet still **competent-but-flat** — no focal
> comparison, legend where a direct label belongs, a default rainbow, a dashboard with no hierarchy. Name the
> theory it falls short of and the exemplar that clears it; that turns "looks generic" into a verifiable fix.

## 7. Animated diagram craft — when motion teaches, and when it flickers

> *Motion is a medium, not a decoration. An **animated** diagram earns its keep only when the motion **carries
> meaning a still cannot** — and is held to the same motivated-motion bar as any figure (design art-direction
> [§9](../../../../design/knowledge/canon/art-direction.md#9-motion--temporal-craft--when-a-figure-earns-animation)).*

**Motion helps when it reveals temporal/sequential structure a static frame flattens:**
- **Build-order** — a pipeline lighting up stage-by-stage, so the *order* becomes the message.
- **A cycle closing** — a feedback/retry/build-measure-learn loop drawn as it returns to its start.
- **Walking a pipeline** — a token/request traced through nodes, one hop at a time.

**Motion is gratuitous (demote) when:** the diagram is *structural* (an ER diagram, a class hierarchy, a static
topology) and animation adds drift/spin/fade with no sequence to teach — a still reads it faster.

**The three craft rules (a finding cites the broken one):**
1. **Motivated motion** — every movement sequences meaning; no spinning nodes, no gratuitous drift. Broken → demote to a still.
2. **Reduced-motion poster** — ship a strong, complete **static final frame** as the fallback; honour `prefers-reduced-motion`; nothing flashing >3×/s. The poster must read the whole structure alone.
3. **Per-frame legibility** — *every* sampled frame is a legible diagram on its own (labels readable, no half-drawn edges mid-transition); the final/loop frame is poster-worthy. Broken → the animation hides the data between frames.

> **How the reviewer judges it:** score motion from a **frame-strip montage** (sampled frames in one image),
> exactly as the still image reviewer does. Motivated, eased, per-frame-legible motion with a clean poster =
> award-tier; motion-for-motion's-sake on a structural diagram = demote to still; strobing / illegible
> mid-frames = the accessibility gate bites. Rendering pipeline and poster/frame extraction:
> [raster-toolchain.md](../../../knowledge/raster-toolchain.md).

---

> **Sources to cite:** Cleveland & McGill (graphical-perception ranking); Bertin (visual variables);
> Tufte (data-ink, chartjunk, lie factor, small multiples); Few (*Information Dashboard Design* — dashboard
> restraint); Wilkinson (*The Grammar of Graphics*); ColorBrewer (Brewer/Harrower) for palettes; for
> **animated** diagrams, the motivated-motion bar in design art-direction §9. Name the principle in every
> finding so the producer can verify the fix removed it.
