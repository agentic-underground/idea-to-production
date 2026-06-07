---
name: check
description: >
  Verify that MISSION-CONTROL's operate tooling is installed and reachable — an HTTP prober (curl) for
  health checks, jq for parsing metric/log JSON, plus optional log/metric/observability CLIs (a
  Prometheus/Loki client, kubectl, the cloud provider CLI). Trigger with /mission-control:check (or
  "check mission-control prerequisites", "what operate tools are installed?"). Runs a fast ✓/✗ probe
  grouped by tier. Advisory by default (MISSION-CONTROL degrades gracefully — a missing CLI narrows a
  lens to partial coverage, never a false "healthy"); pass --strict to fail on a missing required tool.
  Reads the canonical manifest skills/check/requirements.tsv.
metadata:
  type: diagnostic
  output: a ✓/✗ tool table (stdout); exit 0 advisory, non-zero only with --strict
model: claude-haiku-4-5
---

# MISSION-CONTROL — Dependency Check

Shows which operate tools are present so an `/operate-gate` or `/observability` run knows, up front, which
lenses will be authoritative vs heuristic. It installs nothing — it reports and points at install guidance.

## Run it

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh            # advisory ✓/✗ table
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh --strict   # exit 1 if a REQUIRED tool is missing
```

## What it checks

[`requirements.tsv`](requirements.tsv) (`name · probe · tier · install-hint`):

- **required** — `git`, `bash` (the floor every skill needs).
- **recommended** — the tools that turn a lens from heuristic to authoritative: `curl` (HTTP health
  probes — the golden-signal "errors/latency" lens), `jq` (parse metric/log/probe JSON).
- **optional** — observability/platform CLIs that deepen a lens when the live system uses them:
  `promtool`/`logcli` (Prometheus/Loki), `kubectl` (workload health & saturation), `aws`/`gcloud`/`az`
  (cloud metrics & logs), `gh` (incident/issue automation).

## Interpreting the result

A `✗` is never a hard failure — MISSION-CONTROL's lenses also reason from whatever telemetry is reachable
and **report the gap** rather than declaring "healthy" on no evidence. Each `✗` prints its install hint
(the local source of truth is this skill's `requirements.tsv`); fuller rationale lives in the marketplace
`PREREQUISITES/` folder when run from the marketplace source tree.

> [`requirements.tsv`](requirements.tsv) is the single source of truth — it is what this check runs.
