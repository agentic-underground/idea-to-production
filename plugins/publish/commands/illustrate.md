---
description: Illustrate documentation — find the highest-impact figure-sites and drive each from SPEC → two options → an A/B-until-best design review → an embedded dark-mode, transparent-background asset. One file, one section, the current doc, or a /loop-driven trawl of the whole doc tree (embedding + ledgering as it goes).
---

Follow the [`illustrator` skill](../skills/illustrator/SKILL.md). First run the dependency probe and tell the
user which handlers are live (it routes around absent ones — never blocks):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh
```

Then parse `$ARGUMENTS` into one of four modes:

| `$ARGUMENTS` | Mode | Behaviour |
|---|---|---|
| `docs` (or empty) | **trawl / loop** | Walk the doc tree from the entry points (`README.md`, `plugins/deliver/VALUE_FLOW.md`, `plugins/deliver/knowledge/glossary.md`, `first-principles.md`), rank sites tree-wide ([site-ranking](../skills/illustrator/references/site-ranking.md)), and drive each above-floor site through the full pipeline. Resumes from `.publish/illustration-ledger.json`; embeds the asset + edits the markdown + appends the ledger on each `BEST`. Best run under `/loop /illustrate docs` so it picks up where it left off. |
| `this` | **current context** | Illustrate the doc/file currently in context (the one just discussed or open). Single-shot per site; shows the asset, does not edit the doc unless asked. |
| `{filename}` (an existing path) | **one file** | Rank sites in that one file and illustrate each above the floor. |
| `{content area}` (free text, no such path) | **described section** | Locate the described section by grepping the tree, then illustrate that site. |

**Disambiguation:** if `$ARGUMENTS` resolves to an existing path → file mode; else if it is `docs`/`this`/empty
→ trawl/context; otherwise treat it as a content-area description.

For every site the skill: ranks it (Phase 1) → picks the value handler + type (Phase 2, **preferring vector +
deterministic over ComfyUI**) → authors the [SPEC](../skills/illustrator/references/spec-schema.md) (Phase 3)
→ has the handler render **two** options (Phase 4) → runs the
[A/B-until-best loop](../skills/illustrator/references/illustrate-ab-loop.md) with the `design-reviewer` in
comparative mode (Phase 5) → emits, and in trawl mode embeds + ledgers (Phase 6). Every figure is dark-mode,
transparent-ground, and legible on any host ([dark-mode canon](../skills/illustrator/references/dark-mode-canon.md)).

Report the trawl budget honestly (`N scanned · M above floor · K illustrated · …`) and, for each figure, the
A/B trajectory and the final fitness score. When a figure lands clean and the reviewer celebrates it as *the
best* — mark the green gate.
