---
name: fleet-v2-roadmap-migration
description: Roadmap split-brain migration — live roadmap moved from legacy .i2p/roadmap/ tree to FLEET v2 docs/roadmap/ pipeline; multi-PR, read-path first
metadata:
  type: project
---

The roadmap source-of-truth is migrating from the legacy `.i2p/roadmap/{backlog,do,doing,done}/` flow tree (read by flow-mcp `render_roadmap`) to the **FLEET v2 pipeline** at `docs/roadmap/` (`.pipeline.md` manifest + `EPIC_NNNN.md` + `PLAN_NNNN.md`). The legacy tree is now LEGACY history.

**Why:** "what's on the roadmap" split-brained — v2 schema in docs/roadmap/ was the intended canonical surface but reads still resolved to the stale legacy tree, so live state was read by nothing in-session.

**How to apply:**
- This is a MULTI-PR migration. PR #145 (fix/roadmap-v2-routing) is the additive READ-path fix only: i2p SessionStart hook `roadmap-routing.sh`, neutralised flow onboard hook's render_roadmap rule, roadmapper SKILL.md §1+§5 v2-first. Full v2 EMISSION (roadmapper §3/§6/§11) is a LATER PR by design — do NOT flag §3.2/§11.1 still naming ROADMAP.md as this-PR regressions.
- The new routing rule points at a `pipeline` plugin (/pipeline:status, pipeline-cron.sh) that does NOT exist in this marketplace yet — it's the external FLEET CD engine. The rule is a graceful conditional ("when installed... else structural parse of docs/roadmap/"), and the else-branch reads real existing data, so the read answer WORKS today. Treat the pipeline-plugin reference as MEDIUM doc-accuracy (forward-reference), not a functional break.
- Known doc nit: routing rule + SKILL.md §5 say the EPIC `## Plans` table columns are "order | epic | state", but the actual table is `order | plan | state` (`epic` is the .pipeline.md manifest column). Minor.
- flow plugin's OWN command surfaces (/flow report, flow.md, flow/SKILL.md, README, flow-mcp/) still actively use render_roadmap over the legacy tree — that's the flow plugin's job and is being retired with it, not a stale global routing rule. See [[flow-plugin-standup]].

**Engine source verified (on this box at /home/user/.local/share/fleet/pipeline-marketplace/pipeline/scripts/builder.sh + pipeline-cron.sh):**
- Mode auto-select is `## Plans`-table-driven: cmd_next-plan returns `__flat__` (no table → v1 flat path) else v2 per-PLAN loop (builder.sh:627; pipeline-cron.sh:419-433).
- `_render_plan_build_prompt` (builder.sh:256-266) literally says `READ FIRST: ${BUILD_DOC_REL} (this plan's Construction process + Definition of done)` — confirms the PLAN's `## Construction process` IS the engine bridge. BUILD_DOC_REL = the plan doc.
- Forbidden-mutation guard: `_rules_block` forbids merge/push to merge-target + edit of CFG_FORBIDDEN_MUTATION (manifest); v2 adds FORBIDDEN_EXTRA=epic_rel so the agent touching `.pipeline.md` OR the EPIC doc (`## Plans` state) = CALAMITY (builder.sh:225,362-366,545). Engine owns push/land/state via _land_direct/_rollup_epic/manifest-set-plan.
- **PR-ORDERING GAP (PR #147 / PR-3):** the §3.3 PLAN "Construction process" template tells DELIVER to drive M0→M6, key DELIVERY_COMPLETE to branch HEAD, and NOT push / NOT mutate state. But DELIVER's CURRENT ds-step-9-commit-push.md DOES push the branch, open PR/merge, AND mutate STATUS: IN PROGRESS→COMPLETE/AWAITING MERGE (lines 71-130). That re-cast is PR-4 (not landed). So PR-3 docs describe behavior the code won't do until PR-4. Engine's forbidden guard catches manifest/epic-doc edits but NOT a stray `git push` of the plan branch — so a today-DELIVER run under these PLAN docs could push to origin out of band. Forward-spec, but the gap is real until PR-4 — flag as MEDIUM cross-PR ordering risk on emitted (non-meta) projects; safe on the meta-repo itself (no engine runs here yet).
