# 05 — Deploy Playbook

> **Purpose:** The exact, ordered commands to carry a gated slice from local BUILD to a
> verified PRODUCTION deployment — and how to prove it actually works.
>
> **TL;DR:** Deploys are **prebuilt** because Vercel's build image has no `dx`. Build
> locally (`vercel build`), then upload (`vercel deploy --prebuilt`). Test previews with
> `vercel curl` (auth-protected); the prod alias is public (`curl`). Run the verification
> matrix against the *deployed* URL.

---

## 1. Why prebuilt — the tension that dictates everything

> **IMPORTANT — THE ONLY WAY:** Deploy **prebuilt**. Build the whole thing locally, then
> upload the prebuilt output. Do **not** rely on Vercel to build the web app.

**Why:** Vercel's build servers have a Rust toolchain (for the official Rust runtime) but
do **not** have `dx` (the Dioxus CLI). The web app therefore *cannot* be built on Vercel.
So you build everything locally and ship a prebuilt deployment — which also means the
function is cross-compiled locally via `cargo-zigbuild` + `zig` (see `03 §1`).

> **ANTI-PATTERN (DO NOT):** Push to a Git integration and expect Vercel to run
> `dx bundle`. **Why-not:** `dx` is not present in the build image; the web build fails or
> ships nothing. The prebuilt model sidesteps this entirely.

---

## 2. The commands

> **IMPORTANT — THE ONLY WAY:** Run all `vercel` commands **from the directory that
> contains `vercel.json`** (the repo root holding the hybrid `Cargo.toml`). Prerequisite:
> the user has run `vercel login` and `vercel link` (see `03 §4`).

### Preview (iterate safely; URL is auth-protected)
```bash
# from the project root (where vercel.json lives)
vercel build --yes
vercel deploy --prebuilt --yes
# Previews require auth — test with `vercel curl`, NOT plain curl:
vercel curl https://<preview>.vercel.app/api/{{fn_name}}?name=Claude
```

### Production (public alias)
```bash
vercel build --prod --yes
vercel deploy --prebuilt --prod --yes
# Production alias is public:
curl https://{{project}}-<hash>.vercel.app/api/{{fn_name}}?name=Claude
```

> **WORKED EXAMPLE:** `forge`'s production alias is `https://forge-rust-seven.vercel.app`;
> the Vercel project is `whatbirdisthats-projects/forge`. Prod verification:
> `curl https://forge-rust-seven.vercel.app/api/greet?name=Claude`.

---

## 3. What `vercel build` does locally

1. Runs the `buildCommand` from `vercel.json` → `dx bundle` produces the WASM site into
   `public/` → packaged as `.vercel/output/static`.
2. Detects the Rust function (root `Cargo.toml` `[[bin]]`) and builds it with `@vercel/rust`,
   which cross-compiles via `cargo zigbuild --target x86_64-unknown-linux-gnu` →
   `.vercel/output/functions/api/<name>.func`.

Confirm the `.func` config matches the healthy signature in `04 §6` before deploying.

---

## 4. The verification matrix

> **IMPORTANT — THE ONLY WAY:** A slice is not "done" until every row passes **against the
> deployed URL** (not just localhost). This is the VERIFY station's exit certificate
> (`02 §2`).

| Request | Expected |
|---|---|
| `GET /` | `200`, `text/html`, serves the WASM app |
| `GET /api/{{fn_name}}?name=X` | `200`, `{"ok":true,"message":"Hello, X! …"}` |
| `GET /api/{{fn_name}}` | `200`, defaults to `World` |
| `GET /api/{{fn_name}}?name=` | `400`, `{"ok":false,"message":"name must not be empty"}` |

> **GUARDRAIL:** Test previews with `vercel curl <url>`, not plain `curl`. **Why:** preview
> deployments are protected by default and a plain `curl` returns *"Authentication
> Required"*, which looks like a broken function but is just the auth gate. The production
> alias is public, so plain `curl` is correct there.

---

## 5. Deploy-time guardrails (quick recall — full detail in `06`)

> **GUARDRAIL:** Keep `cargo-zigbuild` + `zig` installed even when deploying from x86_64
> Linux — the function is cross-compiled to Lambda's older glibc. A native host-glibc build
> crashes at runtime.

> **ANTI-PATTERN (DO NOT):** Try to deploy through the Vercel MCP server. It is read-only
> and its OAuth client is rejected by Vercel. Use the CLI.

> **GUARDRAIL:** Never deploy a slice whose GATE station (`cargo xtask ci`) is not green.
> Production is the last station, not a debugging environment.

---

## 6. The deploy loop in one block (quick reference)

```bash
# One-time (user does the interactive auth/link):
npm i -g vercel && vercel login
cd {{project}} && vercel link        # → {{vercel_project}}
# (ensure the Rust-runtime capability is enabled on the project)

# Every slice:
cargo xtask ci                       # GATE must be green first
vercel build --prod --yes            # BUILD (local; WASM site + cross-compiled fn)
vercel deploy --prebuilt --prod --yes  # DEPLOY
curl https://<prod-alias>/api/{{fn_name}}?name=Claude   # VERIFY
```

---

Continue to [`06-guardrails-and-antipatterns.md`](06-guardrails-and-antipatterns.md).
