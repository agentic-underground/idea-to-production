---
id: 48
title: "Statusline widget line-break control (break-before / break-after / none)"
status: COMPLETE
priority: MEDIUM
added: 2026-06-15
completed: 2026-06-15
depends_on: "—"
---

# [48] Statusline widget line-break control (break-before / break-after / none)

**Brief Description**
A concierge skill lets the user assign a line-break attribute to each line-2 status-line widget so the
meters wrap to fit the terminal. Triggered conversationally ("show me the statusline widgets" / "I want
to edit the statusline widgets"), it presents a chooser of widgets (plus a "select all" option) and a
break attribute [break-before | break-after | none], persists the choices to
`~/.claude/i2p-statusline.conf`, and the renderer composes line breaks accordingly — `none` defers
wrapping to the terminal (the parent container).

### User Stories
- AS A solo builder I WANT to choose where the statusline meters break onto new lines SO THAT the status
  line fits my terminal width.
- AS A user I WANT to invoke a widget editor by saying "show me the statusline widgets" SO THAT I can
  configure breaks without hand-editing a conf file.
- AS A user I WANT a "select all widgets" option SO THAT I can apply one break attribute to every widget
  at once.

### EARS Specification
**Ubiquitous**
- The system SHALL support a per-widget line-break attribute with values `break-before`, `break-after`,
  and `none` for each line-2 status-line widget.
- The system SHALL default every widget's break attribute to `none` (widgets flow on one line; wrapping
  deferred to the terminal), preserving the current layout.

**Event-driven**
- WHEN the user says "show me the statusline widgets" or "I want to edit the statusline widgets" THE
  SYSTEM SHALL present the list of line-2 widgets (including a "select all widgets" option) and a choice
  of break attribute [break-before | break-after | none].
- WHEN the user selects widget(s) and a break attribute THE SYSTEM SHALL persist `break_<key>=<value>`
  for each selected widget to `~/.claude/i2p-statusline.conf` and refresh the installed renderer.
- WHEN the renderer composes the line-2 widgets THE SYSTEM SHALL begin a new line before a widget whose
  attribute is `break-before`, begin a new line after a widget whose attribute is `break-after`, and keep
  `none` widgets inline (joined by the existing MSEP separator), deferring wrapping to the terminal.

**Unwanted behaviour**
- IF adjacent break attributes would produce an empty line THEN THE SYSTEM SHALL collapse them to a
  single line break; leading/trailing breaks SHALL be trimmed (no blank lines).
- IF a `break_<key>` value is missing or invalid THEN THE SYSTEM SHALL treat it as `none`.
- IF a widget's data is absent this render (segment not shown) THEN its break attribute SHALL have no
  effect (no spurious blank line).

**State-driven**
- WHILE the line-1 identity row is rendered THE SYSTEM SHALL keep it on its own line (break control
  applies to line-2 widgets only).

**Optional feature**
- WHERE plugin-contributed widgets (`~/.claude/state/statusline-widgets.d/*.sh`) are present THE SYSTEM
  SHALL render them with the default `none` unless a break key is provided (extension point).

### Acceptance Criteria
1. Given the default config, When the statusline renders, Then line-2 widgets appear on one flowing line
   (current behaviour) and the terminal soft-wraps at its width.
2. Given `break_rate_7d=before`, When rendered, Then the 7-day rate widget starts on a new line and the
   widgets before it stay on the prior line.
3. Given `break_context=after`, When rendered, Then a single line break follows the context gauge.
4. Given a widget with `break-before` immediately after a widget with `break-after`, When rendered, Then
   exactly one line break (no blank line) appears between them.
5. Given the trigger "show me the statusline widgets", When invoked, Then the user sees the widget list +
   a "select all" option + the three attributes, and the selection is written to the conf.
6. Given a widget whose data is absent this render, When it carries a break attribute, Then no blank line
   appears.
7. Given an invalid/missing `break_<key>`, When rendered, Then it behaves as `none`.

### Implementation Notes
- **Renderer** `plugins/concierge/statusline/i2p-statusline.sh`: replace the line-2 assembly (today:
  collect `line2_parts[]`, join with `MSEP`, one `printf "\n"`) with a break-aware composer that walks an
  ordered list of `(key, rendered_segment)` and emits `\n` per `break_<key>` (collapse consecutive, trim
  edges); `none`-adjacent widgets stay joined by `MSEP`. Keep line 1 unchanged. Add a parallel
  `line2_keys[]` array so each part carries its key (currently the key is lost).
- **Config**: extend the existing conf loader (the `SEG` block) to also read `break_<key>` into a `BREAK`
  map with a `break_of()` helper defaulting to `none`; update the conf header comment (document
  `break_<key>` keys). Keys: `break_context break_rate_5h break_rate_7d break_lifecycle
  break_session_cost break_lifecycle_cost break_catches`.
- **New skill** `plugins/concierge/skills/statusline-widgets/SKILL.md` (+ command
  `plugins/concierge/commands/statusline-widgets.md`), triggers: "show me the statusline widgets", "I
  want to edit the statusline widgets", "edit statusline widgets". It enumerates the line-2 widget keys,
  presents the chooser (select widgets incl. "select all" + one of the three attributes), writes
  `break_<key>` lines to the conf **preserving the visibility keys**, then runs `statusline/install.sh`
  to refresh. Reuse the existing conf format, `install.sh`, and `MSEP`.
- Backward-compatible: absent break keys ⇒ `none` ⇒ today's single meters line.
- Honour the four-mirror guardrail (SKILL.md frontmatter + README /command mention) and bump the
  concierge plugin version (CI check H).

### Human Interface Test Plan
- [statusline-widgets trigger]: say "show me the statusline widgets" → verify a chooser lists the line-2
  widgets + a "select all widgets" option + the attribute choice [break-before | break-after | none] →
  select `{rate_7d: break-before}` → confirm → verify `break_rate_7d=before` is written to
  `~/.claude/i2p-statusline.conf` → /reload → verify the 7-day rate widget now renders on its own line →
  re-invoke the trigger → verify it reflects the current attribute.
