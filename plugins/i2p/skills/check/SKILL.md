---
name: check
description: >
  Consolidated marketplace readiness. Use for /i2p:check (or "are all my tools installed?",
  "check the whole marketplace", "what's missing across the plugins?"). Runs every installed
  plugin's /check and merges the ✓/✗ results into one table grouped by plugin, then summarises
  what's missing and how to install it. Thin: it delegates to each plugin's check, it owns no
  probes of its own.
metadata:
  type: orchestrator
  output: one consolidated ✓/✗ readiness table (advisory; --strict to flag missing required tools)
  composes: [each installed plugin's /check]
model: inherit
---

# i2p — Consolidated dependency check

The specialist plugins each ship a `/check`. This runs them all and gives you **one** readiness picture,
so you don't have to remember to probe each plugin separately — and, because i2p now also ships the
welcome hooks and the status line (the arrival layer, folded into i2p), it **first probes its own**
tool dependencies (`jq`/`bash`/`awk`/`git` — the tools those hooks and the renderer use) before
consolidating the rest.

> **Stance — advisory, never a false PASS.** A missing tool **narrows a capability**, it does not break
> the marketplace. Report gaps plainly; with `--strict`, surface a non-OK overall status when a
> **required** tool is missing.

---

## 0. Probe i2p's own dependencies first

i2p ships SessionStart welcome/status-line hooks and the two-line ANSI status line. They all degrade to a
pure-bash fallback when a tool is absent (never failing the session), but `jq` gives clean JSON and `awk`
drives the gauges. Run i2p's own dependency probe and include its rows in the consolidated table under an
**i2p** group:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict              # exit 1 if a REQUIRED tool is missing
```

It reads the canonical manifest [`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):
`bash` (required — the shell every hook and the renderer run in), `jq` + `awk` (recommended — clean JSON
for the hooks and numeric gauges for the status line; pure-bash fallback otherwise), `git` (optional — the
status line's branch field). A `✗` is never a hard failure here.

## 1. Run each installed plugin's check

For each plugin that is **installed** and ships a check, run it, passing `$ARGUMENTS` through
(`--strict`, `--tier=recommended`, …):

| Plugin | Check |
|---|---|
| discover | `/discover:check` |
| ideator | `/ideator:check` |
| foundry | `/foundry:check` |
| atelier | `/atelier:check` |
| security | `/security:check` |
| publish | `/publish:check` |
| operate | `/operate:check` |

Prefer running them in parallel. Do **not** re-implement any probe here — each plugin's check reads its
own canonical `skills/check/requirements.tsv`.

## 2. Consolidate

Merge every row into **one table grouped by plugin**: `plugin · tool · tier · ✓/✗ · install hint`.
Then a one-line summary: `<N> present, <M> missing (<K> required)` across the suite.

## 3. Summarise & guide

- Call out the **required** gaps first (these are the ones that matter), then recommended/optional.
- Point at the per-row install hints.
- Name any plugin that is **not installed** so the picture is complete (e.g. "security not installed —
  no security tooling checked").

---

## Self-improvement covenant

Inherits the front door covenant (`knowledge/covenant.md`). If a tool a plugin needs isn't being
checked, the fix is upstream in **that plugin's** `requirements.tsv` — not a patch here.
