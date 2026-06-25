---
description: Run the DELIVER production cycle — ingest the ROADMAP, plan, tier by token budget, and drive items idea→product through the value-flow conveyor.
---

Run a DELIVER cycle.

> **This is the standalone BUILD cycle** (a human-run, whole-`ROADMAP.md` orchestration). For an i2p
> **v2 pipeline** project, day-to-day delivery is the **FLEET continuous-delivery engine's** job, not
> this command: author the roadmap with **`/roadmapper`** (which emits the `docs/roadmap/` v2 EPIC/PLAN
> pipeline), then let the engine drain it (`/pipeline:run`, status via `/pipeline:status`) — the engine
> invokes DELIVER's **PLAN-scope entry** (builder §2.5) per slice. `/deliver:build` remains for a
> deliberate one-off cycle on a legacy `ROADMAP.md`, or an estimate-only run.

1. Read `${CLAUDE_PLUGIN_ROOT}/VALUE_FLOW.md` to ground yourself in the conveyor, the three
   pillars, and the orchestration hierarchy (§9).
2. Invoke the **founder** agent (COO) to establish knowledge-parity and define/confirm the
   value-stations, then delegate the cycle:
   - **builder-lead** plans the cycle from `ROADMAP.md` (SMU, decomposition, tiering, token
     budgets → `DELIVER_PLAN.md`).
   - **lifecycle-orchestrator** drives each item through steps 0–9 + story, enforcing reviewer
     and perf-delta gates.
3. Honour every pillar: parity before build, the full quality chain to STORY at 100% coverage,
   and aggressive waste elimination. Pass only each station's required context (token efficiency).

If `$ARGUMENTS` names a scope ("estimate only", a specific roadmap item, "what would this
cost?"), respect it — e.g. stop after `builder-lead`'s estimate for a cost-only request.
