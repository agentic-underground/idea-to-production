# 40 — MCP servers

[Model Context Protocol](https://modelcontextprotocol.io) servers give agents real, interactive
capabilities beyond text + Bash. The marketplace ships **three** keyless third-party launchers
(Context7 takes an optional rate-limit key) — declared in each plugin's root `.mcp.json` — plus
documented optional extras.

> **Language choice — do NOT compile a plugin MCP.** If you ship a first-party plugin MCP server, write
> it in an **interpreted** language (Ruby/Python/Node), never a compiled one (Rust/Go/…). The
> marketplace's now-retired roadmap MCP (`flow-mcp`) shipped first as a pinned Rust binary and was
> chronically broken — release-sync friction, stale binary caches, undead binaries, zero call
> visibility — so it was re-homed to Ruby before the FLEET continuous-delivery engine superseded it
> entirely. If you are scaffolding an MCP and reach for a compiled language, read the post-mortem first:
> [`../plugins/foundry/knowledge/architecture/mcp-language-choice.md`](../plugins/foundry/knowledge/architecture/mcp-language-choice.md).

## How a plugin ships an MCP server

A plugin declares servers in a `.mcp.json` at its **plugin root**:

```json
{ "mcpServers": { "<name>": { "command": "<cmd>", "args": ["…"], "env": {} } } }
```

- Tools surface to agents as **`mcp__<server>__<tool>`**; an agent's `tools:` frontmatter may use
  the wildcard `mcp__<server>__*`.
- A subagent inherits the project/user MCP servers; to grant the tools to a restricted handler, add
  the `mcp__…__*` name to its `tools:` list (FOUNDRY's web handlers do this for the host-provided
  `chrome-devtools`).
- `.mcp.json` servers are **approval-gated under default permissions**: on first session
  `claude mcp list` shows them as `⏸ Pending approval`, and Claude Code does not connect to (run) a
  plugin/project MCP server until you approve it once via `/mcp`. **Pre-approval differs by scope:** a
  *project*-root `.mcp.json` server can be pre-trusted via `enableAllProjectMcpServers` /
  `enabledMcpjsonServers` in settings, but a **plugin-shipped** server **cannot** — no setting,
  `claude mcp` subcommand, or launch flag (incl. `--dangerously-skip-permissions`, which gates *tools*,
  not MCP-server trust) pre-approves it. The one-time interactive approval is mandatory by design.
- **Pinned for reproducibility.** The third-party servers fetch and execute remote code at
  launch, so the shipped configs pin an **explicit version** (never a floating `@latest`) — a fetched
  server can't change underneath you. The current pins: `@upstash/context7-mcp@3.1.0`,
  `uvx mcp-server-fetch@2026.6.4`.
- **No browser MCP is shipped.** The marketplace drives a browser through the **host-provided
  `chrome-devtools`** MCP (ONE BROWSER — the host points it at the system Chromium). Shipping a browser
  MCP is forbidden by the [browser-MCP rules](../plugins/foundry/knowledge/tooling/headless-browser.md)
  (a shipped `@playwright/mcp` defaulted to a Chrome channel headless hosts don't install and its cache
  GC corrupted the shared browser — removed in the ONE BROWSER cutover).
  `scripts/verify-prereqs.sh` check K asserts every ephemeral-runner `.mcp.json` server carries such a
  pin. (A resident, interpreted first-party server — were the marketplace to ship one again — would be
  exempt: nothing fetched, no package to pin, no artifact-drift. See the
  [language-choice post-mortem](../plugins/foundry/knowledge/architecture/mcp-language-choice.md).)
- Manual fallback (no host MCP, off-fleet): `claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest --headless --isolated` (omit `--executablePath` off-fleet so it auto-manages its own Chrome-for-Testing; on a host with a system browser, point it at that). *(`@latest` is fine here — the pin rule above + check K govern **shipped** `.mcp.json` servers; this is an off-fleet manual command, not a shipped config. Pin a version if you want reproducibility.)*

## Shipped by the marketplace

| Server | Plugin(s) | Package / launch | Tools | Purpose |
|---|---|---|---|---|
| `fetch` | market-scanner, ideator | `uvx mcp-server-fetch@2026.6.4` | `mcp__fetch__*` | Keyless web research: fetch a URL and extract it as **markdown in chunks** — competitor pricing, docs, forum threads. Grounds the discovery scorecard / IDEA package in real evidence. |
| `context7` | foundry | `npx -y @upstash/context7-mcp@3.1.0` | `mcp__context7__*` | **Version-specific** library docs + examples for 9,000+ libraries, injected into context — handlers code against the current API, not the training cutoff. |

> **Browser (`chrome-devtools`) is NOT shipped — it is host-provided** (driven, not bundled). The host
> registers `chrome-devtools` pointed at the system Chromium; foundry's web handlers + atelier's
> `/ui-review`/`/mockup` use `mcp__chrome-devtools__*` for live browser feedback, and degrade gracefully
> when it is absent (see the headless table below). This is the ONE BROWSER posture — the marketplace
> ships no browser MCP of its own.

Prereqs: `fetch` needs `uv`/`uvx`; `context7` needs `node`/`npx`. Both run **keyless** — nothing to
provision but the launcher (Context7 takes an optional key only to raise rate limits).

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
| BUILD/ASSURE — STORY browser/E2E tests (`ds-step-story-tests`, PLAYWRIGHT-AGENT) | a real Chromium (Playwright test runner) | **no — requires browser** | skip browser story tests; run CLI/API journey tests where the interface allows; disclose the browser lens did not run |
| DESIGN — `atelier:mockup` / `atelier:ui-review` (screenshot + a11y crawl) | `mcp.chrome-devtools` + browser | **no — requires browser** | emit an SVG/wireframe fallback or skip; disclose screenshot-grade review skipped |

**The rule:** a headless-safe phase runs unchanged; an MCP/browser-dependent phase, when its MCP can't
spawn (a `mcp.*` DEGRADED record is present, or `CI`/no-display is detected), takes its degraded-but-valid
fallback **and discloses the gap** — it never reports a clean pass over a lens that did not run. The
phase-sensor / lifecycle-orchestrator route on this table; the scorecard (P1-17) marks the affected
coverage PARTIAL.

## Headless-browser discovery (ONE BROWSER)

The marketplace consolidates on **one browser per host** — the system Chromium
(`command -v chromium`/`chromium-browser`/`google-chrome`). Both marketplace consumers point at it:

- **mmdc / puppeteer** (publish renders Mermaid via `mmdc` → puppeteer) — resolves whatever
  `PUPPETEER_EXECUTABLE_PATH` points at (the system Chromium), `PUPPETEER_SKIP_DOWNLOAD=1`.
- **`chrome-devtools` MCP** (host-provided, not shipped) — the host registers it pointed at the system
  Chromium (`--executablePath /usr/bin/chromium --isolated` on FLEET).

No `~/.cache/ms-playwright` slot is involved any more — the browser MCP that used it
(`@playwright/mcp`) was removed in the ONE BROWSER cutover precisely because its registry GC corrupted
that shared cache. A **presence** probe answers "is a browser on the box?" — not "can it actually
launch?"; the gap is the recurring failure **TC-BROWSER-1**, so probe a **real launch**, never just
`command -v`.

**Env single-source-of-truth.** Resolved **once at setup** by
[`scripts/ensure-browser.sh`](../scripts/ensure-browser.sh) into the user's shell / CI env — never baked
into `.mcp.json`:

```sh
export PUPPETEER_EXECUTABLE_PATH="$(command -v chromium||command -v chromium-browser||command -v google-chrome)"
export PUPPETEER_SKIP_DOWNLOAD=1
```

This is the **capability-not-path** rule: the config declares the *capability*, setup supplies the
*path* the local machine has. (The Playwright **test runner**, if a built project uses it for committed
story tests, manages its own browser separately — that is a per-project concern, not a marketplace MCP.)

For the full pattern — both resolvers, the TC-BROWSER-1 ledger entry, the `--fix` repair, and the
`THE ONLY WAY` "diagnose-before-installing" rule — see
[`knowledge/tooling/headless-browser.md`](../plugins/foundry/knowledge/tooling/headless-browser.md).

## Optional extras worth wiring (not shipped by default)

Grouped by what they amplify. The shipped three cover the common case keylessly; these need an API key,
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
