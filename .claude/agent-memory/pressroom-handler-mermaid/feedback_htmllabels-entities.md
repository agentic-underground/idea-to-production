---
name: htmllabels-entities
description: Under htmlLabels:false, HTML entities (&larr; &rarr; &amp; etc) print literally in labels; use the Unicode glyph directly in the .mmd source
metadata:
  type: feedback
---

When node/edge labels are forced to native SVG text via `htmlLabels:false` (the rsvg-safe path, see [[rsvg-htmllabels]]), **HTML character entities are NOT decoded** — `&larr;` renders as the literal seven characters `&larr;` in every output (SVG, rsvg PNG, and the mmdc/chrome PNG).

**Why:** entity decoding is an HTML-rendering step. With foreignObject/HTML labels disabled, mermaid emits the label text verbatim into `<tspan>`, so `&larr;` is just a string.

**How to apply:** put the **literal Unicode glyph** in the `.mmd` source instead of the entity — `←` not `&larr;`, `→` not `&rarr;`, `≈` not `&asymp;`. DejaVu Sans (the canon font) covers the common arrows/math glyphs, so they rasterise fine on both grounds. Verify with `grep -c '←' file.svg` after render (should be >=1), not `grep '&larr;'`.
