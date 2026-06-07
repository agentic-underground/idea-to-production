---
description: Incident response — declare severity & roles, mitigate before diagnosing, then generate a runbook and a blameless postmortem.
---

Run the **incident** skill.

Mode from `$ARGUMENTS` (default: `declare`): `declare` (live response), `runbook` (write/lookup the runbook
for a failure mode), or `postmortem` (blameless retrospective after resolution).

- **declare** — set severity (SEV1 outage/data-loss → SEV5 cosmetic; declare early, revise as you learn),
  assign Incident Command roles (IC / Ops-Tech / Comms / Scribe), **mitigate before diagnosing** (roll
  back, fail over, shed load, flag off), and keep a timestamped timeline → `INCIDENT-<id>.md`.
- **runbook** — symptom → detecting golden signal(s) → ordered, copy-pasteable mitigation → escalation.
- **postmortem** — **blameless**: timeline, impact (incl. SLO/error-budget hit), **plural** contributing
  causes, and **owned, dated** action items → `POSTMORTEM-<id>.md`.

Every action item that adds a signal or a runbook feeds `/observability` and self-improvement.
