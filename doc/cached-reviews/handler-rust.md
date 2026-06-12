# Cached review — FOUNDRY handler-rust

**Target file:** `plugins/foundry/agents/handler-rust.md`  
**Unit:** `handler-rust`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Coverage floor is unenforceable — the gate contains no coverage measurement, and the cited test-policy has no Rust coverage command

**Evidence:** Line 66: "**100% line coverage AND 100% branch coverage is the floor.**" — but line 69-70 defines the gate as only "`cargo fmt --all -- --check` + `cargo clippy --workspace --all-targets -- -D warnings` + `cargo test --workspace`". None of these measures coverage. Worse, the handler cites `${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md` (line 108-109), whose "Branch Coverage Commands" and "Stack-Specific Coverage Commands" tables (test-policy.md ~lines 274-294) list Python/pytest, JavaScript/jest, TypeScript/vitest, and Playwright — there is NO Rust row anywhere. The handler's central quality promise has no enforcement mechanism in this file or in the canon it cites.

**Recommendation:** Add a coverage command to the gate: `cargo llvm-cov --workspace --branch --fail-under-lines 100 --fail-under-branches 100` (cargo-llvm-cov; requires `rustup component add llvm-tools-preview`), with a documented fallback (cargo-tarpaulin) and a documented behaviour when neither is installed (surface the gap to the orchestrator, never silently skip). Separately flag upstream that test-policy.md's coverage-command tables need a Rust row.

### 2. [HIGH] Self-containment violations — three load-bearing relative `../knowledge/` paths instead of ${CLAUDE_PLUGIN_ROOT}

**Evidence:** Line 22: "See [`live-feedback.md`](../knowledge/tooling/live-feedback.md)"; line 107-108: "(canon: [`../knowledge/first-principles.md`](../knowledge/first-principles.md) §2"; line 184: "([`kaizen-covenant.md`](../knowledge/architecture/kaizen-covenant.md))". The house law is that a plugin file resolves paths only through ${CLAUDE_PLUGIN_ROOT}. The same file proves the convention is known — lines 31, 36, 51, 109, and 152 all use `${CLAUDE_PLUGIN_ROOT}/knowledge/...`. An agent definition is consumed as a spawned subagent's system prompt with cwd set to the user's project, not the agents/ directory — `../knowledge/tooling/live-feedback.md` will dangle (or resolve against an unrelated project directory) at runtime.

**Recommendation:** Replace all three relative links with `${CLAUDE_PLUGIN_ROOT}/knowledge/tooling/live-feedback.md`, `${CLAUDE_PLUGIN_ROOT}/knowledge/first-principles.md`, and `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/kaizen-covenant.md`, matching the file's own dominant convention.

### 3. [HIGH] Spawning Model Policy hardcodes concrete model IDs, contradicting the canonical model-selection policy

**Evidence:** Lines 95-97 hardcode "`claude-haiku-4-5` (test code)", "`claude-sonnet-4-6` (default)", "`claude-opus-4-8` (stories)". knowledge/policy/model-selection.md says (line 28): "Tiers map to the latest model in each family. Resolve at spawn time, do not hardcode" and (line 36): "When a new model family ships, update **only this table** and the whole fleet re-tiers." By duplicating the ID resolution into the handler, a re-tier of the canonical table leaves this file silently stale — the exact failure mode the policy doc exists to prevent. (This pattern is replicated across all handler-*.md files, so the fix is fleet-wide, but it is a defect in this file.)

**Recommendation:** Rewrite the table's third column to name TIERS (haiku / sonnet / opus) and add one line: "Resolve tier → concrete ID at spawn time via `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md` — never hardcode an ID here."

### 4. [MEDIUM] "Never modify test code" drops the covenant's phase qualifier, contradicting this handler's TEST/STORY duties

