---
name: statusline-widgets
description: >
  Edit the line-break layout of the idea-to-production status line's line-2 widgets so the bar fits
  your terminal. Use for /concierge:statusline-widgets (or "show me the statusline widgets", "I want
  to edit the statusline widgets", "edit the statusline widgets", "make the statusline wrap"). Presents
  the widgets as a choice and assigns each a break attribute — break-before (start on a new line),
  break-after (break after it), or none (flow inline; the terminal soft-wraps). Persists to
  ~/.claude/i2p-statusline.conf and refreshes the installed renderer.
metadata:
  type: configurator
  output: break_<widget>=… lines in ~/.claude/i2p-statusline.conf + a refreshed renderer
model: inherit
---

# concierge — Status-line widget line-break editor

The status line's **line 2** is a row of widgets. By default they all flow on one line and the
terminal soft-wraps. This skill lets the user place **hard line breaks** per widget so the bar fits a
narrow terminal — without hand-editing a conf file. (Line 1, the identity row, is always its own line.)

> Line-break control is distinct from **visibility** (whether a segment shows at all). Visibility is
> `/concierge:statusline`; this skill only sets the `break_<widget>` keys and never changes the `<seg>=0/1`
> visibility keys.

## The configurable widgets (line 2)

`context` · `rate_5h` · `rate_7d` · `lifecycle` · `session_cost` · `lifecycle_cost` · `catches`

Each takes one **break attribute**:
- **break-before** — the widget starts on a **new line**.
- **break-after** — a line break follows the widget.
- **none** *(default)* — the widget stays **inline** (separated by the meter separator); wrapping is
  deferred to the terminal (the parent container).

> Adjacent breaks collapse to a single line break (no blank lines), and a break on a widget whose data
> is absent this render has no effect — both handled by the renderer.

## Procedure

1. **Read current state.** Read `~/.claude/i2p-statusline.conf` (or `$CLAUDE_I2P_STATUSLINE_CONF`) if it
   exists; note any existing `break_<widget>=…` so you can show the current attribute per widget.
2. **Present the choice** with `AskUserQuestion`:
   - First ask **which widgets** to change — a multi-select of the seven widgets **plus a "Select all
     widgets" option** (selecting it = apply to every widget). Show each widget's current attribute.
   - Then ask **which break attribute** to apply to the selected widgets — single-select of
     **break-before / break-after / none** (rich descriptions as above).
   - Loop if the user wants different attributes for different widgets (e.g. break-before for `rate_7d`,
     none for the rest).
3. **Persist** each selected widget by running the helper (idempotent; preserves all other conf lines):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/statusline/set-widget-break.sh <widget> <before|after|none>
   ```
   ("Select all" → run it once per widget in the list above.)
4. **Refresh the renderer** so the installed copy is current (the renderer reads the conf at render time;
   re-installing also guarantees the break-aware version is in place):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/statusline/install.sh
   ```
5. **Confirm** the resulting layout to the user and remind them it applies after a restart or `/reload`.
   Offer to show a preview by piping sample JSON through `${CLAUDE_PLUGIN_ROOT}/statusline/i2p-statusline.sh`.

## Notes

- Plugin-contributed widgets (`~/.claude/state/statusline-widgets.d/*.sh`) render with `none` by default;
  their break key is `break_widget:<name>` (advanced; the chooser covers the seven built-ins).
- This skill edits only `break_<widget>` keys in the conf and re-copies the one renderer file — nothing else.
