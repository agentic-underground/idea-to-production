# 45 — Language servers (LSP)

Claude Code can attach **language servers**, giving agents real go-to-definition, hover types, and
**live diagnostics** instead of grep-only navigation — a direct quality win, especially for the Rust
handlers. There are two ways to wire them; the marketplace uses the first and recommends the second
for languages it doesn't pin.

## 1. Wired into the marketplace manifest (`lspServers`)

`.claude-plugin/marketplace.json` declares `lspServers` on the **foundry** plugin entry, all with
`strict: false` so a missing binary degrades gracefully (no attach, no error):

| Language | Server binary | Install |
|---|---|---|
| Rust | `rust-analyzer` | `rustup component add rust-analyzer` |
| TypeScript / JS | `typescript-language-server` (+ `typescript`) | `npm i -g typescript-language-server typescript` |
| Python | `pyright-langserver` | `npm i -g pyright` or `uv tool install pyright` |

Probe: `command -v rust-analyzer typescript-language-server pyright-langserver`.

## 2. Official LSP companion plugins (recommended for other languages)

Anthropic publishes standalone LSP plugins in `claude-plugins-official` — install the ones you need
rather than re-declaring them here:

`rust-analyzer-lsp`, `typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `clangd-lsp`, `jdtls-lsp`,
`kotlin-lsp`, `lua-lsp`, `php-lsp`, `ruby-lsp`, `swift-lsp`, `csharp-lsp`.

```bash
# example: add the official marketplace, then the language servers you want
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install gopls-lsp@claude-plugins-official
```

Each still needs its underlying server binary installed (the plugin only wires it up).

## Fallback (no LSP attached)

The same diagnostics are available through Bash and never block correctness:
`cargo check` · `tsc --noEmit` · `pyright <path>` · `ruff check` · `gopls check`.

Ansible: [`ansible/cargo.yml`](ansible/cargo.yml) (rust-analyzer component),
[`ansible/npm.yml`](ansible/npm.yml) (typescript-language-server, pyright),
[`ansible/go.yml`](ansible/go.yml) (gopls).
