# 05 — DISCOVERY / IDEATION prerequisites (market-scanner + ideator)

The front-end plugins — **market-scanner** (DISCOVERY) and **ideator** (REFINEMENT) — are mostly
*dialogue*: their power is reasoning, not binaries. The one capability that materially sharpens them is
**web research** — checking demand, competitor pricing, market size, and current-stack reality against
the real world instead of the user's say-so. None of it is required; all of it degrades to
reasoning-from-the-user when absent.

## The web-research tier

| Tool | Tier | Probe | Why | Install |
|---|---|---|---|---|
| WebSearch / WebFetch | built-in | — (native Claude tools) | Always-on baseline: search demand signals, fetch a competitor pricing page. No install, **no probe**. | ships with Claude Code |
| Fetch MCP (`mcp-server-fetch`) | recommended | `command -v uvx` | Keyless URL→markdown extraction in chunks — pull pricing/docs/forum pages cleanly. **Shipped** in [`plugins/market-scanner/.mcp.json`](../plugins/market-scanner/.mcp.json) + [`plugins/ideator/.mcp.json`](../plugins/ideator/.mcp.json) (`mcp__fetch__*`). | `uv` present → `uvx mcp-server-fetch` (ephemeral, no install) |
| Tavily MCP | optional | `command -v npx` | Agentic **search + extract + crawl + map** in one server — deeper, real-time market research. Needs an API key. | `env TAVILY_API_KEY=… npx -y tavily-mcp@latest` |
| Exa MCP | optional | `command -v npx` | **Semantic** search ("find companies doing X") — finds conceptually-related results keyword engines miss. Needs an API key. | `env EXA_API_KEY=… npx -y exa-mcp-server` |
| `gh` (GitHub CLI) | recommended | `command -v gh` | Used by each plugin's `self-improve` to open the improvement PR. | GitHub CLI (cli.github.com) |
| `ripgrep` | optional | `command -v rg` | Faster local research over your own notes/docs. | `apt install ripgrep` |

> **WebSearch/WebFetch vs Fetch MCP vs Tavily/Exa.** Built-in WebSearch/WebFetch cover the common case
> with zero setup. The shipped **Fetch MCP** adds robust, chunked extraction with no key. **Tavily/Exa**
> are for heavy, agentic research and require keys — wire them only if discovery is a core, repeated
> workflow. See [`40-mcp.md`](40-mcp.md) for the full MCP picture and approval model.

## How the skills use it

`market-scan` grounds the A–E scorecard (demand, market, willingness-to-pay, competition) in fetched
evidence and **cites it**; `ideate` validates the value&price / wedge / stack-fit axes against live pages
before writing them into the IDEA package. Unverifiable claims become **open questions**, never silent
guesses. Evidence-gathering never blocks the dialogue — it sharpens it.

> **For the provisioning agent.** Nothing here needs a dedicated install task: WebSearch/WebFetch are
> built in; the Fetch MCP launches via `uvx` (ensure **uv** — see [`ansible/uv.yml`](ansible/uv.yml));
> Tavily/Exa launch via `npx` (ensure **node** — see [`ansible/npm.yml`](ansible/npm.yml)). The API keys
> for Tavily/Exa are **runtime secrets — never bake them into the playbook**; inject via env at use time.
> Canonical tool lists: [`plugins/market-scanner/skills/check/requirements.tsv`](../plugins/market-scanner/skills/check/requirements.tsv)
> and [`plugins/ideator/skills/check/requirements.tsv`](../plugins/ideator/skills/check/requirements.tsv).
