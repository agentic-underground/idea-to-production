# FOUNDRY Plan — idea-to-production / mission-control — 2026-06-14

Items planned: **[37]** Flow-server stdio MCP transport (`--mcp` flag) and **[38]** Register flow-server MCP in project settings.

---

## Stack Manifest

| Layer | Technology |
|---|---|
| Language | Rust (edition 2021) |
| Async runtime | tokio 1.40 (rt-multi-thread, io-util features already in Cargo.toml) |
| Serialisation | serde 1.0 + serde_json 1.0 |
| HTTP framework | axum 0.7 (HTTP path unchanged; not used by stdio path) |
| Error types | thiserror 1.0 |
| Test runner | cargo test (tokio test macros already in dev-deps) |
| Config parsing | hand-rolled `Config::from_args` (no clap — see §SMU) |
| New external crate needed? | None — `tokio::io::stdin` / `tokio::io::stdout` + `serde_json` are sufficient |
| Project settings file | `.claude/settings.json` at the repo root (does not yet exist — must be created) |
| Documentation | `plugins/mission-control/flow-server/README.md` (already exists; must be updated) |

---

## Subject Matter Understanding — Status

### flow-server Architecture

The binary is a single Rust crate (`flow-server`) with a pure domain core and thin IO adapters. The public module topology (from `lib.rs`) is:

```
flow_server
├── api      — axum router; REST verb handlers; shared rendering helpers
├── auth     — bearer-token gate middleware
├── config   — CLI flag parser (hand-rolled iterator, no clap)
├── domain   — pure core (ids, model, graph, events, status, gate, roadmap view)
├── history  — startup ingest helpers
├── mcp      — 13-verb JSON-RPC surface (TOOLS list + handle + call_tool dispatch)
├── store    — single serialised writer (Arc<Mutex<...>> wraps the file-backed state)
└── ws       — WebSocket upgrade + broadcast
```

The binary (`main.rs`) is a thin wiring shim: parse config → load token → open store → ingest roadmap (optional) → restore gates → build router → bind TCP → serve.

### Current MCP Handle Signature

```rust
// mcp.rs, line 34
pub async fn handle(State(state): State<AppState>, Json(req): Json<Value>) -> Response
```

This is an **axum extractor-flavoured** function. It receives its `AppState` via `State<AppState>` and the raw JSON body via `Json<Value>`. It is registered at `.route("/mcp", post(mcp::handle))` inside `api.rs` (line 53).

**The problem for stdio reuse:** the `State(state): State<AppState>` and `Json(req): Json<Value>` parameters are axum extractor types. You cannot call this function directly from a non-axum context — you can only call it through the axum dispatcher. The real dispatch logic lives in the private `call_tool(state: &AppState, id: Value, name: &str, args: Value)` function below it.

**Extraction strategy (T37-1):** Create a new `pub async fn dispatch(state: &AppState, req: Value) -> Value` that contains the `handle` function's body (the `id`/`method` extraction and the `match method` block), returning a `Value` instead of an axum `Response`. The HTTP handler becomes a thin wrapper that calls `dispatch` and serialises its return. The stdio loop calls `dispatch` directly. The response builders (`ok`, `rpc_error`, etc.) need to return `Value` rather than `Response` — or duplicate into `Value`-returning variants. This is the load-bearing refactor decision (see Risks section).

### CLI Arg Parser

**No clap.** The config module uses a hand-rolled `while let Some(flag) = it.next()` iterator loop over `std::env::args().skip(1)`. Every known flag is matched as a string literal; unknown flags return `ConfigError::UnknownFlag`.

**Adding `--mcp`:** Add a `mcp: bool` field to `Config`, default `false`, matched as `"--mcp"` in the parser (no value consumed — it is a boolean flag). Because `--mcp` is value-less, the parser arm is `"--mcp" => { cfg.mcp = true; }` — no `it.next()` call needed.

The `ConfigError::UnknownFlag` guard means the `--mcp` arm must be added before the `other =>` catch-all. Existing tests in `config.rs` verify that unknown flags error; this means the `--mcp` arm must be registered or `unknown_flag_errors` would catch it.

### Current Test Structure

