# Pillar 3 — Waste Elimination

> **Bindings:** *waste-elimination* ≡ *muda · mura · muri* (incl. *rediscovery* waste). (See the core language in [`../glossary.md`](../glossary.md) and [`../first-principles.md`](../first-principles.md) §1.)

The persistent, rigorous, **systematic** identification and elimination of waste in all its
forms. FOUNDRY applies the lean / Toyota Production System discipline to software development. The
governing intuition:

> **A bug found in development is far less wasteful than a bug found in production.**
> Therefore more (cheap, early) testing is *less* waste, not more work.

## The three Ms — muda · mura · muri

Lean names **three** kinds of loss, and they compound: uneven flow (*mura*) creates overburden
(*muri*), and overburden breeds outright waste (*muda*). FOUNDRY attacks all three.

| The M | What it is | In software it looks like | FOUNDRY's countermeasure |
|---|---|---|---|
| **Muda** (waste) | activity that adds no value | the **seven wastes**, tabled below | the whole pillar — see below |
| **Mura** (unevenness) | irregular flow, bursty load, inconsistent depth | erratic batch sizes; a lumpy work graph (some stations starved, others swamped); reviews of wildly different rigour; knowledge docs at uneven depth | **even flow** — one vertical slice at a time; tiering by token budget; tests-as-coordinates so disjoint work runs at a steady, parallel cadence |
| **Muri** (overburden) | straining a person, agent, or part beyond its sane limit | an over-scoped agent doing more than one thing; a context window stuffed past its budget; a station carrying work that belongs upstream | **token-efficiency** (thin skills, fat references; station-scoped loading) and **self-cleaving** (`architecture/kaizen-covenant.md`) — an element that strains splits into single-purpose parts |

*Muda* is the largest surface, so it gets the detailed treatment: FOUNDRY applies the **seven
wastes** of lean production to software development.

## The seven wastes (muda), applied to software

| Waste | In software it looks like | FOUNDRY's countermeasure |
|---|---|---|
| **1. Overproduction** | building features nobody asked for; speculative abstraction | IDEATOR scopes to the shippable slice; implementation covenant §2 (simplicity first, nothing speculative) |
| **2. Waiting** | a station idle while it waits for an upstream barrier | maximally parallel work graph (tests-as-coordinates, VALUE_FLOW §7); disjoint coordinates run concurrently |
| **3. Transport / hand-off loss** | context dropped between agents; re-deriving what was known | self-contained sentinels + handoff schema; knowledge parity (Pillar 1) |
| **4. Over-processing** | re-stating knowledge; passing whole skills when a fragment is needed; gold-plating | token efficiency (`token-efficiency.md`); define-once knowledge; thin skills |
| **5. Inventory** | half-finished work; large un-merged batches; stale specs | one vertical slice at a time; just-in-time specification; spec freeze |
| **6. Motion / rework** | tests modified to pass; refactoring unrelated code; re-litigating frozen specs | tests are the contract (implementation covenant §5); surgical changes (§3) |
| **7. Defects** | bugs reaching production; regressions; flaky tests | the full assurance chain + perf-delta gate (Pillar 2); 100% coverage floor; flaky-test ban |
| **8. Rediscovery** | re-diagnosing a problem already solved; "it worked yesterday"; drifting versions | **determinism & pinning** (`pillars/determinism-and-pinning.md`): a proven version matrix + zero-drift templates + a **guardrails ledger** (`protocols/guardrails-ledger.md`) so a bug is paid for exactly once |

## The economics
A defect's cost grows by orders of magnitude with each station it survives:

```
caught at TEST  ≪  caught at STORY  ≪  caught in REVIEW  ≪  caught in PRODUCTION
   (cheap)                                                        (catastrophic)
```

Every reviewer gate, every coverage requirement, every perf sample is an **early, cheap**
place to convert a would-be production defect into a development-time finding. This is why
FOUNDRY is aggressively averse to skipping a gate to "save time": the saving is illusory; the
defect just moves to a more expensive station.

## A standing duty, not a phase
Waste elimination is continuous — this is **kaizen**. The `inspector` audits FOUNDRY itself for
accumulated waste (drift, duplication, dead skills). The KAIZEN self-improvement covenant
(`architecture/kaizen-covenant.md`) makes every document responsible for noticing and removing
its own muda, mura, and muri over time. Recurring waste of one kind is a signal to fix the
upstream process, not just the instance.
