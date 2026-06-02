---
name: development-system-core
description: Use when orchestrating lifecycle execution of an IDEATOR item across SDLC steps 0-9, including stage maturity checks, quality gates, and iterative progress to Definition Of Done.
---

# Development System Core

## Purpose

Provide operational guardrails for lifecycle maturity progression. Every stage agent and the orchestrator must consult this skill to understand what "done" means at each maturity level and what actions are prohibited until that maturity is reached.

## Maturity Ladder

| Level | Name | Condition |
|---|---|---|
| M0 | Idea captured | Problem and actor intent recorded; no implementation intent |
| M1 | Planned | Plan and requirements (EARS) complete; Gherkin contracts approved |
| M2 | Behavior documented | Gherkin scenarios cover happy/unhappy/abuse; mapped to EARS IDs |
| M3 | Tests authored | Failing tests prove gap; infrastructure stable; gap map documented |
| M4 | Implemented | Implementation satisfies tests; spec intent confirmed |
| M5 | Release workflow complete | Sync, commit, push, roadmap/plan closure done |
| M6 | DoD audit complete | All Definition Of Done gates satisfied; orchestrator marks COMPLETE |

## Required Checks Per Stage

Before a stage agent can mark its stage complete:

1. **Objective clarity**: Exactly one primary outcome for the stage is met.
2. **Contract references**: All upstream artifacts are explicitly cited in the handoff payload.
3. **Evidence quality**: Produced artifact is complete, specific, and reviewable.
4. **Handoff completeness**: Downstream instructions are explicit, imperative, and testable.

## Prohibited Actions

| Action | Prohibited until |
|---|---|
| Writing Gherkin scenarios | M1 (EARS complete) |
| Writing test code | M2 (Gherkin approved) |
| Writing production code | M3 (tests RED, gap map documented) |
| Running green test suite | M4 (implementation complete) |
| Committing and pushing | M5 (post-sync green suite confirmed) |
| Marking item COMPLETE | M6 (global DoD audit passed) |

## Commands For Agents

- **Never skip stage order** without explicit orchestrator override.
- **Never accept stage completion** without reviewer-gate pass.
- **Always emit handoff payload** in the schema defined in `${CLAUDE_PLUGIN_ROOT}/skills/handoff-protocol/SKILL.md`.
- **Always read DEFINITION_OF_DONE.md** before stage execution.
- **Always validate the incoming sentinel** before beginning work.

## Integration With FOUNDRY

When operating inside a FOUNDRY cycle, this maturity ladder maps to FOUNDRY's PHASE_POOL:

| FOUNDRY Phase | DS Maturity | DS Steps |
|---|---|---|
| Pre-cycle | M0 | IDEATOR brief |
| EARS-AGENT | M1 | step-0, step-1 |
| FEATURE-AGENT | M2 | step-2 |
| TEST-AGENT | M3 | step-3, step-4 |
| IMPLEMENT-AGENT | M4 | step-5, step-6 |
| STORY-AGENT | M4.5 | step-story-tests (emits STORY_PROVEN) |
| DELIVERY-AGENT | M5 | step-7, step-8, step-9 (emits DELIVERY_COMPLETE) |
| FOUNDRY completion | M6 | global DoD audit |

> `step-story-tests` is mandatory. Items cannot reach M5 without `STORY_PROVEN`
> in the sentinel chain. Skipping the story step is the most common silent
> coverage gap in TDD pipelines.

## Dependencies

- `${CLAUDE_PLUGIN_ROOT}/skills/roadmapper/SKILL.md` — roadmap lifecycle management
- `${CLAUDE_PLUGIN_ROOT}/skills/code-quality/SKILL.md` — code design reference
- `${CLAUDE_PLUGIN_ROOT}/skills/handoff-protocol/SKILL.md` — stage handoff schema
- `${CLAUDE_PLUGIN_ROOT}/skills/reviewer-gate/SKILL.md` — reviewer enforcement rules

## State Skill Exit Criteria

At each maturity transition, the orchestrator reads the corresponding state skill
to validate that all exit criteria are satisfied before advancing:

| Maturity transition | State skill | Exit criteria govern |
|---|---|---|
| Pre-M0 → M1 | `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/discovery.md` | Brief readiness before planning |
| M1 → M2 | `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/specification.md` | EARS and Gherkin quality bar |
| M2 → M4 | `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/verification.md` | Test-first proof and green evidence |
| M4 → M5 | `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/delivery.md` | Sync, commit, push quality bar |
| M5 → M6 | `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/production-readiness.md` | Full DoD certification |

## SOLID Covenant

This skill carries the SOLID self-improvement covenant. If maturity gates are consistently violated (stages skipped, handoffs missing fields, DoD audit finding the same gate failing repeatedly), update the Prohibited Actions table and the Required Checks to be more explicit. Precision here prevents waste downstream.
