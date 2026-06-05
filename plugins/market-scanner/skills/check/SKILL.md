---
name: check
description: >
  Verify MARKET-SCANNER's external tool dependencies are installed and reachable. Trigger with
  /market-scanner:check (or "check market-scanner prerequisites"). Runs a fast ✓/✗ probe grouped by
  tier; advisory by default (never blocks), --strict to fail on a missing required tool. Reads the
  canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ dependency table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# MARKET-SCANNER — Dependency Check

MARKET-SCANNER is mostly a guided dialogue, so its tool surface is small. This confirms the few it does
use are present. It installs nothing — it reports and points at install hints.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

[`requirements.tsv`](requirements.tsv) is the single source of truth (`name · probe · tier · hint`).
`gh` is recommended so `self-improve` can open the improvement PR; companions (`ideator`, `pressroom`,
`foundry`) are **plugins**, referenced by capability, not probed here.
