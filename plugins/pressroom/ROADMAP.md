# PRESSROOM — Roadmap

The shipped v1 covers prose (writer), standalone diagrams (diagram-studio), print PDFs
(rich-pdf-with-diagrams), and the `/publish` orchestrator. **v1.2** adds the Mermaid-native
**mermaid-specialist** (full taxonomy + theming + ELK) and the adversarial **design-reviewer**
(typography + data-viz canon, in a convergent loop). This roadmap captures the remaining expansion
path toward a complete publishing house. Items are independently shippable.

**v1.4** adds the **illustrator** — a documentation-illustration studio that ranks figure-sites by impact,
specs each, has a graphical **value handler** (Graphviz / Mermaid / chart / hand-composition / ComfyUI) render
two options, and runs an adversarial **A/B-until-best** review (the design-reviewer's comparative mode). Every
figure is dark-mode and transparent by default; `/illustrate docs` trawls the whole tree under `/loop`,
embedding and ledgering as it goes.

## Near-term

- **`comfyui-mcp` — the secured generative backend.** `handler-comfyui` currently talks raw HTTP to a live
  ComfyUI server (`$PRESSROOM_COMFYUI_URL`); the LAN is the only trust boundary (a known Phase-0 gap). The
  [`comfyui-mcp/`](../../comfyui-mcp/ROADMAP.md) sub-project closes it: a containerised ComfyUI (with the
  `DIFFUSION_MODELS` folder bind-mounted) fronted by a **demonstrably secure MCP server** — workflow-template
  allowlisting, validated params, a model allowlist, a path-traversal-safe `/view` proxy, network isolation,
  and authn. It is built by dogfooding the marketplace's own pipeline: **foundry** builds the server
  test-first, **sentinel** runs the security gate, **pressroom** documents it; then `handler-comfyui` switches
  from `curl` to `mcp__comfyui__*` tools.
- **`slide-deck` skill** — generate presentation decks (Marp markdown → HTML/PDF, or Beamer for
  LaTeX users) from an article or outline. Reuses `diagram-studio` for figures sized to 16:9 and
  the writer's narrative discipline (one idea per slide, hook on every section). A natural
  `format=slides` target for `/publish`.
- **Multi-format export** — a `format=` matrix beyond markdown/pdf: `docx`, `epub`, `html`
  (single-file, styled) via a pandoc-backed renderer, so one source reaches every channel.
- **TTS-optimised output mode** — the writer already hints at this (flowing prose, no inline
  headers, em-dash pacing); promote it to a first-class `format=audio-script` for narration
  pipelines.

## Mid-term

- **Citations & bibliography** — when an article references sources, manage a `references.bib`
  and render footnotes/endnotes consistently across markdown, PDF, and HTML.
- **Web-publish targets** — push finished articles to dev.to, Hashnode, or a static-site repo
  (front-matter generation, canonical URLs, cover-image hookup), with a dry-run preview.
- **Changelog & release-notes automation** — generate release notes directly from conventional
  commits between two refs, then let the writer polish them — a `/publish release-notes vX..vY`
  flow.

## Longer-term

- **Brand/style themes** — a `pressroom.config.json` carrying fonts, colours, and a LaTeX/CSS
  theme so every artefact (PDF, slides, web) shares one visual identity.
- **Diagram round-tripping** — import existing Mermaid/DOT/draw.io and re-compose it to the
  charting matrix, flagging legibility violations for fix.
- **Localisation** — produce parallel-language editions of an article with diagrams whose labels
  are externalised and translated.

## Principles guiding expansion

Every new surface (a) shares the **one legibility discipline** (the 4×9 charting matrix and its
lessons log), (b) flows through `/publish` as another `format=` target, (c) keeps PRESSROOM
self-contained (no assumption that foundry or any other plugin is installed), and (d) carries the
self-improvement covenant so feedback compounds across all output formats.
