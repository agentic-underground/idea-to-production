# Crawl configuration — `crawl.mjs`

The committed-snapshot fallback for `/ui-review` when the Playwright MCP isn't available. Target-agnostic:
no hardcoded panels, selectors, or ports — it reads the app's own same-origin links.

| Env var | Required | Default | Meaning |
|---|---|---|---|
| `BASE_URL` | **yes** | — (never assumed) | The running app's base URL, e.g. `http://localhost:5173`. |
| `ROUTES` | no | auto-discover | Comma-separated paths to visit instead of discovery, e.g. `/,/dashboard,/settings`. |
| `OUT` | no | `docs/guide/design/review/<YYYY-MM-DD>` | Output directory. |
| `VIEWPORTS` | no | `desktop,mobile` | `desktop`=1440×900, `mobile`=375×812. |
| `MAX_ROUTES` | no | `25` | Cap on auto-discovered routes (avoids unbounded crawls). |
| `WAIT_MS` | no | `600` | Settle time after each navigation. |

```bash
# Auto-discover routes from the running app:
BASE_URL=http://localhost:5173 node ${CLAUDE_PLUGIN_ROOT}/skills/ui-review/scripts/crawl.mjs

# Explicit route list, desktop only:
BASE_URL=http://localhost:3000 ROUTES="/,/pricing,/app/dashboard" VIEWPORTS=desktop \
  node ${CLAUDE_PLUGIN_ROOT}/skills/ui-review/scripts/crawl.mjs
```

**Prereqs:** the target project must have Playwright installed (`npm i -D @playwright/test &&
npx playwright install chromium`) — the script loads it from the project's `node_modules`. Verify with
`/atelier:check`. The output is a gallery `README.md` + `screenshots/*.png`; the reviewer reads the PNGs
with built-in vision (no API key).

> **Prefer the live MCP path** (`mcp__playwright__*`) when available — it also exposes the **accessibility
> tree** and can run `axe-core`, which a static screenshot cannot. This script exists for committed
> baselines and for sessions without the MCP.
