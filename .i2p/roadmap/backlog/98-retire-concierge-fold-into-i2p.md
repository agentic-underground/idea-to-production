---
id: 98
title: "Retire concierge → fold into i2p"
status: PENDING
priority: HIGH
added: 2026-06-17
depends_on: "—"
---

# [98] Retire concierge → fold into i2p

**Brief Description**
Retire the standalone `concierge` plugin and fold its surfaces into the `i2p` front door. The front-door
greeting, the welcome flow, and the status line are just things that happen when you open an i2p project —
they do not need a separate product name. Move concierge's commands, skills, hooks, and `statusline/`, plus
the SessionStart welcome and `define-welcome`, into `plugins/i2p/`; re-namespace `/concierge:*`→`/i2p:*`;
preserve the `~/.claude/hook-state` opt-out markers so users who already declined a welcome/statusline stay
declined; drop the `concierge` entry from `marketplace.json` and merge its `hooks.json` into i2p's. The
status line is the multi-tenant HUD — it becomes i2p's instrument.

### User Stories
- AS a marketplace user I WANT the greeting, welcome, and status line to come from the `i2p` front door
  SO THAT there is one entry-point product, not a separate "concierge" name for things that just happen.
- AS a user who already opted out of the welcome or status line I WANT my choice preserved across the merge
  SO THAT I am not re-prompted after concierge is folded in.

### EARS Specification
**Ubiquitous**
- The `concierge` plugin SHALL NOT exist after this item — no `plugins/concierge/` dir and no
  `.claude-plugin/marketplace.json` entry for it.
- The status line, welcome flow, `define-welcome`, and statusline-widget editing SHALL be served by `i2p`
  under the `/i2p:` namespace.

**Event-driven**
- WHEN a session starts in an i2p project THE SYSTEM SHALL run i2p's merged SessionStart hooks (inject-kaizen,
  session-intro, welcome inject/offer, statusline offer, doc-alert) honouring the existing
  `~/.claude/hook-state` opt-out markers.

**Unwanted behaviour**
- IF a user previously recorded a welcome or statusline opt-out under `~/.claude/hook-state` THEN the merged
  i2p hooks SHALL NOT re-offer it — the marker SHALL still suppress the prompt.
- IF any `concierge` reference (dir path, `/concierge:` prefix, manifest entry) survives THEN
  `bash scripts/verify-prereqs.sh` SHALL be red until it is fixed.

### Acceptance Criteria
1. Given the merge, When `bash scripts/verify-prereqs.sh` runs, Then it ends green — Check H sees no
   `concierge` dir and no orphan entry, and Checks N/O pass with one fewer plugin copy of KAIZEN.md /
   inject-kaizen.sh (concierge's copies are removed, not orphaned).
2. Given a fresh session, When it starts, Then i2p greets/offers the welcome and status line, and
   `/i2p:statusline`, `/i2p:statusline-widgets`, `/i2p:define-welcome` resolve.
3. Given a user with an existing `~/.claude/hook-state` welcome/statusline opt-out, When a session starts,
   Then no re-prompt occurs.
4. Given a repo-wide search, When grepping for `concierge` and `/concierge:`, Then no stale references remain
   in shipped plugin files, manifests, or docs.

### Implementation Notes
- Move concierge surfaces into `plugins/i2p/`: `git mv` the command files (`define-welcome.md`,
  `statusline.md`, `statusline-widgets.md`, and concierge's `check.md`/`inspect.md` content — fold rather than
  clobber i2p's own `check`/`inspect`), the skills (`check`, `define-welcome`, `statusline-install`,
  `statusline-widgets`), the `statusline/` dir (incl. `count-adversarial-catches.sh`, `capture-cost.sh`), and
  the hook scripts (`inject-welcome.sh`, `offer-welcome.sh`, `offer-doc-alert.sh`, `offer-statusline.sh`,
  `check-statusline-drift.sh`, `welcome-preamble.md`).
- Merge `plugins/concierge/hooks/hooks.json` into `plugins/i2p/hooks/hooks.json`: append concierge's
  SessionStart entries (welcome inject/offer, statusline offer, doc-alert, drift check) after i2p's existing
  ones, and add concierge's `PostToolUse` (Write|Edit → count-adversarial-catches.sh) and `Stop`
  (capture-cost.sh) hook blocks. De-dup the single `inject-kaizen.sh` SessionStart entry (i2p already has one).
- Preserve the `~/.claude/hook-state` opt-out marker filenames the moved offer scripts read/write — do not
  rename them, so prior opt-outs keep matching.
- Re-namespace every `/concierge:*`→`/i2p:*` in the moved files and across all docs (README.md, VALUE_FLOW.md,
  glossary.md, docs/SLASH_COMMANDS.md, knowledge/); update each command's frontmatter/self-reference.
- Remove the `concierge` block from `.claude-plugin/marketplace.json` (Check H name-set parity) and delete the
  emptied `plugins/concierge/` dir, including its KAIZEN.md / inject-kaizen.sh copies (Checks N/O count one
  fewer copy — they must not become orphans).
- `foundry` companions do NOT reference concierge — no companion edit. Confirm `i2p`'s own `check`/`inspect`
  still work after folding concierge's into them.
- ONE atomic PR; must end green on `bash scripts/verify-prereqs.sh`.
