---
name: rust-webapp-rollout
description: >
  One-shot rollout of a full-Rust web app + serverless API — shared pure domain core, a
  Dioxus/WASM web frontend, and a Rust serverless function on Vercel's official Rust runtime —
  from empty directory to a VERIFIED production deployment, first time, every time. Use this skill
  when the user wants to build or deploy a Rust web app or API, a Dioxus/WASM frontend, a Vercel
  Rust function, a "RUST_WEBAPP_API", or says "scaffold a Rust web project" / "deploy Rust to
  Vercel" / invokes `/rust-webapp-rollout`. Carries the proven version matrix, 16 zero-drift
  templates, the bootstrap runbook, the guardrail ledger, and the verification matrix. Pairs with
  the handler-rust-webapp value-handler. Self-improving: every new failure mode becomes a guardrail.
metadata:
  type: rollout
  stack: rust + dioxus/wasm + vercel-official-rust-runtime
  output: a verified production deployment (web app + /api function)
  source-of-zero-drift: references/templates/
model: inherit
---

# RUST-WEBAPP-ROLLOUT — empty directory to verified production, first time, every time

> *A full-Rust vertical slice — shared pure core, Dioxus/WASM web, Rust serverless function on
> Vercel's official Rust runtime — carried from IDEA to a VERIFIED production deployment, with a
> quality gate an agent can enforce and never has to argue with.*

This skill is the **production specification** for the `RUST_WEBAPP_API` class. It is not a
tutorial — every command, version, file shape, and guardrail in its references was paid for in
real debugging time on the shipped `forge` project. Follow it and a fresh build never repeats that
cost. The value-handler `handler-rust-webapp` staffs the work; this skill carries the discipline.

> **IMPORTANT — THE ONLY WAY:** Read `references/00-MANIFEST.md` first, then execute
> `references/08-bootstrap-runbook.md`, consulting `references/01`–`07` and
> `references/templates/` exactly where each step cites them. Copy the templates; never
> hand-author these files from memory — that reintroduces drift and the `06` saga.

This skill adopts the marketplace **certainty-marker protocol**
(`${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/certainty-markers.md`): when a marker and your
instinct disagree, the marker wins — it was written *after* the mistake.

---

## The line (stations, with DEPLOY + VERIFY)

```
IDEA ─▶ BRIEF ─▶ SPEC(EARS) ─▶ COORDINATES ─▶ IMPLEMENT ─▶ STORY ─▶ GATE ─▶ BUILD ─▶ DEPLOY ─▶ VERIFY
                              (failing tests)   (green)            (CI)   (prebuilt)         (prod)
```

Each station has an **entry condition**, a **transformation**, and an **exit certificate**. Freight
may not advance without its certificate. Full station table: `references/02-stations-idea-to-production.md`.

> **GUARDRAIL:** Do not BUILD before the GATE is green; do not DEPLOY before BUILD succeeds; do not
> call a slice done before VERIFY passes against the **deployed** artefact (not localhost).
> Skipping a station is how silent breakage reaches production.

---

## Knowledge-parity before deploy — ask the user first

> **IMPORTANT — THE ONLY WAY:** The deploy stations need the user's account and interactive auth.
> Reach knowledge-parity *before* building (see `${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/knowledge-parity.md`).
> Ask the user to run interactive commands via the `! <command>` form.

1. A **Vercel account** (free tier suffices).
2. **Node 18+ and the Vercel CLI** (`npm i -g vercel`; `vercel --version` → 54.x).
3. **`vercel login`** (interactive — user only).
4. **`vercel link`** from the repo root (the dir with `vercel.json`) → the project slug.
5. **Enable the Rust-runtime capability** on the Vercel project (the official runtime is
   permission-gated). Ask the user to confirm.
6. **Preview vs production** — confirm which deploys are previews (auth-protected) and when to
   promote to the public production alias.

Full detail: `references/03-toolchain-and-environment.md`.

---

## The bootstrap runbook (the page you execute)

1. **Decide placeholders** once — `{{project}}`, `{{crate_prefix}}`, `{{fn_name}}`,
   `{{vercel_project}}` (`references/templates/README.md`).
2. **Scaffold from `references/templates/`** — copy the 16 templates, substitute placeholders
   consistently. Verify the **hybrid root `Cargo.toml`** (`[workspace]` **and** `[package]` with the
   function `[[bin]]`; **no** `api/Cargo.toml`) and the empty `[build]` table in `.cargo/config.toml`.
3. **`cargo xtask setup` → `cargo xtask check`** (must exit 0) — toolchain install/verify.
4. **Carry the first vertical slice** through the stations: SPEC → write **failing COORDINATES** in
   `core` (unit + `proptest`), confirm they fail for the right reason → IMPLEMENT the minimum to
   green → STORY-wire the `server`/`ui`/`api` shells → **GATE: `cargo xtask ci` fully green**.
