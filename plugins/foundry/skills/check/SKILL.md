---
name: check
description: >
  Verify that FOUNDRY's external tool dependencies are installed and reachable on this machine —
  language toolchains, test runners, the Playwright MCP + a browser, debuggers, and language
  servers. Trigger with /foundry:check (or "check foundry prerequisites", "are my foundry tools
  installed?"). Runs a fast ✓/✗ probe grouped by tier (required / recommended / optional). Advisory
  by default (never blocks); pass --strict to fail when a required tool is missing. Reads the
  canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ dependency table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# FOUNDRY — Dependency Check

Confirms the **software musculature** FOUNDRY relies on is present, so a run does not discover a
missing tool halfway through. It does not install anything — it reports, and points at install
guidance.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --tier=recommended
```

## What it checks

The canonical list is [`requirements.tsv`](requirements.tsv) (TAB-separated:
`name · probe · tier · install-hint`). Tiers:

- **required** — FOUNDRY's core needs it (`git`, `bash`).
- **recommended** — materially better: language toolchains, `rust-analyzer`/TS/Python LSP, the
  Playwright MCP + a browser, `lldb`/`debugpy`.
- **optional** — stack-specific: `dx`, `zig`, `cargo-zigbuild`, `vercel`, `cargo-nextest`, …

## Interpreting the result

A `✗` is **not** a failure — FOUNDRY degrades gracefully (e.g. no LSP → it falls back to
`cargo check`/`tsc --noEmit`; no Playwright → web story tests are skipped with a disclosed gap).
Each `✗` prints its install hint (the local source of truth is this skill's `requirements.tsv`).
For the full rationale and Ansible fragments, see the marketplace `PREREQUISITES/` folder —
`10-foundry.md`, `40-mcp.md`, `45-lsp.md` — when foundry is run from the marketplace source tree.

> Keep [`requirements.tsv`](requirements.tsv) as the **single source of truth**: it is what this
> check executes, and the `PREREQUISITES/` prose is curated to match it.