**Evidence:** Line 32-33: "As per the PRINCIPLE_PHILOSOPHY: think before coding, ask if unclear, never widen scope unnecessarily, never modify test code." The cited implementation-covenant.md (line 65) says "**Never modify test code during implementation.**" — phase-qualified. This handler is explicitly "Spawned by TEST-AGENT ... and STORY-AGENT" (description, lines 7) to AUTHOR test code in Phases 3 and 5; the unqualified instruction forbids the handler's own primary duty in two of its three phases. A literal-minded spawned agent could refuse to write the coordinates it was spawned to write.

**Recommendation:** Restore the qualifier: "never modify test code *during the IMPLEMENT phase* — in TEST and STORY phases authoring test code IS the assignment."

### 5. [MEDIUM] SUBJECT_MATTER_UNDERSTANDING is claimed in the description but never operationalized in the body

**Evidence:** Line 10 (frontmatter description): "Carries the KAIZEN self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." The body never mentions SUBJECT_MATTER_UNDERSTANDING again — no instruction to locate or read it. Every ds-step agent operationalizes it (e.g., ds-step-3-tests.md line 40: "Load `doc/SUBJECT_MATTER_UNDERSTANDING.md` if present."; ds-step-5-implementation.md line 25 likewise). The handler promises a contract it gives the spawned agent no way to honour.

**Recommendation:** Add to the body (near the implementation-covenant instruction at line 31): "If `doc/SUBJECT_MATTER_UNDERSTANDING.md` exists in the project, read it before writing any code — domain terms, invariants, and constraints there bind your type design and error taxonomy."

### 6. [MEDIUM] Wrong-model refusal directive has no detection mechanism

