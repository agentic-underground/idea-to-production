---
description: Verify OPERATE's operate tooling (curl, jq, log/metric CLIs) is installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the OPERATE dependency check. Execute the script and present its ✓/✗ table, then summarise
which tools are missing and which operate lenses will therefore run as "partial coverage" (never a silent
"healthy"). Point at the install hints and the marketplace `PREREQUISITES/` folder.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. See the
[`check` skill](../skills/check/SKILL.md).
