---
name: maintain
description: >
  Keep the lights on — the maintenance cadence for a live product: dependency upkeep and CVE patching,
  certificate/secret rotation, backup-restore drills, capacity review against saturation trends, and
  budgeted tech-debt paydown. Trigger with /maintain [path] (or "what maintenance is overdue?", "check
  the dependencies", "is anything stale?", "tech-debt cadence"). Composes security's /scan-dependencies
  by capability. Produces MAINTENANCE-FINDINGS.md; consumable standalone or by /operate-gate.
  Self-improving: every upkeep emergency becomes a scheduled cadence item.
metadata:
  type: scanner
  lens: maintenance
  output: findings (markdown) → MAINTENANCE-FINDINGS.md or the operate-gate report
  model: inherit
---

# MAINTAIN

Upkeep that is scheduled is hygiene; upkeep that is deferred becomes an incident. This skill keeps a live
product's maintenance on a **cadence** — the rhythm, not the bureaucracy. Grounded in
[`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §4 (ITIL-lite maintenance).

## The cadence — what it reviews

| Cadence item | What "overdue" looks like |
|---|---|
| **Dependency upkeep** | known-vulnerable versions, unpinned/floating ranges, abandoned packages, typosquats |
| **CVE patching** | a published advisory against a shipped dependency or base image, unpatched |
| **Cert & secret rotation** | TLS certs near expiry; long-lived credentials past their rotation window |
| **Backup / restore drill** | for stateful systems, a restore path that has **not** been exercised recently |
| **Capacity review** | saturation trending toward the constrained resource's ceiling (from `observability`) |
| **Tech-debt paydown** | debt that raises change-risk, budgeted *alongside* features — not "someday" |

## Dependency upkeep — compose security (by capability)

For the dependency/CVE rows, **compose `security`'s `/scan-dependencies`** when SECURITY is installed — it
already parses manifests/lockfiles across ecosystems and flags vulnerable/unpinned/abandoned/typosquat
packages. Fold its findings into the maintenance report. When SECURITY is **absent**, fall back to a static
read of the manifests and **note the reduced coverage** — never declare deps clean on no audit.

## Stuck-phase detection (time-in-phase)

A lifecycle phase running far past its budget is invisible drift, not progress — a maintenance signal the
cadence must surface. [`scripts/stuck-phase.sh`](scripts/stuck-phase.sh) reads `<project>/.i2p/lifecycle.json`
`history[]` timestamps, computes time-in-current-phase, and against sensible per-phase budgets (OPERATE is
long-lived by design; BUILD/ASSURE/SECURE/PUBLISH should not sit for days) **prints a proposal** when a phase
is over budget — e.g. *"phase BUILD active 9d (budget 7d) — investigate or advance: `/i2p:lifecycle done
BUILD`"*. It **never auto-advances** (advancing is a human decision) and degrades gracefully on a corrupt or
absent `lifecycle.json`. Run it as part of the cadence:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/maintain/scripts/stuck-phase.sh" --dir <project>
```

Fold an over-budget phase into MAINTENANCE-FINDINGS.md as a cadence item; it is a propose-only advisory, not a
gate.

## Degraded capabilities (point-of-use)

For the dependency/CVE rows, when SECURITY (or any tool you reach for) is **absent at point-of-use**, follow
the degraded-capabilities discipline defined once in
[`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §5 (canonical contract:
`degraded-capabilities.md`): **emit** a `{capability, reason, since_phase}` record (e.g.
`{"capability":"lens.scan-dependencies","reason":"SECURITY not installed","since_phase":"OPERATE"}`) — inline
marker + the `<project>/.i2p/degraded-capabilities.json` state file when reachable — **route around** it (fall
back to the static manifest read), and **disclose** the reduced coverage as **partial**, never "deps clean on
no audit".

## Lightweight change discipline

Changes to a live system are deliberate: a known blast radius, a rollback plan, and — for risky change —
gated by remaining **error budget** (from `observability`). Standard/low-risk upkeep is pre-approved;
significant change is reviewed. (Full change-management ceremony is out of scope; the *discipline* is not.)

## Output

`MAINTENANCE-FINDINGS.md` (or folded into OPERATE-REPORT.md): a cadence table marking each item current /
due / overdue, the scan-dependencies summary, and a prioritised next-actions list (security-relevant upkeep
first, then expiring credentials, then debt). Overdue security upkeep pushes the operate-gate verdict to
WATCH or worse.

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). Every upkeep task that became an
*emergency* (an expired cert, a CVE exploited before patching) is the signal: add it as a **scheduled
cadence item** with a clear "overdue" trigger — folded in once, upstream — so the next cycle catches it on
schedule instead of in an incident.
