---
id: 12
title: "Roadmap-item documentation + illustration pipeline (PRESSROOM)"
status: COMPLETE
priority: HIGH
added: 2026-06-13
depends_on: "— (atomic; PRESSROOM; token-fairness-gated)"
completed: 2026-06-13 (PR #42)
---

# [12] Roadmap-item documentation + illustration pipeline (PRESSROOM)

**Brief Description**
For each **completed** roadmap item, the orchestrator commissions a PRESSROOM documentation pipeline on
parallel sub-agents: a **sonnet** pass collects, synthesises, and drafts the documentation; an **opus** pass
adversarially reviews it; an **opus** pass produces the final draft. The document is **adaptive** — every
item gets a how-to; a UI/usage section is added only when the item has a user interface, and a
technical/architecture section only when the item introduces structure. In parallel, the illustrator mines
the content for figures and commissions each through a **bounded** loop: a **sonnet** agent draws the initial
concept art, an **opus** adversarial reviewer scores it on the design-fitness rubric, and an **opus**
craft-handler polishes — looping up to **N=4** rounds, accepting early on a passing rubric score, and
shipping the best-scoring draft if the cap is reached. The whole pipeline is scheduled per item as a durable
off-peak job through the token-fairness gate.

### User Stories
- AS a reader I WANT professional, illustrated documentation for each item — how-to always, UI and technical
  sections where relevant — SO THAT the product explains itself as it is built.
- AS the maintainer I WANT the heavy opus work tiered, bounded, and budgeted SO THAT quality is high and the
  token meter is never put at risk.

### EARS Specification
**Event-driven**
- WHEN a roadmap item completes THE SYSTEM SHALL commission its documentation on parallel sub-agents: sonnet
  collect+draft → opus adversarial review → opus final.
- WHEN drafting the document THE SYSTEM SHALL include a how-to for every item, a UI/usage section only where
  the item has a user interface, and a technical/architecture section only where the item introduces structure.
- WHEN the documentation is drafted THE SYSTEM SHALL commission each illustration through a bounded loop
  (sonnet concept → opus review → opus craft), accepting early when the design-reviewer's fitness score meets
  the threshold or the verdict is PASS.
- WHEN an item completes THE SYSTEM SHALL schedule its pipeline as a durable off-peak job with an explicit
  per-item +Xk token ceiling, gating every wave through the `tf` scheduler.
**Unwanted behaviour**
- IF the illustration loop reaches N=4 rounds without a passing score THEN THE SYSTEM SHALL ship the
  best-scoring draft and log that it capped (round count + final score) — it SHALL NOT loop unbounded.
- IF dispatching this pipeline would breach the live token-fairness window or the per-item ceiling THEN THE
  SYSTEM SHALL pause to the ledger and resume off-peak, never running it inline past the gate.
**Optional feature**
- WHERE per-job model selection (#8) is available THE SYSTEM SHALL honour any per-item model overrides for
  these sub-agents.

### Acceptance Criteria
1. Given a completed item, Then an adaptive documentation artefact exists (how-to always; UI/technical
   sections present iff relevant) that passed an opus adversarial review.
2. Given a figure, Then it either passed the rubric within 4 rounds, or the best-scoring draft was shipped
   with a logged cap note — the loop never runs unbounded.
3. Given the token window or per-item ceiling is near its limit, Then the pipeline pauses to the ledger and
   resumes off-peak, not inline.
4. Given a non-UI item, Then no UI/usage section is generated (no wasted opus pass).

### Implementation Notes
- Reuse PRESSROOM `illustrator` (A/B-until-best), `design-reviewer` (fitness score + verdict — the rubric
  gate), and `craft-study` craft-handler; for the doc text, PRESSROOM `writer` + an opus DOCUMENT-REVIEWER.
  Set the agent model tiers explicitly per stage (sonnet draft / opus review / opus final) via the same
  model-override mechanism as #8.
- **Adaptivity inputs:** "has a UI" / "introduces structure" come from the item's own roadmap fields (its
  Human Interface Test Plan presence ⇒ UI; new bounded-context/architecture note ⇒ technical section).
- **Loop guard:** N=4 max rounds, accept on `fitness ≥ threshold` or `verdict == PASS`, else best-so-far +
  cap log. Mirrors the finale (#7) "4×-reviewed stunning" bar.
- **Token governance:** each item is a `tf plan --profile doc --width W` fan-out with a per-item +Xk ceiling;
  queued as a durable off-peak job (22:00–08:00), every wave gated, pause/resume via `tf ledger`.
- Output is reused three ways: the item's docs, the issue annotations (#11), and the wiki (#13).
- Token safety: dispatch only through the `tf` scheduler; cadence is per completed item, never per commit.

### Development Plan Reference
`doc/ROADMAP_ITEM_DOC_PIPELINE_PLAN.md`
