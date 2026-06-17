---
name: check
description: >
  Verify that FLOW's external tooling — the flow-mcp launcher's toolchain — is installed and reachable:
  curl (retrieve the pinned release asset), sha256sum/shasum (verify it against the committed pin), jq
  (parse the MCP/roadmap JSON), plus cargo as a dev/source-build fallback. Trigger with /flow:check (or
  "check flow prerequisites", "what flow tools are installed?"). Runs a fast ✓/✗ probe grouped by tier.
  Advisory by default (FLOW degrades gracefully — the launcher resolves the binary lazily and never serves
  a wrong roadmap answer); pass --strict to fail on a missing required tool. Reads the canonical manifest
  skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ tool table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# FLOW — Dependency Check

Shows which tools the **flow-mcp** launcher needs are present, so a `/flow-setup` or `/flow:pull` run
knows up front which resolution path will work — retrieve-and-verify the pinned release, or fall back to a
source build. It installs nothing — it reports and points at install guidance.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

## What it checks

[`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):

- **required** — `git`, `bash` (the floor every skill needs).
- **recommended** — the tools that let the flow-mcp launcher obtain a **verified pinned binary** with no
  Rust toolchain: `curl` (download the release asset from GitHub Releases), `sha256sum`/`shasum` (verify
  the asset against the committed `bin/SHA256SUMS` — a mismatch is refused, never executed), `jq` (parse
  the MCP/roadmap JSON the skills and hooks read).
- **optional** — `cargo` (the **dev/source-build fallback** — only a contributor's machine, or a platform
  with no published release, needs it; never required on a destination), `gh` (inspect release assets / cut
  a new flow-mcp pin).

## Interpreting the result

A `✗` is never a hard failure — FLOW resolves the binary lazily and reports a missing path rather than
serving a wrong roadmap answer. Without `curl`+`sha256sum` the launcher can still use a previously-cached,
pin-verified binary; without `cargo` it simply cannot source-build on an unsupported platform. Each `✗`
prints its install hint (the local source of truth is this skill's `requirements.tsv`); fuller rationale
lives in the marketplace `PREREQUISITES/` folder when run from the marketplace source tree.

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
