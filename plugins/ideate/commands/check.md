---
description: Verify IDEATE's external tool dependencies are installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the IDEATE dependency check. Execute the script and present its ✓/✗ table, then summarise anything
missing and how to install it.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. The rich dossier's
renderers belong to publish (`/publish:check`). See the [`check` skill](../skills/check/SKILL.md).
