---
name: gh-pipeline-vendored-layer
description: EPIC 0068 A1 keystone — gh-pipeline.sh vendored create/link layer; sourced-API parity contract with the roadmapper enricher + the latent cache-KEY risk for the A2 cutover
metadata:
  type: project
---

`scripts/roadmap/gh-pipeline.sh` (PLAN 0068.002 / PR #314) is the vendored GitHub Project-v2
create/link layer — the WRITE half whose READ half is `delete-epic.sh`. It replaces the external
FLEET `pipeline-gh-project.sh` as the sourced library for the board enricher
`plugins/deliver/skills/roadmapper/scripts/roadmapper-gh-fields.sh` (A2).

**Sourced-API contract A2 depends on** (its `_assert_fleet_api` at line 43 checks existence of):
`ghp_graphql _ghp_cache _ghp_cache_get _ghp_items _ghp_repo_slug` + `pcfg_resolve`. All present & parity-verified.
Cache shape written by `_ghp_build_cache`: `{project_id,project_number,fields:{<name>:{id,type,options:{<opt>:<id>}}}}` —
satisfies A2's `.fields.Estimate.id`, `.fields.Priority.options[$o]`, and `_ghp_items` col-4 = `.content.number`.

**LATENT cache-KEY risk for the A2 cutover (NOT a bug in #314 — A2 untouched there).**
Why: `_ghp_cache` keys the cache FILE by `${CFG_REG_ID:-${PIPELINE_PROJECT:-_default}}`. `ensure-project`
(CLI, usually no `PIPELINE_PROJECT`) writes the cache under the REGISTRY KEY (e.g. `idea-to-production.json`),
but A2's docstring says it needs `PIPELINE_PROJECT=<project-id>`. If the A2 cutover PLAN passes a GraphQL
node-id (PVT_...) as `PIPELINE_PROJECT` instead of the registry key, `_ghp_cache` resolves to a DIFFERENT
filename than `ensure-project` wrote → `_need_cache` fail-closes → enricher silently no-ops.
How to apply: when reviewing the A2 source-path cutover PR, confirm `PIPELINE_PROJECT` (or `CFG_REG_ID`) is
the REGISTRY KEY, not the node-id — and that ensure-project and the enricher agree on the cache filename.

**Registry merge is non-clobbering** (verified): `cmd_ensure_project`'s jq `(.projects[$k] // {}) + {…}`
preserves register-with-fleet's governance fields (delivery/admin_merge/merge_mode/epic_glob/manifest/
branch_prefix/merge_target/priority); repo/remote preserved via `//`; project_owner effectively preserved
because `pcfg_resolve` pre-loads `CFG_PROJECT_OWNER` from the existing entry.
