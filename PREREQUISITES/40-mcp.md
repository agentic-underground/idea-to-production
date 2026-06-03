# 40 — MCP servers

[Model Context Protocol](https://modelcontextprotocol.io) servers give agents real, interactive
capabilities beyond text + Bash. The marketplace ships two, declared in each plugin's root
`.mcp.json`, and documents optional extras.

## How a plugin ships an MCP server

A plugin declares servers in a `.mcp.json` at its **plugin root**:

```json
{ "mcpServers": { "<name>": { "command": "<cmd>", "args": ["…"], "env": {} } } }
```

- Tools surface to agents as **`mcp__<server>__<tool>`**; an agent's `tools:` frontmatter may use
  the wildcard `mcp__<server>__*`.
- A subagent inherits the project/user MCP servers; to grant the tools to a restricted handler, add
  the `mcp__…__*` name to its `tools:` list (FOUNDRY's web handlers do this for `playwright`).
- `.mcp.json` servers are **approval-gated**: on first session `claude mcp list` shows them as
  `⏸ Pending approval`. Approve once, then they health-check and connect. This is a safety feature,
  not a bug — it means shipping the config does not silently auto-run a subprocess.
- Manual fallback (no plugin): `claude mcp add playwright -- npx -y @playwright/mcp@latest`.

## Shipped by the marketplace

| Server | Plugin | Package / launch | Tools | Purpose |
|---|---|---|---|---|
| `playwright` | foundry | `npx -y @playwright/mcp@latest` | `mcp__playwright__*` | Live browser: navigate, accessibility-tree snapshot, screenshot, console/network. Complements the Playwright **test** contract. |
| `semgrep` | sentinel | `uvx semgrep-mcp` | `mcp__semgrep__*` | SAST: code-level vulnerability patterns. Bundles its own `semgrep`. |

Prereqs: `playwright` needs `node`/`npx` (browser auto-downloads on first use). `semgrep` needs `uv`/`uvx`.

## Optional extras worth wiring (not shipped by default)

| Server | Package / launch | Why you'd add it |
|---|---|---|
| GitHub | `npx -y @modelcontextprotocol/server-github` | Issues/PRs/repo API from inside a session (needs a token). |
| Filesystem | `npx -y @modelcontextprotocol/server-filesystem <path>` | Scoped filesystem access for a sandboxed agent. |
| Fetch / HTTP | a remote `type:"http"` server by URL | Generic web/API fetch. |

> **Debugger over MCP?** Community DAP-bridge MCP servers exist but none is official/stable. Prefer
> the Bash-driven debugger recipes in [`live-feedback.md`](../plugins/foundry/knowledge/tooling/live-feedback.md).
> Vercel also publishes an MCP server, but it is **read-only** and **must not** be used to deploy —
> FOUNDRY's rust-webapp guardrails require the Vercel **CLI** for deploys.

Ansible: the launchers are `npx`/`uvx`, so [`ansible/npm.yml`](ansible/npm.yml) +
[`ansible/uv.yml`](ansible/uv.yml) cover them. Approval is interactive per-project.
