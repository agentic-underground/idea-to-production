---
name: lifecycle-states
description: >
  The lifecycle-state router for the DELIVER conveyor. Use at every maturity boundary of a
  roadmap item to validate that the current state's exit criteria are met before advancing.
  Covers all five boundaries: converting an IDEATE brief into stable implementation intent
  before specification (discovery); formal EARS + Gherkin requirement/behaviour contracts
  before implementation (specification); test-first proof, failure-gap mapping, implementation
  validation, and regression prevention (verification); upstream synchronization, commit
  narrative quality, and delivery transaction completion (delivery); and final release
  confidence assessment, unresolved-risk disposition, and Definition Of Done certification
  (production-readiness). Trigger whenever an item transitions between SDLC steps and you must
  prove the gate before proceeding.
---

# Lifecycle States

> Agent-internal — invoked by the DELIVER conveyor, not typed directly.

The exit-criteria definitions for the DELIVER conveyor. Where `ds-step-*` agents are the
**executors** and `phase-sensor` is the **detector**, these states are the **gate
definitions**: each says exactly what must be true to leave one maturity level for the next.
This is one skill with five state files, loaded on demand (token efficiency — read only the
state you are gating).

> Conceptual model lives in [`../../VALUE_FLOW.md`](../../VALUE_FLOW.md) §4 and the loop model
> in `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/orchestration-loop.md`. The triad —
> executor (`ds-step-*`) / detector (`phase-sensor`) / gate-definition (this skill) — is one
> model viewed three ways, not three competing systems.

## The five states (read the one you are gating)

| Boundary | Gate | Read | Owns advance to |
|---|---|---|---|
| brief → plan | **Discovery** | `states/discovery.md` | `ds-step-0-plan` |
| spec authored | **Specification** (EARS + Gherkin; freeze on pass) | `states/specification.md` | `ds-step-3-tests` |
| RED → GREEN | **Verification** (test-first, gap map, green, regression) | `states/verification.md` | `ds-step-story-tests` / sync |
| green → shipped | **Delivery** (sync, commit narrative, push) | `states/delivery.md` | global DoD audit |
| final gate | **Production-Readiness** (full DoD audit, not a rubber stamp) | `states/production-readiness.md` | item `COMPLETE` |

## How to use
1. Identify the boundary the item is crossing.
2. Open the matching `states/*.md` and check **every** exit criterion.
3. If all pass → emit the advance sentinel (`${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md`) and hand off.
4. If any fail → do **not** advance; return to the owning step, or surface up the line
   (questions flow up — `${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/knowledge-parity.md`).

## Rules carried by every state
- **Specification freeze:** once `FEATURE_COMPLETE`, EARS/Gherkin are frozen; a genuine gap
  is surfaced to DISCUSS mode, never patched in place (`states/specification.md`).
- **Tests are the contract:** never modify a test to make implementation easier
  (`${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/implementation-covenant.md` §5).
- **100% coverage is the floor** at verification and production-readiness
  (`${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md`).
- **Not a rubber stamp:** production-readiness is a full audit; a failed gate opens iteration
  N+1 rather than declaring done with known gaps.
