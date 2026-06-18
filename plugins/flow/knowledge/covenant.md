# FLOW — pillars & the KAIZEN self-improvement covenant

> This plugin's own anchor for the marketplace's governing philosophy. Like every `idea-to-production`
> plugin, FLOW is bound by the **three pillars** and the **KAIZEN self-improvement covenant**.
> (The canonical, in-depth homes live in the `foundry` plugin's `knowledge/`; this is the local copy a
> standalone install carries — referenced by concept, not by a cross-plugin path.)

## The three pillars

- **Knowledge-parity** (≡ *knowledge-alignment*) — the roadmap is the shared truth of *what is being
  delivered*, and FLOW keeps that truth one local, ~0-token answer that travels with the project. Every
  state move is evidenced — who carried the item, what they did, what it cost — recorded through the
  flow-mcp's typed verbs, never asserted. `/flow:pull` never guesses which item to build: an empty or
  ambiguous backlog is refused, not invented.
- **Quality-first** (≡ *quality-confidence*) — the delivered increment is built in, not bolted on; FLOW
  **composes** foundry's conveyor rather than re-implementing the build, so the rigour of the gate is
  never weakened by the carry verb. The flow-mcp server is plain Ruby (>= 3.3.8, standard library only) —
  the same source runs everywhere, deterministic local compute, nothing to build, download, or drift.
  Raise the floor (a deterministic server, a deterministic roadmap render) instead of lowering the bar
  (a guessed roadmap answer, a guessed item).
- **Waste-elimination** (≡ *muda · mura · muri*) — remove waste in every form, *including the rediscovery of
  the roadmap state*. `render_roadmap` answers "what's on the roadmap" by local compute at ~0 LLM tokens so
  the slow `.i2p/roadmap/` scan is never re-paid; the Ruby server runs straight off the host's interpreter
  with no build/fetch step to re-pay; a self-contained plugin never re-resolves a sibling's path.

> **Overarching constraint — token-efficiency:** thin skills, fat references; define once, reference many;
> load only what a task needs. The flow-mcp server does the heavy lifting (deterministic roadmap render,
> typed state moves) at ~0 tokens; the model triages, carries, and explains.

## The KAIZEN self-improvement covenant

Every element of this plugin — each skill, command, and knowledge doc — continuously asks how it can
improve, and each iteration must at least **halve the remaining distance to perfection**. When an element
grows to do more than one thing, it **self-cleaves** into smaller, single-purpose elements.

Concretely, FLOW improves by folding **delivery feedback** back into its surface: a carry that **stalled**
(an item stuck in a lane, an empty board where a roadmap existed, the server not serving a populated tree)
or a verb that **over-reached** (a wrapper that re-implemented what foundry already owns) becomes a
sharpened skill, a tighter flow-mcp contract, or a reference-not-restate — landed via branch →
adversarial review → **PR**, so **every future delivery, for all users, flows cleaner and answers
faster**. The `self-improve` skill drives this loop.

> A FLOW pass that came up empty on a populated roadmap — or that re-implemented the build instead of
> composing it — has not honoured the covenant. The fix is not heroics but a **better-articulated verb,
> contract, or reference**, fixed once, upstream.