**Rust tests (cargo test — all in-crate, `lib.rs` wires them with `#[cfg(test)]`):**
- `mcp.rs` — unit tests for response builders (4 tests; test private helpers via `super::*`)
- `mcp_contract_intest.rs` — router-level contract tests (9 tests; use `build_router` + `tower::ServiceExt::oneshot`)
- `mcp_surface_intest.rs` — exhaustive verb surface (≈40 tests; happy + error + abuse)
- `http_contract_intest.rs`, `http_surface_intest.rs` — REST surface (similar pattern)
- `store_contract_intest.rs` — store semantics
- `ws_contract_intest.rs` — WebSocket upgrade
- `story_gate_persist_intest.rs` — gate persistence story test
- `config.rs` (inline) — 10 unit tests for the flag parser
- `domain/` — extensive pure-core tests

**Coverage:** 100% line+region; `main.rs` excluded (entrypoint shim).

**Frontend:** `cd static && npm test` — vitest+jsdom, 100% coverage; not touched by [37] or [38].

### `.claude/settings.json` Status

**The file does not yet exist.** A search of the entire repo for `settings.json` (excluding `node_modules` and `target`) returned no results. The file must be **created** from scratch, not merged into an existing one. Item [38] is therefore a pure create operation, not a merge. The ROADMAP entry for [38] describes merging as the safe pattern — still correct, because if the file has been created between now and when [38] runs, the agent must merge, not clobber.

---

## Shared Infrastructure Map

| Component | Needs it | Build in | Notes |
|---|---|---|---|
| `Config.mcp: bool` field | [37] T37-2 | T37-2 | Prerequisite for T37-3, T37-4 |
| `mcp::dispatch(state: &AppState, req: Value) -> Value` | [37] T37-1, T37-3 | T37-1 | The core refactor; HTTP handler and stdio loop both call it |
| Token-free `AppState` construction path | [37] T37-3 | T37-3 | stdio mode loads the store but needs no HTTP token; `AppState` must be constructible with a dummy/empty token or the field conditionally used |

### Token / Auth in stdio mode

A non-obvious complexity: `AppState` carries a `Token` field, and `build_router` requires it. The stdio path does not use auth — there is no HTTP request to gate. The implementer must either construct `AppState` with a dummy `Token` (no HTTP request ever checks it in stdio mode) or refactor `AppState` to make `token` optional. The simplest safe approach: construct a dummy `Token::new("stdio-noop")` in stdio mode — the token is never read in the stdio path so this is harmless, and it avoids changing the `AppState` struct signature.

---

## Token Budget Summary

| Item | Est. tokens | Basis |
|---|---|---|
| [37] T37-1 Refactor dispatch | ~3k | Medium Rust refactor; changes mcp.rs response types |
| [37] T37-2 CLI --mcp flag | ~1k | Single field + match arm + tests |
| [37] T37-3 stdio loop | ~3k | New async fn; BufReader + line loop + serde_json |
| [37] T37-4 Wire in main.rs | ~1k | Branch in main; warning log |
| [37] T37-5 Unit tests for dispatch | ~3k | Mirror of existing mcp.rs test structure |
| [37] T37-6 Story test (subprocess) | ~4k | tokio::process::Command; pipe stdin/stdout |
| [38] T38-1 Create settings.json | ~0.5k | JSON write; no existing content to preserve |
| [38] T38-2 Update README.md | ~1k | Append MCP registration section |
| **Total** | **~16.5k** | — |

---

## Work Decomposition

### Item [37] — Flow-server: stdio MCP transport (`--mcp` flag)

**Tier:** PRIMARY
**Priority status:** HIGH
**Token budget estimate:** ~15k
**Estimation basis:** comparable to a medium Rust refactor with subprocess story test; no IDEA_COST history comparables for this codebase
**Depends on:** nothing (first item in this cycle)
**Parallel-safe with:** [38] cannot start until [37] is complete

**Tasks (ordered):**

**T37-1: Extract `mcp::dispatch` — refactor only, no new behaviour**