**Evidence:** Lines 99-100: "If you were spawned on the wrong model for your phase, refuse and surface the mismatch to the orchestrator before doing any work." A spawned subagent generally cannot introspect which model ID it is running on; the file gives no mechanism (no env var, no handshake field from the spawning agent's prompt) to perform this check, making the directive unactionable as written.

**Recommendation:** Make the check concrete: require the spawning phase agent to state the model tier it spawned the handler with in the task prompt (per the handoff-protocol schema), and instruct the handler to compare that declared tier against the phase table — refusing only on a declared mismatch, and proceeding with a logged caveat when the tier is undeclared.

### 7. [MEDIUM] Environment Assumptions probe has no failure branches — absent toolchain or missing Cargo.toml is unhandled

**Evidence:** Lines 143-148 give probe commands (`rustc --version && cargo --version`, `ls Cargo.toml ...`) but no instruction for any failing outcome: cargo not installed, no Cargo.toml (uninitialized project), or a pinned toolchain channel that is not installed (`rust-toolchain.toml` honoured at line 150 only for the not-upgrading case). The handler does not say whether it scaffolds a workspace, refuses, or escalates — a cold-start agent meeting an empty directory or a missing toolchain has no doctrine.

**Recommendation:** Add an explicit failure ladder: (a) cargo missing → halt and surface to the orchestrator referencing /foundry:check, never attempt installation silently; (b) no Cargo.toml → confirm with the phase agent whether scaffolding is in scope before creating a workspace (default layout: workspace with a pure `core` crate); (c) pinned channel uninstalled → `rustup toolchain install $(channel)` only if rustup is present, else halt and report.

### 8. [LOW] Inconsistent forbidden-panic-macro lists between Prime Directive 1 and Implementation Standards

**Evidence:** Line 48 forbids "`unwrap()`/`expect()`/`panic!()`/`todo!()`/unchecked indexing" (no `unreachable!`); line 159-160 forbids "`unwrap`/`expect`/`panic!`/`unreachable!`/unchecked indexing" (no `todo!`). Neither list names `unimplemented!`. Two near-identical lists that differ invite a literal agent to conclude `unreachable!` is allowed in the core or `todo!` is allowed at the edges.

**Recommendation:** Unify to one canonical list stated once and referenced from the other location: `unwrap`/`expect`/`panic!`/`todo!`/`unimplemented!`/`unreachable!`/unchecked indexing — none in non-test code. Better still, enforce it mechanically via clippy lints (`-D clippy::unwrap_used -D clippy::expect_used -D clippy::indexing_slicing -D clippy::panic -D clippy::todo -D clippy::unimplemented -D clippy::unreachable`) scoped to the core crate.

### 9. [LOW] Security posture is advisory ("Recommend cargo audit / cargo deny") despite a guilty-until-proven-innocent framing

**Evidence:** Line 173-174: "Recommend `cargo audit` / `cargo deny` for the supply chain; justify every new dependency." — "Recommend" is the weakest verb in the file, sitting directly under "dependencies are guilty until proven innocent" (line 171). No instruction covers the tools being absent, and supply-chain checking never enters the gate, so in practice it will never run.

**Recommendation:** When adding any new dependency, make `cargo audit` (or `cargo deny check advisories`) mandatory if installed, and require the handler to report 'supply chain UNVERIFIED — cargo-audit not installed' in its completion handoff when it is not — converting a silent skip into a visible risk line.

### 10. [SUGGESTION] Workspace-member discovery glob is fragile — misses nested members

**Evidence:** Line 147: `grep -RE 'thiserror|proptest|serde' Cargo.toml */Cargo.toml crates/*/Cargo.toml 2>/dev/null` only finds members one level deep or under `crates/`; nested layouts (`crates/domain/core/Cargo.toml`, `services/*/Cargo.toml`) are silently missed, so the handler may wrongly conclude proptest/thiserror are absent.

**Recommendation:** Use the authoritative probe: `cargo metadata --format-version 1 --no-deps` (parse `.packages[].dependencies` with jq, or at minimum `cargo tree -e normal -i thiserror` per crate) instead of path globs.

## Capability-uplift proposals

### 1. No coverage measurement tooling — the 100% line+branch floor has no Rust command anywhere in the handler or its cited canon

**Proposal:** Add a 'Coverage measurement — THE ONLY WAY' subsection under the gate: "Measure with cargo-llvm-cov: `cargo llvm-cov --workspace --branch --fail-under-lines 100 --fail-under-branches 100` (install: `cargo install cargo-llvm-cov` + `rustup component add llvm-tools-preview`). Run it after every green test run; the gate is not green until coverage is green. Fallback when cargo-llvm-cov cannot be installed: `cargo tarpaulin --workspace --branch --fail-under 100`. If neither tool is available, report 'coverage UNMEASURED' in the completion handoff — never claim the floor is met without a number."

**Rationale:** This is the handler's most material gap: it declares the strictest coverage floor in the fleet while carrying zero ability to measure it, and test-policy.md's coverage-command tables (lines ~274-294) have no Rust row to fall back on. handler-python operationalizes its equivalent ("Run with coverage after every meaningful change", handler-python.md line 150); the Rust handler must too.

### 2. No unsafe-code doctrine — a Rust handler with no position on `unsafe` is missing the language's defining safety contract

**Proposal:** Add a Prime Directive: "**The core forbids unsafe.** Put `#![forbid(unsafe_code)]` at the root of every pure-core crate — forbid, not deny, so no downstream `#[allow]` can re-open it. If an edge crate genuinely requires `unsafe` (FFI, performance-proven hot path): each block carries a `// SAFETY:` comment stating the invariant that makes it sound; the crate sets `#[deny(unsafe_op_in_unsafe_fn)]`; and the unsafe code gets Miri coordinates (`cargo +nightly miri test -p <crate>`) pinning the soundness claim. An undocumented `unsafe` block is a BLOCKING defect, same severity as a reverse dependency edge."

**Rationale:** The file regulates panics exhaustively but says nothing about unsafe — the only mechanism by which Rust code can actually exhibit UB. 'Make illegal states unrepresentable' (line 162) is hollow if unsafe can bypass the type system unobserved.

### 3. No async/concurrency discipline — the description claims 'services' in scope but the doctrine is entirely synchronous

**Proposal:** Add an 'Async & concurrency' section: "The pure core stays runtime-agnostic — it never depends on tokio/async-std; async lives at the edges, which call into sync core functions. In async edge code: no blocking calls (`std::fs`, `std::thread::sleep`, blocking channels) inside async fns — use `tokio::task::spawn_blocking` (clippy pairs: `-D clippy::unused_async`, and watch for `await_holding_lock`). Async tests use `#[tokio::test]` and wrap any I/O-bound assertion in `tokio::time::timeout` so a hang fails fast instead of stalling the gate. Shared-state invariants (locks, atomics) that matter get a `loom` model-checking coordinate, not just an example test."

**Rationale:** Line 8 scopes the handler to 'libraries, CLIs, services, domain cores', and the most common real-world Rust service defects (blocked executor, deadlock, lock held across await) are exactly the class this file is silent on.

### 4. No mutation testing — coordinate DENSITY is asserted by the cited test-policy but the handler has no way to verify it

**Proposal:** Add to 'Tests are coordinates — in practice': "**Density is verified, not assumed.** Before declaring a slice done, run `cargo mutants --workspace --in-diff <(git diff main)` (cargo-mutants) over the changed code. Every surviving mutant is a missing coordinate: an implementation change the test suite cannot distinguish from the correct one. Add the coordinate that kills it, or document in the handoff why the mutant is equivalent. 100% coverage with surviving mutants is under-pinned code — the floor is met but the SOLUTION is not yet pinned."

**Rationale:** test-policy.md (lines 28-41) is explicit that the worked quantity is coverage *density*, not the coverage number — 'high coverage and low density' code passes this handler's current gate undetected. cargo-mutants is the standard Rust mechanization of exactly that doctrine.

### 5. Supply-chain verification is a recommendation, not a gate, and lockfile discipline is absent

**Proposal:** Harden the Security posture section: "`Cargo.lock` is committed for every workspace that produces a binary, service, or deployed artifact — an unlocked build is non-reproducible and unauditable. Adding or bumping any dependency triggers, in order: (1) justification in the handoff (what it does, why std/existing deps can't, maintenance signal, transitive count via `cargo tree -e normal | wc -l` before/after); (2) `cargo audit` — a new advisory is a BLOCKER, not a note; (3) `cargo deny check` when `deny.toml` exists (advisories, licenses, bans, sources). If audit/deny are not installed, the completion handoff carries the line 'supply chain UNVERIFIED' so the sentinel gate sees the gap."

**Rationale:** The current text ('Recommend cargo audit / cargo deny', line 173) is the weakest clause in an otherwise non-negotiable file, and it contradicts its own framing one paragraph earlier ('dependencies are guilty until proven innocent', line 171). A recommendation with no trigger, no failure path, and no gate hook will never execute.

### 6. No feature-flag or API-surface discipline — the gate only certifies the default feature set, and public-API docs/doctests are unmentioned

**Proposal:** Add to the gate section: "Crates with `[features]` are gated across the matrix, not just defaults: `cargo hack check --each-feature --workspace` (cargo-hack; escalate to `--feature-powerset` when features interact). A coordinate that only holds under default features pins nothing for downstream consumers. Library crates additionally carry `#![deny(missing_docs)]` on the public core; every public item's doc example compiles and runs under `cargo test --doc` — a doctest is a coordinate the consumer reads first. Note: `cargo test --workspace` runs doctests for library targets, but adding `--all-targets` silently SKIPS them — never combine the gate's test command with `--all-targets`."

**Rationale:** Conditional compilation is Rust's most common 'compiles for me, breaks for the consumer' failure mode and the current gate cannot see it; and the `--all-targets`-skips-doctests trap is a known cargo footgun that this gate's exact wording (clippy uses `--all-targets`, test does not) suggests the author knows but never wrote down — undocumented knowledge is one refactor away from loss.
