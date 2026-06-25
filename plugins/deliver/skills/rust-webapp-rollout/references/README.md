# RUST_WEBAPP_API — Knowledge Package

> **Purpose:** This package is the **foundation of the `RUST_WEBAPP_API` value handler**.
> It carries the complete, hard-won, drift-free knowledge required to scaffold,
> build, gate, and deploy a YouRedactIt-class solution — a **Rust/WASM web frontend +
> Rust serverless function on Vercel's official Rust runtime, sharing one pure domain
> core** — **first time, every time**, with zero trial-and-error.

This is not a tutorial. It is a **production specification**. Every command, version,
file shape, and guardrail in here was paid for in real debugging time on the shipped
`forge` (YouRedactIt) project. An agent that follows this package never repeats that cost.

---

## How the handler should consume this package

Read in order. Each document is a **station**; the value (a working solution) is carried
from one to the next.

| # | Document | What it gives the implementor |
|---|----------|-------------------------------|
| — | [`00-MANIFEST.md`](00-MANIFEST.md) | Mission, prime directives, the quality-first creed, the proven version matrix, glossary. **Read first.** |
| 1 | [`01-architecture-blueprint.md`](01-architecture-blueprint.md) | The canonical crate graph, the one-way dependency LAW, the hybrid `Cargo.toml`. |
| 2 | [`02-stations-idea-to-production.md`](02-stations-idea-to-production.md) | The carriage of value: IDEA → PRODUCTION stations, vertical slices, tests-as-coordinates. |
| 3 | [`03-toolchain-and-environment.md`](03-toolchain-and-environment.md) | Exact toolchain, `xtask`, and **what to ask / require of the user**. |
| 4 | [`04-vercel-rust-runtime.md`](04-vercel-rust-runtime.md) | The official `@vercel/rust` runtime, the function pattern, `vercel.json`, the `.cargo` gotcha. |
| 5 | [`05-deploy-playbook.md`](05-deploy-playbook.md) | The prebuilt deploy model, exact commands, the verification matrix. |
| 6 | [`06-guardrails-and-antipatterns.md`](06-guardrails-and-antipatterns.md) | The full symptom → cause → fix ledger and the FORBIDDEN list. |
| 7 | [`07-quality-gate-and-process.md`](07-quality-gate-and-process.md) | The CI gate, coordinates-testing, the adversarial agent roles. |
| 8 | [`08-bootstrap-runbook.md`](08-bootstrap-runbook.md) | The ordered "empty dir → deployed slice" checklist. **The page you execute.** |
| — | [`templates/`](templates/) | Copy-paste-ready, parameterized canonical files. **The source of zero drift.** |

**Fast path for a new build:** read `00`, then jump to `08-bootstrap-runbook.md` and
execute it, consulting `01`–`07` and `templates/` as each step cites them.

---

## How to read the certainty markers

Every consequential statement in this package is tagged. The markers are literal and
mean exactly this:

- `> **IMPORTANT — THE ONLY WAY:**` — The single sanctioned approach. There is no
  acceptable alternative. Do not deviate.
- `> **GUARDRAIL:**` — A rule that exists to prevent a specific, known production
  failure. Breaking it reintroduces a bug we already paid to find.
- `> **ANTI-PATTERN (DO NOT):**` — A forbidden or outdated approach, always paired with
  the **why** and the **why-not** so the reasoning travels with the rule.
- `> **WORKED EXAMPLE:**` — The concrete reference from the shipped `forge` project.

When a marker and your instinct disagree, the marker wins. These were written *after* the
mistakes, not before.

---

## What this package guarantees

1. **No trial-and-error.** Every dead end the original build hit is documented as an
   anti-pattern with the fix already applied in the templates.
2. **No knowledge drift.** The templates are the exact shipped files, parameterized. Copy
   them; do not reinvent them.
3. **No ambiguity.** Each decision point carries exactly one `THE ONLY WAY`.
4. **First time, every time.** The bootstrap runbook reproduces a deployable solution
   end-to-end.

---

## Provenance

Distilled from the shipped YouRedactIt / `forge` repository — principally
`forge/docs/technical/proper-wasm-build-env-with-vercel-function-api.md`, the hybrid
`forge/Cargo.toml`, `forge/xtask/`, the CI gate, and the `.claude/` agent roles — plus the
project's deployment field notes. The proven version matrix is in `00-MANIFEST.md`.
