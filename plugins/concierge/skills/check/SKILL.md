---
name: check
description: >
  Verify that CONCIERGE's external tool dependencies are installed and reachable — the JSON
  helper its hooks and status line use (jq) and the shell they run in (bash). Trigger with
  /concierge:check (or "check concierge prerequisites", "what does the status line need?").
  Runs a fast ✓/✗ probe grouped by tier. Advisory by default (CONCIERGE degrades gracefully —
  every hook and the renderer fall back to pure-bash when a tool is absent, never failing the
  session); pass --strict to fail on a missing required tool. Reads the canonical manifest
  skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ dependency table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# CONCIERGE — Dependency Check

Shows which tools CONCIERGE's hooks and status line can use, so you know up front whether they
will run with clean JSON (`jq`) or fall back to the pure-bash path. It installs nothing — it
reports and points at install guidance.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

## What it checks

[`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):

- **required** — `bash` (the shell every hook and the renderer run in).
- **recommended** — `jq` (clean JSON parsing for the SessionStart hooks and the status line; a
  pure-bash regex fallback is used when it is absent, so this is a quality-of-life upgrade, not a
  hard dependency).
- **optional** — `git` (the status line's branch field; degrades to harness-provided fields).

## Interpreting the result

A `✗` is never a hard failure — CONCIERGE is built to degrade: the hooks and the status line all
carry pure-bash fallbacks and simply narrow what they show rather than erroring. Each `✗` prints its
install hint (the local source of truth is this skill's `requirements.tsv`).

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
