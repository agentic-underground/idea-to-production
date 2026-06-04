# FOUNDRY Inspection Report — 2026-06-04

> **Archived, maintainer-facing.** A point-in-time `/foundry:inspect` snapshot, kept in
> `doc/historical/` (not part of any plugin). Any `~/.claude` mention below is historical record —
> that environment is no longer a concern of the marketplace plugins, which are self-improving and
> run where they are installed. The CRITICAL fixes here were applied and merged; the WARNING/
> SUGGESTION items were addressed in the follow-up.

## Summary

| Category | Files inspected | Issues found |
|---|---|---|
| Skills | 28 | 3 |
| Agents | 28 | 3 |
| Knowledge | 30 | 4 |
| Hooks/Manifests/MCP | 6 | 2 |
| Cross-system | — | 2 |

**Total issues: 14** (CRITICAL: 2, WARNING: 7, SUGGESTION: 5)

Two CRITICAL findings were **fixed in the working tree** (this is the marketplace source repo).
The recently-landed surfaces (Playwright MCP + six web-handler grants, the `lspServers` block, the
per-plugin `/…:check` skills + byte-identical `check.sh`, `/foundry:prerequisites`,
`/foundry:pr-review`, and the entire merge-governance / `AWAITING_MERGE` feature) are largely
**clean and internally consistent** — the propagation across context-sentinel, orchestration-loop,
definition-of-done, roadmapper, delivery, ds-step-9, and founder is thorough. The FORGE de-drift
holds: no cross-plugin filesystem paths to sentinel/pressroom remain, and the `~/.claude` references
that survive are all in the provenance/legacy allowlist except one (W-1).

---

## Issues

### CRITICAL — Stale dated model ID disagrees with the canonical table  ✅ FIXED
**File:** `plugins/foundry/skills/builder/SKILL.md:589,602`, `skills/check/SKILL.md:13`,
`agents/ds-step-3-tests.md:5,13,17`, `agents/coverage-loop-agent.md:11,19`, and all 9 web/handler
spawning tables (`handler-{playwright,react,fastapi,css,js,vanilla-js,python,rust,rust-webapp}.md`).
**Finding:** 13 files pinned `claude-haiku-4-5-20251001` (dated). The canonical single-source-of-truth
table in `knowledge/policy/model-selection.md:31` declares the haiku ID as **`claude-haiku-4-5`**
(bare) and states "Resolve at spawn time, do not hardcode … pinned IDs cannot silently age out."
The opus/sonnet references already use bare IDs (`claude-opus-4-8`, `claude-sonnet-4-6`); only haiku
carried the stale suffix — a direct contradiction of the policy the inspector is meant to enforce
(`model-selection.md:38`: "An agent whose `model:` disagrees with this table is a drift defect").
**Impact:** spawning agents pass a dated model ID that the model-selection doc says is wrong; when
the haiku family revs, these 13 sites age out independently of the table the policy promised would
re-tier the whole fleet in one edit.
**Fix applied:** replaced every `claude-haiku-4-5-20251001` → `claude-haiku-4-5` across all 13 files.
Verified zero dated haiku IDs remain.

### CRITICAL — Dangling reference to a migrated path in the delivery agent  ✅ FIXED
**File:** `plugins/foundry/agents/ds-step-9-commit-push.md:53`
**Finding:** Step 9 instructed "append the cost record per `references/idea-cost-schema.md`". That
relative path resolves to `agents/references/idea-cost-schema.md`, which does not exist — the file
was moved to `knowledge/orchestration/idea-cost-schema.md` (recorded in `docs/MIGRATION.md:31`). The
reference was never updated and was an un-clickable bare-backtick path.
**Impact:** the delivery agent — at the most consequential step (writing the cost ledger) — is
pointed at a nonexistent file; an agent that tries to open it fails or silently skips the schema.
**Fix applied:** rewrote to a correct, clickable relative link:
`[`../knowledge/orchestration/idea-cost-schema.md`](../knowledge/orchestration/idea-cost-schema.md)`.

---

