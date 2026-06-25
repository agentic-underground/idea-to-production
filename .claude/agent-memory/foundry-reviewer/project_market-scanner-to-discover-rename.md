---
name: market-scanner-to-discover-rename
description: PR #264 market-scanner→discover rename; clean functionally; residual = pre-existing bare "scanner" phase-labels (masthead/svg/audit) + new "DISCOVER — Discover" displayName stutter
metadata:
  type: project
---

PR #264 (`chore/rename-market-scanner-to-discover`, commit 0d653ae) renamed plugin
`market-scanner` → `discover`. Skill/command `market-scan` and `/discover:market-scan`
PRESERVED correctly; `discoverability`/`discoverRoutes` not corrupted.

**Functionally clean:** zero tracked `market-scanner` tokens, old dir gone, all 8 source
paths resolve, companions `"discovery":"discover"` correct in i2p+ideate, hooks use
`${CLAUDE_PLUGIN_ROOT}` (path-agnostic), verify-prereqs ALL PASS (H/I/R green).

**Residual (NON-blocking):**
- Bare word `scanner` survives as the DISCOVER phase's owning-plugin LABEL in
  README.md:3 masthead alt-text, docs/images/masthead.svg:53 `<text>scanner</text>`,
  docs/MARKETPLACE_AUDIT_REPORT.md:95 ASCII diagram. **These said `scanner` on main too**
  (the masthead abbreviated `market-scanner`→`scanner` already) — so the rename did NOT
  regress them, but it left them now doubly-stale (neither old nor new name). MEDIUM
  consistency, not a rename-introduced regression.
- plugin.json displayName became `DISCOVER — Discover what's worth building` (was
  `MARKET-SCANNER — Discover...`) — wordmark/verb stutter INTRODUCED by this PR.
  marketplace.json sibling correctly says `DISCOVER — Find what's worth building`. LOW.

**Why:** mechanical wordmark swaps reproduce the [[rename-wordmark-alttext]] class —
verify-prereqs Check I validates link/file existence, NOT label semantics, so bare
phase-labels in SVG/masthead/ASCII art and displayName stutters pass CI green.
**How to apply:** on plugin-rename PRs, grep the masthead/SVG/diagram phase-owner labels
for the OLD abbreviation AND check displayName for `<WORDMARK> — <samewordasverb>` stutter;
both slip past the gate.
