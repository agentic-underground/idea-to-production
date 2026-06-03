# 06 — Guardrails & Anti-Patterns (The Ledger)

> **Purpose:** The consolidated, no-ambiguity ledger of every problem this stack threw at
> the original build, with the symptom → cause → fix for each, plus the explicit FORBIDDEN
> list. This is the page that turns "trial and error" into "first time, every time".
>
> **TL;DR:** Each entry below cost real debugging time. The templates already apply every
> fix. If you hit a symptom in the left column, the cause and fix are here — do not
> re-diagnose from scratch.

Every entry is tagged so the reasoning travels with the rule. When in doubt, the templates
in [`templates/`](templates/) are the canonical, already-fixed form.

---

## A. Build / toolchain

### A1 — `cargo install dioxus-cli` fails compiling `auth-git2`
- **Symptom:** installing the Dioxus CLI fails to compile (`auth-git2`,
  `Cred::credential_helper` removed).
- **Cause:** a bare install re-resolves to latest-compatible deps and pulls a `git2`
  version that breaks `auth-git2`.
- **Fix → GUARDRAIL:** always `cargo install dioxus-cli --locked`. `xtask setup` does this.

### A2 — `rsx!`, `#[component]`, `use_signal`, `use_memo` not found in the UI crate
- **Symptom:** the shared UI crate can't see the Dioxus authoring macros/hooks.
- **Cause:** `dioxus = { default-features = false }` drops the `lib` feature (which bundles
  `macro`/`html`/`signals`/`hooks`); the renderer features (`web`/`mobile`) do **not**
  re-add them.
- **Fix → IMPORTANT (THE ONLY WAY):** put the authoring features on the shared dep —
  `dioxus = { version = "0.7", default-features = false, features = ["macro","html","signals","hooks"] }`
  — and add `"launch"` to each platform crate. See `01 §4`.

### A3 — Linker error `unable to find library -lxdo`
- **Symptom:** link step fails on `-lxdo`.
- **Cause:** the desktop/mobile renderer (pulled in via the mobile crate's `dioxus`
  features) links `libxdo`.
- **Fix → GUARDRAIL:** install `libxdo-dev` (in the `xtask` Debian package list). See `03 §5`.

### A4 — `dx bundle` fails: "Failed to find binary package to build"
- **Symptom:** `dx bundle` can't decide what to build.
- **Cause:** in a multi-binary workspace, `dx` cannot infer the crate.
- **Fix → IMPORTANT (THE ONLY WAY):** always pass `--package {{crate_prefix}}-web`. This is
  baked into the `vercel.json` `buildCommand` (`04 §4`) and `xtask bundle`.

---

## B. The Vercel function — the long saga

### B1 — `vercel build`: "Function Runtimes must have a valid version"
- **Symptom:** build rejects the runtime config.
- **Cause:** `"runtime": "vercel-rust@1"` is not a valid pinned version — and the community
  runtime is deprecated anyway.
- **Fix → ANTI-PATTERN (DO NOT) use a `functions` block / community runtime.** Use the
  official zero-config runtime; remove the `functions` block entirely. See `04 §1`, `04 §4`.

### B2 — `cargo zigbuild … --bin <name>` can't find the bin
- **Symptom:** Vercel runs `cargo --bin <name>` from the root and can't find it, or errors
  *"current package believes it's in a workspace when it is not"*.
- **Cause:** the function lived in a separate, non-member `api/Cargo.toml`. Vercel
  auto-detects `api/*.rs` and builds from the project root, where that bin isn't visible.
- **Fix → IMPORTANT (THE ONLY WAY):** make the function a `[[bin]]` of the **root package**
  (the hybrid manifest). No `api/Cargo.toml`. See `01 §3`, `04 §2`.

### B3 — 500 `FUNCTION_INVOCATION_FAILED`; logs show `Missing AWS_LAMBDA_FUNCTION_NAME`
- **Symptom:** the function deploys but every invocation 500s; logs cite a missing
  `AWS_LAMBDA_*` env var.
- **Cause:** `vercel_runtime` **1.x** depends on `lambda_runtime`, whose
  `Config::from_env()` eagerly `expect()`s `AWS_LAMBDA_*` env vars. Vercel doesn't set them
  — **and reserves the `AWS_LAMBDA_` prefix**, so you can't add them. Downgrading
  `lambda_runtime` doesn't help (every version is eager).
- **Fix → IMPORTANT (THE ONLY WAY):** use **`vercel_runtime = "2"`** (hyper-based, no
  `lambda_runtime`). The 2.x handler API differs — see `04 §3`.

### B4 — Migrating to the official runtime: `Cannot read properties of undefined (reading 'target')`
- **Symptom:** `vercel build` crashes inside `@vercel/rust` with this JS error.
- **Cause:** `@vercel/rust` 1.3.0 reads `.cargo/config.toml` and accesses
  `cargoBuildConfiguration?.build.target` — it guards the config object but **not** a
  missing `[build]` table. Our `.cargo/config.toml` exists (for the `xtask` alias) but had
  no `[build]`.
