# Pillar 1 — Knowledge Parity

> **Bindings:** *knowledge-parity* ≡ *knowledge-alignment*. (See the core language in [`../glossary.md`](../glossary.md) and [`../first-principles.md`](../first-principles.md) §1.)

**The agent fully and clearly understands the ask before it acts.** Parity is the
precondition for everything downstream: a misunderstanding at the IDEA layer is the most
expensive defect there is, because every station amplifies it.

## What parity requires
- **The IDEATOR (PRODUCT_MANAGER) reaches parity with the user first.** It asks clarifying
  questions — one at a time, conversationally — until the brief is actionable (specific,
  observable), the actors are named, scope is bounded (in *and* out), constraints are
  concrete, and the success metric is testable. A vague brief is reflected back and clarified
  before production starts.
- **Every artefact is self-contained.** A brief, a roadmap entry, an EARS spec, a sentinel, a
  handoff payload — each must let a fresh agent with **zero conversation history** proceed
  correctly. This is "cold-start safety." If an agent needs the chat log to act, parity failed.
- **Ambiguity is surfaced, never assumed.** When multiple interpretations exist, the agent
  presents them rather than silently picking one (see `pillars/implementation-covenant.md §1`).

## Questions flow up
A value-station that hits an ambiguity it cannot resolve from its inputs **asks the
PRODUCT_MANAGER**. If the PRODUCT_MANAGER cannot answer satisfactorily, **the user is
consulted.** Production never improvises around a knowledge gap.

```
handler ──question──▶ PRODUCT_MANAGER ──can't answer──▶ user
        ◀──answer (becomes a spec/SMU update so it is never asked twice)──
```

An answer obtained this way is **written back** into the brief, SMU, or spec — so the same
question is never asked twice. This is parity compounding over time.

### When the gap is in the IDEA itself — feedback flows upstream

A subset of these questions reveal that the **IDEA package** (the brief/SMU that arrived from the
upstream `ideator` plugin) was ambiguous where it should have been precise. When that happens, do
**both**:

1. **Per-project write-back** (above) — resolve it into this project's brief/SMU so it is never asked
   again *here*.
2. **Cross-project ideation-feedback** — record a structured entry (*symptom → which IDEA-doc field was
   unclear → what would have prevented it*) routed to the `ideator` / `discover` **self-improve**
   intake. Their KAIZEN self-improvement loop turns recurring entries into a sharpened challenge-protocol
   axis or package field **via a PR**, so every future ideation for *all* users asks the missing question
   by default. The IDEA station's receiver wires this (`skills/ideator/SKILL.md §0.5.1`); the LEARN
   station carries it (`skills/value-station-handoff/SKILL.md`, LEARN). When the `ideator` plugin is
   absent, only step 1 applies — the inline fallback owns the gap.

## Specification freeze
Once parity is reached and the spec is authorized, the spec is **frozen**: implementation
conforms to it, not the other way around. A genuine spec gap found downstream is surfaced
back up the line (DISCUSS mode) and re-authorized — never patched in place to make code easier.
See `specs/ears.md` and `protocols/definition-of-done.md`.

## Parity before deploy — ask, don't assume, the environment

Knowledge parity is not only about the *spec*; it extends to the **environment and prerequisites**
the work needs to reach production. Before a deploy station can run, the agent must reach parity with
the user on what only the user can provide — accounts, interactive auth, and permission-gated
capabilities — rather than discovering the gap mid-deploy.

> **WORKED EXAMPLE:** The `rust-webapp-rollout` skill reaches deploy-parity *before* building by
> asking the user, up front, to confirm: a platform account; the CLI installed and authenticated
> (interactive — user only); the project linked; the permission-gated runtime capability enabled;
> and the preview-vs-production policy. Each answer is written back so it is never asked twice. A
> deploy that *discovers* a missing prerequisite at the deploy station has already failed parity.

> **GUARDRAIL:** Interactive, account-bound steps (logins, linking) are the **user's** to run —
> surface them (e.g. via the `! <command>` form) rather than attempting them blind. Production never
> improvises around a missing credential or capability.

## How parity is carried
| Mechanism | Carries |
|---|---|
| Subject-Matter-Understanding (`orchestration/subject-matter-understanding.md`) | the domain vocabulary all handlers bind to |
| Context sentinel (`protocols/context-sentinel.md`) | machine-readable phase state |
| Handoff schema (`protocols/handoff-schema.md`) | human-readable intent between stations |
