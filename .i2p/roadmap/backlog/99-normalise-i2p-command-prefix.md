---
id: 99
title: "Normalise i2p command prefix: /i2p:i2p-check → /i2p:check"
status: PENDING
priority: LOW
added: 2026-06-17
depends_on: "—"
---

# [99] Normalise i2p command prefix: /i2p:i2p-check → /i2p:check

**Brief Description**
Remove the redundant `i2p-` stutter from the `i2p` plugin's command names. Today the namespace already
encodes the plugin (`/i2p:`), so `/i2p:i2p-check` repeats it. Audit the whole `i2p:i2p-*` redundancy
(`i2p-help`, `i2p-flow`, `i2p-lifecycle`, `i2p-review`, `i2p-check`), decide one consistent scheme, and at
minimum rename `/i2p:i2p-check`→`/i2p:check`. Consistency is mandated, so the chosen scheme must be applied
uniformly across all five commands rather than fixing one in isolation.

### User Stories
- AS a user invoking the front door I WANT `/i2p:check` (not `/i2p:i2p-check`) SO THAT the command name is not
  a stutter of its own namespace.
- AS a user learning the marketplace I WANT all five i2p commands to follow one naming scheme SO THAT the
  namespace is predictable.

### EARS Specification
**Ubiquitous**
- The `i2p` commands SHALL follow a single consistent naming scheme with no `i2p-` stutter where the `/i2p:`
  namespace already conveys it; at minimum `i2p-check` SHALL be `check` (invokable as `/i2p:check`).

**Event-driven**
- WHEN a user invokes the renamed command(s) THE SYSTEM SHALL resolve and run the same skill/behaviour as
  before the rename.

**Unwanted behaviour**
- IF a renamed command's old name is still referenced anywhere in shipped files, manifests, or docs THEN
  `bash scripts/verify-prereqs.sh` and the docs SHALL be inconsistent until the reference is fixed.

### Acceptance Criteria
1. Given the renamed command(s), When `bash scripts/verify-prereqs.sh` runs, Then it ends green (Check H is
   unaffected — only command names change, not the plugin identity; Checks N/O still pass).
2. Given the new scheme, When a user runs `/i2p:check` (and any other renamed command), Then it resolves and
   runs.
3. Given a repo-wide search, When grepping for the old command name(s) (`i2p-check`, plus any others the
   chosen scheme renames), Then no stale references remain in shipped plugin files or docs.

### Implementation Notes
- This item does NOT rename the plugin (it stays `i2p`), so Check H (dir == `plugin.json` name == marketplace
  entry) is untouched; the change is command-file names + their self-references only.
- Audit `plugins/i2p/commands/`: `i2p-help.md`, `i2p-flow.md`, `i2p-lifecycle.md`, `i2p-review.md`,
  `i2p-check.md`. Decide the scheme — recommended: strip the `i2p-` prefix on every command (→ `help`, `flow`,
  `lifecycle`, `review`, `check`) so they read `/i2p:help`, `/i2p:flow`, etc. Apply it to ALL five for
  consistency, not just `check`.
- `git mv` each command file, update its frontmatter and self-reference, and update the matching skill names
  and any cross-references in other plugins' skills/docs.
- Sweep docs (README.md, VALUE_FLOW.md, glossary.md, docs/SLASH_COMMANDS.md, knowledge/, and the
  `/i2p-check`-style mentions in skill descriptions) to the new names.
- Coordinate with #98 if both land: concierge's folded-in commands also enter the `/i2p:` namespace — keep the
  whole i2p command set on one scheme.
- ONE atomic PR; must end green on `bash scripts/verify-prereqs.sh`.
