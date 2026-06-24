# Why the scheduler would have organised this build as haiku → sonnet → opus → review

> **The discipline this pipeline applies:** every handler authored through this handler-build pipeline
> (research → synthesis → build → review) is routed to the pinned-version-matrix + FORBIDDEN-list covenant
> in [`../../../plugins/foundry/knowledge/orchestration/handler-authoring-discipline.md`](../../../plugins/foundry/knowledge/orchestration/handler-authoring-discipline.md).
> The four-wave shape proven below **is** that doc's four-wave build pipeline — this is the run that derived it.

This pipeline was **not** shaped by preference. Given the four phases of "produce a value-handler
from research", the token-fairness scheduler's routing rule emits this exact shape — tiers, wave
widths, off-peak ordering, and consent — deterministically. This document records the proof, run on
this machine.

## The rule

`token-fairness/scheduler/0.1.0/knowledge/cognition-routing.md`:

> `best_fit = cheapest tier whose ceiling ≥ the unit's cognition floor` — never downgrade below the
> floor to save tokens; `discernment` escalates to opus when a wrong PASS would propagate (gates,
> security).

| cognition_class | tier | applied to building a value-handler |
|---|---|---|
| `mechanical` | haiku | web-research harvest — high-volume, low-judgement, recoverable |
| `discernment` | sonnet | synthesis into a knowledge wall — recoverable judgement, reconcile + summarise |
| `thought-intensive` | opus | authoring the handler — one error cascades into *every future build* that spawns it |
| `discernment --escalate` | opus | adversarial review — a false PASS propagates undetected (it **is** a gate) |

## The proof (actual `tf route` output, this machine)

```
$ tf route --cognition mechanical        --name research-fanout   --width 12
  → "best_fit_tier":"haiku"   per_tier_usd {haiku:0.528, sonnet:1.584, opus:2.64}
$ tf route --cognition discernment       --name synthesis-fanout  --width 4
  → "best_fit_tier":"sonnet"  per_tier_usd {haiku:0.176, sonnet:0.528, opus:0.88}
$ tf route --cognition thought-intensive --name handler-authoring --width 4
  → "best_fit_tier":"opus"    per_tier_usd {haiku:0.176, sonnet:0.528, opus:0.88}
$ tf route --cognition discernment --escalate --name handler-review --width 4
  → "best_fit_tier":"opus"    (escalated: review is a gate)
```

`best_fit_tier` = **haiku / sonnet / opus / opus** — the same tiers the user named, assigned purely
from each phase's cognition floor with **no human tier-picking**. The user's intuition and the
scheduler converge because both obey one principle: *the cheapest tier that is still correct for the
work's cognition floor.*

The shape extends past tiers:

- **Wave width** — fan-out-wide → narrow → one-per-handler — is the profiles' `max_parallel`:
  haiku 8, sonnet 4, opus 2. Cheap-and-parallel up front, expensive-and-serial at the end.
- **Off-peak ordering** — research is `mechanical` + `offpeak_eligible:true` (safe unattended);
  authoring + review stay in-session (`offpeak_eligible:false`, fragile, user-reviewed).
- **Consent** — a value-handler fan-out is `budget_directive_required:true`; the **+400k** cap is
  mandatory, not optional. Without it the scheduler refuses to fan out.

## Discipline applied to this run

```
$ tf plan --class large
  💰 ~250k tokens · p95 ±60% · SEEDING (0 samples)
  🕒 Schedule: DEFER → off-peak 22:00–08:00 (now is peak; est is large)
$ tf plan-open large 376000      → bracketed; baseline_tokens captured
$ tf ledger init . build-4-handlers … 400000 15   → 4 units
$ tf gate --headroom 15          → ASK / no-live-signal  (fail-closed)
```

Two honest notes, recorded rather than hidden:

1. **The stamp advised DEFER** (peak hours, large class, 0 samples → wide ±60% band). The user, present
   and reviewing, **overrode with explicit run-now + a +400k hard cap**. A consented override by a
   present operator is legitimate; the per-wave gate remains the ceiling guard.
2. **The gate returned `no-live-signal`** in this session — `tf` has no live `rate_limits` payload
   here, so the **L1 live-ceiling guard is blind**. Protection therefore rests on **L2: the +400k
   consent cap, enforced structurally** by bounded fan-out width (12 haiku + 4 sonnet + 4 opus
   author + 4 opus review = 24 tightly-sized units) rather than by an automated live veto. This is
   the scheduler's own fail-closed posture — *no signal → ASK, never silently CONTINUE* — surfaced to
   the operator instead of papered over.

At completion the job is closed with `tf plan-close` so the actual session-token delta feeds the
estimator's convergence (currently SEEDING → first sample).
