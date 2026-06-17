---
description: Start or report the idea-to-production PRODUCT LIFECYCLE — DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE ↻ (nine phases forming a cycle, with the BUILD ⇄ ASSURE ⇄ SECURE loop). Tracks .i2p/lifecycle.json; the status line shows the phase.
---

Drive the product lifecycle. Follow the [`lifecycle` skill](../skills/lifecycle/SKILL.md):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh $ARGUMENTS
```

- no args / `status` → report the current phase.
- `init [name]` → start a new lifecycle at **DISCOVER**, then route to the phase owner
  (`/market-scan`, then `/ideate`, …) — naming only installed plugins.
- `done <PHASE>` → mark a phase complete; advances to the next **only if** currently at `<PHASE>`
  (order-safe, idempotent). This is what each owning plugin calls at its exit signal.
- `fail <ASSURE|SECURE>` → the loop **back-edge**: a failed quality/security gate re-enters **BUILD**
  (records the loop iteration in `loop_pass`) instead of advancing. Order-safe; only the two loop gates.
- `advance` / `set <PHASE>` → move through the phases by hand.

For **token-cost** (actual vs estimate per phase, + the self-calibrating estimator) run the sibling
`skills/lifecycle/scripts/cost.sh report .`; the status line shows live spend (`◇ session`, `◈ life`).
See [`../knowledge/instrumentation.md`](../knowledge/instrumentation.md).

For the model itself (owners, academic lineage, entry/exit signals), see
[`../knowledge/product-lifecycle.md`](../knowledge/product-lifecycle.md) — or run `/i2p:help`, which
explains the lifecycle and offers to kick one off. Enable the phase widget with `/i2p:statusline`.
