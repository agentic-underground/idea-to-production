---
description: Edit the line-break layout of the status line's line-2 widgets so the bar fits your terminal — assign each widget break-before / break-after / none (none flows inline and lets the terminal wrap).
---

Edit the status line's line-2 widget line-breaks. Follow the
[`statusline-widgets` skill](../skills/statusline-widgets/SKILL.md):

1. Read the current `~/.claude/i2p-statusline.conf` and note each widget's current `break_<widget>` value.
2. Present a choice (via `AskUserQuestion`): **which widgets** (multi-select, incl. a "Select all widgets"
   option) and **which attribute** — `break-before` / `break-after` / `none`.
3. Persist each selected widget (idempotent; preserves all other keys):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/statusline/set-widget-break.sh <widget> <before|after|none>
   ```
4. Refresh the installed renderer:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/statusline/install.sh
   ```

Widgets: `context · rate_5h · rate_7d · lifecycle · session_cost · lifecycle_cost · catches`.
`none` (default) keeps a widget inline and defers wrapping to the terminal. Remind the user changes
apply after a restart or `/reload`. Visibility (showing/hiding segments) is the separate
`/i2p:statusline` command.
