---
description: Verify FOUNDRY's external tool dependencies are installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the FOUNDRY dependency check. Execute the check script and present its ✓/✗ table to the user,
then briefly summarise what (if anything) is missing and how to install it (point at the marketplace
`PREREQUISITES/` folder and the per-row install hints).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Pass `--strict` to exit non-zero when a **required** tool is missing; `--tier=recommended` to scope.
This is advisory — a missing tool narrows a capability, it does not break FOUNDRY. See the
[`check` skill](../skills/check/SKILL.md) for details.
