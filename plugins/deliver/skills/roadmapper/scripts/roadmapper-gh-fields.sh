#!/usr/bin/env bash
# roadmapper-gh-fields.sh — enrich the GitHub Project (v2) board items that the vendored create/link tool
# (scripts/roadmap/gh-pipeline.sh — EPIC 0068 / A1) deliberately creates THIN. roadmapper calls this in
# github_board mode, AFTER `ensure-epic` / `ensure-plan-subissue`, to make the backlog browsable:
#   • replace the thin one-line issue body with the FULL EPIC/PLAN content (a clickable doc link + the
#     same rich content the local docs/roadmap/*.md carries), re-appending the idempotency marker;
#   • set the board's Estimate (story points) + Priority custom fields.
#
# It does NOT modify the tool — it SOURCES gh-pipeline.sh (which guards its CLI dispatch behind a
# BASH_SOURCE/$0 check) to REUSE its GraphQL wrapper, per-project field cache, and item resolution, then
# layers only the setters the create/link tool doesn't expose. (KAIZEN: reuse, don't rediscover.)
#
# Requires: PIPELINE_PROJECT=<registry-key> in the env (the repo's key in ~/.claude/pipeline-projects.json —
# NOT a GraphQL node-id; gh-pipeline.sh keys its field cache by it), `gh` logged in with project scope, and
# `jq`. Override the tool path with PIPELINE_GH_PROJECT=/path.
#
# Verbs:
#   set-body     <issue#> <body-file>                 # replace issue body w/ file, preserving the marker
#   set-plan     <issue#> <plan-file> [summary-file]  # compose `## Summary`+`---`+`## Plan` from files
#   set-stub     <issue#> <summary-text> [plan-text]  # compose a well-formed stub body from INLINE text
#   sync-plan    <order>  <plan-file> [summary-file]  # plan-mode→issue PIPE: resolve ORDER→issue, write Plan
#   set-estimate <issue#> <number>                    # board "Estimate" (NUMBER) field — story points
#   set-priority <issue#> <Urgent|High|Medium|Low>    # board "Priority" (single-select) field
set -uo pipefail

# --- locate + source the vendored create/link tool (reuse, never modify) ---------------------------
# EPIC 0068 / A2 cutover: prefer the in-repo VENDORED gh-pipeline.sh — the pipeline is now self-sufficient
# (no external FLEET engine). Resolution order: explicit PIPELINE_GH_PROJECT override → a plugin-local copy
# under ${CLAUDE_PLUGIN_ROOT} (a standalone-installed plugin) → this marketplace repo's scripts/roadmap →
# the legacy external FLEET tool (last-resort back-compat). NOTE: a standalone-installed deliver plugin does
# not yet SHIP gh-pipeline.sh inside itself — until it does, github_board mode is self-sufficient only where
# the repo tree (or an override) provides the tool. See scripts/roadmap/gh-pipeline.sh (the create/link layer).
_find_ghp() {
  [[ -n "${PIPELINE_GH_PROJECT:-}" && -f "${PIPELINE_GH_PROJECT}" ]] && { echo "$PIPELINE_GH_PROJECT"; return 0; }
  local here c; here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for c in \
    "${CLAUDE_PLUGIN_ROOT:-/nonexistent}"/skills/roadmapper/scripts/gh-pipeline.sh \
    "$here"/../../../../../scripts/roadmap/gh-pipeline.sh \
    "$HOME"/.local/share/fleet/*/pipeline/scripts/pipeline-gh-project.sh \
    "$HOME"/.claude/plugins/*/pipeline/scripts/pipeline-gh-project.sh \
    "$HOME"/.claude/plugins/*/*/pipeline/scripts/pipeline-gh-project.sh; do
    [[ -f "$c" ]] && { echo "$c"; return 0; }
  done
  return 1
}
GHP="$(_find_ghp)" || { echo "roadmapper-gh-fields: cannot find gh-pipeline.sh (set PIPELINE_GH_PROJECT)" >&2; exit 1; }
# shellcheck source=/dev/null
. "$GHP"                       # → ghp_graphql, _ghp_cache(_get), _ghp_items, _ghp_repo_slug, pcfg_resolve
pcfg_resolve >/dev/null 2>&1 || true   # populate CFG_REPO/CFG_REMOTE/CFG_PROJECT_OWNER from PIPELINE_PROJECT

