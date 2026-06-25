---
name: state-discovery
description: Lifecycle state skill for converting IDEATE brief intent into stable implementation intent before formal specification begins.
---

# State Discovery

## Applies To

- Pre-step-0 readiness assessment
- Clarifying actors, goals, boundaries, and constraints from an IDEATE brief
- Evaluating whether a roadmap item is ready for the Development System

## Purpose

An item that enters the Development System with an unclear problem statement, undefined actors, or ambiguous scope will produce rework at every stage. State Discovery prevents that by enforcing a stability check before planning begins.

## Exit Criteria — All must be true before advancing to step-0-plan

- [ ] Problem statement is actionable (a specific, observable problem — not "improve UX")
- [ ] Primary actor(s) are named and their role is clear (not "users" — who specifically?)
- [ ] Scope boundaries are explicit: what IS in scope, what is NOT
- [ ] Constraints are concrete: performance, security, compatibility, platform requirements
- [ ] Success metric is testable: "a user can complete X in under Y seconds" not "better"
- [ ] The item does not duplicate an existing EARS specification (duplicate check done)
- [ ] All open questions from the IDEATE brief have been answered or accepted as risks

## Actions If Exit Criteria Not Met

1. Identify which criteria are not satisfied.
2. Return to IDEATE brief or ROADMAPPER (DISCUSS mode) to resolve.
3. Do NOT allow step-0 to begin until all criteria are met.
4. Document resolved gaps in the handoff payload as accepted risks if they cannot be fully resolved.

## Handoff Target

`ds-step-0-plan` — with a fully resolved IDEATE brief and stable intent.

## Integration

This state skill is called before the FOUNDRY PHASE_POOL begins processing an item. The LEAD ENGINEER or FOUNDRY orchestrator should apply this check when reviewing items for tier assignment.

## KAIZEN Covenant

This skill carries the KAIZEN self-improvement covenant. If items consistently fail Discovery exit criteria in the same way (e.g., actors always underspecified, success metrics always vague), the IDEATE question bank needs enrichment. Flag for the self-improvement covenant ([`kaizen-covenant.md`](../../../knowledge/architecture/kaizen-covenant.md)).
