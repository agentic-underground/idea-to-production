---
description: Verify SECURITY's security scanners (SCA, secrets) are installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the SECURITY dependency check. Execute the script and present its ✓/✗ table, then summarise
which scanners are missing and which security lenses will therefore run as "partial coverage" (never
a silent PASS). Point at the install hints and the marketplace `PREREQUISITES/` folder.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. See the
[`check` skill](../skills/check/SKILL.md).
