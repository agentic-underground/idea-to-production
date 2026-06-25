---
name: settings-json-absent
description: .claude/settings.json does not exist at the repo root as of 2026-06-14; item [38] must create it from scratch, but always read-then-merge defensively in case it was created in the interim
metadata:
  type: project
---

As of 2026-06-14, there is no `.claude/settings.json` at `/home/user/Code/idea-to-production/.claude/settings.json`. A search of the entire repo for `settings.json` (excluding `node_modules` and `target`) returned zero results.

**Why:** Item [38] (Register flow-server MCP in project settings) was planned and the file's absence was confirmed. The file will be created as part of that item.

**How to apply:** When an agent starts T38-1, check if the file exists before writing. If it has been created since this plan was written, merge the `flow-server` key into the existing `mcpServers` object rather than overwriting. Never clobber an existing settings.json.
