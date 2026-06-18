---
description: Finish setting up the flow-mcp roadmap MCP — ensure a compliant Ruby, walk the one-time approval, and verify the connection.
---

Guide the user through finishing the **flow-mcp MCP** setup, then verify it. flow-mcp is the roadmap MCP
the flow plugin ships — an **interpreted Ruby server** (Ruby ≥ 3.3.8, standard library only; there is no
binary to build, download, or cache). `render_roadmap` answers "what's on the roadmap" by local compute
at ~0 tokens, plus `list_items` / `post_status` / `set_wait_go` / …. Be concise and friendly.

**Step 1 — confirm a compliant Ruby is present** (the server runs on the host's Ruby; safe to re-run):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/flow-mcp/bin/flow-mcp" --doctor
```

Read the `ruby` line:
- **`ruby … >= 3.3.8 ✓`** → good, continue to Step 2.
- **`NONE >= 3.3.8 found`** → install Ruby first — Debian/Ubuntu: `apt-get install ruby` (Debian 13 ships
  3.3.8); macOS: `brew install ruby`; or rbenv/asdf. **Until Ruby is installed**, the roadmap can still
  be operated by hand via the `/flow:flow-by-hand` fallback runbook (same semantics, slower, no server).

**Step 2 — reconcile against YOUR OWN available tools.** Look at whether you have `mcp__flow-mcp__*`
tools right now:

- **If you DO have them** → the server is already connected. Don't make the user do anything. Confirm it
  works by calling `render_roadmap` (or `list_items`) and show them the result ("✓ flow-mcp is
  connected — here's what's on the roadmap…"). Done.

- **If you do NOT have them** → it isn't connected yet. Tell the user exactly this, briefly:
  1. **Restart Claude Code** if they just installed or updated flow — Claude Code only reads a
     plugin's MCP config (`.mcp.json`) at startup, so a restart is required after an install/update.
     (`/reload-plugins` loads skills/hooks but **not** new MCP servers.)
  2. **Run `/mcp`**, find **`flow-mcp`** (it shows as ⏸ *Pending approval*), and **approve** it.
  3. Explain honestly: this one-time approval **cannot** be skipped — a plugin's MCP server is not
     auto-trusted by any setting, CLI command, or launch flag; it's a deliberate Claude Code security
     gate. After you approve it once it connects immediately (the server is just `ruby`, no build/fetch),
     and future sessions need no further action.
  4. Tell them to re-run `/flow:flow-setup` after approving, and you'll verify the connection.

Do not nag and do not repeat steps the user has already done. Meanwhile, "what's on the roadmap" still
works via the `/flow:flow-by-hand` runbook (a direct, by-hand read of the `.i2p/roadmap/` tree) — the
MCP path just makes it instant and ~0-token.
