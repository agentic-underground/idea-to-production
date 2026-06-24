---
name: one-browser-chrome-devtools
description: PR #244 ONE BROWSER cutover — marketplace stops shipping @playwright/mcp, drives host chrome-devtools; rename facts + the latent-bug fix
metadata:
  type: project
---

PR #244 "ONE BROWSER" removed the shipped `@playwright/mcp` server (foundry/.mcp.json + deleted atelier/.mcp.json) and migrated to the **host-provided** `chrome-devtools` MCP (unprefixed `mcp__chrome-devtools__*`).

**Why:** the shipped @playwright/mcp defaulted to a Google-Chrome channel headless hosts don't install, and its registry GC corrupted the shared `~/.cache/ms-playwright` (the "flappy chromium" bug). Also fixed a LATENT bug: the 7 handler grants `mcp__playwright__*` (unprefixed) matched NOTHING at runtime (plugin-shipped servers namespace as `mcp__plugin_<plugin>_<server>__*`); the host chrome-devtools is genuinely unprefixed so the new wildcard actually works.

**How to apply (review facts that hold post-merge):**
- Capability id renamed `mcp.playwright`→`mcp.chrome-devtools` everywhere (degraded-capabilities.md, phase-sensor). Consistent single id. Zero `mcp.playwright` survive. NOT generalized to `mcp.browser` — fine; the 5-rule contract is the anti-recurrence move, not the id.
- Residual `@playwright/mcp` / `mcp__playwright__*` mentions live ONLY in `docs/internal/cached-reviews/` + `docs/historical/` (provenance archive, rename-exempt — see [[project_provenance-archive]]). 4 intentional HISTORY mentions in live docs (40-mcp.md ×2, headless-browser.md, live-feedback.md) all clearly narrate the cutover.
- The Playwright **TEST runner** (`npx playwright test`) is deliberately kept — distinct from the browser MCP. Docs keep the distinction; ansible npm.yml keeps `playwright`, drops `@playwright/mcp`.
- check C (shipped-MCP↔40-mcp.md parity) PASSES: parser reads only `|`-rows in "Shipped" table; the chrome-devtools blockquote uses `>` so it's ignored. verify-prereqs ALL GREEN.
- Off-fleet is gracefully degraded (atelier README/plugin.json/note + live-feedback all say "degrades when absent"; phase-sensor routes on mcp.chrome-devtools). Self-containment tenet is about `${CLAUDE_PLUGIN_ROOT}` PATH resolution, NOT bundling deps — host-MCP dependency doesn't violate it.

**Known soft spot (MEDIUM, not a blocker):** 40-mcp.md line 37 states the pinning rule "never a floating @latest", then line 49's manual off-fleet fallback recommends `chrome-devtools-mcp@latest` with no reconciliation. Justified (manual command, not a shipped .mcp.json, so check K doesn't gate) but the @latest tension is left unacknowledged 12 lines after the rule.