# Fail LOUD (not silently at runtime) if a FLEET update drifted the private surface we source — turns a
# silent enrichment no-op into a clear, actionable error. (Reviewer: untested private-API coupling.)
_assert_fleet_api() {
  local fn missing=""
  for fn in ghp_graphql _ghp_cache _ghp_cache_get _ghp_items _ghp_repo_slug; do
    declare -F "$fn" >/dev/null 2>&1 || missing+=" $fn"
  done
  [[ -z "$missing" ]] || { echo "roadmapper-gh-fields: FLEET board tool drifted — missing expected function(s):$missing (update this helper to match $GHP)." >&2; exit 1; }
}
_assert_fleet_api

# Require the per-project field cache (built by `gh-pipeline.sh ensure-project`, §3.3-B step 1).
# Fails closed — a field SETTER must never create/mutate the project as a side effect (read-modify-write
# on an already-ensured board only).
_need_cache() {
  [[ -n "$(_ghp_cache_get '.project_id')" ]] && return 0
  echo "roadmapper-gh-fields: board not ensured for this project — run 'gh-pipeline.sh ensure-project' first (§3.3-B step 1)." >&2
  return 1
}

# board item node id for a given issue number (this repo's items, by board order)
_item_for_issue() { _ghp_items | awk -F'\t' -v n="$1" '$4==n{print $1; exit}'; }

# --- set-plan body composer (EPIC 0072 / PLAN 0072.001) -------------------------------------------
# The canonical EPIC/PLAN issue body is `## Summary` + `---` + `## Plan`, followed by the idempotency
# marker and the fan-out `Depends-on:`/`Touches:` annotations. `set-plan` re-composes it idempotently —
# replacing the Summary/Plan prose while preserving the marker + annotations BYTE-EXACT (dedup + the CS3
# fan-out both depend on that). The composer + extractors are PURE (string in, string out) → --self-test.

# _rgf_trim_blanks : strip leading + trailing blank lines from stdin (keeps interior blanks).
_rgf_trim_blanks() { sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba;}'; }
# _rgf_extract_marker <body> : echo the REAL pipeline marker (a NUMERIC order, `NNNN` or `NNNN.SSS`),
# taking the LAST (trailer) match. Requiring digits skips a PROSE example like `<!-- pipeline-plan-NNNN.SSS -->`
# that a Summary/Plan may quote when describing the format; trailer-most wins over any in-prose numeric example.
_rgf_extract_marker() { printf '%s' "$1" | grep -oE '<!-- pipeline-(epic|plan)-[0-9]{4}(\.[0-9]{3})? -->' | tail -1; }
# _rgf_extract_annotations <body> : echo the Depends-on:/Touches: lines from the TRAILER block only — the
# lines that FOLLOW the real marker — NOT a whole-body grep. A narrative "Touches:" line in the ## Plan
# prose must never be promoted into the trailer (that would corrupt it + poison the CS3 fan-out, and grow
# unbounded on every re-compose). No marker ⇒ no trailer ⇒ no annotations.
_rgf_extract_annotations() {
  local body="$1" marker; marker="$(_rgf_extract_marker "$body")"; [ -n "$marker" ] || return 0
  printf '%s\n' "$body" \
    | awk -v m="$marker" '{l[NR]=$0; if(index($0,m))last=NR} END{for(i=last+1;i<=NR;i++)print l[i]}' \
    | grep -iE '^[[:space:]]*(Depends-on|Touches):' || true
}
# _rgf_strip_trailing_rule : drop a trailing `---` separator line (+ trailing blanks) from stdin.
_rgf_strip_trailing_rule() {
  awk '{l[NR]=$0} END{e=NR; while(e>0 && l[e]~/^[[:space:]]*$/)e--; if(e>0 && l[e]~/^---[[:space:]]*$/)e--; for(i=1;i<=e;i++)print l[i]}'
}
# _rgf_extract_summary <body> : echo the prose under `## Summary`, bounded by the `## Plan` heading (NOT the
# first `---`/`## ` — a Summary may itself contain a rule or a sub-heading), minus the trailing `---` separator.
_rgf_extract_summary() {
  printf '%s\n' "$1" | awk '
    /^##[[:space:]]+Summary[[:space:]]*$/ {grab=1; next}
    grab && /^##[[:space:]]+Plan[[:space:]]*$/ {grab=0}
    grab {print}' | _rgf_strip_trailing_rule | _rgf_trim_blanks
}
# _rgf_plan_stub : the default `## Plan` body for a freshly-authored EPIC/PLAN whose real plan is not yet
# written (the doc-less / issue-primary path). Keeps the body well-formed (Summary + --- + Plan) so no new
# item ever lands as a thin one-liner; a later `set-plan` (from plan mode) re-composes over it, marker + any
# Depends-on:/Touches: trailer preserved byte-exact.
_rgf_plan_stub() {
  printf '%s' "_Plan to be authored in plan mode. This stub keeps the issue body well-formed (\`## Summary\` + \`## Plan\`) until the real plan lands via \`roadmapper-gh-fields.sh set-plan\`._"
}

