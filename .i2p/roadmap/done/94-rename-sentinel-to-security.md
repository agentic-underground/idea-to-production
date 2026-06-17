---
id: 94
title: "Rename sentinel → security (+ scan-* command renames)"
status: COMPLETE
priority: HIGH
added: 2026-06-17
completed: 2026-06-17
depends_on: "—"
---

# [94] Rename sentinel → security (+ scan-* command renames)

**Brief Description**
Rename the `sentinel` plugin to `security` so the plugin name is function-first and matches the SECURE
phase of the value flow, dropping the "salesy" codename. In the same atomic PR, rename its four commands
to a verb-first `scan-*` scheme: `security-gate`→`scan-all`, `dependency-audit`→`scan-dependencies`,
`secret-scan`→`scan-for-secrets`, `pii-audit`→`scan-for-pii`. Blast radius is roughly 168 files (the
plugin dir, every `/sentinel:` command prefix, every `plugins/sentinel/` doc path, the foundry companion
key, and the byte-mirrored KAIZEN assets), so this is a single large but mechanical rename PR.

### User Stories
- AS a marketplace user I WANT the security plugin to be called `security` SO THAT its name tells me what
  it does and lines up with the SECURE phase, not an opaque codename.
- AS a user invoking scanners I WANT `/security:scan-dependencies` / `/security:scan-for-secrets` /
  `/security:scan-for-pii` / `/security:scan-all` SO THAT the command verbs describe the action consistently.

### EARS Specification
**Ubiquitous**
- The plugin SHALL be named `security` consistently across its directory name, `plugin.json` `name`, and its
  `.claude-plugin/marketplace.json` entry (the three-way identity that Check H enforces).
- The four scanner commands SHALL be named `scan-all`, `scan-dependencies`, `scan-for-secrets`, and
  `scan-for-pii`, invokable as `/security:scan-*`.

**Event-driven**
- WHEN `foundry`'s security companion is resolved THE SYSTEM SHALL find it under the `security` key →
  `security` plugin (the renamed companion target).

**Unwanted behaviour**
- IF any `sentinel` reference (dir path, `/sentinel:` prefix, companion value, manifest entry, doc link)
  survives the rename THEN `bash scripts/verify-prereqs.sh` SHALL be red until it is fixed — no dangling old name.

### Acceptance Criteria
1. Given the renamed plugin, When `bash scripts/verify-prereqs.sh` runs, Then it ends green — including
   Check H (dir == `plugin.json` name == marketplace entry) and Checks N/O (KAIZEN.md / inject-kaizen.sh
   byte-identical across all plugin copies).
2. Given the four renamed commands, When a user runs `/security:scan-all`, `/security:scan-dependencies`,
   `/security:scan-for-secrets`, `/security:scan-for-pii`, Then each resolves and runs its scan.
3. Given a repo-wide search, When grepping for `sentinel`, `/sentinel:`, `security-gate`, `dependency-audit`,
   `secret-scan`, `pii-audit`, Then no stale references remain in shipped plugin files, manifests, or docs.

### Implementation Notes
- `git mv plugins/sentinel plugins/security`; set `name` to `security` in `plugins/security/.claude-plugin/plugin.json`
  and update the matching entry (`name` + `source: ./plugins/security`) in `.claude-plugin/marketplace.json` — Check H.
- Rename the command files under `plugins/security/commands/`: `security-gate.md`→`scan-all.md`,
  `dependency-audit.md`→`scan-dependencies.md`, `secret-scan.md`→`scan-for-secrets.md`, `pii-audit.md`→`scan-for-pii.md`;
  update each command's self-reference, frontmatter, and any skill that names the old command.
- Re-sync the byte-mirrored `plugins/security/KAIZEN.md` and `plugins/security/hooks/inject-kaizen.sh` after the move
  so md5sums still match the canonical root / sibling copies (Checks N/O).
- Update `foundry` companions in `plugins/foundry/.claude-plugin/plugin.json`: `"security": "sentinel"` →
  `"security": "security"` (key unchanged, value renamed). `foundry`'s `/pr-review` composes the security gate by
  capability — confirm it resolves the renamed plugin/command.
- Sweep every `/sentinel:` command prefix and `plugins/sentinel/` path in docs (README.md, VALUE_FLOW.md,
  glossary.md, docs/SLASH_COMMANDS.md, knowledge/) → `/security:` and `plugins/security/`, including the four
  command-name renames.
- ONE atomic PR; must end green on `bash scripts/verify-prereqs.sh`.
