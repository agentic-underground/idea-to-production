# 40 — MCP servers

[Model Context Protocol](https://modelcontextprotocol.io) servers give agents real, interactive
capabilities beyond text + Bash. The marketplace ships **four** — three keyless third-party launchers
(Context7 takes an optional rate-limit key) and its own first-party **flow-server** (a retrieved,
pinned, SHA256-verified Rust binary) — declared in each plugin's root `.mcp.json`, plus
documented optional extras.

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
  plugin/project MCP server until you approve it once via `/mcp`. **Pre-approval differs by scope:** a
  *project*-root `.mcp.json` server can be pre-trusted via `enableAllProjectMcpServers` /
  `enabledMcpjsonServers` in settings, but a **plugin-shipped** server (like `flow-server`) **cannot** —
  no setting, `claude mcp` subcommand, or launch flag (incl. `--dangerously-skip-permissions`, which
  gates *tools*, not MCP-server trust) pre-approves it. The one-time interactive approval is mandatory
  by design. operate smooths this: it pre-warms the `flow-server` binary and offers
  **`/operate:flow-setup`** to walk + verify the approval (see its [README](../plugins/operate/flow-server/README.md#finishing-the-install-the-smooth-path)).
- **Pinned for reproducibility.** The three third-party servers fetch and execute remote code at
  launch, so the shipped configs pin an **explicit version** (never a floating `@latest`) — a fetched
  server can't change underneath you. The current pins: `@playwright/mcp@0.0.75`,
  `@upstash/context7-mcp@3.1.0`, `uvx mcp-server-fetch@2026.6.4`.
  `scripts/verify-prereqs.sh` check K asserts every ephemeral-runner `.mcp.json` server carries such a
  pin. **`flow-server` is first-party and the rule still holds**: a resident-binary command (so check K
  exempts it) that runs a **pinned release** — the launcher reads the exact tag from
  `flow-server/bin/RELEASE` and verifies each retrieved asset against the **committed** `bin/SHA256SUMS`,
  refusing any binary whose digest doesn't match. Every machine converges on one SHA-verified binary;
  a release is adopted only by a reviewed PR that bumps the pin (the determinism the earlier
  latest-tracking launcher gave up — see the
  [flow-server README](../plugins/operate/flow-server/README.md#no-rust-toolchain-required--the-launcher-retrieves-a-prebuilt-binary)).
- Manual fallback (no plugin): `claude mcp add playwright -- npx -y @playwright/mcp@0.0.75`.

## Shipped by the marketplace

| Server | Plugin(s) | Package / launch | Tools | Purpose |
|---|---|---|---|---|
| `fetch` | market-scanner, ideator | `uvx mcp-server-fetch@2026.6.4` | `mcp__fetch__*` | Keyless web research: fetch a URL and extract it as **markdown in chunks** — competitor pricing, docs, forum threads. Grounds the discovery scorecard / IDEA package in real evidence. |
| `context7` | foundry | `npx -y @upstash/context7-mcp@3.1.0` | `mcp__context7__*` | **Version-specific** library docs + examples for 9,000+ libraries, injected into context — handlers code against the current API, not the training cutoff. |
| `playwright` | foundry, atelier | `npx -y @playwright/mcp@0.0.75` | `mcp__playwright__*` | Live browser: navigate, accessibility-tree snapshot, screenshot, console/network. foundry uses it for STORY feedback; atelier for `/ui-review` crawl + a11y snapshot. |
| `flow-server` | operate | `${CLAUDE_PLUGIN_ROOT}/flow-server/bin/flow-server-mcp` — a launcher that retrieves the **pinned** prebuilt binary (tag in `bin/RELEASE`) from GitHub Releases and SHA256-verifies it against the **committed** `bin/SHA256SUMS` (no Rust toolchain on the destination; source-builds only as a dev fallback) | `mcp__flow-server__*` | The roadmap flow board's MCP surface. `render_roadmap` answers "what's on the roadmap" by local compute (~0 LLM tokens); `list_items`/`post_status`/`set_wait_go`/`append_spend`/… read and carry roadmap items. **First-party** — the marketplace's own Rust binary, not a fetched package. |

Prereqs: `fetch` needs `uv`/`uvx`; `context7` + `playwright` need `node`/`npx` (Playwright's
browser auto-downloads on first use). All three run **keyless** — nothing to provision but the launcher
(Context7 takes an optional key only to raise rate limits).

## headless_capable — which phases need a spawnable MCP/browser, which are headless-safe

A **headless/CI run** (no display, no approval prompt, or an environment where an `.mcp.json` server
cannot be spawned) can still do most of the value-flow — but a few phases/skills **require** a live MCP or
a real browser and must be **routed around and disclosed**, never silently producing an empty pass. This is
prose guidance; the runtime contract it serves is
[`../plugins/foundry/knowledge/protocols/degraded-capabilities.md`](../plugins/foundry/knowledge/protocols/degraded-capabilities.md)
(a `mcp.*` degraded record, or a detected headless/CI env, is what a consumer routes on).

| Phase / skill | Needs a spawnable MCP/browser? | headless_capable | Routing when MCP can't spawn |
|---|---|---|---|
| DISCOVER / IDEATE web research (`fetch`) | `mcp.fetch` (web fetch) | **degrades** | fall back to user-supplied evidence; disclose research is un-grounded |
| BUILD — most DEV_SYSTEM phases (EARS, FEATURE, TEST, IMPLEMENT, commit) | no | **yes — headless-safe** | run normally |
| BUILD — `context7` version-specific docs lookup | `mcp.context7` (nice-to-have) | **yes (degrades)** | code against the training cutoff; disclose docs were not version-checked |
| BUILD/ASSURE — STORY browser/E2E tests (`ds-step-story-tests`, PLAYWRIGHT-AGENT) | `mcp.playwright` + a real Chromium | **no — requires browser** | skip browser story tests; run CLI/API journey tests where the interface allows; disclose the browser lens did not run |
| DESIGN — `atelier:mockup` / `atelier:ui-review` (screenshot + a11y crawl) | `mcp.playwright` + browser | **no — requires browser** | emit an SVG/wireframe fallback or skip; disclose screenshot-grade review skipped |

**The rule:** a headless-safe phase runs unchanged; an MCP/browser-dependent phase, when its MCP can't
spawn (a `mcp.*` DEGRADED record is present, or `CI`/no-display is detected), takes its degraded-but-valid
fallback **and discloses the gap** — it never reports a clean pass over a lens that did not run. The
phase-sensor / lifecycle-orchestrator route on this table; the scorecard (P1-17) marks the affected
coverage PARTIAL.

## Headless-browser discovery (the two marketplace resolvers)

The marketplace owns **two** consumers that each need a Chromium, and **each finds one differently** —
so the *same* browser is often on disk in several places while one consumer still reports "not
installed". The two resolvers:

- **mmdc / puppeteer** (pressroom renders Mermaid via `mmdc` → puppeteer) — resolves a **pinned Chrome
  revision** under `~/.cache/puppeteer`, **or** whatever `PUPPETEER_EXECUTABLE_PATH` points at.
- **Playwright MCP** (`@playwright/mcp`, shipped by `atelier` + `foundry`) — resolves a **slot** under
  `~/.cache/ms-playwright` (`PLAYWRIGHT_BROWSERS_PATH`), including a per-MCP `mcp-chromium-<hash>/` slot.

A browser also lives system-wide (`command -v chromium`/`chromium-browser`/`google-chrome`). A
**presence** probe answers "is a browser on the box?" — not "can *this consumer* launch one?"; that
gap is the recurring failure, captured as **TC-BROWSER-1**.

**Env single-source-of-truth.** One resolver, resolved **once at setup** by
[`scripts/ensure-browser.sh`](../scripts/ensure-browser.sh) into the user's shell / CI env — never baked
into `.mcp.json`:

```sh
export PUPPETEER_EXECUTABLE_PATH="$(command -v chromium||command -v chromium-browser||command -v google-chrome)"   # or a cache-resident binary
export PUPPETEER_SKIP_DOWNLOAD=1
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
```

These are machine-specific paths, so they are **resolved into the env by `ensure-browser.sh`, NEVER
written into a shipped `.mcp.json`** — every shipped server carries `env: {}` on purpose. This is the
**capability-not-path** rule: a shipped config declares the *capability* (a browser MCP), the setup
step supplies the *path* the local machine actually has. Bake a path in and the config is wrong on the
next machine; resolve it at setup and it is right on every machine.

For the full pattern — both resolvers, the TC-BROWSER-1 ledger entry, the `--fix` repair, and the
`THE ONLY WAY` "diagnose-before-installing" rule — see
[`knowledge/tooling/headless-browser.md`](../plugins/foundry/knowledge/tooling/headless-browser.md).

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
