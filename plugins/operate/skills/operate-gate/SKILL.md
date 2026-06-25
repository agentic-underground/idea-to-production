---
name: operate-gate
description: >
  The OPERATE front door. Two jobs, one report: an operational-READINESS check at/before go-live (are the
  four golden signals instrumented, SLOs defined, alerts wired, runbooks written, rollback proven?), and
  the steady-state HEALTH view of a live product (SLO attainment, error-budget burn, open incidents,
  maintenance debt). Trigger with /operate-gate [readiness|health|path]. Produces OPERATE-REPORT.md with a
  READY / WATCH / NOT-READY verdict. Composes the observability, incident, iterate, and maintain skills.
  Standalone on any live project, or the steady state the i2p OPERATE phase reports against.
metadata:
  type: orchestrator
  output: OPERATE-REPORT.md (verdict READY | WATCH | NOT-READY)
  composes: [observability, incident, iterate, maintain]
model: inherit
---

# OPERATE-GATE

One command, one report, one verdict. OPERATE-GATE is the front door to OPERATE: it certifies a
product is **ready to live in production**, and — once live — gives the **steady-state health view** of how
the mission is actually flying. Mission control does not end at launch; it *begins* there.

Grounded in [`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) (SRE SLIs/SLOs/error
budgets, the four golden signals, incident command, build-measure-learn, ITIL-lite maintenance).

---

## Quick start

```bash
/operate-gate              # full: readiness checklist + steady-state health → OPERATE-REPORT.md
/operate-gate readiness    # go-live readiness only — run before/at PUBLISH→OPERATE
/operate-gate health       # steady-state health only — the recurring "how is it flying?" view
/operate-gate ./service    # operate a specific subproject
```

---

## Two modes, one front door

```
                    ┌─ observability   (golden signals · SLOs · alerts)  ─┐
/operate-gate ─┼─ incident        (open incidents · runbook coverage) ─┼─▶ consolidate ─▶ verdict
                    └─ maintain        (deps · debt · cadence)            ─┘
                       (+ iterate surfaces the re-entry signal, if any)
```

### Mode A — Readiness (at go-live)

The operational-readiness checklist. A product is **READY** to OPERATE only when each line is evidenced,
not asserted:

| Readiness line | Evidence (canon) |
|---|---|
| **Golden signals instrumented** | latency / traffic / errors / saturation are emitted and queryable (`observability`) |
| **SLOs defined** | each user-facing SLI has an achievable, written SLO + error budget |
| **Alerts wired** | every SLO has an alert that pages on budget burn — and *only* on actionable conditions |
| **Logging & tracing present** | the three observability pillars are correlated (request/correlation IDs) |
| **Runbooks exist** | the top failure modes have a written, mitigate-first runbook (`incident`) |
| **Rollback proven** | a rollback / feature-flag-off / failover path exists and has been exercised |
| **On-call defined** | someone is reachable; the incident roles (IC/comms/scribe) are named |
| **Backups/restore drilled** | for stateful systems, a tested restore path (`maintain`) |

A missing line is a **gap, never a silent pass** — it lands in the report's Gaps section and pushes the
verdict to WATCH or NOT-READY.

### Mode B — Health (steady state)

The recurring "how is the mission flying?" view of a live product:

- **SLO attainment & error-budget burn** — are we inside budget? is the burn rate accelerating?
- **Golden-signal snapshot** — current latency tails, traffic, error rate, saturation headroom.
- **Open incidents & their severity** — anything live, anything un-postmortemed.
- **Maintenance debt** — unpatched CVEs, unpinned/abandoned deps, overdue rotations, tech-debt cadence.
- **Re-entry signal** — has a metric/incident/feedback signal crossed into "this is a new opportunity"?
  (surfaced by `iterate` — see Product lifecycle below).

---

## The verdict rule

| Verdict | Condition | Meaning |
|---|---|---|
| **NOT-READY** | a readiness line is missing that would leave an incident undetectable or unrecoverable (no monitoring, no rollback, no on-call), **or** an active SEV1/SEV2 incident | Do **not** treat as operable. Close the gap first. |
| **WATCH** | readiness complete but with caveats, **or** error budget burning hot / SLO at risk / overdue maintenance | Operable, but a named risk needs attention. |
| **READY** | every readiness line evidenced; SLOs inside budget; no open major incident; maintenance current | Cleared to operate — or flying clean. |

The verdict is the **worst across all lenses** — a clean dependency audit never offsets a missing rollback
path. A lens that cannot run (missing tool/telemetry) **cannot return READY for that lens**; it returns
WATCH with the gap noted (no false "healthy").

---

## OPERATE-REPORT.md structure

```markdown
# Operate Report — <project>
**Date:** YYYY-MM-DD   **Mode:** readiness|health|full   **Verdict:** READY | WATCH | NOT-READY

## Executive Summary
| Lens | Status | Highest risk | Coverage |
|------|--------|--------------|----------|
| Observability (golden signals · SLOs) | ✓/⚠/✗ | … | full/partial |
| Incident (open · runbook coverage)    | ✓/⚠/✗ | … | … |
| Maintenance (deps · debt · cadence)   | ✓/⚠/✗ | … | … |

## Readiness checklist        (each line: evidenced ✓ / gap ✗ + why)
## Steady-state health        (SLO attainment, error-budget burn, golden-signal snapshot)
## Open incidents
## Re-entry signal            (is there a new opportunity for DISCOVER? — from iterate)
## Gaps & coverage            (what was NOT checked, and why — tools/telemetry missing)
## Next actions               (prioritised: NOT-READY blockers → WATCH risks → hygiene)
```

---

## Graceful degradation

- A lens whose tool is missing (no `curl` for probes, no metrics CLI) runs what it can from reachable
  telemetry and marks the lens **partial coverage** — never a false READY.
- Composes `secure`'s `/scan-dependencies` for the maintenance lens **by capability** (only if installed);
  notes the gap otherwise.
- Stands alone on any live repo; lights up the companions automatically when present.

This degradation is **machine-checkable**, not ad-hoc. Per the contract defined once in
[`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §5 (canonical:
`degraded-capabilities.md`): when a sub-lens (`observability`/`incident`/`maintain`) cannot run because a
tool/MCP/lens is unavailable at point-of-use, it **emits** a `{capability, reason, since_phase}` record
(inline + `<project>/.i2p/degraded-capabilities.json`). OPERATE-GATE **reads** that state file when present,
**routes around** the dead lens, and reflects it in the report: the lens's row shows **partial** coverage,
its gap is named in **Gaps & coverage**, and — per the verdict rule — that lens **cannot return READY**. A
degraded lens yields WATCH-with-gap, never a silent PASS over a check that did not run. The SessionStart
MCP-liveness hook (`hooks/scripts/mcp-liveness.sh`) pre-populates the state file with any MCP that died, so
a mid-session MCP death is already disclosed by the time the gate runs.

---

## Self-improvement covenant

OPERATE-GATE inherits the covenants of its sub-skills (covenant:
[`../../knowledge/covenant.md`](../../knowledge/covenant.md)). Additionally: every time a real incident is
*not* caught by a READY verdict, a readiness line or a verdict condition is tightened so the same class
cannot pass again — the next gate starts stricter than the last.

## Product lifecycle (by capability)

OPERATE-GATE reports the steady state of the **OPERATE** phase. It does **not** advance the lifecycle on its
own — OPERATE ends only when a learning becomes a new opportunity, which the [`../iterate/SKILL.md`](../iterate/SKILL.md)
skill detects and acts on (calling `/i2p:lifecycle done OPERATE` → DISCOVER ↻). When this gate's **Re-entry
signal** section finds such a signal, hand off to `/iterate`. The canonical model is
`i2p/knowledge/product-lifecycle.md`; degrades silently when i2p is absent.