# _rgf_compose <summary> <plan> <marker> <annotations> : the canonical body (marker/annotations optional).
_rgf_compose() {
  local out; out="## Summary"$'\n\n'"$1"$'\n\n'"---"$'\n\n'"## Plan"$'\n\n'"$2"
  [ -n "$3" ] && out="$out"$'\n\n'"$3"
  [ -n "$4" ] && out="$out"$'\n'"$4"
  printf '%s\n' "$out"
}

cmd_set_plan() {   # issue# plan-file [summary-file]
  local issue="${1:?issue#}" planfile="${2:?plan-file}" sumfile="${3:-}" slug cur summary plan marker anns body
  [[ -f "$planfile" ]] || { echo "roadmapper-gh-fields: plan file not found: $planfile" >&2; return 1; }
  slug="$(_ghp_repo_slug)"
  cur="$(gh issue view "$issue" --repo "$slug" --json body -q .body 2>/dev/null)"
  marker="$(_rgf_extract_marker "$cur")"; anns="$(_rgf_extract_annotations "$cur")"
  if [[ -n "$sumfile" ]]; then
    [[ -f "$sumfile" ]] || { echo "roadmapper-gh-fields: summary file not found: $sumfile" >&2; return 1; }
    summary="$(_rgf_trim_blanks < "$sumfile")"
  else
    summary="$(_rgf_extract_summary "$cur")"   # keep the existing Summary (reviewer edits only the Plan)
  fi
  plan="$(_rgf_trim_blanks < "$planfile")"
  body="$(_rgf_compose "$summary" "$plan" "$marker" "$anns")"
  printf '%s' "$body" | gh issue edit "$issue" --repo "$slug" --body-file - >/dev/null \
    && echo "issue #$issue plan synced${marker:+ (marker preserved)}${anns:+ (annotations preserved)}"
}

# _rgf_resolve_order <order> : classify + normalize a ROADMAP ORDER — echo "plan <NNNN.SSS>" or "epic <NNNN>",
# or empty + rc1 if malformed. The plan-mode pipe keys on the ORDER (never a GitHub issue#: the two-number-
# space hazard) so a `Depends-on:` token and a sync target speak the same space. A dotted order is a PLAN;
# a bare order is an EPIC. Normalization (zero-pad, reject 5-digit / trailing-dot) is the sourced validators'.
_rgf_resolve_order() {
  local o="${1:-}" n
  if [[ "$o" == *.* ]]; then
    n="$(_ghp_norm_plan_order "$o" 2>/dev/null)" && { printf 'plan %s' "$n"; return 0; }
  else
    n="$(_ghp_norm_order "$o" 2>/dev/null)" && { printf 'epic %s' "$n"; return 0; }
  fi
  return 1
}

