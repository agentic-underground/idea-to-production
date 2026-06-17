---
description: Verify FLOW's flow-mcp toolchain (curl, sha256sum, jq, cargo fallback) is installed and reachable — a ✓/✗ table by tier (advisory; --strict to fail on a missing required tool).
---

Run the FLOW dependency check. Execute the script and present its ✓/✗ table, then summarise
which tools are missing and which flow-mcp resolution path is therefore unavailable (retrieve-and-verify
the pinned release vs the cargo source-build fallback) — never a silent wrong roadmap answer. Point at
the install hints and the marketplace `PREREQUISITES/` folder.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. See the
[`check` skill](../skills/check/SKILL.md).
