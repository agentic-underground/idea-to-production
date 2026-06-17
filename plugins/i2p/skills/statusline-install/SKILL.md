---
name: statusline-install
description: >
  Install (or remove) the idea-to-production status line. Use for /i2p:statusline (or
  "give me the status bar", "turn on the i2p status line", "enable the fancy statusline",
  "turn off the status line"). Copies the plugin's renderer to ~/.claude and points
  settings.json at it (portable across machines), or removes it with `off`. Prints a merry
  toast on success. Edits only the statusLine key + the one renderer file.
metadata:
  type: installer
  output: ~/.claude/statusline-command.sh + settings.json statusLine (or its removal) + a toast
model: inherit
---

# i2p — Status-line installer

The idea-to-production status line is a rich two-line ANSI bar: identity/git/PR/model on line 1;
context-window + rate-limit gauges, the **product-lifecycle phase**, and the **⚔ caught** reviewer
tally on line 2. The renderer ships **inside this plugin** so it is version-controlled and portable;
this skill copies it into `~/.claude/` and wires `settings.json` (which cannot reference
`${CLAUDE_PLUGIN_ROOT}`).

## Do this

Run the installer, passing `$ARGUMENTS` through (`off` removes it):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/statusline/install.sh $ARGUMENTS
```

It is idempotent and non-destructive beyond the `statusLine` key:
1. copies `${CLAUDE_PLUGIN_ROOT}/statusline/i2p-statusline.sh` → `~/.claude/statusline-command.sh` (chmod +x);
2. atomically sets `~/.claude/settings.json` `statusLine` to `{"type":"command","command":"bash …"}`,
   **preserving every other key** (jq, with a python3 fallback; creates the file if absent);
3. prints the toast.

Present the output verbatim, then note the bar appears after a **restart or `/reload`**.

## Notes
- The **⚔ caught** tally is fed automatically by this plugin's PostToolUse hook
  (`statusline/count-adversarial-catches.sh`) — no setup needed; it works once i2p is installed.
- The **lifecycle phase** widget lights up once a project has a `.i2p/lifecycle.json` (see `/i2p-help`).
- Other plugins can add their own segments by dropping an executable printer in
  `~/.claude/state/statusline-widgets.d/*.sh` (fed the same stdin JSON; prints one colored segment).

## Self-improvement covenant
Inherits the marketplace covenant. If the renderer misreads a field or a terminal mangles a glyph, fix
it in the shipped `statusline/i2p-statusline.sh` once — every future install inherits the fix.
