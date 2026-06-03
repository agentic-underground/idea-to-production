---
name: state-specification
description: Lifecycle state skill for formal requirement and behavior contract creation (EARS and Gherkin) before implementation.
---

# State Specification

## Applies To

- step-1-ears (EARS specification)
- step-2-feature-docs (Gherkin feature documentation)
- The transition between these steps and their reviewer checks

## Purpose

Specification state governs the quality bar for requirements (EARS) and behavior contracts (Gherkin) before test code is written. A specification approved at this state is frozen — implementation must conform to it.

## Exit Criteria for EARS (step-1 complete) — All must be true

- [ ] EARS set is complete for this roadmap item (all actors, all constraints covered)
- [ ] Every EARS statement is uniquely ID'd (e.g., `EARS-042`)
- [ ] Each statement uses a recognized EARS form correctly (Ubiquitous/Event-driven/State-driven/Unwanted/Optional)
- [ ] No EARS statement is untestable ("shall be performant" is rejected — must specify measurable threshold)
- [ ] No EARS statement contradicts an existing one in the full specification
- [ ] EARS-REVIEWER: PASS
- [ ] SMU-REVIEWER: PASS (vocabulary consistent with domain)

## Exit Criteria for Gherkin (step-2 complete) — All must be true

- [ ] Every EARS statement has ≥ 3 scenarios: happy path, unhappy path, abuse/adversarial path
- [ ] Every scenario is tagged `@EARS-{ID}` for at least one EARS ID
- [ ] Given-When-Then structure is correct throughout
- [ ] Scenarios are written in SMU domain language (not code language)
- [ ] Every scenario is independently runnable (no inter-scenario dependencies)
- [ ] BDD-REVIEWER: PASS
- [ ] COVERAGE-REVIEWER: PASS

## Specification Freeze Rule

Once Gherkin has passed reviewer gate and the `FEATURE_COMPLETE` sentinel is issued, the specification is **frozen**. No changes to EARS statements or Gherkin scenarios are permitted during steps 3–9 unless:
1. A genuine spec gap is discovered during implementation (stop, surface to orchestrator, return to DISCUSS mode).
2. The orchestrator explicitly authorizes a new iteration.

## Handoff Target

`ds-step-3-tests` — with complete EARS IDs, approved Gherkin scenarios, and all reviewer gates passed.

## SOLID Covenant

This skill carries the SOLID self-improvement covenant. If specification gaps are consistently found during implementation (spec freeze being broken by necessary corrections), the EARS question bank or Gherkin abuse-path coverage is insufficient. Flag for the self-improvement covenant ([`solid-covenant.md`](../../../knowledge/architecture/solid-covenant.md)).