- Goal: create `pub async fn dispatch(state: &AppState, req: Value) -> Value` that contains the current `handle` body logic, returning a JSON `Value` (the JSON-RPC response object) rather than an axum `Response`.
- The current response builders (`ok`, `rpc_error`, `invalid_params`, `map_store`, `store_error`, `flow_error`, `graph_error`) all return axum `Response`. These must each gain a twin that returns `Value`, OR the builders are refactored to return `Value` and `handle` wraps the result with `Json(...).into_response()`.
- Recommended approach: add `fn ok_val(id: Value, result: Value) -> Value` etc. alongside the existing axum variants, or replace the axum variants wholesale since there is only one call site each. The axum `handle` becomes:
  ```rust
  pub async fn handle(State(state): State<AppState>, Json(req): Json<Value>) -> Response {
      Json(dispatch(&state, req).await).into_response()
  }
  ```
- The existing `mcp_contract_intest.rs` and `mcp_surface_intest.rs` tests must remain green after this refactor — they test through the HTTP router, which still calls `handle`.
- Est. ~3k tokens. Handler: handler-rust.

**T37-2: Add `--mcp` flag to `config.rs`**

- Add `pub mcp: bool` to `Config` struct, default `false`.
- Add `"--mcp" => { cfg.mcp = true; }` arm in `Config::from_args` before the `other =>` catch-all.
- Add tests to `config.rs` inline tests: `mcp_flag_absent_is_false`, `mcp_flag_present_is_true`.
- Est. ~1k tokens. Handler: handler-rust.

**T37-3: Implement `run_stdio` async function**

- New private function in `main.rs` (or a new `stdio.rs` module registered in `lib.rs`):
  ```rust
  async fn run_stdio(store: Arc<Store>) -> Result<(), Box<dyn std::error::Error>>
  ```
- Construct `AppState { store, token: Token::new("stdio-noop") }` (token never read in stdio mode).
- `tokio::io::BufReader::new(tokio::io::stdin())` + `read_line` loop.
- On EOF (empty line or `read_line` returns `Ok(0)`): break and return `Ok(())`.
- Each line: deserialise with `serde_json::from_str::<Value>(&line)`. On parse error: write a JSON-RPC parse error response (`{"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"parse error"}}`).
- On success: call `mcp::dispatch(&state, req).await` and serialise the result as a single line to stdout with `tokio::io::stdout()` + `write_all` + `\n`.
- Stdout writes must flush after each line. Use `tokio::io::AsyncWriteExt`.
- Est. ~3k tokens. Handler: handler-rust.

**T37-4: Wire `--mcp` in `main.rs`, with `--port` warning**

- After `Config::from_args`, if `cfg.mcp` is true:
  - If the port was explicitly set (detect: compare `cfg.port != Config::default().port` — but this heuristic is weak since the user might coincidentally pass the default port; the ROADMAP says "log warning, run stdio mode" so we can simply log the warning always if `--mcp` is present alongside any explicit `--port` in the args): log `eprintln!("flow-server: --mcp and --port are mutually exclusive; running in stdio mode")`.
  - Load the store as usual.
  - Call `run_stdio(store).await?`.
  - Return `Ok(())` — do not bind the TCP listener.
- If `cfg.mcp` is false: continue with existing HTTP path unchanged.
- Note: the simplest approach to the `--port` detection problem is to always emit the warning if `--mcp` is present, since the user will see the warning and the behaviour is still correct. Alternatively, add a `port_was_explicit: bool` tracking field to `Config`. The simpler approach wins.
- Est. ~1k tokens. Handler: handler-rust.

**T37-5: Unit tests for the stdio dispatch path**

- Add a new test module `stdio_dispatch_tests` (or inline in `mcp.rs`) that calls `mcp::dispatch` directly with a pre-built `AppState` (using a temp store), exercises all five exposed tools (`list_items`, `render_roadmap`, `post_status`, `set_gate`, `append_spend`) and verifies the returned `Value` has the expected JSON-RPC shape.
- Also test: unknown tool returns `-32602`, unknown method returns `-32601`, parse error handling.
- These tests do NOT go through the HTTP router — they call `dispatch` directly, providing coverage for the new code path that the existing HTTP-routed tests cannot cover.
- Est. ~3k tokens. Handler: handler-rust.

**T37-6: Story test — subprocess stdio integration**

