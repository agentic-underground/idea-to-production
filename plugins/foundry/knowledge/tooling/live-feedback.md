# Live Feedback, Debuggers & Language Servers

> Canonical reference for the **feedback musculature** available to FOUNDRY value-handlers:
> the chrome-devtools MCP (live browser), CLI debuggers (no new language required), and LSP
> servers (semantic navigation/diagnostics). One copy; handlers link here.
>
> Reachability of every tool named here is verified by `/foundry:check`
> ([`../../skills/check/SKILL.md`](../../skills/check/SKILL.md)); the per-plugin
> `skills/check/requirements.tsv` carries the install hints.
---

## 1. chrome-devtools MCP — live, exploratory browser feedback

FOUNDRY does **not** ship a browser MCP — it relies on the **host-provided `chrome-devtools` MCP**
(one browser per host: the system Chromium it is pointed at). Web value-handlers are granted the
`mcp__chrome-devtools__*` tools; when that MCP is present they drive that one browser, and when it is
absent they degrade gracefully (the test contract below still holds). *(History: FOUNDRY/ATELIER once
shipped a `@playwright/mcp` server in `.mcp.json`; it defaulted to a Google Chrome channel headless
hosts don't install and its registry GC corrupted the shared browser cache — the "ONE BROWSER" cutover
removed it in favour of the host chrome-devtools. See [`headless-browser.md`](./headless-browser.md).)*
Under **default permissions** a host/user-registered MCP still requires approval before it connects.

**The dividing line — MCP for feedback, the CLI runner for the contract:**

| Use the **chrome-devtools MCP** (`mcp__chrome-devtools__*`) for… | Use **`npx playwright test`** (the CLI runner) for… |
|---|---|
| Live, exploratory work *during* implementation: navigate, click, fill, read the **accessibility tree**, screenshot, inspect console/network. | The **committed, deterministic STORY test** — the durable artefact that pins behaviour and runs in CI. |
| Answering "does this actually render / behave right *now*?" without writing a throwaway test. | The test contract (see [`../testing/test-policy.md`](../testing/test-policy.md)). |
| Debugging a flaky selector or a layout issue interactively. | Visual-regression baselines and cross-browser matrices. |

**Rule:** the MCP **complements** the test contract; it never replaces it. Every behaviour you
confirm live with the MCP must still be pinned by a committed Playwright (or unit/component) test
before the slice is done. Do not treat an MCP observation as proof — proof is a green committed test.

---

## 2. Debuggers — driven non-interactively through Bash

A debugger **can** be attached from within an agent session: drive a CLI debugger in batch mode
through the `Bash` tool. **No new language is required** — the current stack already debugs:

| Stack | Recipe (batch / non-interactive) | Prereq |
|---|---|---|
| **Rust** | `rust-lldb -batch -o 'b mymod::myfn' -o run -o 'bt' -o 'frame variable' target/debug/<bin>` — or `gdb --batch -ex run -ex bt --args <bin> <args>`. For tests: `rust-lldb -batch -o run $(cargo test --no-run --message-format=json \| jq -r 'select(.executable).executable' \| head -1)`. | `lldb` or `gdb` |
| **Python** | `python -m pdb -c 'b module:line' -c 'c' -c 'bt' -c 'p locals()' -c 'q' script.py` — or, for remote/IDE-style, `python -m debugpy --listen 5678 --wait-for-client script.py`. | `debugpy` (recommended) / `pdb` (stdlib) |
| **Node / JS / TS** | `node inspect script.js` with `-e` driven commands, or `node --inspect-brk script.js` to expose the V8 inspector (Chrome DevTools Protocol). | bundled with Node |

**When to reach for a debugger:** a failing test whose cause is non-obvious from the assertion —
inspect state at the breakpoint rather than scattering `print`/`console.log`. Capture the batch
output, form the fix, then re-run the test to confirm green.

> **Experimental:** community DAP-bridge MCP servers exist that expose a debugger as MCP tools.
> None is official/stable as of this writing — prefer the Bash recipes above. If you adopt one,
> document it as an optional prerequisite, not a hard dependency.

---

## 3. LSP — semantic navigation & diagnostics

Claude Code attaches **language servers** declared as `lspServers` in the marketplace manifest
(`.claude-plugin/marketplace.json`, foundry entry),
giving agents real go-to-definition, hover types, and **live diagnostics** instead of grep-only
navigation. The **foundry plugin entry** carries `strict: false` (set once at the plugin-entry level
in `marketplace.json`, not per server), so a missing LSP binary degrades gracefully. FOUNDRY wires:

| Language | Server | Binary | Install |
|---|---|---|---|
| Rust | `rust-analyzer` | `rust-analyzer` | `rustup component add rust-analyzer` |
| TypeScript / JS | `typescript-language-server` | `typescript-language-server` | `npm i -g typescript-language-server typescript` |
| Python | `pyright` | `pyright-langserver` | `npm i -g pyright` (or `uv tool install pyright`) |

Anthropic also publishes standalone **official LSP companion plugins** (`rust-analyzer-lsp`,
`typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `clangd-lsp`, …) — installing those is the alternative
to FOUNDRY's bundled `lspServers` and is the right move for languages FOUNDRY does not pin.

**Fallback when no LSP is attached:** get the same diagnostics through Bash — `cargo check`,
`tsc --noEmit`, `pyright <path>`, `ruff check`. The LSP is a speed/ergonomics win, never a
correctness dependency.