# cmd_sync_plan <order> <plan-file> [summary-file] : the plan-mode→issue PIPE (PLAN 0072.003). Resolve a
# roadmap ORDER → its board issue (via the pipeline marker), then write the approved plan into `## Plan`
# through the composer (Summary/marker/annotations preserved). Same verb serves reviewer re-sync. GRACEFUL
# no-op when the board is unreachable or the order is absent — a plan-sync must never hard-fail the operator's
# post-approval step. A malformed order IS an error (return 2) — that's a usage mistake, not a degraded board.
cmd_sync_plan() {
  local order="${1:?order (NNNN or NNNN.SSS)}" planfile="${2:?plan-file}" sumfile="${3:-}" kind norm issue
  [[ -f "$planfile" ]] || { echo "roadmapper-gh-fields: plan file not found: $planfile" >&2; return 1; }
  local res; res="$(_rgf_resolve_order "$order")" \
    || { echo "roadmapper-gh-fields: '$order' is not a roadmap order (NNNN epic or NNNN.SSS plan) — pass the ORDER, never a GitHub issue#." >&2; return 2; }
  kind="${res%% *}"; norm="${res#* }"
  if [[ "$kind" == plan ]]; then issue="$(cmd_plan_issue "$norm" 2>/dev/null)"; else issue="$(cmd_epic_issue "$norm" 2>/dev/null)"; fi
  if [[ -z "$issue" ]]; then
    echo "roadmapper-gh-fields: $kind $norm not resolvable on the board (unreachable or absent) — plan-sync skipped (no-op)." >&2
    return 0
  fi
  cmd_set_plan "$issue" "$planfile" ${sumfile:+"$sumfile"}
}

# cmd_set_stub <issue#> <summary-text> [plan-text] : compose a WELL-FORMED body from inline text (no temp
# files) — `## Summary`(blurb) + `---` + `## Plan`(stub, or given text), preserving the existing marker +
# Depends-on:/Touches: trailer. The doc-less/issue-primary create path (§3.3-B): call it right after
# ensure-epic/ensure-plan-subissue so a fresh item is never a thin one-liner. Idempotent — a later set-plan
# replaces the Plan; re-running set-stub re-composes over the current marker/annotations.
cmd_set_stub() {   # issue# summary-text [plan-text]
  local issue="${1:?issue#}" summary="${2:?summary text}" plan="${3:-}" slug cur marker anns body
  slug="$(_ghp_repo_slug)"
  cur="$(gh issue view "$issue" --repo "$slug" --json body -q .body 2>/dev/null)"
  marker="$(_rgf_extract_marker "$cur")"; anns="$(_rgf_extract_annotations "$cur")"
  [ -n "$plan" ] || plan="$(_rgf_plan_stub)"
  summary="$(printf '%s' "$summary" | _rgf_trim_blanks)"
  body="$(_rgf_compose "$summary" "$plan" "$marker" "$anns")"
  printf '%s' "$body" | gh issue edit "$issue" --repo "$slug" --body-file - >/dev/null \
    && echo "issue #$issue stub composed${marker:+ (marker preserved)}${anns:+ (annotations preserved)}"
}

# --- other verbs ----------------------------------------------------------------------------------
cmd_set_body() {   # issue# body-file
  local issue="${1:?issue#}" file="${2:?body-file}" slug marker body
  [[ -f "$file" ]] || { echo "roadmapper-gh-fields: body file not found: $file" >&2; return 1; }
  slug="$(_ghp_repo_slug)"
  # preserve the EXACT cross-box idempotency marker from the current body (epic or plan), if present and
  # not already carried by the new body — losing it would make the next box create a duplicate issue. Uses
  # the shared numeric-order extractor (skips prose marker examples; trailer-most wins).
  marker="$(_rgf_extract_marker "$(gh issue view "$issue" --repo "$slug" --json body -q .body 2>/dev/null)")"
  body="$(cat "$file")"
  [[ -n "$marker" ]] && ! grep -qF "$marker" "$file" && body="$body"$'\n\n'"$marker"
  printf '%s' "$body" | gh issue edit "$issue" --repo "$slug" --body-file - >/dev/null \
    && echo "issue #$issue body updated${marker:+ (marker preserved)}"
}

