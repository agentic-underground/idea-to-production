# docs/ — idea-to-production documentation

Documentation comes in **two forms**, split by audience:

- **[`guide/`](guide/)** — **user-facing**: human-oriented guides, tours, and onboarding
  (e.g. the [context-building pipeline](guide/context-building-pipeline.md), design sketches).
- **[`internal/`](internal/)** — **agent-facing**: working material for agents and maintainers —
  implementation plans (`*_PLAN.md`), per-item EARS/feature evidence, cached reviews, handler-build
  research, the `image-craft-study` toolchain, and incident learnings.
- **[`historical/`](historical/)** — dated snapshots kept for the record (inspection reports, past
  review verdicts), with **[`historical/archive/`](historical/archive/)** for retired material.

Shared **assets** live at the top level so they are stably linkable from the root README and the
plugins:

- **[`images/`](images/)** — banners, animated GIFs (lifecycle, masthead, plugin heroes), SVG sources.
- **[`diagrams/`](diagrams/)** — vector/`.dot` diagram sources.

> The marketplace's always-on canon — `KAIZEN.md` — and the entry points
> `README.md` / `CLAUDE.md` deliberately remain at the repo root (the canons are injected into every
> plugin's session and must not move).
