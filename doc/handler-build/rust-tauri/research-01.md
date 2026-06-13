# Tauri v2 Architecture Research

## Backend ↔ Webview Boundary

- **Trust model**: Two distinct trust zones—Rust backend (trusted) and WebView frontend (untrusted by default). IPC layer is the strict enforcement boundary. OS native webviews (WebView2 on Windows, WKWebView on macOS, WebKitGTK 4.1 on Linux) isolate frontend code, preventing direct system access.
- **IPC protocol**: JSON-RPC-like serialization over message-passing channel. All arguments and return values must be `serde::Serialize`/`serde::Deserialize`. Async by default via Promise-based invocations.
- **Runtime foundation**: Built on TAO (cross-platform window management) and WRY (webview abstraction), with tauri-runtime and tauri-runtime-wry glue layers. Compile-time processing via tauri-build/tauri-codegen handles `tauri.conf.json` and asset embedding.
- **Binary size**: OS webview leveraging yields ~10–15 MB footprint vs. ~100+ MB for Electron—security patching delegated to OS vendors.

## `#[tauri::command]` IPC Macro

- **Basic pattern**: Rust function decorated with `#[tauri::command]`, registered via `tauri::generate_handler![cmd1, cmd2, ...]` and bound to `.invoke_handler()`. Frontend calls via `@tauri-apps/api/core::invoke()`.
- **Argument handling**: Any `serde::Deserialize` type. Front-end JSON keys must be camelCase. Borrowed types (`&str`) fail in async signatures—use `String` or wrap in `Result`.
- **Return types**: `Result<T, E>` for error propagation (promise rejection). `E` must `impl serde::Serialize`. Async functions are non-blocking; sync functions run on the main thread (risk of UI freeze).
- **Special parameters**: `WebviewWindow`, `AppHandle`, `State<T>`, `tauri::ipc::Request` auto-injected by macro. No explicit binding required—detected by type signature.
- **Dynamic commands (events)**: Alternative to commands: `emit()`/`listen()`/`unlisten()` for untyped JSON payloads. No return values, always async. Less type-safe; prefer commands for stable APIs.

## Capability/Permission ACL in `tauri.conf.json`

- **Architecture**: Capabilities (JSON/TOML files in `src-tauri/capabilities/`) define per-window permission sets. Each capability maps to a list of allowed commands + scopes. Referenced in `tauri.conf.json` or inlined. Platform-specific overrides via `windows`, `macos`, `linux` keys.
- **Default deny**: WebView cannot access any command unless explicitly granted via capability. Even custom commands require explicit declaration—single most common v2 upgrade surprise.
- **Scopes**: Fine-grained runtime authority within a permission (e.g., `fs:scope:/allowed/path` to limit file access to specific directories). Validator schemas provided for IDE autocompletion.
- **Window isolation**: Each window can be assigned different capabilities. Overlapping capabilities merge their permissions—**cannot reduce permissions by reassigning window to subset of capabilities**.
- **Remote sources**: Optional URL patterns allow webviews loaded from CDN/remote origins to access certain commands (security-critical: validate each use case).
- **Schema validation**: Use platform-specific JSON schemas (`https://api.tauri.app/schema/...`) for IDE support. TOML format gains readability but requires manual schema setup.

## App & Window Lifecycle

- **App lifecycle**: `Builder::setup()` runs synchronously before event loop starts (blocking, no parallelism). Use for initializing plugins, state, global listeners. `App<R>` owns the application; `AppHandle` is cloneable reference.
- **Window events**: Register via `.on_window_event()`, `.on_webview_event()`. Events: `Focused`, `ScaleFactorChanged`, `FileDropped`, `CloseRequested`, etc. `CloseRequested` can veto close; `ExitRequested` fires when last window closes.
- **Manager trait**: Both `App` and `AppHandle` implement `Manager`, providing window/state/event/plugin APIs. Choose based on lifecycle phase (setup → `App`, runtime → `AppHandle`).
- **Plugin hooks**: Plugins register lifecycle hooks via `RunEvent` enum: `ExitRequested`, `Exit`, `WindowEvent`, etc. Lifecycle is global + per-window scoped.
- **Setup ordering**: Plugins init → app setup hooks → event loop. Failed setup aborts launch.

## CSP & Security Isolation

