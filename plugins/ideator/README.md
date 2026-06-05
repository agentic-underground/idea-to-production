# IDEATOR — Refine an idea into a build-ready IDEA package

> The bridge from *a candidate worth pursuing* to *a thing the conveyor can build*.

IDEATOR is the **REFINEMENT** phase of the `idea-to-production` marketplace. It takes a validated
opportunity (from [`market-scanner`](../market-scanner/)) or a raw idea you already have, refines it to
**knowledge-parity** through an adversarially-challenged dialogue, and emits the **IDEA package**.

## The IDEA package — two faces, one understanding

- **Agent-facing** (precise, high-clarity, for the conveyor): an **idea brief**, an **SMU-seed**, the
  **first vertical slice**, and a **handoff contract** — that satisfies FOUNDRY's **discovery exit
  criteria** (actionable problem, named actors, explicit scope, concrete constraints, testable success).
  This is what FOUNDRY ingests; it must be unambiguous to a fresh agent with no history.
- **User-facing** (rich, illustrated): the **IDEA dossier** — opportunity narrative, parameter scorecard,
  market/pricing/competition charts — rendered via [`pressroom`](../pressroom/)'s `/publish` **by
  capability** when installed; degrades to structured markdown otherwise.

The two faces never disagree: a fact corrected in one is corrected in both. The package is **iterated with
you** until both are right, *then* handed off.

## How it composes

- **market-scanner → IDEATOR**: a kept opportunity is refined here. Or bring your own raw idea — IDEATOR
  starts the dialogue from scratch.
- **IDEATOR → foundry**: the agent-facing package is handed to [`foundry`](../foundry/)'s IDEA station
  (by capability) → roadmap → `/loop /foundry` carries it to PRODUCTION. **IDEATOR supersedes FOUNDRY's
  inline ideator**, which remains as the graceful-degradation fallback when this plugin is absent.
- The arc: **DISCOVER (market-scanner) → IDEATE (ideator) → BUILD (foundry) → SECURE/PUBLISH
  (sentinel/pressroom)**. *Graceful enhancement* — no hard dependency in any direction.

## The feedback loop

When a downstream builder hits an ambiguity the IDEA package *should* have resolved, that feedback flows
back: the corresponding challenge axis or package field is **sharpened via a PR**, so every future
ideation, for all users, asks the missing question by default. The spark gets sharper over time.

## Governed by the marketplace covenant

IDEATOR holds the **three pillars** (knowledge-parity, quality-first, waste-elimination) under the
**token-efficiency** constraint, and the **SOLID self-improvement covenant**
([`knowledge/covenant.md`](knowledge/covenant.md)). Refinement to knowledge-parity *is* its whole job.

Verify your tools with **`/ideator:check`**. Dual-licensed **MIT OR Apache-2.0**.
