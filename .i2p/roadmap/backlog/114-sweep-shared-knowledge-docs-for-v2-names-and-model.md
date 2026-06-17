---
id: 114
title: "Sweep shared knowledge docs for the v2 names + model"
status: PENDING
priority: MEDIUM
added: 2026-06-17
depends_on: "#94, #95, #96, #97, #98, #100"
---

# [114] Sweep shared knowledge docs for the v2 names + model

**Brief Description**
The renames (#94–#98) and the DELIVER lifecycle insertion (#100) each carry their own doc edits, but the
**shared, cross-referencing knowledge docs** — the ones that name many plugins and commands at once and
narrate the value flow — drift as a class and need a final, deliberate consistency pass. These are
`plugins/foundry/knowledge/glossary.md`, `plugins/foundry/VALUE_FLOW.md`, every per-plugin and the root
`README.md`, `plugins/i2p/knowledge/product-lifecycle.md`, `CLAUDE.md`, and `PREREQUISITES/`. This item
sweeps all of them so the function-first plugin names (**security**, **operate**, **publish**, **flow-mcp**;
**concierge folded into i2p**), the new **DELIVER** phase, and the **BUILD⇄ASSURE⇄SECURE loop** read
consistently everywhere — and verifies that **no stale `sentinel` / `mission-control` / `pressroom` /
`concierge` / `flow-server` reference survives** outside the provenance archives (`.i2p/roadmap/done/*`,
frozen `.foundry/*` specs, `cached-reviews/*`), which are historical and intentionally left as-was. This is
the **final consistency pass** of the epic; because the blast radius spans many files it MAY be split per-doc
(e.g. glossary, VALUE_FLOW, READMEs, lifecycle, CLAUDE.md, PREREQUISITES) if a single PR is too large to
review cleanly.

### User Stories
- AS a marketplace user reading the glossary or a README I WANT every plugin called by its v2 name
  (security/operate/publish/flow-mcp, i2p with no separate concierge) SO THAT the docs and the installed
  plugins agree and I am never sent to a plugin that no longer exists under that name.
- AS a user following the value flow I WANT DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE
  ▸ PUBLISH ▸ OPERATE↻ with the BUILD⇄ASSURE⇄SECURE loop shown SO THAT VALUE_FLOW.md and product-lifecycle.md
  describe the model the marketplace actually runs.
- AS an agent reading CLAUDE.md / PREREQUISITES I WANT no dangling old codename SO THAT I resolve paths and
  companions against names that exist.

### EARS Specification
**Ubiquitous**
- The shared knowledge docs (glossary.md, VALUE_FLOW.md, all README.md, product-lifecycle.md, CLAUDE.md,
  PREREQUISITES/) SHALL name plugins by their v2 names only — `security`, `operate`, `publish`, `flow-mcp`,
  and `i2p` (no standalone `concierge`) — and SHALL describe the DELIVER phase and the BUILD⇄ASSURE⇄SECURE
  loop consistently with the lifecycle state machine from #100.

**Event-driven**
- WHEN the sweep completes THE SYSTEM SHALL contain no occurrence of `sentinel`, `mission-control`,
  `pressroom`, `concierge`, or `flow-server` in any non-archive file (i.e. anywhere except
  `.i2p/roadmap/done/*`, frozen `.foundry/*` specs, and `cached-reviews/*`).

**Unwanted behaviour**
- IF a stale codename is found in a shipped knowledge doc after the sweep THEN the pass SHALL be treated as
  incomplete until it is corrected.
- IF a reference lives in a provenance archive (`.i2p/roadmap/done/*`, frozen `.foundry/*` spec,
  `cached-reviews/*`) THEN THE SYSTEM SHALL leave it untouched — historical records keep the names that were
  true when they were written; only live docs are reconciled.

### Acceptance Criteria
1. Given the swept docs, When glossary.md, VALUE_FLOW.md, the per-plugin + root READMEs, product-lifecycle.md,
   CLAUDE.md, and PREREQUISITES/ are read, Then every plugin is named security/operate/publish/flow-mcp/i2p,
   the DELIVER phase is present, and the BUILD⇄ASSURE⇄SECURE loop is described consistently.
2. Given a repo-wide search that **excludes** the provenance archives
   (`.i2p/roadmap/done/`, `.foundry/`, `cached-reviews/`), When grepping for `sentinel`, `mission-control`,
   `pressroom`, `concierge`, `flow-server`, Then there are zero matches.
3. Given the same search **without** the exclusions, When run, Then the only remaining matches are inside the
   provenance archives — confirming the sweep was scoped, not blanket.
4. Given the split-PR option, When the work lands as multiple per-doc PRs, Then each PR is internally
   consistent on its own and the final PR closes out criterion 2 across the whole tree.

### Implementation Notes
- This is the shared-doc half of Stream 6; the catalog rewrite is its sibling [113]. Keep them separate —
  this item never touches `docs/SLASH_COMMANDS.md` (that is [113]'s file).
- `depends_on` is #94 (sentinel→security), #95 (mission-control→operate), #96 (pressroom→publish),
  #97 (flow-server→flow-mcp), #98 (concierge retire/fold-into-i2p), and #100 (DELIVER lifecycle insertion) —
  each renames or reshapes the thing the shared docs reference. Run this once those have merged so the sweep
  has a stable target. Note: the foundry `/flow` surface (#105/#106) is the *catalog's* concern ([113]); this
  item's "flow" reach is naming `flow-server`→`flow-mcp` and placing DELIVER in the lifecycle narrative.
- Drive the verification from a single deny-list grep with the three archive paths excluded — that grep is
  literally AC#2's evidence; wire it into the PR description. The mirror grep without exclusions is AC#3.
- Mind the canonical-copy promise: some of these docs (notably `KAIZEN.md`-class assets and any byte-mirrored
  knowledge) are shipped byte-identical into every plugin. Edit the canonical source and re-sync all copies in
  the same PR so `scripts/verify-prereqs.sh` Checks N/O stay green; do not hand-edit one plugin's copy.
- Watch for compound/path forms, not just bare words: `plugins/sentinel/`, `/mission-control:`,
  `flow-server-v0.2.x` pins, `concierge:` skill prefixes, and prose like "the pressroom plugin" all count as
  stale and must be swept.
- If split per-doc, a sensible order is: glossary.md and VALUE_FLOW.md first (the canonical model), then the
  READMEs, then product-lifecycle.md, then CLAUDE.md, then PREREQUISITES/ — landing the deny-list-clean grep
  in the final PR.
- One concern per PR; the always-on `/foundry:pr-review` gates each. Touch only the shared knowledge docs.
