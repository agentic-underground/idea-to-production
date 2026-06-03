# 00 — MANIFEST

> **Purpose:** The charter of the `RUST_WEBAPP_API` value handler. Mission, prime
> directives, the quality-first creed, the proven version matrix, and the glossary that
> makes the rest of the package unambiguous.
>
> **TL;DR:** Build a Rust/WASM web app + a Rust serverless function on Vercel's official
> Rust runtime, sharing one pure domain core. Tests are coordinates that pin the solution;
> value is carried station to station from IDEA to PRODUCTION; guardrails keep every
> implementor safe. Pin the versions below. Never weaken the gate.

---

## 1. Mission

The `RUST_WEBAPP_API` value handler produces one thing reliably:

> A **full-Rust vertical slice** — shared pure domain logic, a Dioxus/WASM web frontend,
> and a Rust serverless function — **deployed to Vercel and verified in production**, with
> a quality gate that an agent can enforce and never has to argue with.

The handler's success condition is **first time, every time**: a fresh build reaches a
verified production deployment without rediscovering any problem already solved here.

---

## 2. Prime directives (non-negotiable)

> **IMPORTANT — THE ONLY WAY:** These five directives override convenience, override
> "it compiles", and override any instinct to the contrary. They are the spine of the
> handler.

1. **The core is sacred.** Pure domain logic lives in one crate with **no I/O, no UI, no
   platform code, and no `unwrap()`/`expect()`/`panic!()`** outside tests. Errors are
   typed `thiserror` enums. *(Why: it is the part that must be correct, and it is only
   trivially testable if it is pure. See `01`, `07`.)*
2. **Every change ships with tests.** New logic carries unit tests; anything with an
   invariant carries a `proptest`. No test, no merge. *(Why: a test is the coordinate that
   locates the solution — see the creed below.)*
3. **The CI gate is the gate.** `fmt --check` + `clippy -D warnings` + `test --workspace`
   + a WASM build must all pass. **Never weaken the gate to go green.** *(Why: the gate is
   the station that certifies value before it travels onward.)*
4. **Dependency direction is one-way.** `core ← ui ← {web, mobile}`, `server → core`.
   A reverse edge is a blocking defect. *(Why: it is the bright line that keeps the core
   pure and the system reviewable.)*
5. **Small vertical slices.** Each unit of work is one thin, end-to-end, reviewable change
   that crosses every station. If it balloons, split it.

---

## 3. The quality-first creed

This package speaks one language. Internalize it; it is how the handler reasons.

### Tests are coordinates in multidimensional logical space

A well-formed failing unit test is a **coordinate**: a precise `input → expected output`
assertion against a *pure* function that pins one point (or a tightly-constrained region)
in the space of all possible implementations. The path from **specification** to
**product** is navigated by turning each coordinate green. The test is not a check applied
after the fact — it is **the unequivocal location of the solution itself**. Where the
answer lives stops being a matter of judgement; the coordinates say exactly where.

Consequences the handler acts on:
- **Extract pure logic first.** Pull the decidable core out of DOM/IO/render/network into
  small, dependency-light modules. A coordinate can only be placed in a space that is
  itself pure — side effects blur the location.
- **Express every requirement as failing coordinates** whose input/output pairs locate the
  correct code. Each edge case is another axis that narrows the region until exactly one
  implementation satisfies all coordinates. A bug fix gets a coordinate that *is* the
  bug's negation.
- **Keep the wiring thin.** DOM/IO layers (the web shell, the function handler) carry no
  decidable logic of their own; they consume proven cores and are validated at the
  story/system level.

### Value is carried from station to station

A solution is **carried**, like freight, from **IDEA → PRODUCTION** through a fixed line of
stations (see `02`). At each station the value is transformed and **certified** before it
moves on; the CI gate is the station that refuses to pass uncertified freight. Nothing
reaches production that has not been carried through every station in order.

### Guardrails keep every implementor safe

Every known failure mode is fenced with a **guardrail** (see `06`). A guardrail carries its
own reasoning (symptom → cause → fix) so an implementor never has to *trust* the rule —
they can *see* why it exists. Guardrails are the reason this build is safe to run blind.

---

## 4. The proven version matrix

> **IMPORTANT — THE ONLY WAY:** Use these versions. They are known to work *together*.
> "Latest" is not a version; it is a future incident. Pin everything.

