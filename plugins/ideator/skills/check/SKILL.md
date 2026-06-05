---
name: check
description: >
  Verify IDEATOR's external tool dependencies are installed and reachable. Trigger with /ideator:check
  (or "check ideator prerequisites"). Runs a fast ✓/✗ probe grouped by tier; advisory by default,
  --strict to fail on a missing required tool. Reads the canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ dependency table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# IDEATOR — Dependency Check

IDEATOR is mostly a guided dialogue, so its tool surface is small. This confirms the few it uses are
present. It installs nothing — it reports and points at install hints.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

[`requirements.tsv`](requirements.tsv) is the single source of truth. `gh` is recommended so
`self-improve` can open the improvement PR. The rich user-facing dossier is rendered by **pressroom**'s
tools via `/publish` when installed — verify those with `/pressroom:check`, not here. Companions
(`market-scanner`, `foundry`, `pressroom`) are **plugins**, referenced by capability, not probed.
