---
name: item-37-mcp-stdio
description: Item [37] delivery patterns — axum extractor decoupling, io-std feature requirement, CARGO_BIN_EXE in lib vs integration tests, TempDir vs PathBuf in subprocess tests
metadata:
  type: project
---

# Item [37] — Flow-server stdio MCP transport

**Commit:** ad8082e
**Branch:** feature/items-37-38-mcp-stdio

## Key patterns from this delivery

### Axum extractor decoupling (T37-1)
When a handler uses `State<AppState>` and `Json<Value>` axum extractors, it cannot
be called outside the axum dispatch chain. The correct refactor: extract a
`dispatch(state: &AppState, req: Value) -> Value` core fn returning plain `Value`,
and make the axum handler a one-liner:
```rust
pub async fn handle(State(state): State<AppState>, Json(req): Json<Value>) -> Response {
    Json(dispatch(&state, req).await).into_response()
}
```
The response builders must also return `Value` instead of `Response`. This is the
load-bearing change that enables any transport to call the same logic.

**Why:** Any future transport (stdio, gRPC, Unix socket) that tries to call the
handler directly will fail at compile time with "cannot find extractor".

**How to apply:** Whenever a new transport is added, look for extractor-coupled
handlers first. The fix is always the same: extract the core logic into a plain-fn
`dispatch(state: &AppState, req: T) -> R` and wrap with the transport adapter.

### `tokio::io::stdin/stdout` requires `io-std` feature
`tokio::io::stdin()` and `tokio::io::stdout()` are gated behind the `io-std` feature,
NOT `io-util`. Adding `io-util` is not sufficient. Add `io-std` to `[dependencies]`:
```toml
tokio = { version = "1.40", features = ["rt-multi-thread", "...", "io-util", "io-std"] }
```

**Why:** This is a footgun — `io-util` sounds like it would cover all IO, but stdin/stdout
are a separate feature. The error message "found an item that was configured out" with
`#[cfg(feature = "io-std")]` is the diagnostic.

### `CARGO_BIN_EXE_<name>` only works in integration tests (not lib tests)
The `env!("CARGO_BIN_EXE_flow-server")` macro resolves the compiled binary path.
It ONLY works in files under `tests/` (integration tests), NOT in `src/` lib tests.
In lib tests it produces: `error: environment variable CARGO_BIN_EXE_... not defined at compile time`.

**Fix:** Put subprocess story tests in `tests/stdio_story.rs`, NOT in `src/stdio_story_intest.rs`.
Also need `process` feature in dev-dependencies:
```toml
tokio = { version = "1.40", features = ["...", "process"] }
```

**How to apply:** Any test that spawns the compiled binary must live under `tests/`.
The lib (in-crate) test approach works for everything that doesn't need the binary.

### `PathBuf` has no `.path()` method — use `&dir` directly
A custom `tempdir()` helper returning `PathBuf` cannot call `.path()` (that's on
`tempfile::TempDir`). Use `&dir` or `dir.as_path()` directly with `.arg()`.

### `--mcp` warning always emits
The EARS requirement says log a warning when `--mcp` and `--port` are both supplied.
Simplest implementation: always emit the warning in `--mcp` mode:
```rust
eprintln!("flow-server: --mcp mode active; --port is ignored");
```
This is correct — if `--mcp` is present, the port is ALWAYS ignored, so the warning
is never wrong. Detecting "was --port explicitly passed" would require extra state.

### Boolean flag pattern for hand-rolled arg parser
The hand-rolled `Config::from_args` parser only had value-taking flags before [37].
The first boolean flag pattern:
```rust
"--mcp" => { cfg.mcp = true; }
```
No `it.next()` call — the flag consumes itself. Must be placed BEFORE the `other =>`
catch-all. [[item-36-gate-persist]]
