# 07 — The Quality Gate & Development Process

> **Purpose:** How quality is *certified*, not hoped for. The CI gate as a station,
> coordinates-driven testing in practice, and the adversarial agent roles that carry a
> slice safely to merge.
>
> **TL;DR:** The gate is `fmt --check` + `clippy -D warnings` + `test --workspace` + a WASM
> build, mirrored locally by `cargo xtask ci`. Never weaken it. Logic is pinned by
> coordinates (unit tests + `proptest`) in pure crates. Three adversarial roles —
> builder, reviewer, security-auditor — carry each slice.

---

## 1. The CI gate (the certifying station)

> **IMPORTANT — THE ONLY WAY:** Every slice passes the **same** gate, locally and in CI:
>
> 1. `cargo fmt --all -- --check`
> 2. `cargo clippy --workspace --all-targets -- -D warnings`
> 3. `cargo test --workspace`
> 4. `cargo build -p {{crate_prefix}}-web --target wasm32-unknown-unknown --release`
>
> Locally this is one command: **`cargo xtask ci`**. In CI it is the GitHub Actions
> workflow ([`templates/ci.yml.tmpl`](templates/ci.yml.tmpl)), with `RUSTFLAGS: "-D warnings"`.

**Why a WASM build is in the gate:** the web crate compiling to `wasm32-unknown-unknown` is
a *different* compilation than the host build; a change can pass `cargo test` and still
break the actual deploy target. The gate must certify what production runs.

> **GUARDRAIL — THE SINGLE MOST IMPORTANT PROCESS RULE:** **Never weaken the gate to make a
> PR green.** Not `#[allow(...)]` to silence clippy, not `#[ignore]` on a failing test, not
> dropping `-D warnings`. The gate is the station that certifies freight; a weakened gate
> certifies broken freight. Fix the code.

> **GUARDRAIL:** The hybrid root manifest means the function `[[bin]]` compiles under
> `cargo {clippy,test} --workspace` — so the function is on the gate for free. Keep it that
> way (don't move the function out of the workspace).

---

## 2. Testing as coordinates — in practice

The creed (`00 §3`, `02 §3`) becomes these concrete habits:

> **IMPORTANT — THE ONLY WAY:** Pin all decidable logic with coordinates in **pure** crates
> (`core`, `server`). The thin shells (`web`/`mobile`/`api`) carry no decidable logic and
> are validated at the story/system level, not with unit coordinates.

- **Typed errors, never strings.** Domain errors are a `thiserror` enum. A coordinate can
  assert `Err(GreetingError::TooLong { max: 64, got: 65 })` exactly — a `String` error
  can't be pinned precisely.
  > **ANTI-PATTERN (DO NOT):** `Result<T, String>` in `core`. **Why-not:** it cannot be
  > matched precisely, so the coordinate is blurry and refactors silently change the
  > message without failing a test.
- **Parse, don't validate.** Construction is fallible (`Greeting::new(name) -> Result<…>`);
  once you hold the type, the invariants are guaranteed and no downstream code re-checks
  them. The coordinate that pins construction pins the whole system.
- **Edge cases are axes.** Empty, whitespace-only, exactly-at-max, over-max, unicode — one
  coordinate each. Together they leave exactly one correct implementation.
- **Invariants get `proptest`.** "Never panics for any input" and "valid input always
  round-trips into the rendered output" are properties, not examples — pin them with a
  property test.

> **WORKED EXAMPLE:** `forge-core` ships unit coordinates (`greets_a_normal_name`,
> `trims_whitespace`, `rejects_empty`, `rejects_too_long`, `accepts_exactly_max`) plus two
> `proptest` invariants (`valid_names_appear_in_message`, `never_panics`). `forge-server`
> adds glue coordinates (`ok_for_valid_name`, `graceful_for_empty`,
> `serialises_to_expected_json_shape`). See
> [`templates/crate-core-lib.rs.tmpl`](templates/crate-core-lib.rs.tmpl) and
> [`templates/crate-server-lib.rs.tmpl`](templates/crate-server-lib.rs.tmpl).

---

## 3. The adversarial agent roles

A slice is carried to merge by three roles. The handler should implement these as
sub-agents (or as explicit review passes). Full role briefs:
[`templates/CLAUDE.md.tmpl`](templates/CLAUDE.md.tmpl) plus the role files referenced there.

### Builder
Implements one thin vertical slice at a time, **writing code AND its tests, never code
alone**. Procedure: restate the slice in one sentence (split if not reviewable in one
sitting) → locate the right crate → **write the coordinate(s) first** → implement the
minimum to pass → run `fmt` + `clippy -D warnings` + `test` → respect the golden rules.
Hands off to the reviewer with a summary of what changed and what was deliberately *not*
done.

### Reviewer (adversarial)
Job: **find reasons NOT to merge.** Does not edit; reports `file:line`, severity-sorted
(BLOCKER / MAJOR / MINOR / NIT). Checklist: dependency-direction respected (reverse edge =
BLOCKER); no `unwrap`/`expect`/`panic!`/indexing/overflow risk in `core`/`server`; new
logic has tests + edge cases + a property test where an invariant exists; typed-enum error
style; **actually runs the gate** (does not trust claims); diff is minimal (flags drive-by
changes). Ends with explicit `APPROVE` or `REQUEST CHANGES`.

### Security-auditor
Assumes **inputs are hostile and dependencies are guilty until proven innocent.** Focus:
every external input passes through `core` validation before use (untrusted input reaching
`format!`/paths/process-spawn = BLOCKER); the API surface has status codes, bounded input,
no reflected input or info leakage in errors; supply chain (`cargo tree --duplicates`, new
deps justified, recommend `cargo audit`/`cargo deny`); no secrets committed; **reachable
panics in request paths are availability bugs = BLOCKER**. Run before merging anything that
touches `api/`, dependencies, or input handling.

> **IMPORTANT — THE ONLY WAY (ship flow):** Builder implements + self-gates → Reviewer
> approves (re-run until `APPROVE`) → if the slice touches `api/`, deps, or input handling,
> Security-auditor approves → branch, Conventional-Commit, push, open PR. **Never weaken
> the gate to make things pass.**

---

## 4. Conventional commits

> **GUARDRAIL:** Use Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `build:`,
> `refactor:`, `style:`, `chore:`). One concern per commit; keep diffs surgical. If a
> change balloons, stop and split it into separate slices.

> **WORKED EXAMPLE:** `forge`'s history reads as a clean station log:
> `fix(api): deploy the Rust function on vercel_runtime 2.x`,
> `build(xtask): install zig + cargo-zigbuild in setup`,
> `refactor(api): migrate to Vercel's official Rust runtime`,
> `docs(technical): add WASM + Vercel function build/deploy guide`.

---

## 5. Why this process *is* the guarantee

The gate certifies; the coordinates locate; the adversarial roles refuse to pass
uncertified or unlocated work. Together they are why a build that follows this package
reaches production **first time, every time**: there is no station at which un-pinned,
un-tested, or un-reviewed freight can slip through. The guardrails (`06`) close the few
gaps the gate can't see (platform/deploy config), and the templates apply every fix before
the first line of product code is written.

---

Continue to [`08-bootstrap-runbook.md`](08-bootstrap-runbook.md).