- **Fix → GUARDRAIL (DO NOT REMOVE):** add an empty `[build]` table to
  `.cargo/config.toml`. Harmless; satisfies the access. See `04 §5`.

---

## C. Deploy / platform

### C1 — Preview URL returns "Authentication Required"
- **Symptom:** plain `curl` of a preview deployment returns an auth wall.
- **Cause:** preview deployments are protected by default; only the production alias is
  public.
- **Fix → GUARDRAIL:** test previews with `vercel curl <url>/api/<name>`; use plain `curl`
  only against the public production alias. See `05 §4`.

### C2 — Assuming `zig` is no longer needed after moving to the official runtime
- **Symptom:** native build deploys but the function crashes at runtime; or you drop `zig`
  and the prebuilt build can't cross-compile.
- **Cause:** prebuilt deploys cross-compile the function locally; `@vercel/rust` shells out
  to `cargo zigbuild` to target Lambda's older glibc. A native build against a newer host
  glibc crashes at runtime.
- **Fix → GUARDRAIL:** keep `cargo-zigbuild` + `zig` installed. The `.func` `filePathMap`
  (`target/x86_64-unknown-linux-gnu/release/<name>`) confirms the cross-build. See `03 §1`,
  `04 §6`.

### C3 — Trying to deploy via the Vercel MCP server
- **Symptom:** the MCP server can't deploy; OAuth `client_id` rejected.
- **Cause:** `plugin:vercel:vercel` is read-only (list/inspect/logs) and its OAuth client
  is rejected by Vercel.
- **Fix → ANTI-PATTERN (DO NOT):** don't deploy via MCP. Use the **CLI**. See `03 §4`,
  `05 §5`.

### C4 — Empty/blank site in production
- **Symptom:** `GET /` serves a blank page after deploy.
- **Cause:** the `buildCommand` swallowed a copy error (e.g. trailing `|| true`), so an
  empty `public/` shipped.
- **Fix → GUARDRAIL:** the `buildCommand` must `mkdir -p public && … && cp …` with **no**
  `|| true` — the copy must fail loudly. See `04 §4`.

---

## D. The FORBIDDEN list (never, under any circumstance)

> **IMPORTANT — THE ONLY WAY is to avoid all of these. They are not preferences; each is a
> known production failure or a violated prime directive.**

| Forbidden | Why it's forbidden | Do this instead |
|---|---|---|
| Community `vercel-rust` runtime | Archived Jan 2026; AWS-Lambda-shaped; B1/B3 | Official `@vercel/rust` + `vercel_runtime` 2.x (`04`) |
| `vercel_runtime` 1.x | Pulls `lambda_runtime` → `AWS_LAMBDA_*` panic (B3) | `vercel_runtime = "2"` |
| A `"functions"` block in `vercel.json` | Community-runtime shape; rejected (B1) | Zero-config detection via root `[[bin]]` |
| A separate `api/Cargo.toml` | Breaks auto-detection (B2) | Function `[[bin]]` in the hybrid root manifest |
| `.cargo/config.toml` without `[build]` | `@vercel/rust` 1.3.0 crash (B4) | Keep the empty `[build]` table |
| `cargo install dioxus-cli` (no `--locked`) | `auth-git2` build break (A1) | `--locked` |
| `dx bundle` without `--package` | Can't infer crate (A4) | `--package {{crate_prefix}}-web` |
| `unwrap`/`expect`/`panic!` in `core`/`server`/handler | Panic = availability bug / un-pure core | Typed `thiserror` errors; status codes |
| Any reverse dependency edge | Breaks purity, reuse, reviewability | One-way LAW (`01 §2`) |
| Weakening the CI gate to go green | The gate is the certifying station | Fix the code, never the gate (`07`) |
| Deploying via Vercel MCP | Read-only; OAuth rejected (C3) | Vercel CLI |
| `dropping zig`/cross-build for a native build | Glibc mismatch crash (C2) | Keep `cargo-zigbuild` + `zig` |
| Building the web app on Vercel (Git integration) | No `dx` in the build image | Prebuilt deploy (`05`) |

---

## E. The known-good version matrix (re-stated for safety)

rustc **1.96** · dx **0.7.9** · `vercel_runtime` **2.x** · `@vercel/rust` **1.3.0** ·
Vercel CLI **54.x** · `cargo-zigbuild` **0.22** · `zig` **0.13.0** · Node **18+**.

> **GUARDRAIL:** If you change any version in this matrix, you are off the proven path and
> the guarantees in this package no longer hold. Treat a version bump as its own slice with
> its own full GATE + DEPLOY + VERIFY pass.

---

Continue to [`07-quality-gate-and-process.md`](07-quality-gate-and-process.md).
