# The IDEA package — the deliverable contract

> The one-copy home for **what `/ideate` produces**. The `ideate` skill is a thin router that references
> this; it never restates it. The IDEA package is the ultra-refined source of ideation that FOUNDRY
> carries to PRODUCTION. It has **two faces** — *agent-facing* (precise, for the conveyor) and
> *user-facing* (rich, for the human) — written from one shared, knowledge-parity understanding.

## Face 1 — Agent-facing (simplified · high-precision · high-clarity)

The handoff to FOUNDRY. **Every field is unambiguous, self-contained, and actionable by a fresh agent
with no conversation history.** These align with FOUNDRY's own schemas (by concept — IDEATE carries its
own copy of the contract; it does not reach across the plugin boundary).

1. **IDEA brief** — the single source of truth:
   ```
   TITLE · SLUG · DATE · PROBLEM (1–3 sentences: the specific pain/gap) ·
   ACTORS (named roles, not "users") · IN-SCOPE (v1 bullets) · OUT-OF-SCOPE (v1 bullets) ·
   CONSTRAINTS (performance · platform · compliance · integration · budget) ·
   SUCCESS-METRIC (testable: "actor can do X in under Y", not "better") ·
   PRICE-BAND (from the opportunity) · LANGUAGE/STACK (which **registered** FOUNDRY value-handler — if
   none maps, the stack-fit flag fired in the challenge protocol and its resolution is recorded here) ·
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
- the **parameter scorecard** (a table — reuse the discover A–E axes when the opportunity came from
  a scan);
- **market-sizing / pricing / competition charts**;
- the **user-flow** (how the actor moves through the first slice) and, where the idea is a UI, a
  **mockup screen** of the key view;
- the **chosen-idea rationale** and the first-slice picture.

> **Rendering — by capability (and carefully composed, not first-draft).** Produce the dossier's figures by
> capability, never re-authoring rendering here:
> - **Charts, scorecards, market/pricing diagrams** → **publish** `/publish` (`pdf` for a print-quality
>   dossier, `diagrams` for figures) when installed — the **handler-mermaid** picks the right diagram
>   type and themes it, and the **design-reviewer** critiques it.
> - **User-flows and UI mockups** → **design** `/mockup` when installed — it *designs* the flow/screen to
>   the canon and runs the **convergent designer↔reviewer loop** so the user sees a considered artefact,
>   not a whipped-up sketch. (Flows render as themed Mermaid; mockups as reviewed screens.)
> - **Companions absent** → degrade to structured markdown (tables, ASCII / Mermaid-**source** figures, a
>   text flow) and say plainly that the richer rendering + design review were skipped. Quality still
>   matters: even the markdown flow is ordered and labelled, not a brain-dump.

> **Tie to the slice.** The user-flow and mockup are not decoration — they *visualise the first vertical
> slice* (Face 1 §3) and the **slice** challenge axis, so the user confirms the same thing the conveyor
> will build. A flow that contradicts the slice is a parity failure, caught here.

## One understanding, two faces

The two faces are **not** two documents written twice — they are one knowledge-parity understanding
projected for two readers. The user-facing dossier *persuades and aligns*; the agent-facing package
*instructs precisely*. They must never disagree: a fact corrected in one is corrected in both. The
package is **iterated with the user** until both faces are right, *then* handed off.

## On-disk layout

When the package is written to disk (FOUNDRY absent, or for archival), it takes a **fixed shape** so a
fresh FOUNDRY — or any agent — finds every face of the package by path, with no conversation history.
`<slug>` is the kebab-case `SLUG` field from the IDEA brief (e.g. `task-manager-app`).

```
doc/idea/<slug>/
  brief.md        # agent-facing — the IDEA brief (Face 1 §1): TITLE · SLUG · DATE · PROBLEM · ACTORS ·
                  #   IN/OUT-OF-SCOPE · CONSTRAINTS · SUCCESS-METRIC · FIRST-SLICE pointer. Markdown, labelled fields.
  smu-seed.md     # agent-facing — the SMU seed (Face 1 §2): domain, core concepts/terms, user mental
                  #   model, technical landscape, success/failure definition. Markdown prose, ~200 words. FOUNDRY expands this.
  first-slice.md  # agent-facing — the first vertical slice (Face 1 §3): EARS statement, acceptance
                  #   criteria, stack hint. Markdown with an EARS block + a checklist.
  handoff.md      # agent-facing — the handoff contract (Face 1 §4): objective, entry criteria for
                  #   FOUNDRY, what the challenger verified, knowledge-parity confirmation, open questions / accepted risks. Markdown.
  dossier.md      # user-facing — the IDEA dossier (Face 2): narrative summary, PRICE-BAND, naming
                  #   candidates, the persuade-and-align read. Markdown prose (figures embedded when publish/design rendered them).
```

A worked reference of this layout ships under
[`plugins/ideate/examples/doc/idea/task-manager-app/`](../../examples/doc/idea/task-manager-app/).

## Where it goes

- **FOUNDRY installed** → hand the agent-facing package to FOUNDRY (its IDEA station receives it by
  capability) → roadmap → `/loop /foundry` builds it.
- **FOUNDRY absent** → write the package under `doc/idea/<slug>/` (the **On-disk layout** above) and
  point the user at FOUNDRY (or the inline dev system) to carry it forward.
