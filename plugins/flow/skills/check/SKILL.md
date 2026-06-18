---
name: check
description: >
  Verify that FLOW's runtime is present: Ruby >= 3.3.8 (which runs the flow-mcp server — stdlib only, no
  gems), plus git/bash and the optional jq (parse the MCP/roadmap JSON in hooks) and gh. Trigger with
  /flow:check (or "check flow prerequisites", "what flow tools are installed?"). Runs a fast ✓/✗ probe
  grouped by tier. Advisory by default (FLOW degrades gracefully — with no compliant Ruby the
  /flow:flow-by-hand markdown runbook still operates the roadmap by hand); pass --strict to fail on a
  missing required tool. Reads the canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ tool table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# FLOW — Dependency Check

Shows whether the **flow-mcp** server's runtime is present, so a `/flow:flow-setup` run knows up front
whether the MCP can start. flow-mcp is an interpreted **Ruby** server (≥ 3.3.8, standard library only —
no gems, no build, no binary), so the one prerequisite that matters is a compliant Ruby. It installs
nothing — it reports and points at install guidance.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

## What it checks

[`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):

- **required** — `git`, `bash` (the floor every skill needs), and **`ruby` ≥ 3.3.8** — the interpreter
  that runs flow-mcp. On the Debian-13 fleet the system `ruby` already satisfies the floor; elsewhere a
  Homebrew/rbenv/asdf Ruby works. Runtime needs no gems.
- **recommended** — `jq` (parse the MCP/roadmap JSON the hooks read).
- **optional** — `gh` (inspect the repo / releases).

## Interpreting the result

A `✗` is never a hard failure — FLOW degrades gracefully. If `ruby` is missing or below 3.3.8 the server
cannot start, but the `/flow:flow-by-hand` fallback runbook lets the agent operate the roadmap by hand
over the `.flow/` files (same semantics, slower, no server) until Ruby is installed. Each `✗` prints its
install hint (the local source of truth is this skill's `requirements.tsv`); fuller rationale lives in
the marketplace `PREREQUISITES/` folder when run from the marketplace source tree.

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