5. **Connect Vercel** (user-driven, one-time) — the knowledge-parity steps above.
6. **BUILD → DEPLOY → VERIFY (preview first, then prod)** — prebuilt deploy
   (`references/05-deploy-playbook.md`).

Full ordered checklist: `references/08-bootstrap-runbook.md`.

---

## The quality gate (the certifying station — never weaken it)

> **GUARDRAIL — THE SINGLE MOST IMPORTANT PROCESS RULE:** Never weaken the gate to go green —
> no `#[allow]`, no `#[ignore]`, no dropping `-D warnings`. Fix the code. The gate is the station
> that certifies freight; a weakened gate certifies broken freight.

`cargo xtask ci` = `fmt --all -- --check` + `clippy --workspace --all-targets -- -D warnings` +
`test --workspace` + a `wasm32-unknown-unknown` release build of the web crate. The WASM build is
on the gate because the deploy target is a *different compilation* than the host build. Detail:
`references/07-quality-gate-and-process.md`.

---

## The verification matrix (run against the DEPLOYED url)

| Request | Expected |
|---|---|
| `GET /` | `200`, `text/html`, serves the WASM app |
| `GET /api/{{fn_name}}?name=X` | `200`, `{"ok":true,"message":"Hello, X! …"}` |
| `GET /api/{{fn_name}}` | `200`, defaults to `World` |
| `GET /api/{{fn_name}}?name=` | `400`, `{"ok":false,"message":"name must not be empty"}` |

> **GUARDRAIL:** Test **previews** with `vercel curl <url>` (they are auth-protected); plain `curl`
> is correct only against the public **production** alias. A plain-`curl` "Authentication Required"
> on a preview is the auth gate, not a broken function.

---

## Done-checklist (the exit certificate for the whole rollout)

- [ ] Root `Cargo.toml` is the hybrid manifest; no `api/Cargo.toml` (`refs 01 §3`, `06 B2`)
- [ ] `.cargo/config.toml` has the empty `[build]` table (`refs 04 §5`, `06 B4`)
- [ ] `vercel.json` has the correct `buildCommand` and **no** `functions` block (`refs 04 §4`)
- [ ] `cargo xtask check` exits 0; first slice's coordinates were written failing, then green
- [ ] `cargo xtask ci` fully green; the gate was never weakened (`refs 07 §1`)
- [ ] `.func` shows `runtimeLanguage: "rust"`, `runtime: "executable"` (`refs 04 §6`)
- [ ] Verification matrix passes against the **production** URL (`refs 05 §4`)

When every box is ticked, the line is proven and the project is producing value. Subsequent
features are just more vertical slices carried down the same stations.

---

## References (read in the order each step cites)

| Doc | Gives you |
|---|---|
| `references/00-MANIFEST.md` | Mission, prime directives, the quality-first creed, the **proven version matrix**, glossary. Read first. |
| `references/01-architecture-blueprint.md` | The crate graph, the one-way dependency LAW, the hybrid `Cargo.toml`. |
| `references/02-stations-idea-to-production.md` | The carriage of value: stations, vertical slices, tests-as-coordinates. |
| `references/03-toolchain-and-environment.md` | Exact toolchain, `xtask`, what to ask/require of the user. |
| `references/04-vercel-rust-runtime.md` | `@vercel/rust` runtime, the `vercel_runtime` 2.x function pattern, `vercel.json`, the `.cargo` gotcha. |
| `references/05-deploy-playbook.md` | The prebuilt deploy model, exact commands, the verification matrix. |
| `references/06-guardrails-and-antipatterns.md` | The full symptom → cause → fix ledger + the FORBIDDEN list. |
| `references/07-quality-gate-and-process.md` | The CI gate, coordinates-testing, the adversarial agent roles. |
| `references/08-bootstrap-runbook.md` | The ordered "empty dir → deployed slice" checklist. **The page you execute.** |
| `references/templates/` | Copy-paste-ready, parameterized canonical files. **The source of zero drift.** |

---

## ♻️ Self-improvement covenant (halve the distance to perfection)

This skill compounds. Every new failure mode discovered in a real rollout becomes a new
**guardrail** (symptom → cause → fix) in `references/06-guardrails-and-antipatterns.md`; every
version drift becomes a matrix update in `references/00-MANIFEST.md`; every recurring question
becomes a sharper knowledge-parity prompt. Each iteration must **at least halve the remaining
distance to a flawless, zero-trial-and-error rollout.** A recurring gap signals an upstream fix —
make it once, here, so no future build pays for it. See
`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/kaizen-covenant.md`.
