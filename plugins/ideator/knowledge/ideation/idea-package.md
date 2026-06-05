# The IDEA package — the deliverable contract

> The one-copy home for **what `/ideate` produces**. The `ideate` skill is a thin router that references
> this; it never restates it. The IDEA package is the ultra-refined source of ideation that FOUNDRY
> carries to PRODUCTION. It has **two faces** — *agent-facing* (precise, for the conveyor) and
> *user-facing* (rich, for the human) — written from one shared, knowledge-parity understanding.

## Face 1 — Agent-facing (simplified · high-precision · high-clarity)

The handoff to FOUNDRY. **Every field is unambiguous, self-contained, and actionable by a fresh agent
with no conversation history.** These align with FOUNDRY's own schemas (by concept — IDEATOR carries its
own copy of the contract; it does not reach across the plugin boundary).

1. **IDEA brief** — the single source of truth:
   ```
   TITLE · SLUG · DATE · PROBLEM (1–3 sentences: the specific pain/gap) ·
   ACTORS (named roles, not "users") · IN-SCOPE (v1 bullets) · OUT-OF-SCOPE (v1 bullets) ·
   CONSTRAINTS (performance · platform · compliance · integration · budget) ·
   SUCCESS-METRIC (testable: "actor can do X in under Y", not "better") ·
   PRICE-BAND (from the opportunity) · LANGUAGE/STACK (which FOUNDRY handler) ·
   WILD-CARD (the outside-the-box observation, if any)
   ```
2. **SMU-seed** — a *subject-matter-understanding* seed: what the product is, who it's for, the problem,
   the **core domain concepts/terms**, the design values (tie-breakers), the hard constraints, and what
   success/failure look like. This is the domain parity FOUNDRY's builder-lead expands into the full SMU.
3. **First vertical slice** — the **smallest shippable, end-to-end increment** that proves the core value
   (so FOUNDRY can cut a thin slice immediately rather than boil the ocean).
4. **Handoff contract** — objective (one sentence), the artifacts + their paths, **open questions /
   accepted risks**, and the next-agent instructions — the compact, history-free payload FOUNDRY ingests.

> **Exit gate (THE ONLY WAY).** The agent-facing package must satisfy FOUNDRY's **discovery exit
> criteria** before hand-off — otherwise it produces rework at every downstream stage:
> - **Problem** is *actionable* (a specific, observable problem — not "improve UX").
> - **Actors** are *named* and their role is clear (not "users" — who, specifically?).
> - **Scope** boundaries are *explicit*: what IS in, what is NOT.
> - **Constraints** are *concrete*: performance, security, compatibility, platform.
> - **Success metric** is *testable*.
> - Every **open question** is answered or *explicitly accepted as a risk*.
> If any criterion is unmet, **do not hand off** — return to the dialogue (or, for a chosen-not-to-resolve
> item, record it as an accepted risk).

## Face 2 — User-facing (rich · illustrated)

The **IDEA dossier** the human reviews and iterates on before committing — graphics, charts, tables:
- the **opportunity narrative** (the problem, the wedge, the why-now);
- the **parameter scorecard** (a table — reuse the market-scanner A–E axes when the opportunity came from
  a scan);
- **market-sizing / pricing / competition charts**;
- the **chosen-idea rationale** and the first-slice picture.

> **Rendering — by capability.** Produce the rich dossier by invoking **pressroom's `/publish`** (format
> `pdf` for a print-quality dossier, `diagrams` for figures) **when pressroom is installed**. When it is
> **absent, degrade to structured markdown** (tables, ASCII/Mermaid-source figures) and say plainly that
> the richer rendering was skipped. Never re-author PDF/diagram rendering here — that is pressroom's job.

## One understanding, two faces

The two faces are **not** two documents written twice — they are one knowledge-parity understanding
projected for two readers. The user-facing dossier *persuades and aligns*; the agent-facing package
*instructs precisely*. They must never disagree: a fact corrected in one is corrected in both. The
package is **iterated with the user** until both faces are right, *then* handed off.

## Where it goes

- **FOUNDRY installed** → hand the agent-facing package to FOUNDRY (its IDEA station receives it by
  capability) → roadmap → `/loop /foundry` builds it.
- **FOUNDRY absent** → write the package under `doc/idea/<slug>/` and point the user at FOUNDRY (or the
  inline dev system) to carry it forward.
