---
description: Run the OPERATE gate — go-live readiness + steady-state health → OPERATE-REPORT.md with a READY/WATCH/NOT-READY verdict.
---

Run the consolidated **operate-gate** skill.

Mode from `$ARGUMENTS` (default: `full`): `readiness` (go-live operational-readiness checklist — golden
signals instrumented, SLOs defined, alerts wired, runbooks written, rollback proven, on-call named),
`health` (steady-state SLO attainment, error-budget burn, open incidents, maintenance debt, re-entry
signal), `full` (both), or a project path.

Compose the lenses — **observability** (golden signals · SLOs · alerts), **incident** (open incidents ·
runbook coverage), **maintain** (deps · debt · cadence) — and write `OPERATE-REPORT.md` with one verdict:

- **NOT-READY** — a readiness line missing that leaves incidents undetectable/unrecoverable, or an active
  SEV1/SEV2; do not treat as operable.
- **WATCH** — operable but a named risk needs attention (budget burning hot, overdue maintenance).
- **READY** — every line evidenced; SLOs inside budget; no open major incident; maintenance current.

The verdict is the worst across all lenses. A lens that cannot run (missing tool/telemetry) reports partial
coverage — never a false READY. This is the OPERATE front door; it reports the phase's steady state and
hands a confirmed re-entry signal to `/iterate`. Degrades gracefully when companions/tooling are absent.
