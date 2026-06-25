---
name: check
description: >
  Verify that SECURITY's security scanners are installed and reachable — SCA (npm audit, pip-audit,
  cargo-audit, osv-scanner), secrets (gitleaks). Trigger with
  /secure:check (or "check security prerequisites", "which scanners are installed?"). Runs a fast
  ✓/✗ probe grouped by tier. Advisory by default (SECURITY degrades gracefully — a missing scanner
  narrows a lens to partial coverage, never a false PASS); pass --strict to fail on a missing
  required tool. Reads the canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ scanner table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# SECURITY — Dependency Check

Shows which security scanners are present so a `/scan-all` run knows, up front, which lenses
will be authoritative vs heuristic. It installs nothing — it reports and points at install guidance.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

## What it checks

[`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):

- **required** — `git`, `bash`.
- **recommended** — the scanners that turn a lens from heuristic to authoritative: `pip-audit`,
  `cargo-audit`, `osv-scanner`, `gitleaks`.
- **optional** — ecosystem/extra scanners: `govulncheck`, `trivy`, `grype`/`syft`, `trufflehog`, …

## Interpreting the result

A `✗` is never a hard failure — SECURITY's three core lenses also run on pattern-matching alone and
**report the gap** rather than passing silently. Each `✗` prints its install hint (the local source
of truth is this skill's `requirements.tsv`).

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
