---
description: Instrument & verify observability — the four golden signals, the three pillars, and SLI→SLO→alert definitions.
---

Run the **observability** skill.

Target from `$ARGUMENTS` (default: current repo): a project path or live service.

Verify the **four golden signals** are emitted and queryable (latency — successful vs failed, tails
watched; traffic; errors; saturation of the constrained resource), that the **three pillars** (logs,
metrics, traces) are present and correlated, then propose concrete **SLIs → SLOs → error budgets** and
**actionable alert rules** (page on budget-burn, not raw thresholds; every alert maps to a runbook).

Probe endpoints with `curl`, parse JSON with `jq`, query the metrics/log backend CLI when present — all by
capability; when a tool or telemetry is absent, reason from what's reachable and **name the blind spot**,
never declaring a signal healthy on no evidence. Write `OBSERVABILITY-FINDINGS.md`, or return the findings
section when called by `/operate-gate`.