- Add a new integration test file `tests/stdio_story.rs` (under `plugins/mission-control/flow-server/tests/` which already exists per the directory listing) OR add a new `#[cfg(test)] mod stdio_story_intest;` module in `lib.rs` using `tokio::process::Command`.
- The test must:
  1. Build the binary (or rely on `cargo test` having built it; use `env!("CARGO_BIN_EXE_flow-server")` macro to get the built binary path).
  2. Spawn `flow-server --mcp --data <tempdir>` as a subprocess.
  3. Write a `tools/call list_items` JSON-RPC request to stdin, read the response from stdout, assert it has the grouped shape.
  4. Close stdin (drop the write half of the pipe), assert the process exits with code 0.
- This is the acceptance test for T37-6 AC4 (stdin close → clean exit) and AC1 (reads a valid request, writes the correct response).
- Est. ~4k tokens. Handler: handler-rust.

**VALUE_HANDLERS required:** handler-rust
**Reviewers that will be invoked:** SECURITY-REVIEWER (new network-adjacent stdin surface, though stdio is lower risk than HTTP), COVERAGE-REVIEWER (100% line+region must be maintained)

---

### Item [38] — Register flow-server MCP in project settings

**Tier:** PRIMARY
**Priority status:** HIGH
**Token budget estimate:** ~1.5k
**Estimation basis:** JSON write + markdown append; trivial
**Depends on:** [37] must be complete (the `--mcp` flag must exist before the registration makes sense)
**Parallel-safe with:** nothing in this cycle; [37] must precede it

**Tasks (ordered):**

**T38-1: Create/update `.claude/settings.json` with flow-server MCP entry**

- The file does not currently exist. Create it at `/home/user/Code/idea-to-production/.claude/settings.json`.
- Use the `cargo run` invocation form (not a pre-built binary path) so the entry works without a manual build step during development. The ROADMAP implementation notes show a release binary path — but using `cargo run` with `--manifest-path` is safer as a checked-in dev-mode entry:
  ```json
  {
    "mcpServers": {
      "flow-server": {
        "command": "cargo",
        "args": [
          "run",
          "--manifest-path",
          "plugins/mission-control/flow-server/Cargo.toml",
          "--",
          "--mcp"
        ],
        "description": "Mission-control flow canvas — list_items, render_roadmap, post_status, set_gate, append_spend"
      }
    }
  }
  ```
- If the file already exists when T38-1 runs, the agent MUST read the current content and merge the `flow-server` key into the existing `mcpServers` object — do not clobber. This is the correct defensive pattern regardless of what this plan says about the file's current state.
- Est. ~0.5k tokens. Handler: handler-rust (or any handler; JSON file write).

**T38-2: Update `plugins/mission-control/flow-server/README.md` with MCP registration docs**

- The README already exists (55 lines). Append a new section:
  ```markdown
  ## MCP registration (stdio transport)

  The flow-server speaks [stdio MCP transport](https://modelcontextprotocol.io/docs/concepts/transports)
  when started with `--mcp`. This repo's `.claude/settings.json` registers it so the tools
  (`list_items`, `render_roadmap`, `post_status`, `set_gate`, `append_spend`) appear automatically
  in every Claude Code session.

  **Development mode** (no build step required):
  ```bash
  # The settings.json entry uses `cargo run` — the first call will compile the binary.
  # Subsequent calls reuse the compiled artifact (fast).
  ```

  **Production mode** (faster startup):
  ```bash
  cargo build --release --manifest-path plugins/mission-control/flow-server/Cargo.toml
  # Then update settings.json to point at target/release/flow-server --mcp
  ```

  The binary reads `.flow/` from the **current working directory** when invoked by the MCP harness.
  Run Claude Code from the repo root so the store path resolves correctly.
  ```
- Est. ~1k tokens. Handler: handler-rust (or any handler; markdown append).

**VALUE_HANDLERS required:** handler-rust
**Reviewers that will be invoked:** COVERAGE-REVIEWER (no Rust code changes; coverage unaffected — this is a docs-and-config item)

---

## Parallel Grouping

### PRIMARY Tier

**Round 1** (first item; no dependencies):
- [37] — Flow-server stdio MCP transport
  - T37-1 → T37-2 → T37-3 → T37-4 → T37-5 → T37-6 (strictly ordered within the item)

**Round 2** (after [37] completes):
- [38] — Register flow-server MCP in project settings
  - T38-1 → T38-2 (ordered within the item)

