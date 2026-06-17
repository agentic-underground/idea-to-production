---
name: observability
description: >
  Instrument & verify a live system's observability — the four golden signals (latency, traffic, errors,
  saturation), the three pillars (logs, metrics, traces) present and correlated, and SLI→SLO→alert
  definitions that hold the reliability bar. Trigger with /observability [path] (or "check the golden
  signals", "define SLOs", "is this observable?", "wire up alerts"). Audits what's emitted, names the
  gaps, and proposes concrete SLOs + alert rules. Produces findings consumable standalone or by
  /operate-gate. Self-improving: every unwatched failure becomes a new signal or SLO.
metadata:
  type: scanner
  lens: observability
  output: findings (markdown) → OBSERVABILITY-FINDINGS.md or the operate-gate report
  model: inherit
---

# OBSERVABILITY

You cannot operate what you cannot see. This skill makes a live system **observable**: it verifies the
signals are emitted, defines the targets that make them meaningful, and wires the alerts that page only when
a human must act. Grounded in [`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §1 (SRE).

## What it checks — the four golden signals

For each user-facing service, confirm the **four golden signals** are emitted and queryable:

1. **Latency** — request duration, with **successful and failed latency separated**, and **tails watched**
   (p95/p99), not just the mean (a slow error or a long tail hides in a healthy-looking average).
2. **Traffic** — demand (requests/sec, sessions, transactions/sec).
3. **Errors** — failed-request rate (explicit 5xx, implicit wrong-content, policy "too slow").
4. **Saturation** — fullness of the most-constrained resource (CPU/memory/I/O/queue depth) — the leading
   indicator of imminent degradation.

> Queue/stream/batch systems also want **USE** (Utilization, Saturation, Errors per resource); per-request
> services want **RED** (Rate, Errors, Duration). Golden signals are the user-facing default.

## What it checks — the three pillars

Are **logs, metrics, and traces** all present, and **correlated** (request/correlation IDs, trace
exemplars) so you can pivot from a metric spike to the exact traces and logs behind it? Monitoring answers
*known* questions; observability lets you ask *new* ones. Name any pillar that is absent or un-correlated.

## Define the SLIs → SLOs → alerts

For each golden signal that matters to users:

1. **SLI** — write it as `good events / valid events` read from real telemetry (e.g. `requests with
   status<500 and latency<300ms / all valid requests`). Never assert; measure.
2. **SLO** — propose an **achievable, meaningful** target over a window (e.g. "99.9% over 28 days"). Just
   above what keeps users happy — never an aspirational 100%. State the **error budget** (`1 − SLO`).
3. **Alert** — page on **error-budget burn rate** (fast-burn → page now; slow-burn → ticket), not on raw
   thresholds that fire without action. Every alert must be **actionable** and map to a runbook; a rule that
   fires without a human action is alert fatigue and is a self-improvement signal to delete or tighten it.

## How it runs

- Probe reachable endpoints for health/latency/errors with `curl` (by capability); parse metric/log JSON
  with `jq`; query the metrics/log backend with its CLI (`promtool`, `logcli`, cloud CLI) when present.
- When a tool or telemetry is **absent**, reason from what IS reachable and **name the blind spot** — never
  declare a signal "healthy" on no evidence.

### Degraded capabilities (point-of-use)

When a metrics backend, log source, or probe tool you need is unavailable **at the moment you reach for it**,
follow the degraded-capabilities discipline defined once in
[`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §5 (which references the canonical
contract, `degraded-capabilities.md`): **emit** a `{capability, reason, since_phase}` record (e.g.
`{"capability":"tool.promtool","reason":"metrics backend unreachable","since_phase":"OPERATE"}`) — the inline
`DEGRADED_CAPABILITIES:` marker in your findings, and the `<project>/.i2p/degraded-capabilities.json` state
file when reachable — **route around** the dead source (read what IS reachable), and **disclose** the affected
signal as **partial coverage**, never a "healthy" verdict on no evidence.

## Output

A findings section (standalone `OBSERVABILITY-FINDINGS.md`, or folded into OPERATE-REPORT.md):
present-vs-missing signals, the proposed SLI/SLO/error-budget table, proposed alert rules, and a
**Coverage & Gaps** block naming every unmonitored surface.

## Dogfood — the marketplace observes its own golden signals (P2-18)

The marketplace ships this OPERATE observability lens but must also **turn it on itself** — the cobbler's
children otherwise go unshod. [`scripts/marketplace-golden-signals.sh`](scripts/marketplace-golden-signals.sh)
maps the four golden signals onto the marketplace's **own** deterministic runtime surface — **traffic**
(live plugins / skills / agents / commands / hooks served), **latency** (cold-start: time to enumerate +
`jq`-validate every plugin manifest), **errors** (broken intra-repo references + non-runnable hooks — a dead
reference is a 404 a user hits), **saturation** (the reference error-budget consumed) — and emits a
schema-versioned **health summary** (`marketplace-health/1.0`) the HUD or a CI artifact can read, with a
HEALTHY / WATCH / UNHEALTHY verdict that mirrors `/operate-gate`'s rule (a hard substrate outage never reads
HEALTHY).

It runs as an **external CI job** (`.github/workflows/verify.yml :: marketplace-golden-signals`), **not**
from inside a session — a self-observability lens must survive the thing it observes (a crashed
operate cannot observe its own crash). This is the **HEALTH slice** of the same self-observation
substrate whose **SECURITY slice** is the `secret-scan-self` gitleaks job (P1-11) in the same workflow:
together they dogfood the two lenses the marketplace ships for OPERATE.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/observability/scripts/marketplace-golden-signals.sh" <repo-root> --out marketplace-health.json
```

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). Every incident traced back to a
signal that *wasn't* being watched becomes a new golden-signal/SLI here; every alert that fired without
action becomes a tightened threshold or a deleted rule — folded in once, upstream, so the next system starts
more observable and quieter.
