# 04 — The Vercel Official Rust Runtime

> **Purpose:** How the serverless function is defined, built, and detected. The official
> `@vercel/rust` runtime, the `vercel_runtime` 2.x handler pattern, `vercel.json`, and the
> two config gotchas that otherwise cost hours.
>
> **TL;DR:** Use Vercel's **official** Rust runtime (`@vercel/rust` builder +
> `vercel_runtime` 2.x crate). It is **zero-config**: it detects the function from the root
> `Cargo.toml` `[[bin]]` → `api/*.rs`. `vercel.json` has **no `functions` block**.
> `.cargo/config.toml` **must** contain an (even empty) `[build]` table.

---

## 1. Use the OFFICIAL runtime — not the community one

> **IMPORTANT — THE ONLY WAY:** Build the function on Vercel's **official** Rust runtime:
> the `@vercel/rust` builder (1.3.0) with the `vercel_runtime` 2.x crate. It shipped as a
> first-class runtime (public beta, Dec 2025), runs on Fluid compute with HTTP response
> streaming, and is **zero-config** + **permission-gated** (enable the Rust-runtime
> capability on the project; see `03 §4`).

> **ANTI-PATTERN (DO NOT):** Use the community `vercel-community/rust` runtime (the
> `"functions": { "api/**/*.rs": { "runtime": "vercel-rust@x.y.z" } }` style).
> **Why-not:** it was **archived Jan 2026** — deployments keep working but get no fixes —
> and it pulls a fundamentally different, AWS-Lambda-shaped stack that fails on Vercel (see
> the `AWS_LAMBDA_*` saga in `06`). Migrate off it. The official runtime needs no
> `functions` block at all.

---

## 2. Zero-config detection — how Vercel finds the function

The official runtime detects Rust functions by reading the **root `Cargo.toml`** for
`[[bin]]` entries whose `path` points at `api/*.rs`. That is the *entire* registration
mechanism. This is exactly why the root manifest is a **hybrid workspace+package** that
owns the function `[[bin]]` (see `01 §3`).

> **GUARDRAIL:** The function `[[bin]]` must live in the **root package**, with **no**
> separate `api/Cargo.toml`. A separate manifest breaks auto-detection and triggers
> *"package believes it's in a workspace"*. See `01 §3` and `06`.

---

## 3. The `vercel_runtime` 2.x handler pattern

> **IMPORTANT — THE ONLY WAY:** Write the handler against `vercel_runtime` 2.x (hyper-
> based). Keep the file **boring**: parse the request, delegate all decidable logic to the
> `server` crate (which delegates to `core`), shape the response. No business logic lives
> in the function.

```rust
use serde_json::json;
use vercel_runtime::{run, service_fn, Error, Request, Response, ResponseBody};

#[tokio::main]
async fn main() -> Result<(), Error> {
    run(service_fn(handler)).await
}

async fn handler(req: Request) -> Result<Response<ResponseBody>, Error> {
    let name = req.uri().query()
        .and_then(|q| q.split('&').find_map(|kv| kv.strip_prefix("name=")))
        .map(urldecode)
        .unwrap_or_else(|| "World".to_string());

    let payload = {{crate_prefix}}_server::handle_greet(&name);  // shared, unit-tested logic
    let status: u16 = if payload.ok { 200 } else { 400 };

    Ok(Response::builder()
        .status(status)
        .header("Content-Type", "application/json")
        .body(ResponseBody::from(json!(payload).to_string()))?)
}
```

Key facts about the 2.x API:
- `Request` is `hyper::Request<Incoming>`; you read the query via `req.uri().query()`.
- `Response<ResponseBody>`; build the body from a `String`/`&str`/`serde_json::Value`.
- `run` internally wraps the handler in `service_fn` — pass the **bare** handler to
  `service_fn`, not a pre-wrapped one.
- The status code is derived from the payload (the `server` crate already decided
  ok/not-ok), so invalid input is a clean `400`, never a panic.

Full template: [`templates/api-function.rs.tmpl`](templates/api-function.rs.tmpl).

> **GUARDRAIL:** Never `unwrap()`/`expect()`/`panic!()` in the handler. A panic in a
> serverless handler is an availability bug (a 500 / `FUNCTION_INVOCATION_FAILED`). Invalid
> input must return a status code, not crash. This is enforced by the security-auditor role
> (`07`).

---

## 4. `vercel.json` — custom web build, zero-config function

> **IMPORTANT — THE ONLY WAY:** `vercel.json` configures only the **web** build and output
> directory. It has **NO `functions` block** — the function is detected via the root
> `Cargo.toml` `[[bin]]`.

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "mkdir -p public && dx bundle --platform web --package {{crate_prefix}}-web --release && cp -r target/dx/{{crate_prefix}}-web/release/web/public/* public/",
  "outputDirectory": "public"
}
```

- `--package {{crate_prefix}}-web` is **mandatory**: in a multi-binary workspace `dx`
  cannot infer which crate to build (see `06`).
- The `buildCommand` uses `mkdir -p public && … && cp …` with **no `|| true`**: the copy
  must fail loudly. A swallowed error ships an empty `public/` — a blank site in
  production.

Template: [`templates/vercel.json.tmpl`](templates/vercel.json.tmpl).

> **ANTI-PATTERN (DO NOT):** Add a `"functions"` block to `vercel.json`. **Why-not:** it is
> the community-runtime config shape; with the official runtime it is unnecessary and the
> `"runtime": "vercel-rust@1"` form is rejected outright (*"Function Runtimes must have a
> valid version"*). See `06`.

---

## 5. The `.cargo/config.toml` `[build]` table — mandatory workaround

> **GUARDRAIL — DO NOT REMOVE:** `.cargo/config.toml` **must** contain a `[build]` table,
> even an empty one.
>
> ```toml
> [alias]
> xtask = "run --package xtask --"
>
> # Workaround for @vercel/rust 1.3.0 — see below. An empty [build] table is required.
> [build]
> ```

**Why:** `@vercel/rust` 1.3.0 reads `.cargo/config.toml` and accesses
`cargoBuildConfiguration?.build.target`. It guards the config *object* but **not** a
missing `[build]` *table*. Because we have a `.cargo/config.toml` (for the `xtask` alias),
the builder finds the file, tries to read `build.target`, and crashes with
**`Cannot read properties of undefined (reading 'target')`**. An empty `[build]` table
satisfies the access without changing cargo's behaviour.

Template: [`templates/cargo-config.toml.tmpl`](templates/cargo-config.toml.tmpl).

> **Note:** This is an upstream builder bug; the workaround is harmless and may be removed
> once `@vercel/rust` guards the access. Until then, **keep it**.

---

## 6. The healthy `.func` signature (how you confirm the official runtime)

After `vercel build`, the function's generated config at
`.vercel/output/functions/api/<name>.func/.vc-config.json` should read:

```json
{
  "handler": "executable",
  "runtime": "executable",
  "runtimeLanguage": "rust",
  "architecture": "x86_64",
  "supportsResponseStreaming": true,
  "filePathMap": { "executable": "target/x86_64-unknown-linux-gnu/release/{{fn_name}}" }
}
```

> **GUARDRAIL:** `"runtimeLanguage": "rust"` + `"runtime": "executable"` confirms you are
> on the **official** runtime (not community `vercel-rust`). The `filePathMap` target
> (`x86_64-unknown-linux-gnu`) confirms the `cargo-zigbuild` cross-compile happened. If you
> see anything else, stop and re-check §1–§5 before deploying.

---

Continue to [`05-deploy-playbook.md`](05-deploy-playbook.md).
