---
name: board-mode-forbidden-mutation-default
description: Dropping forbidden_mutation from the FLEET registry silently falls CFG_FORBIDDEN_MUTATION back to the wrong FLEET default; latent in board mode for i2p
metadata:
  type: project
---

When a project's `~/.claude/pipeline-projects.json` entry omits `forbidden_mutation` (as i2p's
board-mode entry now does, PR #242), the engine's `pcfg_resolve` (pipeline-config.sh ~line 101) does
`[[ -n "$v" ]] && CFG_FORBIDDEN_MUTATION="$v"` — so the override is SKIPPED and the var keeps the
hardcoded FLEET default `docs/massive-uplift/.pipeline.md` from `_pcfg_defaults()`, NOT empty.

**Why:** `_f` returns empty for an absent key, and the loader only overrides on non-empty — a
silent-wrong-default class (not a crash).

**How to apply:** This is LATENT-not-broken for i2p in board mode. Trace before flagging:
- The calamity guard (builder.sh:434) greps changed files for `$CFG_FORBIDDEN_MUTATION`. With the
  FLEET default, it never matches an i2p file → guard never fires for the manifest. But the manifest
  is deleted (nothing to protect) AND `FORBIDDEN_EXTRA=epic_rel` still guards the EPIC `## Plans` doc,
  so the live half of the guard works.
- The `gw add "$CFG_FORBIDDEN_MUTATION"` land-commits (builder.sh:472 `_merge_and_complete`, builder.sh
  `_rollup_epic` direct-branch ~line 10-rel) are on the **direct** delivery path. i2p is `delivery:pr`
  + `admin_merge:true` → PR-branch rollup, which calls `manifest-set` → `cmd_manifest-set` → `_gh_board`
  writes board Status and returns BEFORE touching any file. So the bad default is never dereferenced.

So it does NOT regress i2p. It IS an upstream-engine smell (a board-mode entry should clear or ignore
`forbidden_mutation`); surface as KAIZEN to the external FLEET engine, not a per-PR gate.
See [[fleet-registry-field-semantics]].
