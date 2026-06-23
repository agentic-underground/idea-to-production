---
name: fleet-registry-field-semantics
description: FLEET engine registry field semantics (ground truth from engine source) — which keys the engine reads, and the v1-vs-v2 landing-decision split that makes merge_mode INERT for v2 EPICs
metadata:
  type: project
---

Ground truth read from the live engine on this box
(`~/.local/share/fleet/pipeline-marketplace/pipeline/scripts/pipeline-config.sh` `pcfg_resolve`
+ `builder.sh`). The registry is `~/.claude/pipeline-projects.json` (machine-local, uncommitted;
`scripts/register-with-fleet.sh` is the version-controlled recreate).

**Keys the engine actually reads** (pcfg_resolve `_f`): repo, manifest, epic_glob, verify, filter,
branch_prefix, merge_target, forbidden_mutation, sanitization_patterns, merge_mode, delivery,
admin_merge, priority, remote, qualify.protected_remote, qualify.human_authored_gate. Anything else
in the entry is ignored (no bespoke fields).

**epic_glob substitutes the literal `{order}` token** (`_epic_rel`: `${CFG_EPIC_GLOB/\{order\}/$1}`).
So `docs/roadmap/EPIC_{order}.md` → `EPIC_0003.md` — CORRECT for this repo's `EPIC_NNNN.md` naming.
The vendored standard's schema example `{order}_EPIC.md` is just the FLEET worked example, NOT a
required shape; don't flag the i2p ordering as wrong.

**THE LOAD-BEARING SPLIT (v1 vs v2 landing decision):**
- **v2 path** (EPIC has a `## Plans` table → `_build_epic_v2`/`_rollup_epic`, builder.sh ~460-590):
  landing is governed by `delivery` + `admin_merge` ONLY. `pr` + `admin_merge:true` ⇒
  `gh pr merge --admin` ⇒ completed; else mark `delivered` (PR open). **`merge_mode` is NEVER read
  in v2.**
- **v1 flat path** (no `## Plans` → falls through, builder.sh ~655-672): landing = `pcfg_merge_decision`
  which DOES read `merge_mode`/qualify/autonomy/provenance/remote.

**How to apply:** When reviewing governance↔registry mapping docs (PR #151 added a table to
`.foundry/governance.md`), the directional mapping is what matters and it's correct:
direct-merge ↔ admin_merge:true ⇒ engine admin-merges its own PR; pr-approval ↔ admin_merge:false ⇒
`delivered`/human-merges. But presenting `merge_mode: merge` as part of the v2 explanation is
imprecise — it's INERT for v2 EPICs (valid only for flat/v1 epics). Treat as LOW doc-precision, NOT
a correctness defect (the field is harmless + correct for the v1 path). The `delivered` terminal
state is pick-rule-skipped (pipeline-cron.sh:374) so it never re-loops.

The repo's `.pipeline/verify` is read by `_run_verify` as a LINE-BY-LINE command spec (not exec'd),
so it needs no +x bit / interpreter shebang — don't flag the non-executable gate file.
See [[fleet-cd-migration-pr-chain]] [[fleet-v2-roadmap-migration]].
