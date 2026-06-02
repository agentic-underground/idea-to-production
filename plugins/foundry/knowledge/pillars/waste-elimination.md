# Pillar 3 — Waste Elimination

The persistent, rigorous, **systematic** identification and elimination of waste in all its
forms. FOUNDRY applies the **seven wastes** of lean production to software development. The
governing intuition:

> **A bug found in development is far less wasteful than a bug found in production.**
> Therefore more (cheap, early) testing is *less* waste, not more work.

## The seven wastes, applied to software

| Waste | In software it looks like | FOUNDRY's countermeasure |
|---|---|---|
| **1. Overproduction** | building features nobody asked for; speculative abstraction | IDEATOR scopes to the shippable slice; implementation covenant §2 (simplicity first, nothing speculative) |
| **2. Waiting** | a station idle while it waits for an upstream barrier | maximally parallel work graph (tests-as-coordinates, VALUE_FLOW §7); disjoint coordinates run concurrently |
| **3. Transport / hand-off loss** | context dropped between agents; re-deriving what was known | self-contained sentinels + handoff schema; knowledge parity (Pillar 1) |
| **4. Over-processing** | re-stating knowledge; passing whole skills when a fragment is needed; gold-plating | token efficiency (`token-efficiency.md`); define-once knowledge; thin skills |
| **5. Inventory** | half-finished work; large un-merged batches; stale specs | one vertical slice at a time; just-in-time specification; spec freeze |
| **6. Motion / rework** | tests modified to pass; refactoring unrelated code; re-litigating frozen specs | tests are the contract (implementation covenant §5); surgical changes (§3) |
| **7. Defects** | bugs reaching production; regressions; flaky tests | the full assurance chain + perf-delta gate (Pillar 2); 100% coverage floor; flaky-test ban |

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
Waste elimination is continuous. The `inspector` audits FOUNDRY itself for accumulated waste
(drift, duplication, dead skills). The SOLID self-improvement covenant
(`architecture/solid-covenant.md`) makes every document responsible for noticing and removing
its own waste over time. Recurring waste of one kind is a signal to fix the upstream process,
not just the instance.
