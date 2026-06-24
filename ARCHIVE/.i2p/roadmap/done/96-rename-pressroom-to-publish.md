---
id: 96
title: "Rename pressroom → publish"
status: COMPLETE
priority: MEDIUM
added: 2026-06-17
completed: 2026-06-17
depends_on: "—"
---

# [96] Rename pressroom → publish

**Brief Description**
Rename the `pressroom` plugin to `publish` so the plugin name names the PUBLISH phase it serves. Blast
radius is roughly 159 files: the plugin dir, every `/pressroom:*` command prefix, every `plugins/pressroom/`
doc path, the byte-mirrored KAIZEN assets, and the `foundry` companion key `publishing` whose value points at
this plugin. One atomic, mostly-mechanical rename PR.

### User Stories
- AS a marketplace user I WANT the publishing plugin called `publish` SO THAT its name matches the PUBLISH
  phase and I can find it by what it does, not by a codename.
- AS a user invoking it I WANT `/publish:publish`, `/publish:illustrate`, `/publish:check`, etc. SO THAT the
  command namespace is consistent with the phase name.

### EARS Specification
**Ubiquitous**
- The plugin SHALL be named `publish` consistently across its directory name, `plugin.json` `name`, and its
  `.claude-plugin/marketplace.json` entry (Check H).
- Every command, skill, and doc reference SHALL use the `/publish:` prefix and the `plugins/publish/` path.

**Event-driven**
- WHEN `foundry`'s publishing companion is resolved THE SYSTEM SHALL find it under the `publishing` key →
  `publish` plugin (the renamed companion target).

**Unwanted behaviour**
- IF any `pressroom` reference (dir path, `/pressroom:` prefix, companion value, manifest entry, doc link)
  survives THEN `bash scripts/verify-prereqs.sh` SHALL be red until it is fixed.

### Acceptance Criteria
1. Given the renamed plugin, When `bash scripts/verify-prereqs.sh` runs, Then it ends green — Check H
   (dir == name == entry) and Checks N/O (KAIZEN.md / inject-kaizen.sh byte-identical).
2. Given the `foundry` companions map, When `/foundry:foundry` or `/publish:publish` resolves the publisher,
   Then `"publishing"` points at the `publish` plugin and the handoff works.
3. Given a repo-wide search, When grepping for `pressroom` and `/pressroom:`, Then no stale references remain
   in shipped plugin files, manifests, or docs.

### Implementation Notes
- `git mv plugins/pressroom plugins/publish`; set `name` to `publish` in
  `plugins/publish/.claude-plugin/plugin.json` and update the matching `name` + `source: ./plugins/publish`
  entry in `.claude-plugin/marketplace.json` — Check H.
- Update `foundry` companions in `plugins/foundry/.claude-plugin/plugin.json`: `"publishing": "pressroom"` →
  `"publishing": "publish"` (key unchanged, value renamed). `foundry` composes the publisher by capability —
  confirm it resolves the renamed plugin.
- Re-sync the byte-mirrored `plugins/publish/KAIZEN.md` and `plugins/publish/hooks/inject-kaizen.sh` so md5sums
  match (Checks N/O).
- Sweep every `/pressroom:*` prefix and `plugins/pressroom/` path across commands, skills, agents (the
  graphical handlers), hooks, and docs (README.md, VALUE_FLOW.md, glossary.md, docs/SLASH_COMMANDS.md,
  knowledge/) → `/publish:` and `plugins/publish/`. Note other plugins compose PRESSROOM by capability
  (e.g. `operate`'s wiki-publisher, `i2p:review`); update those references too.
- ONE atomic PR; must end green on `bash scripts/verify-prereqs.sh`.
