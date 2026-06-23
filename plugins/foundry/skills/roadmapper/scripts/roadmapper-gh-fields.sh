#!/usr/bin/env bash
# roadmapper-gh-fields.sh — enrich the GitHub Project (v2) board items that the vendored FLEET tool
# (pipeline-gh-project.sh) deliberately creates THIN. roadmapper calls this in github_board mode, AFTER
# `ensure-epic-item` / `ensure-plan-subitem`, to make the backlog browsable:
#   • replace the thin one-line issue body with the FULL EPIC/PLAN content (a clickable doc link + the
#     same rich content the local docs/roadmap/*.md carries), re-appending FLEET's idempotency marker;
#   • set the board's Estimate (story points) + Priority custom fields.
#
# It does NOT modify FLEET — it SOURCES pipeline-gh-project.sh (which guards its CLI dispatch behind a
# BASH_SOURCE/$0 check) to REUSE its GraphQL wrapper, per-project field cache, and item resolution, then
# layers only the setters FLEET doesn't expose. (KAIZEN: reuse, don't rediscover.)
#
# Requires: PIPELINE_PROJECT=<project-id> in the env (resolves repo/remote/owner via the registry),
# `gh` logged in with project scope, and `jq`. Override the engine path with PIPELINE_GH_PROJECT=/path.
#
# Verbs:
#   set-body     <issue#> <body-file>                 # replace issue body w/ file, preserving the marker
#   set-estimate <issue#> <number>                    # board "Estimate" (NUMBER) field — story points
#   set-priority <issue#> <Urgent|High|Medium|Low>    # board "Priority" (single-select) field
set -uo pipefail

# --- locate + source the vendored FLEET board tool (reuse, never modify) ---------------------------
_find_ghp() {
  [[ -n "${PIPELINE_GH_PROJECT:-}" && -f "${PIPELINE_GH_PROJECT}" ]] && { echo "$PIPELINE_GH_PROJECT"; return 0; }
  local c
  for c in \
    "$HOME"/.local/share/fleet/*/pipeline/scripts/pipeline-gh-project.sh \
    "$HOME"/.claude/plugins/*/pipeline/scripts/pipeline-gh-project.sh \
    "$HOME"/.claude/plugins/*/*/pipeline/scripts/pipeline-gh-project.sh; do
    [[ -f "$c" ]] && { echo "$c"; return 0; }
  done
  return 1
}
GHP="$(_find_ghp)" || { echo "roadmapper-gh-fields: cannot find pipeline-gh-project.sh (set PIPELINE_GH_PROJECT)" >&2; exit 1; }
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

# Require the per-project field cache (built by `pipeline-gh-project.sh ensure-project`, §3.3-B step 1).
# Fails closed — a field SETTER must never create/mutate the project as a side effect (read-modify-write
# on an already-ensured board only).
_need_cache() {
  [[ -n "$(_ghp_cache_get '.project_id')" ]] && return 0
  echo "roadmapper-gh-fields: board not ensured for this project — run 'pipeline-gh-project.sh ensure-project' first (§3.3-B step 1)." >&2
  return 1
}

# board item node id for a given issue number (this repo's items, by board order)
_item_for_issue() { _ghp_items | awk -F'\t' -v n="$1" '$4==n{print $1; exit}'; }

# --- verbs ----------------------------------------------------------------------------------------
cmd_set_body() {   # issue# body-file
  local issue="${1:?issue#}" file="${2:?body-file}" slug marker body
  [[ -f "$file" ]] || { echo "roadmapper-gh-fields: body file not found: $file" >&2; return 1; }
  slug="$(_ghp_repo_slug)"
  # preserve FLEET's EXACT cross-box idempotency marker from the current body (epic or plan), if present
  # and not already carried by the new body — losing it would make the next box create a duplicate issue.
  marker="$(gh issue view "$issue" --repo "$slug" --json body -q .body 2>/dev/null \
    | grep -oE '<!-- pipeline-(epic|plan)-[^>]*-->' | head -1)"
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

case "${1:-}" in
  set-body)     shift; cmd_set_body "$@" ;;
  set-estimate) shift; cmd_set_estimate "$@" ;;
  set-priority) shift; cmd_set_priority "$@" ;;
  *) echo "usage: roadmapper-gh-fields.sh {set-body <issue#> <file> | set-estimate <issue#> <n> | set-priority <issue#> <Urgent|High|Medium|Low>}" >&2; exit 2 ;;
esac
