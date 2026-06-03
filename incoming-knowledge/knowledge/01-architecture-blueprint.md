# 01 — Architecture Blueprint

> **Purpose:** The canonical project shape. The crate graph, the one-way dependency LAW,
> and the hybrid root `Cargo.toml` that makes the whole thing deployable.
>
> **TL;DR:** One Cargo workspace. Five crates plus a function `[[bin]]`. Dependencies flow
> one way only: `core ← ui ← {web, mobile}`, `server → core`. The root `Cargo.toml` is a
> **hybrid** — a `[workspace]` AND a `[package]` that owns the serverless function as a
> `[[bin]]`. There is **no** `api/Cargo.toml`.

---

## 1. The crate graph

```
              {{crate_prefix}}-core   (pure domain: logic, validation, errors, tests)
               ^      ^
               |      |
   {{crate_prefix}}-ui   {{crate_prefix}}-server
            ^    ^             ^
            |    |             |
{{crate_prefix}}-web  {{crate_prefix}}-mobile   api/<name>.rs  (Vercel function)
   (WASM)        (native, optional)
```

| Crate | Name | Role | Depends on |
|---|---|---|---|
| `crates/core` | `{{crate_prefix}}-core` | Pure domain logic. No I/O, no UI, no platform, no panics. Typed `thiserror` errors. The testable heart. | nothing in-workspace |
| `crates/ui` | `{{crate_prefix}}-ui` | Shared Dioxus RSX components. Platform-agnostic. | `core` + `dioxus` |
| `crates/web` | `{{crate_prefix}}-web` | Thin WASM shell. Calls `dioxus::launch(App)`. | `ui` |
| `crates/mobile` | `{{crate_prefix}}-mobile` | Thin native shell (optional; iOS/Android). Same `App`. | `ui` |
| `crates/server` | `{{crate_prefix}}-server` | HTTP-agnostic server glue. Validates via `core`, shapes responses. Fully unit-tested without a network. | `core` |
| `api/<name>.rs` | (root pkg `[[bin]]`) | The Vercel serverless function. HTTP plumbing only; delegates to `server`. | `server`, `vercel_runtime` |
| `xtask` | `xtask` | Toolchain manager / build orchestrator. Dev-only. | std |

> **WORKED EXAMPLE:** In `forge`: `forge-core` (the `Greeting` type + `GreetingError`),
> `forge-ui` (the `GreetingLabel` component), `forge-web`, `forge-mobile`, `forge-server`
> (`handle_greet`), and `api/greet.rs` (the `GET /api/greet` handler).

---

## 2. The one-way dependency LAW

> **IMPORTANT — THE ONLY WAY:** Dependencies flow in exactly one direction:
> `core ← ui ← {web, mobile}` and `server → core`. **Never** add a reverse edge.
> A reverse edge is a BLOCKING defect, not a style nit.

**Why this shape:**
- **Testability** — the logic that must be correct lives where it is trivial to test
  (a pure crate with no async, no DOM, no network). This is what makes
  *tests-as-coordinates* (`00 §3`) possible at all.
- **Reuse without drift** — web, mobile, and the API all call the *same* core function, so
  behaviour cannot diverge between platforms. The product can never say one thing on the
  web and another in the API.
- **Reviewability** — the dependency rule is a bright line a reviewer (human or agent) can
  enforce mechanically: grep for a forbidden edge and block the PR.
- **Security** — untrusted input is validated in `core` before anything acts on it; the
  function and UI are thin consumers of already-validated values.

> **ANTI-PATTERN (DO NOT):** Let `core` depend on `ui`, `web`, a serialization-for-a-
> specific-transport concern, or anything with I/O. **Why-not:** it instantly makes the
> core un-pure, which makes it un-coordinate-able — you lose the ability to pin behaviour
> with cheap, fast, deterministic unit tests, and platform-specific bugs leak into the
> part that is supposed to be universally correct.

---

## 3. The hybrid root `Cargo.toml` — the keystone

This is the single most important structural decision in the whole package. Get it right
and Vercel's official Rust runtime auto-detects the function with zero config. Get it wrong
and you enter the multi-hour saga documented in `06`.

> **IMPORTANT — THE ONLY WAY:** The root `Cargo.toml` is **both** a `[workspace]` and a
> `[package]`. The `[package]` half owns the serverless function as a `[[bin]]` pointing at
> `api/<name>.rs`. This is the layout `@vercel/rust` auto-detects (root `Cargo.toml` +
> `[[bin]]` → `api/*.rs`). The function bin still compiles under
> `cargo {clippy,test} --workspace`, so it stays on the CI gate for free.