No parallelism within this cycle. The items are strictly sequential.

---

## Dependency Graph (topological sort)

```
[37] T37-1
   └── T37-2 (needs mcp::dispatch to be the right shape to test CLI separately)
         └── T37-3 (calls dispatch)
               └── T37-4 (branches on cfg.mcp, calls run_stdio)
                     └── T37-5 (unit tests for dispatch)
                           └── T37-6 (subprocess story — needs the binary built)
[38] T38-1 (depends on [37] complete)
       └── T38-2
```

No cycles. Topological sort completes cleanly.

---

## VALUE_HANDLER_POOL Required

| Handler | Purpose |
|---|---|
| handler-rust | All Rust code changes (mcp.rs, config.rs, main.rs, test files) |

No other handler types required. Items [37] and [38] are pure Rust + config/markdown.

---

## Architecture Decisions

No ADR required. This item does not introduce a new persistence mechanism, new external integration, new delivery channel, or new bounded context. It adds a second transport mode to an existing MCP surface — the architectural pattern (the store, the domain, the dispatch logic) is already decided and in production. The only architectural question — how to refactor `mcp::handle` so it is callable from both paths — is resolved at the task level (T37-1) without a full ADR.

---

## Missing Handlers

None for this cycle. handler-rust covers all Rust work. The existing handler-rust agent in the pool is sufficient.

---

## Self-Improvement Flags

1. **Axum extractor coupling pattern:** the `mcp::handle` function's use of `State<AppState>` and `Json<Value>` as extractors makes it uncallable outside the axum dispatch chain. This is a recurring pattern risk: any future transport (gRPC, Unix socket, batch processor) would hit the same extraction problem. The refactor in T37-1 establishes the correct pattern (a `dispatch` fn taking plain Rust types, with a thin axum wrapper). Flag for the handler-authoring discipline: new MCP surface functions should be authored with a `dispatch(state: &AppState, req: Value) -> Value` core and a thin transport adapter.

2. **`Config::from_args` boolean flag handling:** the hand-rolled parser currently has no pattern for boolean flags (all existing flags take a value). T37-2 establishes the first boolean flag (`--mcp`). If more boolean flags are added later, the pattern should be documented or the parser should be upgraded to handle them uniformly.

3. **Story test via subprocess (`env!("CARGO_BIN_EXE_..."`):** T37-6 introduces the first subprocess-level story test for this crate. The `CARGO_BIN_EXE_flow-server` approach is the idiomatic Rust way but requires the binary to be built before the test runs (cargo test --bin flow-server first, or use the integration test's own build). Document this in the test file with a clear comment so future contributors are not confused by a "binary not found" failure.

---

## Resumption Instructions

If this plan is interrupted and resumed in a cold-start session:

1. Read `/home/user/Code/idea-to-production/plugins/mission-control/flow-server/src/mcp.rs` to understand the current `handle` and `call_tool` functions.
2. Read `/home/user/Code/idea-to-production/plugins/mission-control/flow-server/src/config.rs` to understand the current flag parser.
3. Read `/home/user/Code/idea-to-production/plugins/mission-control/flow-server/src/main.rs` to understand the startup wiring.
4. Check whether `T37-1` is done by searching for `pub async fn dispatch` in `mcp.rs`. If it exists, T37-1 is complete.
5. Check whether `Config.mcp` exists in `config.rs`. If it does, T37-2 is complete.
6. Check whether `run_stdio` exists in `main.rs` (or a `stdio.rs` module). If it does, T37-3 is complete.
7. Check whether the `--mcp` branch exists in `main.rs`. If it does, T37-4 is complete.
8. Run `cargo test -p flow-server 2>&1 | tail -5` to see the current test state.
9. Check whether `.claude/settings.json` exists at the repo root. If it contains `flow-server`, T38-1 is complete.
10. Check the flow-server README for the `## MCP registration` section. If it exists, T38-2 is complete.
11. Branch for this cycle: `feature/items-37-38-mcp-stdio` (cut from `main` after pulling latest).

**Governance:** pr-approval required before merge to main. One PR covering both [37] and [38] (they are tightly coupled — the registration is meaningless without the stdio transport).
