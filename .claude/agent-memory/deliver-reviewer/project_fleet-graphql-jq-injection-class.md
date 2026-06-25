---
name: fleet-graphql-jq-injection-class
description: FLEET/roadmapper board scripts splice values into jq programs (jq "$1") and GraphQL query strings instead of binding as data — latent injection class
metadata:
  type: project
---

The vendored FLEET board tool (`~/.local/share/fleet/*/pipeline/scripts/pipeline-gh-project.sh`)
and roadmapper's `plugins/deliver/skills/roadmapper/scripts/roadmapper-gh-fields.sh` build
queries by **string interpolation**, two recurring unsafe primitives:

1. `_ghp_cache_get() { jq -r "$1 // empty" ... }` — caller's path is spliced INTO the jq
   program. Callers like `set-priority` do `_ghp_cache_get ".fields.Priority.options[\"$opt\"]"`
   → `$opt` (user/agent value) rewrites the jq filter (jq-path injection, CWE-917). Saved only
   by `2>/dev/null` + a `[[ -n ]]` guard failing closed.
2. Several GraphQL mutations interpolate node ids directly: `query="mutation{...projectId:\"$pid\",...singleSelectOptionId:\"$oid\"...}"` (CWE-89-class). Safe today only because the
   operands are GitHub-issued opaque node ids (`PVT_*`/`PVTI_*`/`PVTSSF_*`, no quotes).

**Why not a per-PR BLOCK:** in PR #179 every injectable operand was either an opaque node id
or an agent-supplied fixed-menu value (Priority `Urgent|High|Medium|Low`) — no remote-attacker
(issue body / label) path reached them. So findings land MEDIUM (latent, not live).

**RESOLVED in #179 revision (e55d014):** `set-priority` now binds `$opt` via
`jq -r --arg o "$opt" '.fields.Priority.options[$o] // empty'` (data, not program) and uses a
single-quoted parameterised GraphQL mutation with `-f p/i/f/o` (no `\"` interpolation).
Replayed all prior payloads → empty/fail-closed. Bonus hardening same revision: `_need_cache`
dropped the side-effecting `ghp_ensure_project` call (a SETTER can no longer create a board =
least-privilege win); new `_assert_fleet_api` fails loud on vendored-API drift. **The
underlying vendored `_ghp_cache_get` ("jq $1") primitive + engine-side interpolated mutations
remain unsafe** — KAIZEN/gemba target upstream stands.

**The safe pattern already exists in the same file:** `cmd_set_estimate` uses parameterised
`-f query='mutation($p:ID!,...){...}' -F p=… -F i=…`. The fix for #1 is `jq -r --arg o "$opt"
'.fields.Priority.options[$o] // empty'`; for #2, mirror set-estimate's `-F` binding.

**How to apply:** when reviewing any roadmapper/FLEET board-mutation script, check whether a
value crosses into a jq program string or a GraphQL query literal vs. being bound via `--arg`/
`-F`. Flag inconsistency with the `set-estimate` safe sibling. This is a systemic class
([[fail-open-guard-class]] is a cousin) — push the upstream `_ghp_cache_get` fix via KAIZEN
rather than patching each call site. See also [[fleet-cd-migration-pr-chain]].
