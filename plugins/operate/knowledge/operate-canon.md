# OPERATE canon — the named discipline behind OPERATE

> The OPERATE phase is not "watch the dashboards and hope." It is a body of named, battle-tested practice.
> OPERATE grounds every skill in this canon so its judgments cite a discipline, not a vibe. This is
> the local reference the skills point at; it is concrete, not hand-wavy.

OPERATE is the PLM **service/operate** stage carried into software: the product is **realised & live**, and
the job is to keep it healthy, respond when it isn't, learn from how it actually behaves, and feed those
learnings back to DISCOVER (↻). Four named bodies of practice anchor it.

## 1. SRE — reliability as an engineering discipline (Google SRE)

The measurable contract between a service and its users.

- **SLI (Service Level Indicator)** — a *measured* quantity of service health, expressed as a ratio of
  good events to valid events: request success rate, p99 latency under N ms, freshness, correctness,
  durability. An SLI is read from real telemetry, never asserted.
- **SLO (Service Level Objective)** — the *target* for an SLI over a window (e.g. "99.9% of requests
  succeed over 28 days"). The SLO is the reliability bar the team commits to. It must be **achievable and
  meaningful** — set just above what keeps users happy, not at an aspirational 100%.
- **SLA** — the *contractual* consequence of missing an SLO (credits, penalties). OPERATE works at
  the SLI/SLO layer; SLAs are a business wrapper around them.
- **Error budget** — `1 − SLO`. The *permitted* unreliability over the window. A budget that still has room
  means you may ship risky change; a **depleted** budget freezes feature work until reliability is restored.
  The error budget is how reliability and velocity are traded *quantitatively* instead of by argument.
- **The four golden signals** (the SRE book's minimum viable monitoring of any user-facing system):
  1. **Latency** — time to serve a request; **distinguish successful from failed latency** (a fast error is
     still an error, and slow errors can hide in a healthy-looking mean — watch tails, p95/p99).
  2. **Traffic** — demand on the system (requests/sec, sessions, transactions/sec).
  3. **Errors** — rate of failed requests (explicit 5xx, implicit wrong-content, policy "too slow").
  4. **Saturation** — how *full* the service is (CPU, memory, I/O, queue depth) — the leading indicator of
     imminent degradation; measure against the resource that constrains *first*.
  > For queue/streaming/batch systems also watch the **USE** method (Utilization, Saturation, Errors per
  > resource) and the RED method (Rate, Errors, Duration per request) — golden signals are the user-facing
  > default; USE/RED are the resource/request-level complements.
- **Observability ≠ monitoring.** Monitoring answers *known* questions (is the dashboard green?).
  Observability — the **three pillars: logs, metrics, traces** (plus exemplars/correlation IDs that stitch
  them) — lets you ask *new* questions of a running system you didn't anticipate. An OPERATE-ready service
  has all three present and correlated, not just a status page.
- **Toil** — manual, repetitive, automatable, tactical work that scales with load and carries no enduring
  value. SRE caps toil and converts it to automation; recurring toil is a self-improvement signal.

## 2. Incident command — structured response under pressure (ICS / IMS)

Borrowed from emergency services' **Incident Command System**, adapted by the SRE incident-management
practice. The point is to remove ambiguity about *who decides* while the system is on fire.

- **Roles** — **Incident Commander (IC)** owns the response and is the single decision-maker; **Ops/Tech
  lead** drives the technical investigation and mitigations; **Communications lead** owns stakeholder and
  customer updates; **Scribe** keeps the timeline. On a small team one person may wear several hats — but
  the *roles* are explicit, not improvised.
- **Severity (SEV) ladder** — a declared blast-radius/urgency level that sets the response:
  - **SEV1** — critical: full outage or data loss; all-hands, page immediately, exec comms.
  - **SEV2** — major: significant degradation or a key feature down for many users; page on-call.
  - **SEV3** — minor: limited/partial impact with a workaround; handle in business hours.
  - **SEV4/5** — low: cosmetic or single-user; queue as normal work.
  Severity is declared **early and revised** as understanding grows — under-declaring to avoid noise is a
  classic failure mode.
- **Mitigate before you diagnose.** Stop the bleeding (roll back, fail over, shed load, feature-flag off)
  *before* root-causing. Restoring service is the priority; the *why* comes in the postmortem.
- **Blameless postmortem** — after any significant incident, a written, **blameless** retrospective:
  timeline, impact, **contributing causes** (plural — systems fail for many reasons, not one "human
  error"), what went well, and concrete, *owned, dated* action items. Blameless because people who fear
  punishment hide the information you need to prevent recurrence. The output is system change, not blame.

## 3. Build-Measure-Learn — the production feedback loop (Lean Startup)

OPERATE is where the product meets reality, so it is where the **Build → Measure → Learn** loop closes.

- **Instrument for learning, not vanity.** Track **actionable metrics** tied to a hypothesis (activation,
  retention, funnel conversion, task success) over **vanity metrics** (raw pageviews) that feel good but
  drive no decision.
- **Validated learning** — each release is an experiment with a stated hypothesis; production telemetry +
  user feedback either confirm or refute it. The learning, not the code, is the unit of progress.
- **The pivot-or-persevere signal.** When the measured behaviour of the live product diverges from the
  intended outcome — a metric stalls, an incident reveals a wrong assumption, feedback contradicts the
  thesis — that divergence is a **new OPPORTUNITY**. This is the marketplace's **cyclic re-entry**: OPERATE
  hands that opportunity back to **DISCOVER (↻)** to open the next value cycle (the `iterate` skill does
  this, calling `/i2p:lifecycle done OPERATE`). Continuous discovery means the loop never dead-ends at
  launch.

## 4. ITIL-lite maintenance — keep the lights on without ceremony

A lightweight read of ITIL's service-operation/continual-improvement practices — the *cadence*, not the
bureaucracy.

- **Change management (lightweight)** — changes to a live system are deliberate: a known blast radius, a
  rollback plan, and (for risky change) gated by remaining error budget. Standard/low-risk changes are
  pre-approved; significant changes are reviewed.
- **Maintenance cadence** — a recurring rhythm so upkeep never becomes an emergency: dependency upgrades
  and CVE patching (compose `security`'s `/scan-dependencies` by capability when installed), certificate and
  secret rotation, backup/restore drills, capacity review against saturation trends, and **tech-debt**
  paydown budgeted alongside features.
- **Continual service improvement (CSI)** — every cycle, ask what one operational thing to make measurably
  better next: a flaky alert tightened, a runbook added, a toil-task automated, an SLO recalibrated to
  reality. This is the same loop the marketplace's self-improvement covenant demands, expressed in
  operations.

---

## 5. Degraded capabilities — route around a dead tool/MCP/lens, and DISCLOSE

OPERATE runs against live, fallible infrastructure: an MCP server dies mid-session, a telemetry
source is unreachable, a companion lens (`security`'s scan-dependencies) isn't installed. The
discipline is **detect → degrade → disclose**, made machine-checkable, never a silent pass.

**The contract is defined once**, in
[`../../foundry/knowledge/protocols/degraded-capabilities.md`](../../foundry/knowledge/protocols/degraded-capabilities.md)
(the `{capability, reason, since_phase}` record, its two carriers — an inline marker and the
`<project>/.i2p/degraded-capabilities.json` state file — and the consumer rules). OPERATE's
skills are **point-of-use producers AND consumers** of that signal; they reference the contract,
they do not restate it. Three obligations bind every OPERATE skill (P1-15):

1. **Emit at point-of-use.** When a skill reaches for a tool/MCP/lens it needs and finds it
   unavailable — *not* at session start, but in the moment of use — it emits a DEGRADED_CAPABILITIES
   record: the inline marker in its findings (`DEGRADED_CAPABILITIES: [{…}]`), and, when a durable
   writer is reachable, merged additively into `<project>/.i2p/degraded-capabilities.json`. The
   `capability` is namespaced (`mcp.<name>`, `lens.<name>`, `tool.<name>`); the `reason` is concrete;
   `since_phase` is `OPERATE` (or the more specific lifecycle phase if known).
2. **Route around it.** The downstream step whose required capability is degraded takes its
   degraded-but-valid fallback (a static manifest read instead of a live audit, a reachable-endpoint
   probe instead of the full metrics backend) — it does **not** fail the run, and it does **not**
   silently emit an empty result that looks like success.
3. **DISCLOSE — never a silent pass.** The skip is surfaced in the report, naming the capability,
   the reason, and the phase, and the affected coverage is marked **PARTIAL**, never READY/PASS:
   *"ran without the scan-dependencies lens — SECURITY not installed; supply-chain coverage PARTIAL."*

The SessionStart MCP-liveness hook (`hooks/scripts/mcp-liveness.sh`, P1-24) is the crash-surviving
*emitter* for mid-session MCP death (it lives in the hook substrate, not in a skill, so it survives
the crash it detects); the skills below are the point-of-use emitters and the consumers that route
around and disclose.

---

## How the OPERATE skills use this canon

| Skill | Canon it grounds in |
|---|---|
| `operate-gate` | the readiness checklist (golden signals present, SLOs defined, alerts wired, runbooks exist, rollback proven) + the steady-state error-budget/SLO health view |
| `observability` | SRE three pillars + four golden signals + SLI→SLO→alert definition |
| `incident` | ICS roles · SEV ladder · mitigate-before-diagnose · blameless postmortem |
| `iterate` | Build-Measure-Learn · actionable metrics · pivot-or-persevere → re-enter DISCOVER (↻) |
| `maintain` | ITIL-lite change/maintenance cadence + tech-debt + dependency upkeep + stuck-phase detection (§4) |

All five also obey §5 (degraded capabilities): on hitting an unavailable tool/MCP/lens at point-of-use
they emit a record, route around it, and disclose PARTIAL coverage — never a silent pass.

> Self-improvement covenant: if any definition here drifts from how the skills behave or from current SRE
> practice, fix it **here once** — every OPERATE skill that cites this canon inherits the correction.
