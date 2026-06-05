# Scoring & the kill rubric — turning a scan into a verdict

> The one-copy home for **how a scan reaches a keep/kill verdict** over the
> [`parameters.md`](parameters.md) taxonomy. Referenced by the `market-scan` skill, never restated.

## The verdict

A candidate opportunity earns one of three verdicts after the scan walks the taxonomy:

| Verdict | Meaning | Condition |
|---|---|---|
| **KILL** | Reject and re-rank. | **Any** hard kill-threshold tripped (see each parameter's kill column), or the conjunction is implausible. Killing early is the point — it is *cheap* here and *expensive* downstream. |
| **PARK** | Promising but not yet decidable. | No hard kill, but ≥ 1 load-bearing parameter is **unknown** and needs evidence (a fake-door test, a few customer conversations, a pricing probe). Record what evidence would resolve it. |
| **KEEP** | Worth refining into an IDEA. | Every category (A–E) clears its kill-threshold and the conjunction holds; the wedge (D) and the channel (E) are *named*, not hand-waved. |

> **THE ONLY WAY — kill on the conjunction, not the average.** Do not average a fatal flaw away. A 9/10
> on demand with no reachable channel is a **KILL**, not a 7. The parameters are gates in series, not a
> weighted sum. (A weak idea that scores "pretty good on average" is the most expensive kind to ship.)

## Scoring each parameter (for ranking, not for rescuing)

Score each parameter ✅ (clears, ideally beats the recommended default), ⚠️ (borderline → an open
question), or ❌ (trips the kill-threshold). Use the scores to **rank surviving candidates** against each
other — never to outvote a single ❌. Present the scorecard as a table the user can scan at a glance.

## The kill ledger (cross-project memory)

Every recurring kill *reason* is worth remembering so future scans reach it faster. Record kills in the
same **symptom → cause → fix** shape FOUNDRY uses for guardrails:

```
### <slug> — <one-line opportunity>
- **Symptom:** what looked attractive (the pull).
- **Cause:** the parameter that sank it (the real reason it fails).
- **Fix → ANTI-PATTERN / GUARDRAIL:** the pattern to recognise next time, so a like candidate is killed
  on sight (e.g. "vitamin dressed as a painkiller", "no budget owner in the buying chain",
  "great product, no acquisition channel").
```

These accumulate via the plugin's `self-improve` loop (and the cross-project ideation feedback), so the
scanner gets sharper — fewer weak candidates survive to refinement over time. This is the
**waste-elimination** pillar applied to discovery: the cost of a bad idea is paid *once*, here.

## Output of a scan

A scan emits a **validated opportunity** (for a KEEP) or a recorded **kill/park** (with the reason):

- the chosen candidate in one sentence;
- the **scorecard** (the A–E table with ✅/⚠️/❌ + the evidence/probe behind each);
- the verdict (KEEP / PARK / KILL) and *why*;
- the **open questions** (the ⚠️ parameters that need evidence) carried forward;
- the **price band** and **first-slice / stack-fit** note (so refinement and the conveyor can act).

A KEEP is what the `ideator` plugin (REFINEMENT) consumes to build the IDEA package **when installed**;
standalone, it is a markdown **opportunity brief**.
