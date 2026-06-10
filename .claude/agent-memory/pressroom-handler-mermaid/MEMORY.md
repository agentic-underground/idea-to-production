# Pressroom Mermaid Handler — Memory Index

- [rsvg + htmlLabels](feedback_rsvg-htmllabels.md) — mermaid v11 foreignObject labels vanish under rsvg-convert; force single-line native SVG text for the dual-ground gate
- [edge-label pill opacity](feedback_edgelabel-pill-opacity.md) — v11 bakes opacity:0.5 on .edgeLabel rect; themeCSS clobbers node fills, so patch the rendered SVG stylesheet + chrome-screenshot for the opaque pill
- [htmlLabels entities](feedback_htmllabels-entities.md) — under htmlLabels:false, HTML entities (&larr; etc) print literally; use the Unicode glyph (←) directly in the .mmd source
