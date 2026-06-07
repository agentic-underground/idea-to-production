---
description: Verify CONCIERGE's tool dependencies (jq for clean-JSON hooks/statusline, bash) are installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the CONCIERGE dependency check. Execute the script and present its ✓/✗ table, then summarise
which tools are missing and which surfaces will therefore run on the pure-bash fallback (the hooks
and the status line still work — they just narrow what they show, never failing the session).
Point at the install hints.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. See the
[`check` skill](../skills/check/SKILL.md).