cmd_set_estimate() {   # issue# number
  local issue="${1:?issue#}" num="${2:?number}" item pid fid
  _need_cache || return 1
  item="$(_item_for_issue "$issue")"; [[ -n "$item" ]] || { echo "roadmapper-gh-fields: no board item for issue #$issue" >&2; return 1; }
  pid="$(_ghp_cache_get '.project_id')"; fid="$(_ghp_cache_get '.fields.Estimate.id')"
  [[ -n "$fid" ]] || { echo "roadmapper-gh-fields: no Estimate field on board" >&2; return 1; }
  # -F coerces the numeric string to a GraphQL number (matching Float!) — exactly what we want here.
  # shellcheck disable=SC2016  # $p/$i/$f/$v are GraphQL variables (bound via -F), NOT shell expansions.
  ghp_graphql -f query='mutation($p:ID!,$i:ID!,$f:ID!,$v:Float!){updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{number:$v}}){projectV2Item{id}}}' \
    -F p="$pid" -F i="$item" -F f="$fid" -F v="$num" >/dev/null \
    && echo "issue #$issue Estimate=$num"
}

cmd_set_priority() {   # issue# Urgent|High|Medium|Low
  local issue="${1:?issue#}" opt="${2:?priority}" item pid fid oid
  _need_cache || return 1
  item="$(_item_for_issue "$issue")"; [[ -n "$item" ]] || { echo "roadmapper-gh-fields: no board item for issue #$issue" >&2; return 1; }
  pid="$(_ghp_cache_get '.project_id')"
  fid="$(_ghp_cache_get '.fields.Priority.id')"
  # bind $opt as DATA via jq --arg — never splice it into the jq program (CWE-917 jq-path injection).
  oid="$(jq -r --arg o "$opt" '.fields.Priority.options[$o] // empty' "$(_ghp_cache)" 2>/dev/null)"
  [[ -n "$fid" && -n "$oid" ]] || { echo "roadmapper-gh-fields: no Priority option '$opt' on board" >&2; return 1; }
  # parameterised mutation — operands bound via -f, NOT interpolated into the query string (CWE-89 class).
  # shellcheck disable=SC2016  # $p/$i/$f/$o are GraphQL variables (bound via -f), NOT shell expansions.
  ghp_graphql -f query='mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}' \
    -f p="$pid" -f i="$item" -f f="$fid" -f o="$oid" >/dev/null \
    && echo "issue #$issue Priority=$opt"
}

