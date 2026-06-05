---
description: Verify ATELIER's external tool dependencies are installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the ATELIER dependency check. Execute the script and present its ✓/✗ table, then summarise anything
missing and how to install it.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. ATELIER reviews with
built-in vision (no API key); live crawls use the **Playwright MCP** + a Chromium browser. User-flow
rendering belongs to pressroom (`/pressroom:check`). See the [`check` skill](../skills/check/SKILL.md).
