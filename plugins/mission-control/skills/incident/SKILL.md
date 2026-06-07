---
name: incident
description: >
  Incident response for a live product — declare severity, assign incident-command roles, mitigate before
  diagnosing, then generate a runbook and a blameless postmortem. Trigger with /incident [declare|runbook|
  postmortem] (or "we have an outage", "triage this incident", "write the postmortem", "what's the
  runbook for X?"). Structures the response under pressure and turns each incident into durable knowledge.
  Produces INCIDENT-<id>.md / POSTMORTEM-<id>.md; consumable standalone or by /operate-gate.
  Self-improving: every incident that surprised us becomes a runbook and an alert.
metadata:
  type: responder
  lens: incident
  output: INCIDENT-<id>.md, a runbook, and/or POSTMORTEM-<id>.md
  model: inherit
---

# INCIDENT

When the system is on fire, ambiguity about *who decides* costs minutes you don't have. This skill brings
the **Incident Command System** discipline to software incidents and converts each one into knowledge so the
next like incident is recognised on sight. Grounded in
[`../../knowledge/operate-canon.md`](../../knowledge/operate-canon.md) §2 (incident command).

## Three modes

```bash
/incident declare      # live response: severity, roles, mitigate-first, timeline
/incident runbook      # write/lookup the runbook for a failure mode (before it happens)
/incident postmortem   # blameless retrospective after a resolved incident
```

## Mode: declare (live response)

1. **Declare severity early** (and revise as you learn — under-declaring is a classic failure):
   - **SEV1** full outage / data loss → all-hands, page, exec comms.
   - **SEV2** major degradation / key feature down for many → page on-call.
   - **SEV3** minor / partial with a workaround → business hours.
   - **SEV4/5** cosmetic / single-user → normal queue.
2. **Assign roles** (one person may wear several on a small team, but name them):
   **Incident Commander** (single decision-maker) · **Ops/Tech lead** (investigates, mitigates) ·
   **Comms lead** (stakeholder/customer updates) · **Scribe** (timeline).
3. **Mitigate before you diagnose.** Stop the bleeding first — roll back, fail over, shed load,
   feature-flag off. Restoring service beats finding root cause; the *why* is the postmortem's job.
4. **Keep a timeline** — detection, declaration, each action + timestamp, mitigation, resolution. The
   scribe's record is the raw material for the postmortem.

Write `INCIDENT-<id>.md` with severity, impact, roles, timeline, and the mitigation applied.

## Mode: runbook (before it happens)

For a named failure mode, write a **mitigate-first runbook**: symptom → the golden signal(s) that detect it
→ immediate mitigation steps (in order, copy-pasteable) → escalation path → links to the relevant
dashboards. Readiness (`/operate-gate readiness`) expects the top failure modes to each have one.

## Mode: postmortem (after resolution)

A **blameless** retrospective — blameless because people who fear punishment hide the information you need:

- **Timeline** (from the incident record) and **impact** (users, duration, SLO/error-budget hit).
- **Contributing causes — plural.** Systems fail for many interacting reasons, never one "human error".
- **What went well / what was luck / what was hard.**
- **Action items** — concrete, **owned, and dated**. Each closes a gap so the class cannot recur.

Write `POSTMORTEM-<id>.md`. Every action item that adds monitoring or a runbook is a self-improvement
signal for the `observability` and `incident` skills.

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). An incident that **surprised** us —
no runbook, no alert, an unwatched signal — is the signal: the fix is a new runbook + a new golden-signal/
alert (via `observability`), folded in once, upstream, so the next operate cycle catches it earlier and the
on-call sleeps.
