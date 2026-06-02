# Pillar 1 — Knowledge Parity

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

## Specification freeze
Once parity is reached and the spec is authorized, the spec is **frozen**: implementation
conforms to it, not the other way around. A genuine spec gap found downstream is surfaced
back up the line (DISCUSS mode) and re-authorized — never patched in place to make code easier.
See `specs/ears.md` and `protocols/definition-of-done.md`.

## How parity is carried
| Mechanism | Carries |
|---|---|
| Subject-Matter-Understanding (`orchestration/subject-matter-understanding.md`) | the domain vocabulary all handlers bind to |
| Context sentinel (`protocols/context-sentinel.md`) | machine-readable phase state |
| Handoff schema (`protocols/handoff-schema.md`) | human-readable intent between stations |
