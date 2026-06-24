---
id: 102
title: "Statusline phase widget — render 9 phases + the B/A/S loop"
status: COMPLETE
completed: 2026-06-18
priority: MEDIUM
added: 2026-06-17
depends_on: "#98 (statusline now in i2p), #100, #101"
---

# [102] Statusline phase widget — render 9 phases + the B/A/S loop

**Brief Description**
Update the statusline phase widget to render the v2 model: nine phases instead of eight, plus a
**loop indicator** for the BUILD ⇄ ASSURE ⇄ SECURE loop, reading the new `.i2p/lifecycle.json` loop
fields (`loop_state`, `loop_pass`) added in #101. The widget currently lives in the statusline
renderer `i2p-statusline.sh` (the phase widget block ~lines 261–290), draws an **8-pip** progress
track, and uses a hard-coded fallback phase string
`DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE` (~line 279) when `.phases[]` is absent.
Per #98 the statusline moves into the i2p plugin, so this item targets the post-merge i2p-owned
renderer.

### User Stories
- AS a builder watching the status bar I WANT it to show the nine v2 phases SO THAT the pip count and
  current-phase highlight match the model (no stale 8-pip track).
- AS a builder iterating through the loop I WANT a loop indicator (e.g. the B/A/S segment shown as a
  ⇄ cluster with the iteration count) SO THAT I can see at a glance that I'm cycling
  BUILD/ASSURE/SECURE rather than progressing linearly.

### EARS Specification
**Ubiquitous**
- The phase widget SHALL render the nine v2 phases, driven by `.i2p/lifecycle.json` `.phases[]`, with
  a nine-phase hard-coded fallback string when `.phases[]` is absent.
- The widget SHALL render a **loop indicator** for the BUILD ⇄ ASSURE ⇄ SECURE segment, reading
  `loop_state` (and `loop_pass` when present) from the state file.

**Event-driven**
- WHEN `current_phase` is one of BUILD/ASSURE/SECURE THE widget SHALL show the loop indicator and
  highlight the active loop state.
- WHEN `loop_pass` indicates more than one iteration THE widget SHALL surface that (e.g. `⇄ ×2`) so a
  re-entry into BUILD is visible.
- WHEN the state file is absent or unreadable THE widget SHALL degrade gracefully to the static
  nine-phase fallback, never erroring the status bar.

**Unwanted behaviour**
- IF any "8", `(n/8)`, or 8-pip assumption remains in the widget THEN that is a defect — the track
  SHALL be nine phases.
- IF the loop fields are missing from an older state file THEN the widget SHALL still render the nine
  phases without the loop count (no crash, no blank bar).

### Acceptance Criteria
1. Given a v2 `.i2p/lifecycle.json`, When the statusline renders, Then it shows a nine-pip track with
   the current phase highlighted.
2. Given `current_phase` in BUILD/ASSURE/SECURE with `loop_state`/`loop_pass` set, When rendered,
   Then a loop indicator marks the B/A/S segment and shows the iteration when > 1.
3. Given a `.phases[]`-less or absent state file, When rendered, Then the nine-phase fallback string
   is used and the bar does not error.
4. Given the renderer source, When inspected, Then no hard-coded "8" pip count or `(n/8)` remains.

### Implementation Notes
- Depends on #98 moving the statusline into i2p — until then the live file is
  `plugins/concierge/statusline/i2p-statusline.sh`; the phase widget is the block at ~lines 261–290
  (`current_phase` at ~274, `.phases` join at ~275, the fallback string at ~279, the pip loop at
  ~281–283). Target whichever path owns it post-#98 (expected `plugins/i2p/statusline/i2p-statusline.sh`).
- Implements the rendering of the model from #100 and reads the schema fields from #101 — depend on
  both for the exact phase order and the `loop_state`/`loop_pass` field names.
- Keep the widget read-only and jq-best-effort (it already guards on jq); the loop indicator is a
  presentation layer over the new fields, computing nothing the state machine doesn't already record.
- Honour the existing widget break-layout config (`set-widget-break.sh` / statusline-widgets) — the
  phase widget stays one logical widget.