- **Content Security Policy**: Configurable in `tauri.conf.json` under `security.csp`. Restricts script sources, object sources, connect sources. Typical hardening: `default-src 'self'`, `script-src 'self' 'wasm-unsafe-eval'` (for WASM), `connect-src https:` (remote APIs only).
- **Isolation pattern**: Preload script (`src-tauri/tauri.conf.json::security.dangerousRemoteDomainIpcAccess`) optional for legacy HTML; modern approach: inline bootstrap via `document.addEventListener('DOMContentLoaded')` and `window.__TAURI__` namespace injection.
- **Core purity**: Rust backend is pure—no FFI to C libraries unless audited. Tauri controls all system calls via TAO/WRY. WebView sandboxing relies on OS implementation; Tauri enforces boundaries via capability ACL.
- **Threat model**: Assumes compromised frontend (XSS) and Rust code are in different trust zones. Does NOT protect against malicious Rust code or compromised developer system. IPC boundary is the firewall.

## Testing & Validation

- **Unit tests**: Commands can be tested as regular Rust functions. Mock `State<T>` using test fixtures; use `tauri::test::mock_builder()` for app integration tests.
- **Integration tests**: Use `tauri-driver` with WebDriver Protocol (WDP) to automate UI. Alternative: `@tauri-apps/api` in test runners (Vitest, Jest) + `--test` CLI flag.
- **Capability validation**: Simulate permission denial by omitting command from capability JSON; verify frontend receives IPC error (rejected promise).
- **Lifecycle hooks**: Add instrumentation (logging, metrics) in setup/run/exit phases. Use plugin hooks for cross-cutting concerns (telemetry, crash reporting).
- **CSP testing**: Browser DevTools in `tauri://` context; CSP violations logged to console. Use `tauri app --dev` to iterate.

## Common Failure Modes & Mitigations

1. **Command not registered**: Symptom: "unknown invoke key" error. Mitigation: Ensure `generate_handler!` includes command; verify capabilities grant permission.
2. **Async + borrowed types**: Symptom: compilation error with `&str` in async fn. Mitigation: Use `String` or `Arc<str>`; wrap in `Result` for error handling.
3. **Capability merge override**: Symptom: window assigned to two capabilities still has merged (stricter) permissions. Mitigation: Create explicit minimal capability; audit capability inheritance.
4. **CSP blocking inline scripts**: Symptom: scripts fail silently; check DevTools console. Mitigation: Use `nonce-` or hash-based CSP; avoid inline `<script>` tags.
5. **Type mismatch serialization**: Symptom: "could not serialize" or "deserialize" error. Mitigation: Ensure frontend JSON keys match Rust struct field names (camelCase convention); check `serde` derive correctness.
6. **Setup blocking event loop**: Symptom: UI freeze on startup. Mitigation: Offload heavy I/O to background thread via `std::thread` or tokio task; complete setup quickly.

## Canonical Versions & Tooling

- **Tauri v2 stable**: `2.x` (current production release). v1 is deprecated but receives critical patches. v2 breaking changes from v1: command registration API, capability system mandatory, plugin API redesign.
- **Frontend API**: `@tauri-apps/api@2.x` (npm package). Provides `invoke()`, `event`, `fs`, `window`, etc. Auto-synced with Tauri Rust version.
- **Build tools**: `tauri-cli` handles scaffolding + bundling. Installation: `cargo binstall tauri-cli` or `npm add -D @tauri-apps/cli`. Minimal Rust: `cargo new --bin myapp && cargo add tauri`.
- **Plugin ecosystem**: Published to `@tauri-apps/{plugin-name}` (npm) + crates.io. Official: fs, http, clipboard, updater, notification, dialog, barcode-scanner, websocket. Custom plugins implement `Plugin` trait.
- **Bundler**: Generates native installers (.exe, .dmg, .deb, .msi) with code signing. Configured in `tauri.conf.json::bundle`.
- **IDE support**: VS Code extension `tauri.tauri` (Microsoft/Tauri team). JSON schema auto-completion via `https://api.tauri.app/schema/`.

## Sources

- [Tauri v2 Architecture — Tauri Documentation](https://v2.tauri.app/concept/architecture/)
- [Calling Rust from the Frontend — Tauri Documentation](https://v2.tauri.app/develop/calling-rust/)
- [Capabilities — Tauri Documentation](https://v2.tauri.app/security/capabilities/)
- [Permissions — Tauri Documentation](https://v2.tauri.app/security/permissions/)
- [Security Overview — Tauri Documentation](https://v2.tauri.app/security/)
- [Inter-Process Communication — Tauri Documentation](https://v2.tauri.app/concept/inter-process-communication/)
- [Plugin Development — Tauri Documentation](https://v2.tauri.app/develop/plugins/)
- [Application Lifecycle (App and AppHandle) — DeepWiki](https://deepwiki.com/tauri-apps/tauri/2.2-application-lifecycle-(app-and-apphandle))
- [Window and Webview Management — DeepWiki](https://deepwiki.com/tauri-apps/tauri/2.3-window-and-webview-management)
