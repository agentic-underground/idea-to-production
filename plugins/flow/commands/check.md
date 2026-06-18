---
description: Verify FLOW's runtime (Ruby >= 3.3.8 runs flow-mcp, plus jq) is installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the FLOW dependency check. Execute the script and present its ✓/✗ table, then summarise
which tools are missing and whether flow-mcp can therefore start — if Ruby >= 3.3.8 is absent, the
server cannot run and the roadmap is operated via the `/flow:flow-by-hand` runbook instead — never a
silent wrong roadmap answer. Point at the install hints and the marketplace `PREREQUISITES/` folder.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. See the
[`check` skill](../skills/check/SKILL.md).
