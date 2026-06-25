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
  output: doc/opportunities/opportunity-<slug>.md → DISCOVER re-entry (↻)
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
   not just a bug to patch. A concrete carrier of this signal is the **action-item ledger** (written by
   `incident`'s postmortem): run the detector to surface postmortem action items that were never landed —
   an **un-closed / overdue** fix is exactly such a divergence and a re-entry candidate:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/incident/scripts/overdue-action-items.sh" --dir <project>
   ```
   Weigh each overdue item below: a recurring-class fix that keeps slipping is a pivot signal, not just
   backlog. (The detector PROPOSES; advancing the lifecycle stays a human decision.)
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

Write the brief to **`doc/opportunities/opportunity-<slug>.md`** — the **same path and schema** DISCOVER
already consumes (this is market-scanner's opportunity-brief location and shape, so the re-entry artefact
is literally the contract `/market-scan` ingests, not a parallel format). Capture: the production evidence
(which signal, the numbers, the source), the problem it points at, who has it, and why it's worth a cycle.
This is the seed `market-scanner`/`ideator` expect.

> **Schema note — one contract.** The file uses **market-scanner's opportunity-brief schema** (the
> candidate in one sentence; the A–E scorecard / open questions where known; the price band; a
> first-slice / stack-fit note — see `market-scan/SKILL.md` "Output"). What `/iterate` adds is the
> **production-evidence** preamble (the signal that surfaced it). DISCOVER reads this file directly in its
> **thesis-validation mode** — it does not re-derive the opportunity from scratch.

- If **market-scanner** is installed → hand the file to it (`/market-scan`) for adversarial **validation**
  of this specific thesis before it becomes an IDEA (its thesis-validation mode ingests
  `doc/opportunities/opportunity-<slug>.md` directly).
- If **ideator** is installed but market-scanner is not → hand a validated-enough opportunity to `/ideate`.
- Standalone → the markdown brief IS the artefact; a human carries it forward.

### Round-trip example (OPERATE ↻ DISCOVER)

A worked close of the cycle, showing the shared contract end-to-end:

1. **Signal (OPERATE).** Activation has stalled at 38% for three releases; the postmortem ledger shows a
   recurring "users abandon at the import step" theme — a divergence between measured and intended outcome.
2. **Pivot test → new opportunity.** This isn't backlog upkeep; it points at a *different problem* (the
   import flow is the wrong wedge for a new segment). `/iterate` writes
   **`doc/opportunities/opportunity-self-serve-import.md`** — the production evidence preamble plus the
   market-scanner brief skeleton (one-sentence candidate, the segment, the price-band guess, open
   questions).
3. **Re-entry (DISCOVER).** The operator runs **`/market-scan doc/opportunities/opportunity-self-serve-import.md`**.
   Market-scan recognises the handed file, enters **thesis-validation mode**, and scores *that* thesis
   against the A–E taxonomy (it does not propose fresh candidates) — upholding, parking, or killing it.
4. **Onward.** An upheld thesis flows to `/ideate` as a validated opportunity; the loop has closed on a
   shared artefact, not a re-narration. `/i2p:lifecycle done OPERATE` (below) cycles the phase to DISCOVER.

## Product lifecycle (by capability)

When a real **re-entry signal** is confirmed (a new opportunity framed, not routine work), and the **i2p**
plugin is installed, mark the **OPERATE** phase done so the marketplace product lifecycle and the status
line cycle back to **DISCOVER (↻)** — opening the next value cycle:

```bash
/i2p:lifecycle done OPERATE   # order-safe & idempotent — a no-op unless a lifecycle is running at OPERATE
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md` (OPERATE
→ DISCOVER ↻ is the cyclic re-entry described there).

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). When a signal that *should* have
opened a new cycle was missed (the product drifted while everyone watched green dashboards), the fix is a
sharper re-entry signal or a better actionable-metric definition — folded in once, upstream — so the next
loop closes on the right learning sooner.