### WARNING — Live `~/.claude`-style coupling in the founder agent
**File:** `plugins/foundry/agents/founder.md:229`
**Finding:** "When you generate skills via `skill-creator`, you write them under
`./.claude/plugins/foundry/`." This project-relative path assumes the marketplace-source layout and
is a residue of the FORGE de-drift. An installed plugin should not write generated skills into a
hardcoded `.claude/plugins/foundry/` directory.
**Impact:** in a normal install, this instruction points the author flow at a path that may not be
the right plugin root; it contradicts the de-drift principle that actors run where they are installed.
**Proposed fix:** either scope it to the source-repo case explicitly ("when running from the
marketplace source") or express the destination by capability / `${CLAUDE_PLUGIN_ROOT}` rather than a
fixed `./.claude/plugins/foundry/`. Left unapplied — the correct target is intent-dependent.

### WARNING — Glossary not extended for the three merged PRs' user-facing terms
**File:** `plugins/foundry/knowledge/glossary.md:87-111`
**Finding:** The glossary §3 omits surfaces that just landed. **Skills** (l.87) is missing `check`,
`prerequisites`, `pr-review`. **Commands** (l.93) is missing `/foundry:check`,
`/foundry:prerequisites`, `/foundry:pr-review`, and the `/sentinel:check` / `/pressroom:check`
commands. **Core concepts** (l.98) is missing "Merge governance", "AWAITING MERGE",
"Adversarial PR review", and "Live feedback / Playwright MCP". The propagation checklist in
`context-sentinel.md:307` explicitly requires glossary registration for new user-facing terms.
**Impact:** the glossary — advertised as the conceptual single source — drifts behind the system; a
reader cannot look up `AWAITING MERGE` or `pr-review`.
**Proposed fix:** add the missing skills/commands to §3 and four Core-concept entries (merge
governance + its two modes, AWAITING MERGE, adversarial PR review, live feedback). Multi-line content
addition — surfaced for the next pass rather than auto-applied.

### WARNING — `builder/SKILL.md` §15.5 duplicates the canonical model policy (one-copy violation)
**File:** `plugins/foundry/skills/builder/SKILL.md:579-608`
**Finding:** §15.5 "TOKEN EFFICIENCY MODEL POLICY" is a full second copy of
`knowledge/policy/model-selection.md` (the same table, the same spawning rule). The knowledge-parity
pillar (`pillars/knowledge-parity.md`) and the one-copy rule say canonical facts live in exactly one
place. This duplication is exactly why the dated-haiku drift (C-1) propagated to 13 sites — the copy
ages independently.
**Impact:** two copies of the model policy drift apart (already happened with the haiku ID).
**Proposed fix:** replace §15.5's table/rule with a one-line pointer to
`knowledge/policy/model-selection.md`, keeping only builder-specific spawning prose.

### WARNING — Stale "reviewer, reviewer" duplication and `ARCHITECT-AGENT` naming
**File:** `plugins/foundry/skills/builder/SKILL.md:588,596` (also `:416`)
**Finding:** Two tables list "reviewer, reviewer" (the same role twice — a leftover from before the
reviewer roles were consolidated into the single `reviewer` agent) and refer to `ARCHITECT-AGENT`,
which the roster now calls `handler-architect`.
**Impact:** confusing role inventory; implies a second reviewer agent that does not exist.
**Proposed fix:** collapse "reviewer, reviewer" → "reviewer"; rename `ARCHITECT-AGENT` →
`handler-architect` to match `agent-roster.md`.

### WARNING — `live-feedback.md` implies a per-LSP-server `strict` flag that does not exist
**File:** `plugins/foundry/knowledge/tooling/live-feedback.md:63`
**Finding:** "FOUNDRY wires (all `strict: false`, so a missing binary degrades gracefully)". In
`marketplace.json`, `"strict": false` is set once at the **plugin-entry** level (line 41), not on each
`lspServers` entry. The phrasing implies a per-server flag.
**Impact:** a maintainer may look for (or add) a nonexistent per-server `strict` key.
**Proposed fix:** reword to "the foundry plugin entry is `strict: false`, so a missing LSP binary
degrades gracefully" — attribute the flag to the plugin entry, not the servers.

### WARNING — `pr-review` / `check` / `prerequisites` skills not catalogued in the agent roster
**File:** `plugins/foundry/knowledge/orchestration/agent-roster.md`
**Finding:** The roster catalogues agents and the inspector but does not mention the new command-driven
skills (`pr-review` fans out the `reviewer` agent in six adversarial roles; `check`/`prerequisites`
are diagnostic surfaces). `pr-review` in particular *spawns the reviewer agent* and so belongs in the
roster's account of how reviewer roles are used.
**Impact:** the roster — billed as "the complete catalogue of agents used in a FOUNDRY cycle" — omits
the orchestrator that now drives the adversarial panel at the merge gate.
**Proposed fix:** add a short "Command-driven skills" note to the roster naming `pr-review` (and its
six reviewer roles), `check`, and `prerequisites`, cross-linked to their SKILL.md files.

### WARNING — Prose pointers to "FOUNDRY §15.5 / §4.3" rely on an unstated numbering scheme
**File:** `agents/ds-step-1-ears.md:13`, `ds-step-2-feature-docs.md:13`, `coverage-loop-agent.md:19`,
`ds-step-3-tests.md:13`, `handler-python.md:69`, `builder-lead.md:186`, `idea-cost-schema.md:117`.
**Finding:** Several agents say "Pinned … per FOUNDRY §15.5" / "the heuristic table in FOUNDRY §4.3".
These § numbers map to sections in `skills/builder/SKILL.md` (which has a `## 15.5`), **not** to
`VALUE_FLOW.md` (which only goes to §10). The convention is undocumented, so the pointer reads as
dangling. The canonical policy actually lives in `knowledge/policy/model-selection.md`.
**Impact:** a reader chasing "FOUNDRY §15.5" against VALUE_FLOW finds nothing; the real source is
ambiguous.
**Proposed fix:** repoint the model-tier "§15.5" mentions at
`knowledge/policy/model-selection.md` (clickable link), and the "§4.3" cost-estimate mentions at the
actual heuristic location, retiring the bare "FOUNDRY §N" convention.

---

### SUGGESTION — `requirements.tsv` lacks a `gh` row, but `gather-diff.sh` hard-requires it
**File:** `plugins/foundry/skills/check/requirements.tsv`
**Finding:** `pr-review`'s `gather-diff.sh:35` dies if `gh` is absent for the PR-number path, and
`--post` needs it, yet `gh` is not a probed row in the dependency manifest. `/foundry:check` therefore
cannot warn that the PR-review surface is degraded.
**Proposed change:** add `gh  command -v gh  recommended  install GitHub CLI (cli.github.com)`.

### SUGGESTION — `check.sh` byte-identical copies have no automated drift assertion
**File:** `plugins/{foundry,sentinel,pressroom}/skills/check/scripts/check.sh`
**Finding:** All three copies are confirmed byte-identical (md5 `41eeaa86…`), and the header says
"Inspector/CI may assert the copies match." No such assertion exists yet; the inspector verifies it
manually each run.
**Proposed change:** add a tiny CI/inspector check (`md5sum | sort -u | wc -l == 1`) so a future edit
to one copy is caught automatically.

### SUGGESTION — `live-feedback.md` links to `PREREQUISITES/40-mcp.md` with no clickable target
**File:** `plugins/foundry/knowledge/tooling/live-feedback.md:21,46` (also `skills/check/SKILL.md:46`,
`skills/prerequisites/SKILL.md:42`)
**Finding:** `[`PREREQUISITES/40-mcp.md`]` is written as a reference but has no `(target)` and the
folder only exists in the marketplace source. The bracket-only form renders as literal text.
**Proposed change:** either make these conditional-source links explicit ("in the marketplace source:
`PREREQUISITES/40-mcp.md`") or drop the link syntax so they don't render as broken links.

### SUGGESTION — `coverage-loop-agent` / `flaky-test-fixer` absent from `model-selection.md` role lists
**File:** `plugins/foundry/knowledge/policy/model-selection.md:14-15`
**Finding:** `coverage-loop-agent` is listed (haiku, l.14) and `flaky-test-fixer` (sonnet, l.15) — both
present, good. But the web handlers' phase→tier table (l.17-21) does not name `handler-architect`,
which always runs opus (it is in the opus row l.12). A reader cross-checking handlers may be briefly
confused that one "handler-" is opus-pinned while the rest inherit.
**Proposed change:** add a one-line note that `handler-architect` is the exception (opus, not
`inherit`) — it already appears in the opus row, so this is a clarity nit.

### SUGGESTION — Report format self-review (SOLID covenant)
**File:** this report
**Finding:** The format holds its single responsibility (audit + surface) and segregates
CRITICAL/WARNING/SUGGESTION. One drift: the file:line citations would be more substitutable for a
human audit if each WARNING with a multi-site footprint (e.g. the §15.5 pointers) listed every site,
as done here — keep that pattern.
**Proposed change:** none required; retain the multi-site enumeration convention.

---

## Self-Improvement Triggers

- **Knowledge-parity enforcement (W-3 + C-1):** the dated-haiku drift propagated to 13 sites *because*
  `builder/SKILL.md` §15.5 duplicates `model-selection.md`. Collapsing §15.5 to a pointer would make
  C-1's class structurally impossible to recur — a covenant-grade fix worth scheduling next.
- **Glossary extension (W-2):** three merged PRs added user-facing terms without the
  `context-sentinel.md:307` glossary step. The covenant calls for the glossary to be reviewed against
  its stated purpose each time a term lands; add the missing entries.
- **Numbering-convention retirement (W-8):** the "FOUNDRY §N" pointers predate the
  `knowledge/policy/` + `knowledge/orchestration/` split. Repointing them at the canonical files
  removes a whole class of ambiguous cross-references.

## Files with No Issues (spot-verified clean)

- `.mcp.json` (foundry) and `.mcp.json` (sentinel) — correct, minimal, env-clean.
- `hooks/hooks.json` — correct matcher, `${CLAUDE_PLUGIN_ROOT}` path, script present & executable.
- `marketplace.json` — plugin `name`s match each `plugin.json`; author/homepage/repo/license/keywords
  present; `lspServers` well-formed (rust-analyzer / typescript-language-server / pyright).
- `skills/check/scripts/check.sh` — byte-identical across all three plugins (verified by md5).
- `skills/pr-review/scripts/gather-diff.sh` — robust (aborts loudly rather than emitting an empty
  packet; 2-dot→3-dot normalisation; gh-mandatory for PR numbers).
- `knowledge/protocols/merge-governance.md` + the full `AWAITING_MERGE` propagation chain
  (context-sentinel, orchestration-loop, definition-of-done, roadmapper, delivery, ds-step-9) —
  consistent and complete; the stacked-PR retargeting guard is rigorous.
- The six web handlers' `mcp__playwright__*` grants — exactly the six browser-facing handlers;
  `handler-fastapi` correctly excluded.
- FORGE de-drift — no cross-plugin filesystem coupling to sentinel/pressroom; companions referenced
  by capability throughout; surviving `~/.claude` references are provenance-allowlisted (except W-1).