# --- self-test: PURE composer/extractor assertions incl. the idempotency round-trip (no gh/network) ---
cmd_self_test() {
  local fails=0
  eq() { if [ "$2" = "$1" ]; then echo "  ✓ $3"; else echo "  ✗ $3 (want [$1] got [$2])"; fails=$((fails+1)); fi; }
  has() { if printf '%s' "$2" | grep -qE "$3"; then echo "  ✓ $1"; else echo "  ✗ $1"; fails=$((fails+1)); fi; }
  echo "roadmapper-gh-fields.sh --self-test (set-plan + set-stub composer)"
  local M='<!-- pipeline-plan-0072.001 -->' A body1
  A="$(printf 'Depends-on: 0072.002, 0072.003\nTouches: scripts/x.sh, a.md')"
  body1="$(_rgf_compose 'Summary A.' 'Plan A body.' "$M" "$A")"
  has 'compose: ## Summary heading'    "$body1" '^## Summary$'
  has 'compose: --- rule'              "$body1" '^---$'
  has 'compose: ## Plan heading'       "$body1" '^## Plan$'
  has 'compose: marker byte-exact'     "$body1" '<!-- pipeline-plan-0072\.001 -->'
  has 'compose: Depends-on preserved'  "$body1" '^Depends-on: 0072\.002, 0072\.003$'
  has 'compose: Touches preserved'     "$body1" '^Touches: scripts/x\.sh, a\.md$'
  eq "$M"          "$(_rgf_extract_marker "$body1")"       'extract_marker round-trips'
  # marker extraction must SKIP a prose example (the bug the #338 dogfood caught) and take the real trailer:
  eq "$M" "$(_rgf_extract_marker "$(printf 'quotes <!-- pipeline-plan-NNNN.SSS --> in prose\n%s' "$body1")")" \
     'extract_marker skips a NNNN.SSS prose example → real numeric trailer'
  eq '<!-- pipeline-plan-0072.009 -->' \
     "$(_rgf_extract_marker "$(printf 'see <!-- pipeline-plan-0072.001 --> earlier\n<!-- pipeline-plan-0072.009 -->')")" \
     'extract_marker: trailer-most numeric marker wins over an in-prose numeric example'
  eq "$A"          "$(_rgf_extract_annotations "$body1")"  'extract_annotations round-trips (order preserved)'
  eq 'Summary A.'  "$(_rgf_extract_summary "$body1")"      'extract_summary round-trips'
  # IDEMPOTENCY — re-compose with a NEW plan from the extracted parts; Summary+marker+annotations survive.
  local m2 a2 s2 body2
  m2="$(_rgf_extract_marker "$body1")"; a2="$(_rgf_extract_annotations "$body1")"; s2="$(_rgf_extract_summary "$body1")"
  body2="$(_rgf_compose "$s2" 'Plan B (revised).' "$m2" "$a2")"
  has 'idempotent: Summary survives'     "$body2" '^Summary A\.$'
  has 'idempotent: new Plan applied'     "$body2" '^Plan B \(revised\)\.$'
  has 'idempotent: marker survives'      "$body2" '<!-- pipeline-plan-0072\.001 -->'
  has 'idempotent: annotations survive'  "$body2" '^Depends-on: 0072\.002, 0072\.003$'
  eq "$(_rgf_extract_marker "$body1")"      "$(_rgf_extract_marker "$body2")"      'idempotent: marker identical'
  eq "$(_rgf_extract_annotations "$body1")" "$(_rgf_extract_annotations "$body2")" 'idempotent: annotations identical'
  eq 'x' "$(printf '\n\nx\n\n' | _rgf_trim_blanks)" 'trim_blanks strips leading+trailing blanks'
  # Finding 1 (HIGH): a narrative "Touches:" line in the PLAN prose must NOT be promoted into the trailer,
  # and the trailer must be byte-identical across a SECOND re-compose (idempotent, no unbounded growth).
  local pbody a1 pbody2
  pbody="$(_rgf_compose 'Sum.' "$(printf 'Plan mentions Touches: the auth module and the board.\nmore.')" "$M" "$A")"
  a1="$(_rgf_extract_annotations "$pbody")"
  eq "$A" "$a1" 'annotations: narrative "Touches:" in plan prose NOT promoted (trailer-scoped)'
  pbody2="$(_rgf_compose "$(_rgf_extract_summary "$pbody")" 'new plan.' "$(_rgf_extract_marker "$pbody")" "$a1")"
  eq "$A" "$(_rgf_extract_annotations "$pbody2")" 'annotations: byte-identical after a SECOND re-compose'
  # Finding 2 (MEDIUM): a Summary with an internal `---` and a `## ` sub-heading survives the keep-Summary path.
  local S2 sbody
  S2="$(printf 'Intro.\n\n---\n\n## Detail\ntail.')"
  sbody="$(_rgf_compose "$S2" 'P.' "$M" "$A")"
  eq "$S2" "$(_rgf_extract_summary "$sbody")" 'summary: internal --- and ## sub-heading preserved'
  # compose WITHOUT marker/annotations (a fresh EPIC/PLAN) stays well-formed.
  has 'compose: bare body still well-formed' "$(_rgf_compose 'S' 'P' '' '')" '^## Plan$'
  # PLAN 0072.002 — the create-time STUB: a fresh body must be well-formed (Summary + --- + Plan(stub))
  # from an inline blurb, so no new EPIC/PLAN ever lands as a thin one-liner (the doc-less/issue-primary
  # path). The default Plan stub is non-empty; a later real plan re-composes over it, marker preserved.
  has 'stub: default plan stub non-empty' "$(_rgf_plan_stub)" '.'
  local stubbody; stubbody="$(_rgf_compose 'Fresh summary blurb.' "$(_rgf_plan_stub)" "$M" '')"
  has 'stub: ## Summary heading'      "$stubbody" '^## Summary$'
  has 'stub: --- rule'                "$stubbody" '^---$'
  has 'stub: ## Plan heading'         "$stubbody" '^## Plan$'
  has 'stub: marker preserved'        "$stubbody" '<!-- pipeline-plan-0072\.001 -->'
  eq 'Fresh summary blurb.' "$(_rgf_extract_summary "$stubbody")" 'stub: summary blurb round-trips'
  local realbody; realbody="$(_rgf_compose "$(_rgf_extract_summary "$stubbody")" 'Real plan.' "$(_rgf_extract_marker "$stubbody")" '')"
  has 'stub→real: marker survives'    "$realbody" '<!-- pipeline-plan-0072\.001 -->'
  has 'stub→real: plan text replaced' "$realbody" '^Real plan\.$'
  # PLAN 0072.003 — the plan-mode→issue pipe resolves by roadmap ORDER (NNNN.SSS plan / NNNN epic), NEVER a
  # GitHub issue# (the two-number-space hazard). _rgf_resolve_order classifies+normalizes the order so
  # `sync-plan` can map it to an issue via the marker; a malformed order fails (never silently mis-resolves).
  eq 'plan 0072.003' "$(_rgf_resolve_order 72.3)"     'resolve_order: NNNN.SSS → plan (zero-padded)'
  eq 'plan 0072.003' "$(_rgf_resolve_order 0072.003)" 'resolve_order: already-padded plan kept'
  eq 'epic 0073'     "$(_rgf_resolve_order 73)"       'resolve_order: bare NNNN → epic (zero-padded)'
  eq 'epic 0072'     "$(_rgf_resolve_order 0072)"     'resolve_order: already-padded epic kept'
  eq ''              "$(_rgf_resolve_order abc 2>/dev/null)"     'resolve_order: non-numeric → empty (reject)'
  eq ''              "$(_rgf_resolve_order 12345 2>/dev/null)"   'resolve_order: 5-digit epic → empty (reject)'
  eq ''              "$(_rgf_resolve_order 0072. 2>/dev/null)"   'resolve_order: trailing-dot plan → empty (reject)'
  if [ "$fails" -eq 0 ]; then echo "✓ composer self-test passed"; return 0
  else echo "✗ composer self-test: $fails failure(s)"; return 1; fi
}

case "${1:-}" in
  set-body)     shift; cmd_set_body "$@" ;;
  set-plan)     shift; cmd_set_plan "$@" ;;
  set-stub)     shift; cmd_set_stub "$@" ;;
  sync-plan)    shift; cmd_sync_plan "$@" ;;
  set-estimate) shift; cmd_set_estimate "$@" ;;
  set-priority) shift; cmd_set_priority "$@" ;;
  --self-test)  cmd_self_test ;;
  *) echo "usage: roadmapper-gh-fields.sh {set-body <issue#> <file> | set-plan <issue#> <plan-file> [summary-file] | set-stub <issue#> <summary-text> [plan-text] | sync-plan <order> <plan-file> [summary-file] | set-estimate <issue#> <n> | set-priority <issue#> <Urgent|High|Medium|Low> | --self-test}" >&2; exit 2 ;;
esac