```toml
[workspace]
resolver = "2"
members = ["crates/core", "crates/ui", "crates/web", "crates/server", "crates/mobile", "xtask"]

# The package half: owns the serverless function as a [[bin]].
[package]
name = "{{project}}"
version = "0.1.0"
edition.workspace = true
license.workspace = true
publish = false

[[bin]]
name = "{{fn_name}}"            # e.g. "greet"
path = "api/{{fn_name}}.rs"     # e.g. "api/greet.rs"

[dependencies]
vercel_runtime = "2"
tokio = { version = "1", features = ["macros"] }
serde_json = { workspace = true, features = ["raw_value"] }
{{crate_prefix}}-server = { path = "crates/server" }
```

The full annotated template, including `[workspace.dependencies]`, `[workspace.package]`,
and the WASM-size `[profile.release]`, is in
[`templates/Cargo.toml.root.tmpl`](templates/Cargo.toml.root.tmpl).

> **ANTI-PATTERN (DO NOT):** Create a separate `api/Cargo.toml` for the function.
> **Why-not:** Vercel auto-detects `api/*.rs` and runs `cargo --bin <name>` **from the
> project root**. With the function in a separate, non-member `api/Cargo.toml`, cargo
> errors with *"current package believes it's in a workspace when it is not"* (or simply
> can't see the bin), and the build fails. **Fix:** make the function a `[[bin]]` of the
> **root package**, as above. Bonus: it then also runs in the CI gate.

> **GUARDRAIL:** Centralise dependency versions in `[workspace.dependencies]` so every
> crate stays in lockstep and a version bump is a one-line change. This is also the first
> place a security/review agent looks.

---

## 4. The shared `dioxus` dependency — feature discipline

> **IMPORTANT — THE ONLY WAY:** Declare `dioxus` once in `[workspace.dependencies]` with
> **only the renderer-agnostic authoring features**, and have each platform crate add its
> own renderer + `launch`:
>
> ```toml
> # [workspace.dependencies]
> dioxus = { version = "0.7", default-features = false, features = ["macro", "html", "signals", "hooks"] }
> ```
> ```toml
> # crates/web/Cargo.toml
> dioxus = { workspace = true, features = ["web", "launch"] }
> # crates/mobile/Cargo.toml
> dioxus = { workspace = true, features = ["mobile", "launch"] }
> # crates/ui/Cargo.toml
> dioxus = { workspace = true }
> ```

**Why:** `default-features = false` keeps `devtools`/`logger` and every renderer out of the
shared baseline, so the UI crate stays platform-neutral. The authoring features
(`macro`, `html`, `signals`, `hooks`) are what provide `rsx!`, `#[component]`,
`use_signal`, `use_memo` — they are bundled in the `lib` feature, which lives only in
`default`. The renderer features (`web`/`mobile`) do **not** re-add them.

> **ANTI-PATTERN (DO NOT):** Set `dioxus = { default-features = false }` with no authoring
> features and expect the renderer feature to bring them back. **Why-not:** you get
> *"cannot find macro `rsx!`"*, *"cannot find attribute `component`"*, `use_signal`/
> `use_memo` unresolved — because the `lib` feature (which bundles them) was dropped and
> the renderer features don't re-add it. See `06`.

---

## 5. Why the architecture *is* the quality strategy

The crate graph is not bureaucracy — it is the geometry that makes the quality-first creed
(`00 §3`) physically true:

- The **core** is pure ⇒ every requirement can be expressed as a **coordinate** (a failing
  unit test) that pins exactly one implementation.
- The dependency **LAW** guarantees coordinates placed against the core remain valid no
  matter which platform consumes them ⇒ **no drift**.
- The thin shells (`web`, `mobile`, `api`) carry no decidable logic ⇒ there is nothing in
  them to get subtly wrong; they are validated at the story/system level, not pinned with
  unit coordinates.

This is also why the work parallelises: disjoint coordinates against disjoint pure modules
can be solved by independent agents with no shared mutable context. The only serialization
points are genuinely shared files (the core lib everyone extends, the render orchestrator
everyone wires).

---

Continue to [`02-stations-idea-to-production.md`](02-stations-idea-to-production.md).
