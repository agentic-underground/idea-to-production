# Rust + Tauri Desktop Frontend — Knowledge Wall

**Purpose**: Raw material for the agent-author building the `foundry:rust-webapp-rollout` or any
handler that generates a Tauri v2 desktop app. Read before writing a single line of scaffold.

---

## 1. Prime Directives (Non-Negotiable)

1. **Trust boundary is absolute.** Rust backend = trusted; WebView = untrusted. Every IPC command
   is a public API surface. Treat all inputs as adversarial — validate, sanitize, reject.
2. **Secrets never cross the IPC boundary.** API keys, DB credentials, env vars stay in Rust only.
   No `std::env::var(...)` return over `invoke()`. No exceptions.
3. **Always return `Result<T, E>`.** Unhandled `.unwrap()` / `.expect()` in a command handler
   crashes the entire app process. `E` must `impl serde::Serialize` for the rejection to surface
   in the frontend promise chain.
4. **Default-deny ACL.** Every `#[tauri::command]` must be explicitly listed in a capabilities
   file (`src-tauri/capabilities/`). An unlisted command silently fails at runtime — this is
   intentional and non-negotiable security architecture, not a bug.
5. **`invoke_handler` called exactly once.** All commands must be collected in a single
   `tauri::generate_handler![...]`. A second call silently discards the first; earlier commands
   vanish with no compiler warning.
6. **Domain logic lives in a separate crate.** The `src-tauri` crate is the IPC adapter only.
   Business logic belongs in `crates/my-domain/` with zero Tauri or async-runtime dependencies.
   This is the single most important architectural rule for long-term testability.
7. **No `unsafe` without `// SAFETY:` justification.** No blind transmutes, no raw pointer casts.
   Audit via `cargo clippy -- -D unsafe_code` or equivalent lint gate.
8. **No borrowed types in async command signatures.** `&str` in an `async fn` tagged
   `#[tauri::command]` fails compilation. Use `String` or `Arc<str>`.

---

## 2. Canonical Tooling & Pinned Versions

| Tool | Version | Notes |
|---|---|---|
| Tauri Rust crate | `2.x` (2.0+) | v1 is deprecated/EOL; all docs at `v2.tauri.app` |
| `@tauri-apps/api` | `2.x` | Auto-synced with Rust crate; provides `invoke()`, `event`, etc. |
| `@tauri-apps/cli` | `2.x` | npm devDep; also `cargo binstall tauri-cli` |
| Rust toolchain | `1.70+` | Required minimum for Tauri 2; keep current via `rustup update` |
| Node.js | `18+` | For CLI tooling and frontend builds |
| Vite | `5.x` | Recommended frontend bundler; `tauri dev` hooks into `beforeDevCommand` |
| `serde` | `1.0` with `derive` feature | Mandatory for all IPC types |
| `mockall` | latest | Rust mock derive macro for unit testing command deps |
| `tauri-driver` | matches Tauri 2.x | WebDriver server for E2E; separate install |
| Playwright | latest | Cross-browser/webview E2E automation against `tauri-driver` |

**Platform SDKs required at build time:**
- macOS: Xcode Command Line Tools
- Windows: Visual Studio Build Tools (MSVC)
- Linux: `gcc`, `libssl-dev`, `libgtk-3-dev`, `libwebkit2gtk-4.1-dev`
- Linux WebView: WebKitGTK 4.1 (not 4.0; v2 is strict about this)

**IDE**: VS Code extension `tauri.tauri`; JSON schema autocomplete via `https://api.tauri.app/schema/`

---

## 3. Canonical Project Layout

```
my-app/
├── package.json              # frontend meta
├── index.html
├── src/                      # frontend (Svelte / React / Vue)
├── src-tauri/
│   ├── Cargo.toml            # tauri, serde; reference workspace members
│   ├── tauri.conf.json       # app ID, devUrl, frontendDist, bundle, security.csp
│   ├── build.rs              # tauri_build::build() — icons + capability validation
│   ├── src/
│   │   ├── lib.rs            # Builder, .manage(), .invoke_handler(), state init (prefer over main.rs)
│   │   ├── commands.rs       # #[tauri::command] functions — thin adapters only
│   │   └── main.rs           # calls lib::run(); thin desktop entry point
│   └── capabilities/
│       └── default.json      # IPC ACL declarations
├── crates/
│   └── my-domain/            # pure business logic, zero Tauri/IO deps
│       ├── Cargo.toml        # serde only; no tauri, no tokio unless required
│       ├── src/lib.rs
│       └── tests/
└── sidecars/                 # external process binaries (optional)
    ├── my-sidecar/
    │   ├── Cargo.toml
    │   └── src/main.rs
    └── build-sidecars.sh     # cross-compile → name as <bin>-<target-triple>
```

**Why `lib.rs` over `main.rs`?** Enables the same `run()` fn to compile for both desktop and
mobile Tauri targets without a conditional entry point.

---

## 4. Key Idioms

### Builder Skeleton

