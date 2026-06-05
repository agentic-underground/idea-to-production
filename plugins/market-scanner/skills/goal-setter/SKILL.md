---
name: goal-setter
description: >
  Set or refine the standing DISCOVERY GOAL that scans run over. Trigger with /goal (or "set a discovery
  goal", "I want to find a SaaS in <niche>", "refine the goal", "loosen the constraints"). Captures the
  constraints on WHAT to discover (niche, builder edge, target price band, stack-fit, effort appetite,
  hard constraints) — infer-first, one question at a time with a recommended answer + multiple-choice —
  and writes them to .market-scanner/goal.md so /market-scan and /loop scan a bounded space.
metadata:
  type: producer
  output: .market-scanner/goal.md (the standing discovery objective)
model: inherit
---

# MARKET-SCANNER — Goal-setter

A `/goal` bounds the search so scans are focused, not infinite — the constraints on *what to discover*,
distinct from an IDEA (*one chosen thing to build*). The full field set and the loop it drives live in
[`../../knowledge/discovery/goal-loop.md`](../../knowledge/discovery/goal-loop.md).

## How to run

1. Read `.market-scanner/goal.md` if present (refining, not starting fresh).
2. Fill the fields **infer-first** — domain/niche interest, builder edge, target price band, stack-fit
   (which FOUNDRY handlers), effort/time-to-MVP appetite, hard constraints. Ask only what blocks a
   decision, **one focused question at a time, each with a recommended answer + multiple-choice**. A
   left-blank field means "open — surprise me", which is valid (a wider search).
3. Write `.market-scanner/goal.md` (create `.market-scanner/` if absent) and confirm the goal back to the
   user in a compact block.
4. Offer the next move: run `/market-scan` once, or `/loop /market-scan` to iterate over the goal until a
   candidate earns a keep verdict.

> Keep the goal **tight enough to focus, loose enough to surprise.** Over-constrained goals starve the
> scan (only already-killed shapes appear); under-constrained goals scatter it. When a loop keeps
> returning killed shapes, the fix is usually here — loosen one constraint or shift the niche.

Carries the SOLID self-improvement covenant ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)).
