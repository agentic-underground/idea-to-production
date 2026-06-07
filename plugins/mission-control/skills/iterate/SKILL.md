---
name: iterate
description: >
  Close the loop — turn production signals (a stalled metric, an incident's lesson, user feedback) into a
  new, build-ready OPPORTUNITY that re-enters DISCOVER. Trigger with /iterate (or "what should we build
  next?", "turn this incident into a backlog item", "the metric stalled — now what?", "close the
  build-measure-learn loop"). Applies the build-measure-learn pivot-or-persevere test, frames the
  opportunity, and — when i2p is installed — advances the lifecycle OPERATE → DISCOVER (↻). Produces an
  OPPORTUNITY brief and hands off to market-scanner/ideator when present.
metadata:
  type: producer
  lens: build-measure-learn
  output: OPPORTUNITY-<slug>.md → DISCOVER re-entry (↻)
  model: inherit
---

# ITERATE

OPERATE is where the product meets reality — so it is where the **Build → Measure → Learn** loop closes and
the *next* cycle begins. This skill is the marketplace's **cyclic re-entry**: it converts a production
signal into a new opportunity and points it back at DISCOVER. Grounded in
[`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §3 (build-measure-learn).

## The re-entry signal

A learning is worth a new cycle when the **measured behaviour of the live product diverges from its
intended outcome**. Three sources feed it:

1. **Metrics** — an **actionable** metric (activation, retention, funnel conversion, task success) stalls,
   regresses, or contradicts the release hypothesis. (Ignore vanity metrics that move without meaning.)
2. **Incidents** — a postmortem's contributing cause reveals a wrong assumption or a missing capability,
   not just a bug to patch.
3. **Feedback** — users ask for, struggle with, or work around something the product doesn't do.

## The pivot-or-persevere test

For a candidate signal, decide:

- **Persevere** — the thesis holds; this is ordinary backlog/maintenance work → route to the existing
  roadmap (or `maintain` for upkeep), **not** a new DISCOVER cycle.
- **Pivot / new opportunity** — the signal points at a *different problem worth solving* → frame it as an
  **OPPORTUNITY** and re-enter DISCOVER. This is validated learning becoming the next value cycle.

Only a genuine new-opportunity signal re-enters DISCOVER; routine work stays in the operate loop. This keeps
the re-entry meaningful instead of a treadmill.

## Frame the opportunity

Write `OPPORTUNITY-<slug>.md`: the production evidence (which signal, the numbers, the source), the problem
it points at, who has it, and why it's worth a cycle. This is the seed `market-scanner`/`ideator` expect.

- If **market-scanner** is installed → hand the opportunity to it (`/market-scan`) for adversarial
  validation before it becomes an IDEA.
- If **ideator** is installed but market-scanner is not → hand a validated-enough opportunity to `/ideate`.
- Standalone → the markdown brief IS the artefact; a human carries it forward.

## Product lifecycle (by capability)

When a real **re-entry signal** is confirmed (a new opportunity framed, not routine work), and the **i2p**
plugin is installed, mark the **OPERATE** phase done so the marketplace product lifecycle and the status
line cycle back to **DISCOVER (↻)** — opening the next value cycle:

```bash
/i2p-lifecycle done OPERATE   # order-safe & idempotent — a no-op unless a lifecycle is running at OPERATE
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md` (OPERATE
→ DISCOVER ↻ is the cyclic re-entry described there).

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). When a signal that *should* have
opened a new cycle was missed (the product drifted while everyone watched green dashboards), the fix is a
sharper re-entry signal or a better actionable-metric definition — folded in once, upstream — so the next
loop closes on the right learning sooner.