```rust
// src-tauri/src/lib.rs
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(AppState { db: Database::new() })
        .manage(Config::load())
        .invoke_handler(tauri::generate_handler![
            commands::cmd_a,
            commands::cmd_b,
        ])
        .setup(|app| {
            // Synchronous; fast only. No blocking I/O here.
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### Command Handler Pattern

```rust
// src-tauri/src/commands.rs
use my_domain::process;

#[tauri::command]
pub async fn invoke_process(
    input: String,                        // String not &str in async
    state: tauri::State<'_, AppState>,
) -> Result<OutputDto, String> {          // E must be Serialize
    let result = process(&input).map_err(|e| e.to_string())?;
    Ok(OutputDto::from(result))
}
```

### State Pattern

```rust
// State is Arc<Mutex<T>> internally; access:
let guard = state.db.lock().unwrap(); // or .map_err(...)
```

### Capabilities File

```json
// src-tauri/capabilities/default.json
{
  "identifier": "default",
  "description": "Default capability",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "my-custom:allow-invoke-process"
  ]
}
```

### Events (Backend → Frontend Push)

```rust
// When you need push without a command response:
app_handle.emit("event-name", payload)?;
// JS: await listen('event-name', (e) => { ... })
```

Prefer commands for request/response; use events for unsolicited notifications only.

### Sidecar Registration

```json
// tauri.conf.json
"bundle": { "externalBin": ["sidecars/my-sidecar"] }
```

```rust
use tauri_plugin_shell::ShellExt;
app.shell().sidecar("my-sidecar")?.spawn()?;
```

Sidecar binaries must be named `<bin>-<target-triple>` (e.g.,
`my-sidecar-x86_64-unknown-linux-gnu`). One binary per supported platform.

### CSP Hardening

```json
// tauri.conf.json
"security": {
  "csp": "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; connect-src https:"
}
```

---

## 5. Anti-Patterns & Failure Modes

| Symptom | Root Cause | Fix |
|---|---|---|
| "unknown invoke key" at runtime | Command missing from `generate_handler![]` or missing from capabilities JSON | Add to both; restart `tauri dev` |
| `&str` in `async fn` compile error | Borrowed types not valid in async command signatures | Use `String` or `Arc<str>` |
| Silent command failure (no error) | `invoke_handler` called twice; only last wins | Merge all commands into single `generate_handler![]` |
| Capability "merge" gives MORE perms | Two capabilities assigned to one window merge additively — cannot restrict by reassigning | Create a minimal explicit capability; audit inheritance |
| CSP blocks inline scripts silently | Inline `<script>` forbidden by `default-src 'self'` | Use nonce-/hash-based CSP; move scripts to external files |
| Serde "could not deserialize" | JS sends camelCase keys; Rust struct uses snake_case without `#[serde(rename_all)]` | Add `#[serde(rename_all = "camelCase")]` to Rust structs |
| UI freeze on startup | Heavy I/O in `setup()` — blocks the event loop | Move to `std::thread::spawn` or `tokio::spawn` in setup |
| State mutation race | `Arc<Mutex<T>>` guard held across await point | Use `tokio::sync::Mutex` for async-held locks |
| WebDriver connection refused | App not fully started before test runner connects | Add exponential backoff / retry in test fixture |
| Hardcoded secret in binary | Key embedded in Rust string literal | Use env vars at build time; verify with `strings <binary>` |
| `shell: { open: true }` in conf | Grants RCE-equivalent capability | Use whitelist-only shell scope; minimum surface |
| Linux WebKitGTK version wrong | WebKitGTK 4.0 installed; Tauri 2 requires 4.1 | Install `libwebkit2gtk-4.1-dev`; check with `pkg-config` |

---

## 6. Environment Detection Snippet

Use this at the top of a scaffold script or in `build.rs` to gate platform-specific build steps:

```bash
#!/usr/bin/env bash
# Detect platform prerequisites before tauri build

detect_tauri_env() {
  local errors=0

  # Rust toolchain
  if ! rustc --version 2>/dev/null | grep -qE '1\.(7[0-9]|[89][0-9]|[1-9][0-9]{2})'; then
    echo "ERROR: Rust 1.70+ required. Run: rustup update" >&2
    ((errors++))
  fi

  # Tauri CLI
  if ! command -v cargo-tauri &>/dev/null && ! npx @tauri-apps/cli --version &>/dev/null 2>&1; then
    echo "ERROR: tauri-cli not found. Run: cargo binstall tauri-cli" >&2
    ((errors++))
  fi

  # Node
  local node_ver; node_ver=$(node --version 2>/dev/null | tr -d 'v' | cut -d. -f1)
  if [[ -z "$node_ver" || "$node_ver" -lt 18 ]]; then
    echo "ERROR: Node.js 18+ required." >&2
    ((errors++))
  fi

  # Linux-specific WebKit
  if [[ "$(uname -s)" == "Linux" ]]; then
    if ! pkg-config --exists webkit2gtk-4.1 2>/dev/null; then
      echo "ERROR: libwebkit2gtk-4.1-dev missing. Install via apt/dnf/pacman." >&2
      ((errors++))
    fi
    if ! pkg-config --exists gtk+-3.0 2>/dev/null; then
      echo "ERROR: libgtk-3-dev missing." >&2
      ((errors++))
    fi
  fi

  # macOS Xcode CLI tools
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! xcode-select -p &>/dev/null; then
      echo "ERROR: Xcode CLI tools missing. Run: xcode-select --install" >&2
      ((errors++))
    fi
  fi

  if [[ $errors -gt 0 ]]; then
    echo "Environment check failed ($errors issue(s))." >&2
    return 1
  fi
  echo "Tauri environment OK."
}

detect_tauri_env
```

