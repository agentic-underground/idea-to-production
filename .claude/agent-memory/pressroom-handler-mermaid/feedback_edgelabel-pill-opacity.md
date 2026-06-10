---
name: edgelabel-pill-opacity
description: Mermaid v11 bakes opacity:0.5 + a light fill onto .edgeLabel rect; themeCSS can override it but also clobbers node fills, so patch the rendered SVG stylesheet instead
metadata:
  type: feedback
---

Edge-label background pills in mermaid v11 (mmdc 11.x, `theme:base`) are hard to control. The rule baked into the SVG is `.edgeLabel rect{opacity:0.5;background-color:<x>;fill:<x>;}`. Even with `edgeLabelBackground:'#1e1e2e'` set in `themeVariables`, the **opacity stays 0.5**, so a dark fill composites to a mid-grey pill over transparent ground — the grey-on-grey look a reviewer flags.

**Why this matters:** a semi-transparent pill is never page-ground-independent. For the dual-ground gate you need either a fully opaque pill or label text that itself clears >=3:1 on both #fff and #0d1117.

**What does NOT work:**
- `themeCSS` (whether inline in the init directive OR in the `-c` config) to set `.edgeLabel rect{opacity:1;fill:#1e1e2e}` — it lands, BUT the mere presence of a `themeCSS` block **resets the base theme's computed node fills to a pale lavender default**, breaking the dark-mode nodes. Confirmed twice. Do not use themeCSS with `theme:base` if you need dark node fills.
- Init-directive `themeCSS` is also silently dropped when a `-c` config file is passed (same precedence quirk as htmlLabels, see [[rsvg-htmllabels]]).
- Coloring label text via `tspan{fill:...}` in themeCSS cascades into node label text too — avoid.

**What works (the fix):** render normally (no themeCSS, nodes stay dark), then **post-process the rendered SVG**: prepend a scoped rule to the existing `#my-svg` `<style>` block — `#my-svg .edgeLabel rect{opacity:1 !important;fill:#0d1117 !important;stroke:#9aa2c0 !important;stroke-width:1px !important;}`. Equal specificity + `!important` wins; the faint stroke keeps the dark pill delineated on a dark page. This touches only edge-label rects, never nodes.

**Then rasterize the embed PNG from the PATCHED SVG via headless chromium** (mmdc can't ingest an SVG, and rsvg mangles word spacing — see [[rsvg-htmllabels]]). Wrap the patched SVG in `<body>...</body>`, force explicit pixel width/height from the viewBox onto the root `<svg>`, and screenshot:
`chrome --headless --no-sandbox --disable-gpu --hide-scrollbars --default-background-color=00000000 --force-device-scale-factor=2 --window-size=W,H --screenshot=out.png loop.html`
`--default-background-color=00000000` gives a transparent PNG; `--force-device-scale-factor=2` matches mmdc `-s 2`. Chrome lays out text with correct word spacing.

**Consequence for hosts that render raw .mmd** (GitHub markdown): they get the 50%-opacity pill, not the opaque one. So the rendered PNG must be the embed deliverable, not a fenced ```mermaid block, whenever the opaque-pill fix is load-bearing.
