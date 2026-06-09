# doc/images — marketplace documentation illustrations

Rendered illustration assets for the marketplace docs (banners, hero graphics, generated figures). Named by
purpose, kebab-case (`readme-banner.png`, `readme-banner-alt.png`). Lives under the existing `doc/` tree for
consistency with the rest of the repo's documentation.

- **SVG** figures (diagrams, charts, compositions) produced by PRESSROOM's graphical value handlers default to
  `<doc-dir>/diagrams/` beside the doc they illustrate; this folder holds **repo-level raster assets** (e.g.
  the README banner) and any shared illustration.
- **`readme-banner.png`** — the root README's top banner: a **wide, short masthead** (1280×240, ≈5.3:1)
  carrying the wordmark, the tagline, and a single IDEA→PRODUCTION launch-trail (cool spark → warm ignition).
  Authored as a hand-composed SVG by PRESSROOM's `handler-composition` and rasterised at 2× via `rsvg-convert`;
  the editable source is **`readme-banner.svg`** beside it. It sits on its own inset dark card with a
  transparent margin, so it clears the dark-mode-canon dual-ground gate on GitHub light **and** dark themes.
  Chosen as the A/B `BEST` winner (87/100) over an informational 8-phase-ribbon variant, which was rejected as
  redundant with the README body's flow diagram. `readme-banner-alt.png` is a pre-existing alternate raster.
