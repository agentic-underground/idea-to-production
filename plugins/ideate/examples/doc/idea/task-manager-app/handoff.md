# Handoff contract — TaskFlow

> Agent-facing. The compact, history-free payload FOUNDRY ingests at its IDEA station. A fresh agent
> can act on this with no conversation history.

## Objective

Build TaskFlow's first vertical slice — a local-first, keyboard-first task capture-and-complete loop —
so an indie developer can offload a task and mark it done in under 5 seconds.

## Artifacts

| Artifact | Path |
|---|---|
| IDEA brief | [`brief.md`](./brief.md) |
| SMU seed | [`smu-seed.md`](./smu-seed.md) |
| First vertical slice | [`first-slice.md`](./first-slice.md) |
| User-facing dossier | [`dossier.md`](./dossier.md) |

## Entry criteria for FOUNDRY (discovery exit gate — all met)

- **Problem is actionable** — scattered to-dos / no friction-free single-user capture tool; observable,
  specific (not "improve UX").
- **Actors are named** — the solo indie developer, role and context clear (not "users").
- **Scope is explicit** — IN-SCOPE and OUT-OF-SCOPE enumerated in `brief.md`.
- **Constraints are concrete** — platform (browser, no install), performance (< 100 ms add), compliance
  (no accounts/PII, local-only), budget (zero recurring infra).
- **Success metric is testable** — capture-to-complete under 5 seconds, keyboard-only, no docs.
- **First slice is end-to-end** — capture → render → persist → complete, the irreducible loop.

## What the challenger verified

- **Slice axis** — the chosen first slice is genuinely the smallest end-to-end increment; nothing
  smaller proves the core value, nothing in it is removable without breaking the loop.
- **Scope discipline** — projects, tags, due dates, sync, multi-user were each challenged and pushed
  OUT of v1; none is load-bearing for the success metric.
- **Stack fit** — vanilla JS + `localStorage` maps to a registered FOUNDRY value-handler; no stack-fit
  flag fired.
- **Metric testability** — the 5-second / keyboard-only metric is observable and falsifiable.

## Knowledge-parity confirmation

The user-facing dossier and this agent-facing package were projected from **one** shared understanding
and reconciled: the dossier's described loop (capture → see → complete) matches the first slice's EARS
statement exactly. No fact disagrees between the two faces.

## Open questions / accepted risks

- **Accepted risk** — `localStorage` is per-browser and not synced; a user clearing site data loses
  tasks. Acceptable for v1 (local-first is the deliberate posture); sync is the named future paid tier.
- **Open question (deferred, not blocking)** — exact keyboard shortcut for "complete" (Enter on a
  focused task vs. a dedicated key). FOUNDRY decides during design; either satisfies the metric.
