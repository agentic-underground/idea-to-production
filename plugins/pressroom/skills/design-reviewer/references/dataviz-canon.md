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

---

> **Sources to cite:** Cleveland & McGill (graphical-perception ranking); Bertin (visual variables);
> Tufte (data-ink, chartjunk, lie factor, small multiples); Wilkinson (*The Grammar of Graphics*);
> ColorBrewer (Brewer/Harrower) for palettes. Name the principle in every finding so the producer can
> verify the fix removed it.
