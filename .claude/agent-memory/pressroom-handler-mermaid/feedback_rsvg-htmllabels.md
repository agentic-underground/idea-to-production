---
name: rsvg-htmllabels
description: Mermaid v11 emits node labels as foreignObject (HTML) which rsvg-convert drops; force native SVG text for the dual-ground gate
metadata:
  type: feedback
---

When rendering Mermaid (mmdc v11.x) to SVG and rasterising with `rsvg-convert` for the dual-ground gate, node labels can come out **blank** even though shapes/edges/edge-labels render fine.

**Why:** mermaid v11 wraps node labels in `<foreignObject>` (HTML/`<br>`/`<small>`), and `rsvg-convert` does not render foreignObject content — so the text vanishes on the rasterised PNGs even though Chrome/mmdc's own PNG shows it. Edge labels become native `<text>` but node labels do not.

**How to apply:**
- Set BOTH `'htmlLabels':false` (top-level) AND `'flowchart':{'htmlLabels':false}` in the init block.
- **Init-block `htmlLabels:false` alone is NOT reliably honoured by mmdc 11.15** — node labels still emit as foreignObject. The fix that works: pass an explicit mermaid config file via `-c` (e.g. `-c /tmp/mmdc-config.json` with `{"htmlLabels":false,"flowchart":{"htmlLabels":false}}`). With the `-c` file, foreignObject count drops to 0. Always use `-c`, do not trust the init directive for this.
- Even then, **multi-line node labels using `\n` or `<br/>`/`<small>` still route through foreignObject in v11.** Use **single-line node labels** (fold sub-text in with `·`, e.g. `"DISCOVER · discover"`) to force native `<text>`/`<tspan>`.
- Verify before reading PNGs: `grep -c '<foreignObject' file.svg` must be `0`; `grep '<tspan' file.svg` should show the real label text.
- Known cosmetic cost: rsvg renders DejaVu with tight inter-tspan spacing, so `· ` separators may collapse visually (`DISCOVER·discover`) — readable but tight. Acceptable; do not chase it.

Related: [[mermaid-dark-mode-base-theme]] (the transparent base-theme init block that pairs with this).
