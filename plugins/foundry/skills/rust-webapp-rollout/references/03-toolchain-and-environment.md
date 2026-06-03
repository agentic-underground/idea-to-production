# 03 — Toolchain & Environment

> **Purpose:** Exactly what must be installed, why each piece exists, how `xtask` makes it
> one command, and **what the handler must ask of / require from the user** (the parts an
> agent cannot do alone).
>
> **TL;DR:** `cargo xtask setup` installs the Rust+WASM+`dx`+`zig`+`cargo-zigbuild`+system
> libs. The Vercel CLI is a separate Node install the **user** must authenticate
> (`vercel login`) and link (`vercel link`). `cargo xtask check` verifies the toolchain;
> `cargo xtask ci` is the gate.

---

## 1. The install list (and why each item exists)

| Component | Proven version | Purpose | Installed by |
|---|---|---|---|
| Rust toolchain (stable) | 1.96.0 | the compiler | rustup, pinned by `rust-toolchain.toml` |
| `wasm32-unknown-unknown` target | — | the web compile target | `xtask setup` |
| `rustfmt`, `clippy` | — | the CI gate | `xtask setup` |
| Dioxus CLI (`dx`) | 0.7.9 | `dx bundle` (web → static), `dx serve` | `xtask setup` (**`--locked`**) |
| GTK 3 + WebKit2GTK 4.1 + glib | distro | desktop/mobile renderer backend | `xtask setup` (apt, Debian/Ubuntu) |
| `libxdo-dev` | distro | links `-lxdo` for the desktop/mobile renderer | `xtask setup` (apt) |
| `cargo-zigbuild` | 0.22.x | cross-compile the function to Lambda glibc | `xtask setup` |
| `zig` | 0.13.0 | backend for `cargo-zigbuild` | `xtask setup` (Linux x86_64 auto; else manual) |
| Vercel CLI | 54.x | `vercel build` / `vercel deploy` | **the user** (`npm i -g vercel`) |
| Node.js | 18+ | runs the Vercel CLI | **the user** |

> **GUARDRAIL:** Install the Dioxus CLI with `cargo install dioxus-cli --locked`.
> **Why:** a bare install re-resolves to latest-compatible deps and pulls a `git2` that
> breaks `auth-git2` (`Cred::credential_helper` removed), so the install fails to compile.
> `--locked` uses the published, known-good lockfile. `xtask setup` already does this.

> **GUARDRAIL:** `zig` + `cargo-zigbuild` are required **even for deploying from x86_64
> Linux**. **Why:** prebuilt deploys cross-compile the function to Lambda's older glibc via
> `cargo zigbuild --target x86_64-unknown-linux-gnu`; a native build against a newer host
> glibc crashes at runtime on Vercel. The `.func` `filePathMap`
> (`target/x86_64-unknown-linux-gnu/release/<name>`) confirms the cross-build happened.

---

## 2. `xtask` — the single source of truth

> **IMPORTANT — THE ONLY WAY:** All toolchain operations go through the `xtask` crate, not
> through ad-hoc shell. It is invoked as `cargo xtask <command>` via a `.cargo/config.toml`
> alias. The full template is [`templates/xtask-main.rs.tmpl`](templates/xtask-main.rs.tmpl).

| Command | What it does |
|---|---|
| `cargo xtask setup` | Install everything in §1 (idempotent, safe to re-run). |
| `cargo xtask check` | Verify every requirement is present **without installing**. Exits non-zero if anything is missing. |
| `cargo xtask ci` | Run the full GitHub Actions gate locally: `fmt --check` + `clippy -D warnings` + `test --workspace` + WASM release build. |
| `cargo xtask serve` | `dx serve` with hot-reload (web dev loop). |
| `cargo xtask bundle <web\|android\|ios\|all>` | `dx bundle` a target into `dist/<target>/`. |

