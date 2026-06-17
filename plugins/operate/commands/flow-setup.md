---
description: Finish setting up the flow-mcp roadmap MCP — pre-cache the binary, walk the one-time approval, and verify the connection.
---

Guide the user through finishing the **flow-mcp MCP** setup, then verify it. The flow-mcp server is the
roadmap MCP server operate ships (`render_roadmap` answers "what's on the roadmap" by local
compute at ~0 tokens, plus `list_items` / `post_status` / `set_wait_go` / …). Be concise and friendly.

**Step 1 — pre-cache the binary** (so the server starts instantly on approval; safe to re-run, no Rust
needed — it downloads a SHA-pinned release binary):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/flow-mcp/bin/flow-mcp" --ensure-binary
```

**Step 2 — reconcile against YOUR OWN available tools.** Look at whether you have `mcp__flow-mcp__*`
tools right now:

- **If you DO have them** → the server is already connected. Don't make the user do anything. Confirm it
  works by calling `render_roadmap` (or `list_items`) and show them the result ("✓ flow-mcp is
  connected — here's what's on the roadmap…"). Done.

- **If you do NOT have them** → it isn't connected yet. Tell the user exactly this, briefly:
  1. **Restart Claude Code** if they just installed or updated operate — Claude Code only reads a
     plugin's MCP config (`.mcp.json`) at startup, so a restart is required after an install/update.
     (`/reload-plugins` loads skills/hooks but **not** new MCP servers.)
  2. **Run `/mcp`**, find **`flow-mcp`** (it shows as ⏸ *Pending approval*), and **approve** it.
  3. Explain honestly: this one-time approval **cannot** be skipped — a plugin's MCP server is not
     auto-trusted by any setting, CLI command, or launch flag; it's a deliberate Claude Code security
     gate. After you approve it once, it connects immediately (the binary is already pre-cached from
     Step 1, so there's no wait), and future sessions need no further action.
  4. Tell them to re-run `/operate:flow-setup` after approving, and you'll verify the connection.

Do not nag and do not repeat steps the user has already done. Meanwhile, "what's on the roadmap" still
works via a direct scan of the `.i2p/roadmap/` tree — the MCP path just makes it instant and ~0-token.
