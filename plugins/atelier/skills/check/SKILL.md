---
name: check
description: >
  Verify ATELIER's external tool dependencies are installed and reachable. Trigger with /atelier:check (or
  "check atelier prerequisites"). Runs a fast ✓/✗ probe grouped by tier; advisory by default, --strict to
  fail on a missing required tool. Reads the canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ dependency table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# ATELIER — Dependency Check

ATELIER reviews with built-in vision (the `Read` tool sees PNGs — no API key) and drives live browsers via
the **host-provided `chrome-devtools` MCP** (ONE BROWSER — not bundled). Its tool surface is small; this
confirms the few it uses are present. It installs nothing — it reports and points at install hints.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

[`requirements.tsv`](requirements.tsv) is the single source of truth. The **host-provided `chrome-devtools`
MCP** drives the **system Chromium** (ONE BROWSER — atelier ships no MCP); the committed-snapshot crawler
launches via `npx`/`node`. A Chromium browser is needed for live crawls (the host points chrome-devtools at
the system Chromium; the crawler uses the target project's Playwright).
`gh` is recommended so `self-improve` can open the improvement PR. User-flow rendering is **publish**'s
job via `/publish` — verify those with `/publish:check`, not here. Companions (`publish`, `foundry`,
`ideate`) are **plugins**, referenced by capability, not probed.
