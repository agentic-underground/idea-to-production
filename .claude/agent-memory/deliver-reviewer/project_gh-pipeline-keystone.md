---
name: gh-pipeline-keystone
description: gh-pipeline.sh (PR #314, PLAN 0068.002 A1) — injection keystone CLEARED; residual = search-before-create fail-open + contains() marker spoofing
metadata:
  type: project
---

`scripts/roadmap/gh-pipeline.sh` — vendored GitHub Project v2 create/link layer, A1 keystone
of EPIC 0068. Reviewed adversarially as SECURITY-REVIEWER (PR #314).

**Injection keystone HOLDS — do not re-flag as still-vulnerable:**
- jq (CWE-917): every jq call binds via `--arg`/`--argjson`; `_ghp_cache_get` splits the path
  with `jq -R 'split(".")'` and looks it up via `getpath($p)` on an `--argjson`-bound array —
  argument never enters program text. self-test line 468/528 proves an injection path inert.
  Also `_ghp_cache_get`'s arg is only ever a hardcoded literal (`.project_id`/`.project_number`),
  never caller-controlled — doubly safe.
- GraphQL (CWE-89 class): `_ghp_issue_node`, `_ghp_is_subissue`, `_ghp_link_subissue`,
  `cmd_set_status`, `cmd_next_plan` all pass operands via `-f`/`-F` variables into a fixed query
  string. No interpolation. Clean.
- Shell: title via `--title "$title"` (single quoted arg), desc via `printf '%s'|--body-file -`
  stdin. No `eval`, no unquoted expansion, arithmetic `10#$raw` is grep-validated numeric first.

**Sourced-vs-exec:** `set -uo pipefail` applied ONLY when executed (line 48) — correct, doesn't
pollute the caller's shell; library fns check `rc=$?` explicitly so pipefail-off doesn't mask.

**Residual (raised MEDIUM at review):**
1. Search-before-create FAIL-OPEN (fail-open-guard-class): `_ghp_issue_by_marker` (L178-182)
   swallows `gh issue list` errors with `2>/dev/null` + caps at `--limit 800`; empty result is
   indistinguishable from "absent" → routes to CREATE. Triggers: (a) transient gh/rate-limit
   error, (b) repo grows past 800 issues so an old EPIC/PLAN marker falls outside the window.
   Consequence: DUPLICATE EPIC/PLAN issue — contradicts the PR's headline idempotent/
   crash-consistent claim. Fix: check the pipe exit status and fail-CLOSED (abort, don't create)
   on read error; paginate/raise the cap.
2. `contains($m)` substring marker match (L181) on an issue body that becomes attacker-influenceable
   once roadmapper converts EXTERNAL issue text (an explicit later 0068 slice). Latent spoofing:
   a forged marker in desc shadows/duplicates a real pipeline issue. Fix before external-text slice:
   anchor the match / cross-check title, and scrub markers from untrusted desc.

Verdict issued: NEEDS_REVISION (two MEDIUMs). Injection bar = PASS.

**Rev 2 — both MEDIUMs RESOLVED → PASS.** (1) `_ghp_issue_by_marker` now `gh api --paginate`
(no 800 ceiling) + `|| return 2` fail-CLOSED on read error; callers use the correct bash pattern
(`local n` declared separately, then `n="$(...)" || { abort; return 1 }` at :364/:387 so the
command-sub RC is NOT masked). Closes exploit A (repo>limit) and B (transient read→create).
(2) `_ghp_scrub_markers` (sed strips `<!--[[:space:]]*pipeline-(epic|plan)-[^>]*-->`) applied to
desc BEFORE body/title compose (:360/:383). Regex is robust vs the splice-reconstruction bypass:
the exact search marker contains no interior `>`, so its own `<!--` always initiates (or is
subsumed by) a match ending at its own `-->` → guaranteed removed. Injection posture preserved
(API path uses constrained owner/name slug; jq/GraphQL still bind-as-data). No new issues.
