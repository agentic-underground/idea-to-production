---
description: One-shot rollout of a full-Rust web app + Vercel serverless API (shared pure core + Dioxus/WASM + official Rust runtime) — empty dir to verified production.
---

Run the **rust-webapp-rollout** skill.

`$ARGUMENTS` (optional): the project name / first slice intent (e.g. `forge — a greeting API`), or
a stage hint (`scaffold`, `gate`, `deploy`, `verify`).

Drive the full line — IDEA ▶ BRIEF ▶ SPEC ▶ COORDINATES ▶ IMPLEMENT ▶ STORY ▶ GATE ▶ BUILD ▶
DEPLOY ▶ VERIFY — for a Rust/WASM web app + a Rust serverless function on Vercel's official Rust
runtime, sharing one pure domain core. First reach knowledge-parity with the user on the Vercel
prerequisites (account, CLI, `login`, `link`, Rust-runtime capability, preview-vs-prod), then
scaffold from the skill's zero-drift templates, carry the first thin vertical slice, keep
`cargo xtask ci` green (never weaken the gate), deploy prebuilt, and finish only when the
verification matrix passes against the **production** URL.

Read `skills/rust-webapp-rollout/SKILL.md`, start at `references/00-MANIFEST.md`, then execute
`references/08-bootstrap-runbook.md`. The `handler-rust-webapp` value-handler staffs the build.
