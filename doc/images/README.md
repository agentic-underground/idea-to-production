# doc/images — marketplace documentation illustrations

Rendered illustration assets for the marketplace docs (banners, hero graphics, generated figures). Named by
purpose, kebab-case (`readme-banner.png`, `readme-banner-alt.png`). Lives under the existing `doc/` tree for
consistency with the rest of the repo's documentation.

- **SVG** figures (diagrams, charts, compositions) produced by PRESSROOM's graphical value handlers default to
  `<doc-dir>/diagrams/` beside the doc they illustrate; this folder holds **repo-level raster assets** (e.g.
  the README banner) and any shared illustration.
- **`readme-banner.png`** — the root README's top banner. Generated via PRESSROOM's `handler-comfyui` against
  the live ComfyUI backend (`$PRESSROOM_COMFYUI_URL`), model `realcartoon3d_v8.safetensors`, dark-key
  infographic composition to sit on the dark README. `readme-banner-alt.png` is the runner-up from the A/B
  pass — swap the README reference to use it.
