# Research 03: Testing a Tauri App

Testing axis: unit-testing the pure Rust core with `cargo`, mocking IPC, WebDriver/`tauri-driver` and Playwright for webview story tests, and the fmt+clippy+test gate.

## Unit Testing (Cargo)

- Enable `tauri::test` feature in `Cargo.toml`: `tauri = { version = "2.x", features = ["test"] }`
- `#[tauri::command]` decorators produce regular Rust functions—test them directly with `cargo test`, bypassing IPC
- Use `#[cfg(test)] mod tests { ... }` for isolated command handler test suites
- Mock external deps (DB, HTTP, file IO) with `mockall` or similar—Tauri provides no built-in mocks
- Test command inputs/outputs and error serialization independently from the IPC layer
- Canonical: `cargo fmt --check && cargo clippy && cargo test` before merge

## IPC Mocking & Command Testing

- Commands are invoked from the JS frontend via Tauri's IPC bridge; unit tests call Rust functions directly
- For integration tests, use `tauri::test` module utilities to set up a minimal Tauri runtime
- Validate all inputs in command handlers—frontend is untrusted (treat commands like public HTTP endpoints)
- Test error paths: ensure `Result<T, Error>` return serialization matches frontend's expected JSON schema
- Verify input validation logic catches malformed/adversarial payloads
- Async command handlers need load-testing; watch for race conditions under concurrent invocation

## WebDriver & Playwright (End-to-End)

- **tauri-driver**: standalone WebDriver server that pairs with a running Tauri app; enables full-stack testing
- Compatible with Playwright, Selenium, and standard WebDriver Protocol clients
- Set up: `npm install -D @tauri-apps/cli` provides the driver; configure in your test harness
- Playwright integration: `npx playwright test` with a custom fixture that spawns the app via `tauri-driver`
- Tests the complete flow: frontend UI → JS→Rust IPC serialization → Rust handler → IPC return → webview update
- Webview startup timing: add retry logic to handle app launch delays before first WebDriver connection

## Common Failure Modes & Security Red Flags

### Security

- **Secrets in webview**: env vars, API keys, DB creds must NEVER reach JavaScript; keep them in Rust core only
- **Over-broad capabilities**: tauri.conf.json `allowlist` entries like `shell: { open: true }` enable RCE; use whitelist-only with minimal scope
- **Panics**: unhandled `.unwrap()` or `.panic!()` in command handlers crash the app; always return `Result<T, E>`
- **Unsafe code**: justify all `unsafe { }` blocks with `// SAFETY:` comments; no blind transmutes or raw pointer casts

### Testing & Reliability

- **IPC serialization mismatches**: Rust struct field names must match JSON keys from JavaScript; test round-trip serialization
- **Race conditions**: async handlers under high concurrency; load-test with concurrent command invocations
- **WebDriver flakes**: app startup is slow; add exponential backoff when connecting to tauri-driver
- **Binary secrets**: use `cargo strip` and check that `strings <binary>` reveals no hardcoded keys or URLs

## Test Gate & Validation

```bash
# Before commit
cargo fmt --check      # Code style
cargo clippy           # Lint & warnings
cargo test --lib       # Unit tests
cargo test --test '*'  # Integration tests (if present)
```

- Gate passes only if all three succeed
- CI should run on Linux, macOS, Windows to catch platform-specific panics
- WebDriver tests add E2E validation but are slower; run in separate stage or on PR approval

## Sources & Canonical Tooling

- **Tauri 2.x** (`https://crates.io/crates/tauri`): use 2.x branch; 1.x is EOL
- **tauri-driver** (`https://crates.io/crates/tauri-driver`): WebDriver integration
- **Playwright** (`https://playwright.dev/`): cross-browser webview automation
- **mockall** (`https://docs.rs/mockall/`): mock derive macro for Rust dependencies
- **serde** (`https://docs.rs/serde/`): JSON serialization; validate schema in tests
