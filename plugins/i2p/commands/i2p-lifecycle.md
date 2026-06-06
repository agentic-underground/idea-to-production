---
description: Start or report the idea-to-production PRODUCT LIFECYCLE — DISCOVER ▸ IDEATE ▸ DESIGN ▸ BUILD ▸ ASSURE ▸ PUBLISH ▸ IN PRODUCTION. Tracks .i2p/lifecycle.json; the status line shows the phase.
---

Drive the product lifecycle. Follow the [`lifecycle` skill](../skills/lifecycle/SKILL.md):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh $ARGUMENTS
```

- no args / `status` → report the current phase.
- `init [name]` → start a new lifecycle at **DISCOVER**, then route to the phase owner
  (`/market-scan`, then `/ideate`, …) — naming only installed plugins.
- `advance` / `set <PHASE>` → move through the phases at each exit signal.

For the model itself (owners, academic lineage, entry/exit signals), see
[`../knowledge/product-lifecycle.md`](../knowledge/product-lifecycle.md) — or run `/i2p-help`, which
explains the lifecycle and offers to kick one off. Enable the phase widget with `/concierge:statusline`.
