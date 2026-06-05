# 40 — MCP servers

[Model Context Protocol](https://modelcontextprotocol.io) servers give agents real, interactive
capabilities beyond text + Bash. The marketplace ships **four**, all of which run **keyless** (Context7
takes an optional rate-limit key), declared in each plugin's root `.mcp.json`, plus documented optional extras.

## How a plugin ships an MCP server

A plugin declares servers in a `.mcp.json` at its **plugin root**:

```json
{ "mcpServers": { "<name>": { "command": "<cmd>", "args": ["…"], "env": {} } } }
```

- Tools surface to agents as **`mcp__<server>__<tool>`**; an agent's `tools:` frontmatter may use
  the wildcard `mcp__<server>__*`.
- A subagent inherits the project/user MCP servers; to grant the tools to a restricted handler, add
  the `mcp__…__*` name to its `tools:` list (FOUNDRY's web handlers do this for `playwright`).
- `.mcp.json` servers are **approval-gated under default permissions**: on first session
  `claude mcp list` shows them as `⏸ Pending approval`, and Claude Code does not connect to (run) a
  plugin/project MCP server until you approve it. Treat this as the safety default, not an absolute
  guarantee — a permissive permission mode or pre-approval changes it.
- **Pin for provisioning.** The shipped configs use the upstream-documented unpinned launch
  (`@playwright/mcp@latest`, `uvx semgrep-mcp`, `uvx mcp-server-fetch`, and `@upstash/context7-mcp` —
  which ships with **no version tag at all**) for zero-config first use. Each of these fetches and
  executes third-party code at launch. For reproducible or hardened machines, **pin a version** —
  `@playwright/mcp@<ver>`, `@upstash/context7-mcp@<ver>`, `uvx --from semgrep-mcp==<ver> semgrep-mcp`,
  `uvx --from mcp-server-fetch==<ver> mcp-server-fetch` — so a fetched server can't change underneath you.
- Manual fallback (no plugin): `claude mcp add playwright -- npx -y @playwright/mcp@latest`.

## Shipped by the marketplace

| Server | Plugin(s) | Package / launch | Tools | Purpose |
|---|---|---|---|---|
| `fetch` | market-scanner, ideator | `uvx mcp-server-fetch` | `mcp__fetch__*` | Keyless web research: fetch a URL and extract it as **markdown in chunks** — competitor pricing, docs, forum threads. Grounds the discovery scorecard / IDEA package in real evidence. |
| `context7` | foundry | `npx -y @upstash/context7-mcp` | `mcp__context7__*` | **Version-specific** library docs + examples for 9,000+ libraries, injected into context — handlers code against the current API, not the training cutoff. |
| `playwright` | foundry | `npx -y @playwright/mcp@latest` | `mcp__playwright__*` | Live browser: navigate, accessibility-tree snapshot, screenshot, console/network. Complements the Playwright **test** contract. |
| `semgrep` | sentinel | `uvx semgrep-mcp` | `mcp__semgrep__*` | SAST: code-level vulnerability patterns. Bundles its own `semgrep`. |

Prereqs: `fetch` + `semgrep` need `uv`/`uvx`; `context7` + `playwright` need `node`/`npx` (Playwright's
browser auto-downloads on first use). All four run **keyless** — nothing to provision but the launcher
(Context7 takes an optional key only to raise rate limits).

## Optional extras worth wiring (not shipped by default)

Grouped by what they amplify. The shipped four cover the common case keylessly; these need an API key,
a token, or an app-runtime — wire them when the workflow is core and you can supply the secret at runtime.

**Deeper research (discovery/ideation):**

| Server | Package / launch | Why you'd add it |
|---|---|---|
| Tavily | `env TAVILY_API_KEY=… npx -y tavily-mcp@latest` | Agentic **search + extract + crawl + map** in one server — real-time, multi-step market research beyond keyless Fetch. |
| Exa | `env EXA_API_KEY=… npx -y exa-mcp-server` | **Semantic** search ("find companies doing X") — surfaces conceptually-related results keyword engines miss. |

**Code + project (build):**

| Server | Package / launch | Why you'd add it |
|---|---|---|
| GitHub (official) | remote HTTP: `claude mcp add -s user --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer <PAT>"` (or local Docker / `github-mcp-server stdio`) | Issues/PRs/repo API from inside a session. **Use the official [`github/github-mcp-server`](https://github.com/github/github-mcp-server)** — the old `@modelcontextprotocol/server-github` is deprecated. Needs a PAT. |
| Filesystem | `npx -y @modelcontextprotocol/server-filesystem <path>` | Scoped filesystem access for a sandboxed agent (Claude Code's native file tools usually suffice). |

**App-runtime (project-specific):**

| Server | Package / launch | Why you'd add it |
|---|---|---|
| Postgres | `npx -y @modelcontextprotocol/server-postgres <conn-url>` | Let an agent explore schema + run read queries against the project's own DB. |
| Sentry | the Sentry-hosted MCP (token) | Pull production error context into a session. |

> **Debugger over MCP?** Community DAP-bridge MCP servers exist but none is official/stable. Prefer
> the Bash-driven debugger recipes in [`live-feedback.md`](../plugins/foundry/knowledge/tooling/live-feedback.md).
> Vercel also publishes an MCP server, but it is **read-only** and **must not** be used to deploy —
> FOUNDRY's rust-webapp guardrails require the Vercel **CLI** for deploys.

Ansible: every launcher is `npx`/`uvx`, so [`ansible/npm.yml`](ansible/npm.yml) +
[`ansible/uv.yml`](ansible/uv.yml) cover them — **no per-server install task**. API keys/tokens are
**runtime secrets, not Ansible-managed**. Approval is interactive per-project.
