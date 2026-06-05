# 10 — FOUNDRY prerequisites

FOUNDRY drives idea→production across many stacks. It needs the toolchain for whatever stack a given
roadmap item uses, plus the **feedback musculature**: a live browser (Playwright MCP), language
servers (LSP), and debuggers. See [`live-feedback.md`](../plugins/foundry/knowledge/tooling/live-feedback.md)
for how handlers use these.

## Language toolchains & test runners

| Tool | Tier | Probe | Stack | Install |
|---|---|---|---|---|
| `cargo` / `rustc` | recommended | `cargo --version` | Rust handlers | rustup |
| `cargo-nextest` | optional | `cargo nextest --version` | faster Rust test runs | `cargo install cargo-nextest` |
| `dx` (Dioxus CLI) | optional | `dx --version` | Rust webapp (Dioxus/WASM) | `cargo install dioxus-cli --locked` |
| `zig` + `cargo-zigbuild` | optional | `zig version` | Rust→Vercel cross-build (glibc) | zig release + `cargo install cargo-zigbuild` |
| `vercel` CLI | optional | `vercel --version` | Rust webapp deploy | `npm i -g vercel` |
| `node`/`npm` | recommended | `node --version` | JS/TS/React/vanilla handlers | Volta |
| `pnpm` | optional | `pnpm --version` | JS monorepos (note: absent on the validated box) | `npm i -g pnpm` |
| `pytest` | recommended* | `pytest --version` | Python handler tests | `uv tool install pytest` / project venv |
| `jest` / `vitest` | recommended* | `npx vitest --version` | JS/TS tests | project devDependency |

\* per-stack — only needed when the project uses that stack.

## Playwright (browser feedback + story tests)

| Tool | Tier | Probe | Why |
|---|---|---|---|
| Playwright MCP (`@playwright/mcp`) | recommended | `command -v npx` | Live, exploratory browser feedback for web handlers (`mcp__playwright__*`). Shipped in [`plugins/foundry/.mcp.json`](../plugins/foundry/.mcp.json). |
| Playwright test runner | recommended | `npx playwright --version` | The committed, deterministic STORY tests. |
| A Chromium browser | recommended | `npx playwright install chromium` | The CLI runner needs a browser. The MCP downloads its own on first use. (Only `firefox` is preinstalled on the validated box.) |

```bash
npm i -g @playwright/mcp playwright
npx playwright install --with-deps chromium
```

## Up-to-date library docs (Context7 MCP)

| Tool | Tier | Probe | Why |
|---|---|---|---|
| Context7 MCP (`@upstash/context7-mcp`) | recommended | `command -v npx` | Injects **version-specific** docs + examples for 9,000+ libraries into context (`mcp__context7__*`), so handlers write code against the library's *current* API — knowledge-parity, not training-cutoff guesswork. Shipped in [`plugins/foundry/.mcp.json`](../plugins/foundry/.mcp.json). Keyless by default (optional key raises rate limits). |

## Debuggers (no new language required)

| Tool | Tier | Probe | Drives |
|---|---|---|---|
| `lldb` (`rust-lldb`) | recommended | `lldb --version` | Rust (and C/C++) batch debugging |
| `gdb` | optional | `gdb --version` | alternative native debugger |
| `debugpy` | recommended | `python -m debugpy --version` | Python remote/IDE-style debugging |
| (Node inspector) | — | bundled | `node --inspect` / `node inspect` |

```bash
apt install lldb gdb
uv tool install debugpy
```

## Language servers (LSP) — see [`45-lsp.md`](45-lsp.md)

`rust-analyzer`, `typescript-language-server`, `pyright` are wired into the marketplace manifest's
`lspServers` (all `strict:false`). Install the binaries (or the official LSP companion plugins) to
light them up.

Ansible: [`ansible/cargo.yml`](ansible/cargo.yml), [`ansible/npm.yml`](ansible/npm.yml),
[`ansible/apt.yml`](ansible/apt.yml), [`ansible/uv.yml`](ansible/uv.yml).
