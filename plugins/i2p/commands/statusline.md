---
description: Turn on the idea-to-production status line — a rich two-line ANSI bar (context/rate-limit gauges, the product-lifecycle phase, and the ⚔ reviewer-catch tally). Pass `off` to remove it.
---

Install (or remove) the idea-to-production status line. Follow the
[`statusline-install` skill](../skills/statusline-install/SKILL.md):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/statusline/install.sh $ARGUMENTS
```

- No argument → copies the renderer to `~/.claude/statusline-command.sh` and points
  `~/.claude/settings.json` `statusLine` at it (preserving your other settings), then prints a toast.
- `off` → removes the `statusLine` entry.

Present the script's output to the user, then remind them the status line appears after a restart or
`/reload`. This only edits the `statusLine` key in `settings.json` and the one renderer file — nothing else.