| Component | Proven version | Role |
|---|---|---|
| `rustc` (stable) | **1.96.0** | compiler; pinned by `rust-toolchain.toml` |
| `wasm32-unknown-unknown` | — | web compile target |
| Dioxus framework | **0.7** | UI framework (Rust → WASM / native) |
| Dioxus CLI (`dx`) | **0.7.9** | `dx serve` / `dx bundle`; **install with `--locked`** |
| `vercel_runtime` (crate) | **2.x** | the serverless function runtime (hyper-based) |
| `@vercel/rust` (builder) | **1.3.0** | Vercel's official Rust runtime builder |
| Vercel CLI | **54.x** | `vercel build` / `vercel deploy` |
| `cargo-zigbuild` | **0.22.x** | cross-compile the function to Lambda glibc |
| `zig` | **0.13.0** | backend for `cargo-zigbuild` |
| Node.js | **18+** | required by the Vercel CLI |

This matrix is canonical. Every template in `templates/` is written against it.

---

## 5. The stack in one paragraph

One Cargo workspace produces two deploy artefacts from shared Rust code. The **web app**
(`{{crate_prefix}}-web`) compiles to `wasm32-unknown-unknown`, is bundled by the Dioxus CLI
into static files, and is served as a static site. The **serverless function**
(`api/<name>.rs`) is a Rust HTTP handler that runs on Vercel's official Rust runtime and
reuses the same domain logic via a server-glue crate. Because Vercel's build image has no
`dx`, **everything is built locally and shipped prebuilt** (which also means the function
is cross-compiled locally via `cargo-zigbuild` + `zig`). That single tension dictates the
whole deploy model in `04` and `05`.

---

## 6. Glossary

| Term | Meaning |
|---|---|
| **Value handler** | A FOUNDRY production asset (here, a Claude Code plugin/skill) that turns a class of IDEA into PRODUCT. This package is the foundation of the `RUST_WEBAPP_API` one. |
| **Station** | A fixed stage in the IDEA → PRODUCTION line. Value is certified at each before moving on. See `02`. |
| **Carriage of value** | The disciplined movement of a solution from station to station; nothing skips a station. |
| **Coordinate** | A failing unit test: an `input → expected output` assertion that pins the solution's location in logical space. |
| **Vertical slice** | One thin change that crosses every station end-to-end (core → server/ui → web/api → deploy). |
| **The gate** | The CI quality gate (`fmt` + `clippy -D warnings` + `test` + WASM build). The station that certifies freight. |
| **The core** | The pure domain crate (`{{crate_prefix}}-core`): logic, validation, typed errors, tests. No I/O. |
| **The hybrid manifest** | The root `Cargo.toml` that is simultaneously a `[workspace]` and a `[package]` owning the function `[[bin]]`. See `01`, `04`. |
| **Prebuilt deploy** | `vercel build` locally → `vercel deploy --prebuilt`; the only deploy model, because Vercel can't run `dx`. See `05`. |
| **Official Rust runtime** | Vercel's first-class `@vercel/rust` builder + `vercel_runtime` 2.x crate. Replaces the deprecated community `vercel-rust`. See `04`. |
| `{{project}}` | Template placeholder: the project / Vercel name (e.g. `forge`). |
| `{{crate_prefix}}` | Template placeholder: the crate-name prefix (e.g. `forge` → `forge-core`). |
| `{{vercel_project}}` | Template placeholder: the linked Vercel project slug (e.g. `whatbirdisthats-projects/forge`). |

---

## 7. The worked example: `forge` (YouRedactIt)

Throughout this package, the concrete reference is the shipped `forge` project:
a "hello world" greeting slice (`Greeting::new(name) -> Result<Greeting, GreetingError>`)
that exercises the *entire* architecture — a domain type, a typed error enum, real
validation, exhaustive tests including `proptest`, a shared Dioxus component, a WASM web
shell, and a `GET /api/greet?name=…` serverless function — all sharing one core. The
feature is trivial **on purpose**: it proves the *shape* end to end. When you build a real
product, you **keep the shape and swap the contents**.

> **WORKED EXAMPLE:** Every `> **WORKED EXAMPLE:**` callout in this package shows the
> `forge` version of the thing being described, so you always have a real, working
> reference for the abstract rule.

---

Continue to [`01-architecture-blueprint.md`](01-architecture-blueprint.md).