---

## 7. Test & Validation Strategy

### Layer 1 — Domain Unit Tests (fast, no runtime)

```bash
cargo test -p my-domain
```

Pure Rust functions, zero Tauri. This is the primary quality gate; run on every save.

### Layer 2 — Command Handler Tests (Tauri test feature)

Enable in `Cargo.toml`:
```toml
[dev-dependencies]
tauri = { version = "2", features = ["test"] }
mockall = "*"
```

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use tauri::test::mock_builder;

    #[tokio::test]
    async fn test_invoke_process_roundtrip() {
        // Build minimal app, call command function directly (bypass IPC)
        let result = invoke_process("known-input".into(), /* mock state */).await;
        assert!(result.is_ok());
    }
}
```

Test all `Result` error paths and serialization shapes.

### Layer 3 — Pre-commit Gate

```bash
cargo fmt --check          # style
cargo clippy               # lint (fail on warnings in CI: -- -D warnings)
cargo test --lib           # unit tests
cargo test --test '*'      # integration tests (if present)
```

Run on Linux, macOS, and Windows in CI — platform-specific panics are real.

### Layer 4 — IPC Round-trip Integration

Manual or scripted: `tauri dev` → JS `invoke()` with known payloads → assert JSON shape.
Check capability denial: remove command from capabilities JSON, confirm frontend receives rejected
promise (not a crash).

### Layer 5 — E2E WebDriver (PR gate, slower)

```bash
# Terminal 1
cargo tauri build --debug
./src-tauri/target/debug/my-app &

# Terminal 2
cargo install tauri-driver
tauri-driver &
npx playwright test
```

Add exponential backoff in Playwright fixture for app startup (typical: 2–5 s cold start).
Run E2E in a separate CI stage or gated on PR approval — not every commit.

### Sidecar Validation

1. Build sidecar: `cargo build -p my-sidecar --target x86_64-unknown-linux-gnu`
2. Copy to `src-tauri/` with triple in filename: `my-sidecar-x86_64-unknown-linux-gnu`
3. `tauri dev` → verify spawn succeeds (log from Rust side)
4. `strings ./target/.../my-app | grep -i key` — confirm no secrets leaked

---

## 8. Thin Spots — What the Research Left Underspecified

- **Updater plugin (`tauri-plugin-updater`) flow**: research covers the bundler/signing
  concept but gives no end-to-end update server config or key management recipe. Fetch
  `https://v2.tauri.app/plugin/updater/` before building an auto-update handler.
- **Mobile targets (iOS/Android)**: mentioned as a motivation for `lib.rs` over `main.rs` but
  not covered. Tauri 2 does support mobile; the capability system and build pipeline differ
  materially. Treat as out of scope until explicitly required.
- **Workspace Cargo.toml setup**: research shows per-crate `Cargo.toml` examples but does not
  show the workspace root config that ties `src-tauri` + `crates/my-domain` + `sidecars/` into
  a single `cargo build`. Author must supply this.
- **Code signing**: bundler config mentioned; no recipe for certificate provisioning on any
  platform. Critical for distributing outside stores.
- **Async runtime choice**: research says "use tokio" but Tauri 2 ships its own async runtime
  wrapper. Explicit `tokio` as a direct dep can conflict. Verify via `tauri::async_runtime::spawn`
  before adding `tokio` to `Cargo.toml`.
- **`tauri-driver` installation path**: research says "npm install provides the driver" but
  `tauri-driver` is actually a separate Rust binary (`cargo install tauri-driver`), not bundled
  with `@tauri-apps/cli`. Research-03 source list is correct; the body text is misleading.

---

## Sources (Reconciled)

- `https://v2.tauri.app/concept/architecture/`
- `https://v2.tauri.app/develop/calling-rust/`
- `https://v2.tauri.app/security/capabilities/`
- `https://v2.tauri.app/security/`
- `https://v2.tauri.app/concept/inter-process-communication/`
- `https://v2.tauri.app/develop/plugins/`
- `https://v2.tauri.app/develop/sidecar/`
- `https://v2.tauri.app/start/project-structure/`
- `https://v2.tauri.app/reference/cli/`
- `https://deepwiki.com/tauri-apps/tauri/` (architecture, lifecycle, build process)
- `https://docs.rs/mockall/`
- `https://playwright.dev/`
