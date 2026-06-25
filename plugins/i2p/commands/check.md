---
description: Consolidated readiness — run every installed idea-to-production plugin's /check and merge the ✓/✗ results into one table by plugin, with a short summary of what's missing and how to install it.
---

Run the marketplace-wide dependency check. Follow the [`check` skill](../skills/check/SKILL.md):

0. First probe **i2p's own** dependencies — the `jq`/`bash`/`awk`/`git` its welcome hooks and the status
   line use (`bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS`) — and include those rows
   under an **i2p** group.
1. For each **installed** plugin that ships a `/check` (discover, ideator, foundry, atelier,
   security, publish, operate), run it — pass `$ARGUMENTS` through (e.g. `--strict`, `--tier=recommended`).
2. Consolidate every ✓/✗ row into **one table grouped by plugin**, then summarise what is missing and
   how to install it (use the per-row install hints).
3. Name any plugin that is **not** installed so the picture is complete.

This is advisory — a missing tool narrows a capability, it does not break the marketplace. With
`--strict`, report a non-OK overall status when any **required** tool is missing.
