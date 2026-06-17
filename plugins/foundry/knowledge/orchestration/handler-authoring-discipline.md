# Handler-authoring discipline — the pinned-version, FORBIDDEN-list covenant for every new value-handler

> The one-copy home for **how a new VALUE_HANDLER is authored** so it never re-discovers a problem an
> earlier build already solved. It is the antidote to version/tooling thrash (the kind that cost the
> `rust-webapp-rollout` build a saga of Vercel-runtime incidents, and the kind the typst PDF path keeps
> paying — see *Out of scope* below). Generalised from the proven
> [`../../skills/rust-webapp-rollout/references/00-MANIFEST.md`](../../skills/rust-webapp-rollout/references/00-MANIFEST.md)
> charter and its [FORBIDDEN list](../../skills/rust-webapp-rollout/references/06-guardrails-and-antipatterns.md).
> Referenced by the handler-build pipeline (its run-of-record,
> [`../../../../docs/internal/handler-build/SCHEDULER_PROOF.md`](../../../../docs/internal/handler-build/SCHEDULER_PROOF.md),
> routes every handler it authors here) and by the **BUILD HANDLER FIRST** path of the missing-handler
> 3-way gate ([`missing-handler-gate.md`](missing-handler-gate.md)); never restated.

## Why this exists

A value-handler is a FOUNDRY production asset that turns a *class* of IDEA into PRODUCT. When the conveyor
meets a stack with no handler, the safe response is to **author one** (the BUILD path of the gate) — but a
handler thrown together without discipline becomes a *future incident*: "latest" versions that drift,
tooling that breaks in CI, antipatterns rediscovered build after build. The discipline below makes a new
handler **first time, every time**: a fresh build reaches a verified result without re-deriving anything
this handler already knows.

## THE ONLY WAY — every new value-handler SHALL carry these four artefacts

A handler authored under this discipline is **not complete** until it bakes in all four. This is the
checkable contract for AC2 of card #25 (a handler authored under it carries a pinned matrix + FORBIDDEN
list) — and the two starred rows are non-negotiable.

| # | Artefact | What it is | Why (the failure it fences) |
|---|---|---|---|
| 1 ★ | **Pinned version matrix** | A table of every tool/crate/runtime the handler depends on, each at a **proven, pinned** version known to work *together* — never a floating `latest`/`*`/major-only range. | "Latest" is not a version; it is a future incident. An unpinned dep re-resolves on every launch → non-reproducible builds (mirrors `verify-prereqs.sh` §M, which already forbids floating plugin pins). |
| 2 ★ | **FORBIDDEN list** | A table of *never, under any circumstance* — each row: the forbidden thing · why it's forbidden (the known production failure or violated directive) · what to do instead. | A guardrail carries its own symptom → cause → fix so an implementor never has to *trust* the rule — they can *see* it. Guardrails are why a build is safe to run blind. |
| 3 | **The KAIZEN covenant** | The handler carries the replication covenant ([`../architecture/kaizen-covenant.md`](../architecture/kaizen-covenant.md)) — like every other FOUNDRY artefact, it improves itself and stays in sync. | A handler that cannot learn rots; the covenant is how every future build of this stack gets calmer. |
| 4 | **The four-wave build pipeline** | The handler is authored through the proven research → synthesis → build → review pipeline (below), not free-handed. | The pipeline is how the *discipline itself* is applied — it is where the matrix and FORBIDDEN list are derived and proven. |

> **The pinned matrix and the FORBIDDEN list are the two that the conveyor checks.** The discipline doc
> exists so a new handler's matrix and list are not optional decorations but a precondition of being
> registered in the VALUE_HANDLER_POOL.

## The four-wave build pipeline

Every new `handler-<stack>` is authored in four ordered waves — the generalisation of how the proven
handlers (`handler-rust-webapp`, `handler-rust-tauri`) were built:

1. **RESEARCH** — establish the stack's *proven* toolchain by evidence (official docs via context7, real
   build logs, the latest stable releases known to work together). Output: the candidate version matrix
   and the catalogue of known failure modes (each with symptom → cause → fix).
2. **SYNTHESIS** — distil research into the four artefacts: pin the **version matrix**, write the
   **FORBIDDEN list** from the failure catalogue, attach the **KAIZEN covenant**, and write the handler's
   charter/SMU. This is where "latest" becomes a pinned version and a war-story becomes a guardrail.
3. **BUILD** — write the `handler-<stack>.md` agent file (and any companion skill/references) against the
   synthesised matrix, plus a worked example that exercises the *whole* shape end-to-end so the handler
   proves itself trivially before carrying a real product. Register it in the roster
   ([`agent-roster.md`](agent-roster.md)) and the VALUE_HANDLER_POOL table (`builder/SKILL.md` §8).
4. **REVIEW** — run the adversarial gate (`/foundry:pr-review`) prompted to *refute* that the handler is
   complete: does it carry both starred artefacts? Is every version pinned? Does the worked example pass
   the handler's own quality gate? No PASS, no merge into the pool.

## Out of scope — the typst PDF pain is a SEPARATE issue

The typst-based PDF rendering thrash in **pressroom** is the *same disease* (version/tooling drift) but a
**different patient**. It is **NOT** fixed here. It is a standalone `SELF_IMPROVEMENT` issue to harden
pressroom's PDF path (raised via `/operate:gemba` → pressroom). This doc governs *FOUNDRY
value-handler authoring*; it does not reach across the plugin boundary into pressroom's rendering stack.

## Worked example — the discipline already shipped

`handler-rust-webapp` is the reference: its charter
([`00-MANIFEST.md`](../../skills/rust-webapp-rollout/references/00-MANIFEST.md) §4) carries the **proven
version matrix** (`rustc 1.96.0` · `dx 0.7.9` · `vercel_runtime 2.x` · `@vercel/rust 1.3.0` · …), and its
guardrails doc carries the **FORBIDDEN list** (community `vercel-rust`, a `"functions"` block in
`vercel.json`, `unwrap`/`panic!` in the core, weakening the CI gate, …). Every new handler keeps that
*shape* and swaps the *contents* for its own stack.
