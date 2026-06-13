# Research 02: Tauri Project Layout & Build Architecture

## Project Structure (Canonical v2.x)

- **Top-level JS app** + **`src-tauri/` Cargo crate** pattern: frontend framework (Vite/SvelteKit/Next) compiles to static files → bundled into Rust app by `tauri build`
- **Core files in `src-tauri/`:**
  - `Cargo.toml` — workspace dependencies; typically just `tauri`, `serde`, optional `tokio` for async commands
  - `tauri.conf.json` — app ID, dev server URL, build hooks (`beforeDevCommand`, `frontendDist`), bundle config
  - `src/lib.rs` — main backend logic, command definitions, state setup; **preferred over `main.rs`** for mobile/desktop parity
  - `src/main.rs` — thin desktop entry point that calls `app_lib::run()`
  - `build.rs` — runs `tauri_build::build()` at compile time (icons, capability validation)
  - `capabilities/default.json` — IPC permission declarations (which commands accessible, shell scope)
  - Source: [Tauri v2 Project Structure](https://v2.tauri.app/start/project-structure/)

## tauri::Builder & State Management

- **Builder pattern** is the sole orchestration point; fluent chaining:
  ```rust
  tauri::Builder::default()
    .manage(AppState { db: Database::new() })
    .manage(Config::load())
    .invoke_handler(tauri::generate_handler![cmd_a, cmd_b, cmd_c])
    .run(tauri::generate_context!())
    .expect("error while running tauri application")
  ```
- **Commands** annotated with `#[tauri::command]` macro; state injected via `tauri::State<T>`:
  ```rust
  #[tauri::command]
  fn fetch_data(state: tauri::State<AppState>) -> String { ... }
  ```
- **Critical constraint:** `.invoke_handler()` can only be called once; all commands must be collected in a single `generate_handler![...]` macro — design upfront for command organization (modules, traits)
- **State thread-safety:** Tauri uses `Arc<Mutex<T>>` internally; state is shared across all command invocations and window contexts
- Source: [Calling Rust from Frontend](https://v2.tauri.app/develop/calling-rust/)

## Frontend ↔ Rust Communication

- **IPC via commands:** JavaScript invokes Rust functions through `invoke('command_name', { arg: value })`
- **Response channels:** async/await on JS side, return types must be JSON-serializable (use `serde::{Serialize, Deserialize}`)
- **Events:** bidirectional pub/sub for backend → frontend notifications (`emit`, `listen`)
- **No direct memory access** — all communication is serialized over IPC boundaries, enforcing natural separation

## Sidecar Binaries (External Process Isolation)

- **Configuration in `tauri.conf.json`:**
  ```json
  "bundle": {
    "externalBin": ["path/to/my-sidecar"]
  }
  ```
- **Platform naming convention:** Binary must exist as `my-sidecar-x86_64-unknown-linux-gnu`, `my-sidecar-aarch64-apple-darwin`, etc. for each supported target triple
- **Invocation from Rust:**
  ```rust
  use tauri_plugin_shell::ShellExt;
  app.shell().sidecar("my-sidecar")?.spawn()?
  ```
- **Invocation from JS:** `Command.sidecar()` from `@tauri-apps/plugin-shell`
- **Permission boundaries:** Explicit capability declarations required (`shell:allow-execute`, `shell:allow-spawn` with validators)
- **Process isolation:** Sidecars run as independent child processes; no shared memory with main app
- Source: [Embedding External Binaries](https://v2.tauri.app/develop/sidecar/)

## Keeping Domain Core Testable & UI-Free

### Crate Architecture Pattern
- **Separate Rust libraries** (not coupled to Tauri):
  - `my-domain/Cargo.toml` — pure business logic, zero UI/IO dependencies
    ```toml
    [dependencies]
    serde = { version = "1.0", features = ["derive"] }
    # NO tauri, NO tokio unless already needed
    ```
  - `my-domain/src/lib.rs` — exposes `pub fn process(input: &str) -> Result<Output>`
  - Unit tests at the domain level (no runtime, no IPC)

- **Thin Tauri command layer** in `src-tauri/src/commands.rs`:
  ```rust
  use my_domain::process;
  
  #[tauri::command]
  pub fn invoke_process(input: String, state: tauri::State<AppState>) -> Result<String> {
    // Minimal: extract context, call pure fn, return serialized result
    let result = process(&input)?;
    Ok(serde_json::to_string(&result)?)
  }
  ```

### Build & Test Workflow
- **`cargo test` in domain crate** — runs pure logic tests independently, no Tauri runtime
- **`cargo build -p my-domain`** — compiles domain logic without Tauri bloat
- **`tauri dev`** — compiles frontend + full app with commands/state for integration testing
- **`tauri build`** — orchestrates full build pipeline:
  1. Runs `beforeDevCommand` / `beforeBuildCommand`
  2. Compiles Rust backend (`cargo build --release`)
  3. Bundles frontend assets (from `frontendDist`)
  4. Links sidecars (matches platform triples)
  5. Runs platform-specific bundlers (dmg, msi, deb, etc.)
- Source: [Tauri CLI Architecture](https://deepwiki.com/tauri-apps/tauri/7.1-cli-architecture-and-commands), [Build Process](https://deepwiki.com/tauri-apps/tauri/7.3-build-process-(tauri-build))

## Common Failure Modes & Validation

1. **State mutability:** State accessed via `tauri::State<T>` is `Arc<Mutex<T>>`; forgetting `.lock()` or not implementing `Send + Sync` → compile error (good!)
2. **Serialize/Deserialize mismatch:** Command args/returns must derive `serde::{Serialize, Deserialize}` for IPC → runtime panic if missing
3. **Multiple `invoke_handler` calls:** Only last registration is used → silent failure of earlier commands; validate with `tauri dev` integration tests
4. **Sidecar platform triple mismatch:** Binary names must exactly match target triple; test via `file path/to/binary` and cross-compile validation
5. **Capability permission gaps:** Commands fail silently if not declared in `capabilities/default.json`; use `tauri dev` with console logging to diagnose

### Testing & Validation Strategy
- **Unit tests:** `cargo test` in domain crate (pure Rust, no Tauri)
- **Integration tests:** Tauri driver tests or manual `tauri dev` → JS invoke + assert response
- **Sidecar validation:** Write a simple test binary, place platform variants, run `tauri dev`, verify spawn succeeds
- **State isolation:** Test that state mutations from one command don't leak to others (use `Arc<Mutex<T>>` assertions)
- **Command invocation:** Test JS → Rust → Domain → JS round-trip with known inputs/outputs

## Recommended Project Layout

```
my-app/
├── package.json (frontend meta)
├── index.html
├── src/ (frontend code: Svelte, React, etc.)
├── src-tauri/
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   ├── src/
│   │   ├── lib.rs (builder, state setup)
│   │   ├── commands.rs (IPC layer)
│   │   └── main.rs (entry point, calls lib::run())
│   ├── capabilities/default.json
│   └── build.rs (tauri_build::build())
├── crates/
│   └── my-domain/ (pure logic, zero Tauri/IO)
│       ├── Cargo.toml
│       ├── src/lib.rs
│       └── tests/
└── sidecars/
    ├── my-sidecar/ (separate binary project)
    │   ├── Cargo.toml
    │   └── src/main.rs
    └── build-sidecars.sh (cross-compile & place x86_64-*, aarch64-*, etc.)
```

## Canonical Tooling & Versions (2026)

- **Tauri 2.x** (v2.0+): use `v2.tauri.app/*` docs (v1 is deprecated)
- **Rust 1.70+**: required for Tauri 2; use `rustup update`
- **Node.js 18+**: for Tauri CLI (`@tauri-apps/cli` npm package)
- **Platform SDKs:** macOS (Xcode), Windows (Visual Studio Build Tools), Linux (gcc, libssl-dev)
- **Vite 5.x** or equivalent: recommended frontend bundler for dev/prod parity
- Source: [Tauri CLI Reference](https://v2.tauri.app/reference/cli/)

## Sources

- [Tauri v2 Project Structure](https://v2.tauri.app/start/project-structure/)
- [Calling Rust from Frontend](https://v2.tauri.app/develop/calling-rust/)
- [Embedding External Binaries / Sidecars](https://v2.tauri.app/develop/sidecar/)
- [Tauri CLI Architecture](https://deepwiki.com/tauri-apps/tauri/7.1-cli-architecture-and-commands)
- [Build Process (tauri build)](https://deepwiki.com/tauri-apps/tauri/7.3-build-process-(tauri-build))
- [Tauri State Management](https://medium.com/@marm.nakamura/trying-to-the-tauri-gui-on-rust-4-state-management-on-the-tauri-side-8899bda08936)
