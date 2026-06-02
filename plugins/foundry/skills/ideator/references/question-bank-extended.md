# Extended Question Bank

> **For IDEATOR §3.2.** Use these when the core question bank (Q1–Q8) is exhausted and
> the brief still has gaps. Group questions by domain. Pick the most relevant 1–2; do
> not present the whole list to the user.

---

## Technical Architecture

- "Are there existing APIs, databases, or services this must integrate with?"
- "Does this need to run offline, or is a live connection acceptable?"
- "What are the expected data volumes — hundreds of records, millions, more?"
- "Is there a latency requirement (e.g., response within 200ms)?"
- "Does this need to be multi-tenant, or is it single-user/single-org?"

## Security & Compliance

- "Will this handle personal data, financial data, or regulated information?"
- "Are there authentication or authorisation requirements beyond the existing system?"
- "Does this need audit logging — who did what, when?"
- "Are there geographic data-residency requirements?"

## Operability & Reliability

- "What does acceptable downtime look like — best-effort, or SLA-bound?"
- "Does this need rollback capability if a deployment goes wrong?"
- "Should there be monitoring or alerting built in from day one?"

## UX & Accessibility

- "Who is the least technical person who will use this, and what do they need?"
- "Does this need to work on mobile, desktop, or both?"
- "Are there accessibility requirements (WCAG level, screen reader support)?"

## Business & Prioritisation

- "Is there a deadline or event driving this — a launch, a customer commitment?"
- "What happens if we don't build this — what is the cost of inaction?"
- "Is there a competing approach already being considered?"
- "Who owns this feature post-launch — who will maintain it?"

## Innovation Probes (use §3.4 style — one only)

- "Have you considered making this self-service, so users can configure it without
  engineering involvement?"
- "Could this be generalised to serve multiple teams rather than just one?"
- "What if users could extend this themselves — via plugins, scripts, or templates?"
- "Have you looked at how [named competitor or adjacent tool] solves this? Are there
  lessons there?"