**Why a Rust `xtask` and not a shell script:** it is cross-platform, it is itself a
workspace member (so it compiles under the gate), and the toolchain spec (versions,
package lists, the WASM target) lives in one typed place that every machine and every agent
reads identically.

---

## 3. The pinned toolchain file

> **IMPORTANT — THE ONLY WAY:** Commit `rust-toolchain.toml`. It pins the channel,
> components, and targets so CI, every contributor, and every agent compile with the
> *identical* compiler. Reproducibility is a security property.

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
targets = ["wasm32-unknown-unknown"]
```

Template: [`templates/rust-toolchain.toml.tmpl`](templates/rust-toolchain.toml.tmpl).

---

## 4. WHAT TO ASK / REQUIRE OF THE USER

Some steps need a human with account credentials. The handler **cannot** do these and must
explicitly ask the user to do them (suggest the `! <command>` form so the output lands in
the session). Surface these **before** the DEPLOY station, not at it.

> **IMPORTANT — THE ONLY WAY:** Gather these from the user up front:

1. **A Vercel account.** Free tier is sufficient for this stack.
2. **Node.js 18+ and the Vercel CLI.** Ask the user to run:
   ```bash
   npm i -g vercel        # Vercel CLI 54.x
   vercel --version
   ```
3. **Authenticate.** This is interactive and must be the user:
   ```bash
   vercel login
   ```
4. **Link the project** (run from the directory containing `vercel.json`, i.e. the repo
   root that holds the hybrid `Cargo.toml`):
   ```bash
   vercel link        # choose/create the Vercel project → {{vercel_project}}
   ```
5. **Enable the Rust runtime capability** on the Vercel project. The official runtime is
   **permission-gated**: enable the "Rust runtime" capability (via the
   `vercel/vercel-plugin`) on the project so `@vercel/rust` is allowed to build. Ask the
   user to confirm this is enabled.
6. **Decide preview vs production.** Confirm with the user which deploys are previews
   (auth-protected) and when to promote to the public production alias.

> **GUARDRAIL:** The Vercel CLI is **not** installed by `xtask` — it is a Node tool outside
> the Rust toolchain. Do not add it to `xtask setup`. Keep the boundary clean: `xtask` owns
> the Rust/WASM world; the user owns the Vercel/Node world.

> **ANTI-PATTERN (DO NOT):** Attempt to deploy via the Vercel MCP server
> (`plugin:vercel:vercel`). **Why-not:** it is read-only (list/inspect/logs) and, at time
> of writing, its OAuth `client_id` is rejected by Vercel — it cannot deploy at all. Use
> the **CLI**. See `05`, `06`.

---

## 5. System libraries (Debian/Ubuntu)

`xtask setup` installs these via apt on Debian-based systems; on other distros it prints a
manual-install note. They are needed because the Dioxus desktop/mobile renderer backend
links against GTK/WebKit/xdo (pulled in even when you only target web, through the mobile
crate's renderer feature in the workspace):

```
libgtk-3-dev  libwebkit2gtk-4.1-dev  libglib2.0-dev  libxdo-dev
```

`libwebkit2gtk-4.1-dev` ships on Debian 13 (Trixie) / Ubuntu 24.04+. On macOS/Windows or
other distros, install the equivalent GTK 3 + WebKit2GTK 4.1 dev packages and ensure
`pkg-config` finds `glib-2.0` and `gtk+-3.0`.

> **GUARDRAIL:** If you ever see the linker error `unable to find library -lxdo`, the
> missing package is `libxdo-dev`. It is in the `xtask` list for exactly this reason.

> **Note (scope):** If you are building **web + API only** and never `dx serve`/`bundle`
> the native mobile target, the GTK/WebKit/xdo libraries are still pulled in by the
> workspace's mobile crate renderer feature during a workspace build. Keep them installed.
> Native mobile beyond this is an optional extension station and out of scope here.

---

Continue to [`04-vercel-rust-runtime.md`](04-vercel-rust-runtime.md).
