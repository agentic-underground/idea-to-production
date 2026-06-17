---
description: Run the FOUNDRY production cycle — ingest the ROADMAP, plan, tier by token budget, and drive items idea→product through the value-flow conveyor.
---

Run a FOUNDRY cycle.

> **This is the internal BUILD engine.** The intuitive user-facing verb is
> [`/flow:pull`](../../flow/commands/pull.md), which selects the next `.i2p/roadmap/` backlog item,
> carries it, and drives it through *this* command. The owner's directive (roadmap [106],
> [`docs/SLASH_COMMANDS.md`](../../../docs/SLASH_COMMANDS.md)) is that `/foundry:foundry` is
> non-intuitive — *"I want to pull from the backlog" ≠ "/foundry:foundry"* — so prefer `/flow:pull`.
> `/foundry:foundry` remains available as the engine `/flow:pull` wraps (e.g. to run the whole backlog,
> or an estimate-only cycle).

1. Read `${CLAUDE_PLUGIN_ROOT}/VALUE_FLOW.md` to ground yourself in the conveyor, the three
   pillars, and the orchestration hierarchy (§9).
2. Invoke the **founder** agent (COO) to establish knowledge-parity and define/confirm the
   value-stations, then delegate the cycle:
   - **builder-lead** plans the cycle from `ROADMAP.md` (SMU, decomposition, tiering, token
     budgets → `FOUNDRY_PLAN.md`).
   - **lifecycle-orchestrator** drives each item through steps 0–9 + story, enforcing reviewer
     and perf-delta gates.
3. Honour every pillar: parity before build, the full quality chain to STORY at 100% coverage,
   and aggressive waste elimination. Pass only each station's required context (token efficiency).

If `$ARGUMENTS` names a scope ("estimate only", a specific roadmap item, "what would this
cost?"), respect it — e.g. stop after `builder-lead`'s estimate for a cost-only request.
