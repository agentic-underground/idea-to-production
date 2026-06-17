---
id: 113
title: "Reconcile docs/SLASH_COMMANDS.md to shipped reality; clear inline feedback"
status: PENDING
priority: MEDIUM
added: 2026-06-17
depends_on: "#94, #95, #96, #97, #98, #99, #105, #106 (the renames + flow surface that change command names)"
---

# [113] Reconcile docs/SLASH_COMMANDS.md to shipped reality; clear inline feedback

**Brief Description**
`docs/SLASH_COMMANDS.md` is the owner's git-tracked feedback surface — the document whose ~89 inline `>`
directives are the source of the whole Marketplace-v2 epic ([93]). It is currently a mix of the *as-shipped*
command catalog and the owner's *requested changes* scrawled inline. Once Stream 1 (the renames, #94–#99)
and the head of Stream 3 (the flow/DELIVER surface, #105, #106) have merged, the catalog rows are stale:
they still list `/sentinel:*`, `/mission-control:*`, `/pressroom:*`, `concierge`, `flow-server`, and the old
command verbs, and they predate the DELIVER stage and the unified `/flow` family. This item rewrites the
catalog so every row reflects the **final** plugin/command names and the new flow surface, and **removes
every resolved inline `>` note** — each one having been discharged either by a shipped child item or by an
explicit recorded owner decision. The "this file is a feedback surface" framing at the top is preserved: the
file keeps doing its job, it is just brought current. This is documentation reconciliation only — it ships no
plugin behaviour, it follows the behaviour.

### User Stories
- AS the owner I WANT the catalog rows to name the real, shipped commands (`/security:scan-*`, `/operate:*`,
  `/publish:*`, `/flow …`, `/i2p:check`, no `concierge`) SO THAT the document I use to drive feedback matches
  what I can actually type.
- AS the owner I WANT every inline `>` directive I have already had built to be removed (not silently left
  to rot) SO THAT a remaining `>` note unambiguously means "still open", and the feedback surface stays a
  trustworthy signal rather than a graveyard.
- AS a future agent reading this file back I WANT it to match `plugins/*/commands/` and `plugins/*/skills/`
  exactly SO THAT I can trust it as the command index without re-deriving the surface from the tree.

### EARS Specification
**Ubiquitous**
- The file SHALL retain its "this file is a feedback surface" preamble (the git-tracked-markdown framing and
  the `> note:` mechanism) so its role as the owner's feedback channel is unchanged.
- Every command row in the catalog SHALL name a command that actually resolves under some
  `plugins/<plugin>/commands/` (or skill under `plugins/<plugin>/skills/`) at HEAD, with the final v2 plugin
  prefix.

**Event-driven**
- WHEN all of this item's `depends_on` children have merged THE SYSTEM SHALL contain, in
  `docs/SLASH_COMMANDS.md`, no unresolved inline `>` directive — each former `>` note SHALL have been removed
  with a traceable disposition: a shipped child item id, or an explicit owner decision recorded in epic [93].
- WHEN the catalog is regenerated THE SYSTEM SHALL list the DELIVER stage and the `/flow` command family
  (e.g. `/flow pull|carry|report|setup`, per #105/#106) and the BUILD→ASSURE→SECURE loop framing introduced
  by Stream 2.

**Unwanted behaviour**
- IF any catalog row still names a retired identity (`sentinel`, `mission-control`, `pressroom`, `concierge`,
  `flow-server`) or a retired command verb (`security-gate`, `dependency-audit`, `secret-scan`, `pii-audit`,
  `/i2p:i2p-check`) THEN the reconciliation SHALL be treated as incomplete.
- IF a `>` directive cannot be traced to a shipped child or a recorded owner decision THEN THE SYSTEM SHALL
  leave that one `>` note in place (it is still open) rather than delete it — only *resolved* directives are
  cleared.

### Acceptance Criteria
1. Given the merged dependency set, When `grep -nE '^>' docs/SLASH_COMMANDS.md` is run, Then it returns only
   `>` lines that are still-open feedback (the preamble blockquote excepted) — every directive discharged by
   #94–#99/#105/#106 (or by a recorded owner decision) is gone.
2. Given the catalog, When each command row is checked against the tree, Then every row resolves to an
   existing file under `plugins/<plugin>/commands/` or `plugins/<plugin>/skills/`, using the final names
   (`/security:scan-all`, `/security:scan-dependencies`, `/security:scan-for-secrets`, `/security:scan-for-pii`,
   `/operate:*`, `/publish:*`, `/flow …`, `/i2p:check`), and no row names a retired plugin/command.
3. Given the rewritten file, When the preamble is read, Then the "this file is a feedback surface" framing and
   the `> note:` mechanism are still present and accurate.
4. Given each removed `>` directive, When its disposition is reviewed, Then it traces to a shipped child item
   id or an explicit owner decision in epic [93] — no directive is dropped without a paper trail.

### Implementation Notes
- This is the catalog half of Stream 6; the shared-knowledge-doc sweep is its sibling [114]. Keep the two
  separate: this item owns only `docs/SLASH_COMMANDS.md`.
- Regenerate rows from the live surface: enumerate `plugins/*/commands/*.md` and the user-facing
  `plugins/*/skills/` at HEAD after the renames, then write each row from the file that exists — do not
  hand-patch the stale rows one prefix at a time (that is how drift re-enters).
- Build the directive-disposition map first: for each `>` note, record which child item shipped it (or which
  owner decision in [93] settled it). That map is the evidence for AC#4 and prevents deleting an *open*
  directive by mistake. Notes already visible in the file include the i2p⇄concierge merge (→ #99/#106),
  DELIVER as a lifecycle phase (→ Stream 2 / #100), the BUILD/ASSURE/SECURE split-into-a-loop, the
  `/i2p:i2p-check`→`/i2p:check` rename, and the autonomous self-improvement / KAIZEN directive (→ Stream 4).
- Land this AFTER its dependencies merge — a reconciliation run before the renames ship would reintroduce the
  very stale names it is meant to remove. If the renames land in waves, the safe ordering is one final pass
  once #94–#99 and #105/#106 are all in.
- Do not invent commands to fill gaps: if the owner asked for a command in a `>` note that was *not* built,
  that `>` note stays (open), it does not become a catalog row.
- One atomic PR touching only `docs/SLASH_COMMANDS.md`; the always-on `/foundry:pr-review` is the gate.
