# OPERATE — pillars & the KAIZEN self-improvement covenant

> This plugin's own anchor for the marketplace's governing philosophy. Like every `idea-to-production`
> plugin, OPERATE is bound by the **three pillars** and the **KAIZEN self-improvement covenant**.
> (The canonical, in-depth homes live in the `deliver` plugin's `knowledge/`; this is the local copy a
> standalone install carries — referenced by concept, not by a cross-plugin path.)

## The three pillars

- **Knowledge-parity** (≡ *knowledge-alignment*) — understand the running system before acting; you cannot
  operate what you cannot observe. Every operational claim is evidenced (a signal, a graph, a log line +
  why), never asserted. A recurring incident-class becomes a written runbook, found once. Never raise an
  alert you cannot act on, and never declare "healthy" a service whose golden signals you cannot read.
- **Quality-first** (≡ *quality-confidence*) — operational quality is built in, not bolted on; **the
  operational-readiness gate is never weakened to make go-live**. An SLO is earned by a real SLI, not a
  guessed number. Error budgets gate change; a depleted budget stops feature work until reliability is
  restored. Raise the reliability floor instead of lowering the bar.
- **Waste-elimination** (≡ *muda · mura · muri*) — remove waste in every form, *including the rediscovery of operational knowledge*.
  Every incident produces a blameless postmortem and a runbook so the next like incident is recognised on
  sight and resolved without re-litigation. Toil that recurs is automated away, not endured.

> **Overarching constraint — token-efficiency:** thin skills, fat references; define once, reference many;
> load only what a task needs. Deterministic probes (HTTP health checks, log/metric queries) do the heavy
> lifting; the model triages, correlates, and explains.

## The KAIZEN self-improvement covenant

Every element of this plugin — each skill, command, and knowledge doc — continuously asks how it can
improve, and each iteration must at least **halve the remaining distance to perfection**. When an element
grows to do more than one thing, it **self-cleaves** into smaller, single-purpose elements.

Concretely, OPERATE improves by folding **operational feedback** back into its discipline: an
**incident that surprised us** (no runbook, no alert, an unwatched signal) or **alert fatigue** (a rule
firing without action) becomes a sharpened SLO, a new runbook, or a tightened alert threshold — landed via
branch → adversarial review → **PR**, so **every future operate cycle, for all users, is calmer and
catches more, sooner**. The `self-improve` skill drives this loop.

> An OPERATE pass that was surprised by a foreseeable incident — or that drowned the on-call in noise — has
> not honoured the covenant. The fix is not heroics but a **better-articulated signal, SLO, or runbook**,
> fixed once, upstream.
