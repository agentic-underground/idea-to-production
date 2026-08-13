#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# gh-pipeline.sh — the VENDORED GitHub Project (v2) create/link layer for the idea-to-production
# pipeline. The write half of the relationship whose read half is scripts/roadmap/delete-epic.sh:
# delete-epic READS an EPIC's native sub-issues; this tool CREATES the EPIC/PLAN issues, adds them to
# the board, links each PLAN as a native sub-issue, and sets Status — self-sufficiently, with NO
# dependency on the external FLEET engine (`pipeline-gh-project.sh`), which is absent on most machines.
#
# TWO faces (dispatch guarded on BASH_SOURCE, like FLEET's own tool):
#   • SOURCEABLE LIBRARY — exposes the exact private surface roadmapper-gh-fields.sh sources
#     (ghp_graphql, _ghp_cache, _ghp_cache_get, _ghp_items, _ghp_repo_slug, pcfg_resolve), so the A2
#     cutover is a one-line source-path change and its _assert_fleet_api keeps passing.
#   • CLI — the create/link/read verbs below.
#
# Verbs:
#   ensure-project [title]                  find the owner's project by TITLE (never a hardcoded #4 —
#                                           project numbers are a per-owner sequence), create if absent,
#                                           persist number+node-id into the registry, cache field/option
#                                           ids. Bootstraps the registry + this repo's entry if absent.
#   ensure-epic <order> <desc>              create-or-find the EPIC issue (byte-exact marker), put it on
#                                           the board; echo its issue number. Converges from any state.
#   ensure-plan-subissue <epic#> <order> <desc>
#                                           create-or-find the PLAN issue, board it, AND link it as a
#                                           native sub-issue of <epic#>; echo its number. Crash-consistent:
#                                           marker-found ⇒ ALSO verify the sub-issue link, re-link if gone.
#   set-status <issue#> <Status>            set the board Status single-select for an issue.
#   epic-issue <order> | plan-issue <order> | next-plan <epic#>     read helpers.
#   preflight                               probe repo-scope vs project-scope SEPARATELY; on project-scope
#                                           failure print `gh auth refresh -s project` and exit 3 (the
#                                           caller degrades to local_file — never a hard error, never a
#                                           half-create).
#   --self-test                             hermetic checks of the pure helpers (no gh/network).
#
# SECURITY (this is the keystone; the vendored copy fixes the injection class the memory flags —
# .claude/agent-memory/deliver-reviewer/project_fleet-graphql-jq-injection-class.md):
#   • every value is bound as DATA via `-f`/`-F` (GraphQL) or `jq --arg` (jq) — NEVER spliced into a
#     query/program string. The unsafe `_ghp_cache_get(){ jq -r "$1" }` primitive is NOT vendored:
#     the path is split into literal segments and looked up with getpath($ARGS.positional).
#   • issue title/body come from the CLI caller (roadmapper), treated as content, passed via --body-file
#     stdin / --title — no shell eval.
#
# Requires: gh (authenticated; project scope for board mutations) + jq.  Env overrides (for --self-test
# and portability): PIPELINE_REGISTRY, PIPELINE_CACHE_DIR, PIPELINE_PROJECT (registry key),
# PIPELINE_PROJECT_TITLE, PIPELINE_CREATE_BACKOFF.
# ─────────────────────────────────────────────────────────────────────────────

# ── sourced vs executed ──────────────────────────────────────────────────────
if (return 0 2>/dev/null); then _GHP_SOURCED=1; else _GHP_SOURCED=0; set -uo pipefail; fi

# ── config / paths ───────────────────────────────────────────────────────────
: "${PIPELINE_REGISTRY:=$HOME/.claude/pipeline-projects.json}"
: "${PIPELINE_CACHE_DIR:=$HOME/.claude/pipeline-cache}"
: "${PIPELINE_CREATE_BACKOFF:=1}"   # seconds to pause after a create (GitHub secondary-rate-limit hygiene)

# Canonical Status options this pipeline expects on the board (Backlog→…→Delivered). ensure-project
# CACHES whatever options are present and WARNS on a missing one — it never DELETES/rewrites options
# (deleting a ProjectV2 single-select option WIPES every item's value; see the board-option-delete memory).
_GHP_STATUS_OPTIONS=(Backlog "To Do" "In Progress" Review Revise Done Delivered)

# CFG_* populated by pcfg_resolve (mirrors the FLEET surface roadmapper-gh-fields.sh:37 expects).
CFG_REG_ID=""; CFG_REPO=""; CFG_REMOTE=""; CFG_PROJECT_OWNER=""

# ── tiny ui (stderr; stdout stays machine-parseable for the verbs that echo a number) ────────────────
_ghp_red=$'\033[31m'; _ghp_grn=$'\033[32m'; _ghp_ylw=$'\033[33m'; _ghp_dim=$'\033[2m'; _ghp_rst=$'\033[0m'
[ -t 2 ] || { _ghp_red=""; _ghp_grn=""; _ghp_ylw=""; _ghp_dim=""; _ghp_rst=""; }
_ghp_info() { printf '%s\n' "$*" >&2; }
_ghp_ok()   { printf '  %b✓%b %s\n' "$_ghp_grn" "$_ghp_rst" "$*" >&2; }
_ghp_warn() { printf '  %b⚠ %s%b\n' "$_ghp_ylw" "$*" "$_ghp_rst" >&2; }
_ghp_err()  { printf '  %b✗ %s%b\n' "$_ghp_red" "$*" "$_ghp_rst" >&2; }

# ─────────────────────────────────────────────────────────────────────────────
# PURE HELPERS (no gh, no network) — covered by --self-test
# ─────────────────────────────────────────────────────────────────────────────

# _ghp_norm_order <raw> : normalise an EPIC order to 4 digits ("3"→"0003"). Rejects non 1–4-digit.
_ghp_norm_order() {
  local raw="${1:-}"
  printf '%s' "$raw" | grep -qE '^[0-9]{1,4}$' || return 1
  printf '%04d' "$((10#$raw))"
}

# _ghp_norm_plan_order <raw> : normalise a PLAN order "NNNN.SSS" (or "N.S"→zero-padded). Rejects other.
_ghp_norm_plan_order() {
  local raw="${1:-}" epic sub
  printf '%s' "$raw" | grep -qE '^[0-9]{1,4}\.[0-9]{1,3}$' || return 1
  epic="${raw%.*}"; sub="${raw#*.}"
  printf '%04d.%03d' "$((10#$epic))" "$((10#$sub))"
}

# Title + marker composition — the byte-exact conventions delete-epic.sh (title regex) and
# roadmapper-gh-fields.sh:70 (marker grep) read. Titles: "EPIC 0068: <desc>" / "PLAN 0068.001: <desc>".
_ghp_epic_title()  { printf 'EPIC %s: %s' "$1" "$2"; }
_ghp_plan_title()  { printf 'PLAN %s: %s' "$1" "$2"; }
_ghp_epic_marker() { printf '<!-- pipeline-epic-%s -->' "$1"; }
_ghp_plan_marker() { printf '<!-- pipeline-plan-%s -->' "$1"; }

# ─────────────────────────────────────────────────────────────────────────────
# SOURCED PRIVATE SURFACE — the exact functions roadmapper-gh-fields.sh:36,43 sources.
# ─────────────────────────────────────────────────────────────────────────────

# ghp_graphql <gh-api-graphql-args…> : the GraphQL wrapper, with a bounded retry on transient/secondary
# rate-limit errors. Operands MUST be passed by the caller via -f/-F (bound as data), never interpolated.
ghp_graphql() {
  local attempt=0 max=4 out rc
  while :; do
    out="$(gh api graphql "$@" 2>&1)"; rc=$?
    [ $rc -eq 0 ] && { printf '%s' "$out"; return 0; }
    # retry only on transient classes; fail fast on auth/permission/validation
    if printf '%s' "$out" | grep -qiE 'rate limit|secondary rate|timeout|502|503|was submitted too quickly'; then
      attempt=$((attempt+1)); [ $attempt -ge $max ] && { printf '%s' "$out" >&2; return $rc; }
      sleep "$((attempt*attempt))"; continue
    fi
    printf '%s' "$out" >&2; return $rc
  done
}

# _ghp_repo_slug : echo "owner/name" for the current repo (portable — delete-epic.sh:39-41).
_ghp_repo_slug() { gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null; }

# _ghp_cache : echo the path to THIS project's field-id cache file (id-keyed). Callers jq over it.
_ghp_cache() { printf '%s/%s.json' "$PIPELINE_CACHE_DIR" "${CFG_REG_ID:-${PIPELINE_PROJECT:-_default}}"; }

# _ghp_cache_get <dotted-path> : read a value from the cache as DATA. SAFE reimplementation — the path is
# split into literal segments and looked up with getpath($ARGS.positional); the argument is NEVER spliced
# into a jq program (this is the fix for the vendored `jq -r "$1"` injection primitive). Supports the
# simple dotted paths callers use (.project_id, .fields.Estimate.id); bracket/data lookups use jq --arg
# against "$(_ghp_cache)" directly (see cmd_set_status / the enricher's Priority lookup).
_ghp_cache_get() {
  local path="${1#.}" f seg_json; f="$(_ghp_cache)"
  [ -f "$f" ] || return 0
  # split the path into literal segments with jq itself (pure data), then look them up via getpath on a
  # DATA array bound with --argjson — the argument never enters the jq PROGRAM text (injection-safe).
  seg_json="$(printf '%s' "$path" | jq -R 'split(".")')" || return 0
  jq -r --argjson p "$seg_json" 'getpath($p) | if .==null then empty else . end' "$f" 2>/dev/null
}

# _ghp_items : TSV of THIS project's board items — <itemId>\t<contentType>\t<title>\t<issueNumber>.
# roadmapper-gh-fields.sh:60 keys on $1=itemId and $4=issueNumber; that column contract is load-bearing.
_ghp_items() {
  local num owner
  num="$(_ghp_cache_get '.project_number')"; owner="${CFG_PROJECT_OWNER:-$(_ghp_owner)}"
  [ -n "$num" ] && [ -n "$owner" ] || return 0
  gh project item-list "$num" --owner "$owner" --limit 800 --format json 2>/dev/null \
    | jq -r '.items[] | [.id, (.content.type // ""), (.content.title // ""), (.content.number // "")] | @tsv'
}

# pcfg_resolve : populate CFG_* from the registry entry for PIPELINE_PROJECT (or the entry whose .repo is
# the current repo). Degrades to gh-derived values so the tool still works before a registry exists.
pcfg_resolve() {
  local root slug
  root="$(git rev-parse --show-toplevel 2>/dev/null)"
  slug="$(_ghp_repo_slug)"
  CFG_REG_ID="${PIPELINE_PROJECT:-}"
  if [ -f "$PIPELINE_REGISTRY" ]; then
    # explicit key wins; else match by repo path.
    [ -z "$CFG_REG_ID" ] && CFG_REG_ID="$(jq -r --arg r "$root" '.projects | to_entries[] | select(.value.repo==$r) | .key' "$PIPELINE_REGISTRY" 2>/dev/null | head -1)"
    if [ -n "$CFG_REG_ID" ]; then
      CFG_REPO="$(jq -r --arg k "$CFG_REG_ID" '.projects[$k].repo // empty' "$PIPELINE_REGISTRY" 2>/dev/null)"
      CFG_REMOTE="$(jq -r --arg k "$CFG_REG_ID" '.projects[$k].remote // "origin"' "$PIPELINE_REGISTRY" 2>/dev/null)"
      CFG_PROJECT_OWNER="$(jq -r --arg k "$CFG_REG_ID" '.projects[$k].project_owner // empty' "$PIPELINE_REGISTRY" 2>/dev/null)"
    fi
  fi
  [ -n "$CFG_REG_ID" ] || CFG_REG_ID="${slug##*/}"
  [ -n "$CFG_REPO" ] || CFG_REPO="$root"
  [ -n "$CFG_REMOTE" ] || CFG_REMOTE="origin"
  [ -n "$CFG_PROJECT_OWNER" ] || CFG_PROJECT_OWNER="${slug%%/*}"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# INTERNAL gh helpers (network) — used by the verbs.
# ─────────────────────────────────────────────────────────────────────────────
_ghp_owner() { [ -n "$CFG_PROJECT_OWNER" ] && { printf '%s' "$CFG_PROJECT_OWNER"; return; }; local s; s="$(_ghp_repo_slug)"; printf '%s' "${s%%/*}"; }
_ghp_need() { command -v gh >/dev/null 2>&1 || { _ghp_err "gh CLI required"; return 2; }; command -v jq >/dev/null 2>&1 || { _ghp_err "jq required"; return 2; }; }

# _ghp_issue_by_marker <marker> : echo the issue number whose body carries an EXACT marker, else empty.
# Search-before-create: the marker is unique, so a hit means "already created" (idempotency).
# FAIL-CLOSED: returns non-zero if the READ itself failed (auth/rate-limit/network) so a caller NEVER
# mistakes a failed read for "absent" and creates a duplicate (the fail-open-guard class). PAGINATES all
# issues (gh api --paginate) so repo size never hides an older marker — an empty result with rc 0 means
# genuinely absent, rc≠0 means "could not determine — do not create".
_ghp_issue_by_marker() {
  local marker="$1" slug json; slug="$(_ghp_repo_slug)"
  [ -n "$slug" ] || return 2
  json="$(gh api --paginate "repos/$slug/issues?state=all&per_page=100" --jq '.[]|{number,body}' 2>/dev/null)" || return 2
  printf '%s' "$json" | jq -rs --arg m "$marker" 'map(select((.body // "") | contains($m)))[0].number // empty'
}

# _ghp_scrub_markers <text> : strip any pipeline-marker-like HTML comment from caller-supplied text, so a
# desc can NEVER carry (spoof) another item's idempotency marker into the body we create. Defence for when
# desc later carries converted EXTERNAL issue text (the B4 intake slice) — body is DATA, never a marker source.
_ghp_scrub_markers() { printf '%s' "$1" | sed -E 's/<!--[[:space:]]*pipeline-(epic|plan)-[^>]*-->//g'; }

# _ghp_issue_node <issue#> : echo the GraphQL node id for an issue (needed for addSubIssue).
_ghp_issue_node() {
  local n="$1" owner name slug; slug="$(_ghp_repo_slug)"; owner="${slug%%/*}"; name="${slug#*/}"
  ghp_graphql -f owner="$owner" -f name="$name" -F num="$n" -f query='
    query($owner:String!,$name:String!,$num:Int!){repository(owner:$owner,name:$name){issue(number:$num){id}}}' \
    2>/dev/null | jq -r '.data.repository.issue.id // empty'
}

# _ghp_is_subissue <epic#> <plan#> : succeed if <plan#> is already a native sub-issue of <epic#>.
_ghp_is_subissue() {
  local epic="$1" plan="$2" owner name slug; slug="$(_ghp_repo_slug)"; owner="${slug%%/*}"; name="${slug#*/}"
  ghp_graphql -f owner="$owner" -f name="$name" -F num="$epic" -f query='
    query($owner:String!,$name:String!,$num:Int!){repository(owner:$owner,name:$name){issue(number:$num){
      subIssues(first:100){nodes{number}}}}}' 2>/dev/null \
    | jq -e --argjson p "$plan" '.data.repository.issue.subIssues.nodes[]? | select(.number==$p)' >/dev/null 2>&1
}

# _ghp_link_subissue <epic#> <plan#> : link plan as a native sub-issue of epic (idempotent — no-op if
# already linked). Values bound via -f (node ids), NOT interpolated. The sub_issues GraphQL feature is
# GA (delete-epic reads subIssues without a header); the header is sent defensively and harmlessly.
_ghp_link_subissue() {
  local epic="$1" plan="$2" en pn
  _ghp_is_subissue "$epic" "$plan" && { _ghp_ok "#$plan already a sub-issue of #$epic"; return 0; }
  en="$(_ghp_issue_node "$epic")"; pn="$(_ghp_issue_node "$plan")"
  [ -n "$en" ] && [ -n "$pn" ] || { _ghp_err "could not resolve node ids for #$epic/#$plan"; return 1; }
  ghp_graphql -H 'GraphQL-Features: sub_issues' -F parent="$en" -F child="$pn" -f query='
    mutation($parent:ID!,$child:ID!){addSubIssue(input:{issueId:$parent,subIssueId:$child}){issue{number}}}' \
    >/dev/null 2>&1 && { _ghp_ok "linked #$plan as a sub-issue of #$epic"; return 0; }
  _ghp_err "failed to link #$plan under #$epic (project/sub-issue permission?)"; return 1
}

# _ghp_board_item_for <issue#> : echo the board item node id for an issue, else empty.
_ghp_board_item_for() { _ghp_items | awk -F'\t' -v n="$1" '$4==n{print $1; exit}'; }

# _ghp_board_add <issue#> : ensure the issue is on the board (idempotent) AND seed a valid initial Status
# on a FRESH add. Echoes the item id. A bare `gh project item-add` leaves Status **UNSET** (not Backlog) —
# so the create path must seed it, using the item id item-add returns (**no re-query** → dodges the stale
# item-list propagation race). Non-clobbering: only a just-added item is seeded; an item already on the
# board is returned untouched (never regress a progressed Status).
_ghp_board_add() {
  local n="$1" num owner slug url item seed
  item="$(_ghp_board_item_for "$n")"; [ -n "$item" ] && { printf '%s' "$item"; return 0; }
  num="$(_ghp_cache_get '.project_number')"; owner="$(_ghp_owner)"; slug="$(_ghp_repo_slug)"
  [ -n "$num" ] || { _ghp_err "project not ensured — run ensure-project first"; return 1; }
  url="https://github.com/$slug/issues/$n"
  item="$(gh project item-add "$num" --owner "$owner" --url "$url" --format json 2>/dev/null | jq -r '.id // empty')"
  if [ -n "$item" ]; then
    seed="${PIPELINE_SEED_STATUS:-Backlog}"
    _ghp_set_status_by_item "$item" "$seed" \
      || _ghp_warn "#$n added to board but Status could not be seeded to '$seed' (is '$seed' an option on the board?)"
  fi
  printf '%s' "$item"
}

# ─────────────────────────────────────────────────────────────────────────────
# PREFLIGHT — probe the two scopes SEPARATELY (repo vs Projects-v2).
# ─────────────────────────────────────────────────────────────────────────────
# exit/return: 0 = both OK · 2 = gh/jq/auth missing (hard) · 3 = repo OK but project scope absent
# (caller degrades to local_file — NEVER a half-create).
cmd_preflight() {
  _ghp_need || return 2
  gh auth status >/dev/null 2>&1 || { _ghp_err "gh not authenticated — run: gh auth login"; return 2; }
  local slug owner; slug="$(_ghp_repo_slug)"; owner="$(_ghp_owner)"
  [ -n "$slug" ] || { _ghp_err "could not resolve repo (gh auth?)"; return 2; }
  gh issue list --repo "$slug" --limit 1 >/dev/null 2>&1 || { _ghp_err "repo scope missing — cannot read issues on $slug"; return 2; }
  _ghp_ok "repo scope OK ($slug)"
  # Projects v2 needs `project` scope; probe with a read that requires it.
  if gh project list --owner "$owner" --limit 1 >/dev/null 2>&1; then
    _ghp_ok "project scope OK (owner: $owner)"
    return 0
  fi
  _ghp_warn "project scope MISSING — GitHub Projects v2 is unreachable with this token."
  _ghp_info  "    remediation: gh auth refresh -s project   (then re-run). Degrading to local_file mode."
  return 3
}

# ─────────────────────────────────────────────────────────────────────────────
# ensure-project — find-by-TITLE (never hardcoded #4), create if absent, cache field ids, bootstrap
# the registry. NEVER deletes/rewrites Status options (that wipes item values) — caches present, warns absent.
# ─────────────────────────────────────────────────────────────────────────────
cmd_ensure_project() {
  _ghp_need || return 2
  pcfg_resolve
  local owner title num pid slug root
  owner="$(_ghp_owner)"; slug="$(_ghp_repo_slug)"; root="$(git rev-parse --show-toplevel 2>/dev/null)"
  title="${1:-${PIPELINE_PROJECT_TITLE:-$CFG_REG_ID — pipeline}}"
  [ -n "$owner" ] || { _ghp_err "could not resolve project owner"; return 1; }

  # find-by-TITLE among the owner's projects (numbers are a per-owner sequence you cannot choose).
  local found
  found="$(gh project list --owner "$owner" --format json 2>/dev/null \
    | jq -r --arg t "$title" '.projects[] | select(.title==$t) | "\(.number)\t\(.id)"' | head -1)"
  if [ -n "$found" ]; then
    num="${found%%$'\t'*}"; pid="${found##*$'\t'}"
    _ghp_ok "found project '$title' (#$num) for $owner"
  else
    _ghp_info "creating project '$title' for $owner…"
    local created
    created="$(gh project create --owner "$owner" --title "$title" --format json 2>/dev/null)"
    num="$(printf '%s' "$created" | jq -r '.number // empty')"
    pid="$(printf '%s' "$created" | jq -r '.id // empty')"
    [ -n "$num" ] && [ -n "$pid" ] || { _ghp_err "project create failed (project scope? gh auth refresh -s project)"; return 3; }
    _ghp_ok "created project '$title' (#$num)"
  fi

  # persist number + node-id into the registry (bootstrap the file + entry if absent — the registry does
  # not exist on a fresh machine, exactly like register-with-fleet.sh seeds it).
  mkdir -p "$(dirname "$PIPELINE_REGISTRY")" "$PIPELINE_CACHE_DIR"
  [ -f "$PIPELINE_REGISTRY" ] || printf '%s\n' '{"version":1,"projects":{}}' > "$PIPELINE_REGISTRY"
  local tmp; tmp="$(mktemp)"
  jq --arg k "$CFG_REG_ID" --arg repo "$root" --arg owner "$owner" --arg title "$title" \
     --argjson num "$num" --arg pid "$pid" '
     .projects[$k] = ((.projects[$k] // {}) + {
       repo: (.projects[$k].repo // $repo), remote: (.projects[$k].remote // "origin"),
       board: "github_project", project_owner: $owner, project_title: $title,
       project_number: $num, project_id: $pid })' "$PIPELINE_REGISTRY" > "$tmp" && mv "$tmp" "$PIPELINE_REGISTRY"

  # cache EVERY field id + single-select option map (Status, Estimate, Priority, Pipeline Order, …).
  _ghp_build_cache "$owner" "$num" "$pid" || return 1

  # ensure Status EXISTS + warn on any missing canonical option (never delete/rewrite — destructive).
  _ghp_ensure_status_field "$owner" "$num" "$pid"
  # ensure a "Pipeline Order" NUMBER field exists (safe, non-destructive create-if-absent).
  _ghp_ensure_number_field "$owner" "$num" "Pipeline Order"
  # rebuild cache so newly-created fields are captured.
  _ghp_build_cache "$owner" "$num" "$pid" || return 1
  _ghp_ok "project ensured; field cache → $(_ghp_cache)"
  printf '%s\n' "$num"
}

# _ghp_build_cache <owner> <num> <pid> : write {project_id,project_number,fields:{<name>:{id,type,options:{<opt>:<id>}}}}
_ghp_build_cache() {
  local owner="$1" num="$2" pid="$3" fields tmp
  fields="$(gh project field-list "$num" --owner "$owner" --limit 100 --format json 2>/dev/null)" || return 1
  tmp="$(mktemp)"
  printf '%s' "$fields" | jq --arg pid "$pid" --argjson num "$num" '{
    project_id: $pid, project_number: $num,
    fields: (reduce .fields[] as $f ({}; .[$f.name] = {
      id: $f.id, type: $f.type,
      options: (($f.options // []) | map({(.name): .id}) | add // {}) }))
  }' > "$tmp" && mv "$tmp" "$(_ghp_cache)"
}

# _ghp_ensure_status_field : Status must exist; warn (don't mutate) on any missing canonical option.
_ghp_ensure_status_field() {
  local owner="$1" num="$2" pid="$3" cache opt
  cache="$(_ghp_cache)"
  if [ -z "$(jq -r '.fields.Status.id // empty' "$cache" 2>/dev/null)" ]; then
    _ghp_info "creating single-select 'Status' field…"
    local args=(); for opt in "${_GHP_STATUS_OPTIONS[@]}"; do args+=(--single-select-option "$opt"); done
    gh project field-create "$num" --owner "$owner" --name Status --data-type SINGLE_SELECT "${args[@]}" >/dev/null 2>&1 \
      && _ghp_ok "created Status field" || _ghp_warn "could not create Status field"
    return 0
  fi
  for opt in "${_GHP_STATUS_OPTIONS[@]}"; do
    [ -n "$(jq -r --arg o "$opt" '.fields.Status.options[$o] // empty' "$cache" 2>/dev/null)" ] \
      || _ghp_warn "Status option '$opt' absent (add via the GitHub UI — programmatic option-delete wipes item values)"
  done
}

# _ghp_ensure_number_field <owner> <num> <name> : create a NUMBER field if absent (non-destructive).
_ghp_ensure_number_field() {
  local owner="$1" num="$2" name="$3" cache; cache="$(_ghp_cache)"
  [ -n "$(jq -r --arg n "$name" '.fields[$n].id // empty' "$cache" 2>/dev/null)" ] && return 0
  gh project field-create "$num" --owner "$owner" --name "$name" --data-type NUMBER >/dev/null 2>&1 \
    && _ghp_ok "created '$name' number field" || _ghp_warn "could not create '$name' field"
}

# ─────────────────────────────────────────────────────────────────────────────
# ensure-epic / ensure-plan-subissue — create-or-converge, crash-consistent.
# ─────────────────────────────────────────────────────────────────────────────
cmd_ensure_epic() {
  _ghp_need || return 2
  pcfg_resolve
  local order desc marker title slug n kind
  order="$(_ghp_norm_order "${1:-}")" || { _ghp_err "epic order must be 1–4 digits (got '${1:-}')"; return 2; }
  desc="$(_ghp_scrub_markers "${2:?desc required}")"; slug="$(_ghp_repo_slug)"; kind="${3:-feature}"
  marker="$(_ghp_epic_marker "$order")"; title="$(_ghp_epic_title "$order" "$desc")"

  # FAIL-CLOSED: a failed read must abort, never fall through to create (would duplicate).
  n="$(_ghp_issue_by_marker "$marker")" || { _ghp_err "could not read issues to check for EPIC $order — aborting (not creating, to avoid a duplicate)"; return 1; }
  if [ -n "$n" ]; then
    _ghp_ok "EPIC $order already exists (#$n) — converging"
  else
    n="$(printf '%s\n\n%s' "$desc" "$marker" | gh issue create --repo "$slug" --title "$title" --body-file - 2>/dev/null | grep -oE '[0-9]+$' | tail -1)"
    [ -n "$n" ] || { _ghp_err "failed to create EPIC $order"; return 1; }
    _ghp_ok "created EPIC $order (#$n)"; sleep "$PIPELINE_CREATE_BACKOFF"
  fi
  # converge board membership (crash between create and board-add heals here).
  [ -n "$(_ghp_board_add "$n")" ] && _ghp_ok "EPIC $order on board" || _ghp_warn "EPIC $order not added to board (project scope?)"
  cmd_set_kind "$n" "$kind" || _ghp_warn "EPIC $order kind '$kind' not applied"
  printf '%s\n' "$n"
}

cmd_ensure_plan_subissue() {
  _ghp_need || return 2
  pcfg_resolve
  local epic order desc marker title slug n kind
  epic="${1:?epic# required}"; printf '%s' "$epic" | grep -qE '^[0-9]+$' || { _ghp_err "epic# must be a GitHub issue number (got '$epic')"; return 2; }
  order="$(_ghp_norm_plan_order "${2:-}")" || { _ghp_err "plan order must be NNNN.SSS (got '${2:-}')"; return 2; }
  desc="$(_ghp_scrub_markers "${3:?desc required}")"; slug="$(_ghp_repo_slug)"; kind="${4:-feature}"
  marker="$(_ghp_plan_marker "$order")"; title="$(_ghp_plan_title "$order" "$desc")"

  # FAIL-CLOSED: a failed read must abort, never fall through to create (would duplicate).
  n="$(_ghp_issue_by_marker "$marker")" || { _ghp_err "could not read issues to check for PLAN $order — aborting (not creating, to avoid a duplicate)"; return 1; }
  if [ -n "$n" ]; then
    _ghp_ok "PLAN $order already exists (#$n) — converging"
  else
    n="$(printf '%s\n\n%s' "$desc" "$marker" | gh issue create --repo "$slug" --title "$title" --body-file - 2>/dev/null | grep -oE '[0-9]+$' | tail -1)"
    [ -n "$n" ] || { _ghp_err "failed to create PLAN $order"; return 1; }
    _ghp_ok "created PLAN $order (#$n)"; sleep "$PIPELINE_CREATE_BACKOFF"
  fi
  # CRASH-CONSISTENCY: whether just-created OR pre-existing, ALWAYS verify + heal the sub-issue link and
  # board membership (a crash after issue-create but before link leaves a marker-carrying orphan).
  _ghp_link_subissue "$epic" "$n" || _ghp_warn "sub-issue link not confirmed for #$n"
  [ -n "$(_ghp_board_add "$n")" ] && _ghp_ok "PLAN $order on board" || _ghp_warn "PLAN $order not added to board (project scope?)"
  cmd_set_kind "$n" "$kind" || _ghp_warn "PLAN $order kind '$kind' not applied"
  printf '%s\n' "$n"
}

# ─────────────────────────────────────────────────────────────────────────────
# set-status — board Status single-select for an issue. Values bound via jq --arg / -f (no interpolation).
# ─────────────────────────────────────────────────────────────────────────────
# _ghp_status_oid <cache-file> <status> : echo the single-select option id for a Status NAME, else empty.
# Pure (cache in, id out) — the NAME is bound as DATA (--arg), so --self-test drives it with a fixture.
_ghp_status_oid() { jq -r --arg s "$2" '.fields.Status.options[$s] // empty' "$1" 2>/dev/null; }

# _ghp_status_oid_fresh <status> : resolve a Status option id, REFRESHING the field cache once on a miss.
# The cache is built by ensure-project and not otherwise refreshed, so a board option ADDED later (e.g. a
# new `Review`) is invisible to a stale cache → a false "no Status option". On a cache HIT this returns
# immediately (no gh); only a miss rebuilds from the live board and retries. Empty iff genuinely absent.
_ghp_status_oid_fresh() {
  local status="$1" cache oid num pid owner
  cache="$(_ghp_cache)"
  oid="$(_ghp_status_oid "$cache" "$status")"; [ -n "$oid" ] && { printf '%s' "$oid"; return 0; }
  num="$(_ghp_cache_get '.project_number')"; pid="$(_ghp_cache_get '.project_id')"; owner="$(_ghp_owner)"
  [ -n "$num" ] && [ -n "$pid" ] && [ -n "$owner" ] || return 0
  _ghp_build_cache "$owner" "$num" "$pid" >/dev/null 2>&1 || return 0
  _ghp_status_oid "$cache" "$status"
}

# ── issue KIND (native Type + label) + terminal-status → issue-STATE (Closed) ────────────────────────
# The code owns the FULL issue lifecycle: create+type+label, move Status, and CLOSE on a terminal status
# (a Done item is a Closed issue, consistent with the rest of the board). Mappings are PURE → --self-test.
# _ghp_kind_type <kind> : native GitHub issue Type for a kind (bug|feature|enhancement|task), else empty.
_ghp_kind_type() { case "$1" in bug) echo Bug;; feature) echo Feature;; enhancement) echo Feature;; task) echo Task;; *) echo "";; esac; }
# _ghp_kind_label <kind> : repo label for a kind (empty when the kind needs no label, e.g. feature).
_ghp_kind_label() { case "$1" in bug) echo bug;; enhancement) echo enhancement;; *) echo "";; esac; }
# _ghp_status_closes <status> : true (0) for the TERMINAL statuses whose issue must be Closed.
_ghp_status_closes() { case "$1" in Done|Delivered) return 0;; *) return 1;; esac; }

# cmd_set_kind <issue#> <kind> : set the issue's native Type + add its label (additive; never removes).
# Idempotent — kind is intrinsic (a bug is always a bug), so re-applying converges. Repo-scoped (not board).
cmd_set_kind() {
  local issue="${1:?issue# required}" kind="${2:?kind required}" slug type label
  slug="$(_ghp_repo_slug)"; type="$(_ghp_kind_type "$kind")"
  [ -n "$type" ] || { _ghp_err "unknown kind '$kind' (bug|feature|enhancement|task)"; return 1; }
  gh issue edit "$issue" --repo "$slug" --type "$type" >/dev/null 2>&1 \
    && _ghp_ok "#$issue Type=$type" || _ghp_warn "#$issue Type=$type not set (org issue-types enabled?)"
  label="$(_ghp_kind_label "$kind")"
  [ -n "$label" ] && { gh issue edit "$issue" --repo "$slug" --add-label "$label" >/dev/null 2>&1 \
    && _ghp_ok "#$issue +label:$label" || _ghp_warn "#$issue label '$label' not added (label on repo?)"; }
  return 0
}

# _ghp_set_status_by_item <item-id> <status> : set Status on a KNOWN board-item id (NO re-query, so it is
# safe right after item-add — dodging the stale item-list race). Returns non-zero if the ids/option are
# unresolvable or the mutation fails. Shared by cmd_set_status and the create-path seed in _ghp_board_add.
_ghp_set_status_by_item() {
  local item="$1" status="$2" cache pid fid oid
  cache="$(_ghp_cache)"; [ -f "$cache" ] || return 1
  pid="$(_ghp_cache_get '.project_id')"; fid="$(jq -r '.fields.Status.id // empty' "$cache")"
  oid="$(_ghp_status_oid_fresh "$status")"
  [ -n "$pid" ] && [ -n "$fid" ] && [ -n "$oid" ] || return 1
  # shellcheck disable=SC2016  # $p/$i/$f/$o are GraphQL variables (bound via -f), NOT shell expansions.
  ghp_graphql -f query='mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}' \
    -f p="$pid" -f i="$item" -f f="$fid" -f o="$oid" >/dev/null 2>&1
}

cmd_set_status() {
  _ghp_need || return 2
  pcfg_resolve
  local issue="${1:?issue# required}" status="${2:?Status required}" cache item
  cache="$(_ghp_cache)"; [ -f "$cache" ] || { _ghp_err "project not ensured — run ensure-project first"; return 1; }
  item="$(_ghp_board_item_for "$issue")"; [ -n "$item" ] || { _ghp_err "no board item for issue #$issue"; return 1; }
  [ -n "$(_ghp_status_oid_fresh "$status")" ] || { _ghp_err "no Status option '$status' on board (even after a cache refresh)"; return 1; }
  _ghp_set_status_by_item "$item" "$status" || { _ghp_err "failed to set Status for #$issue"; return 1; }
  _ghp_ok "#$issue Status=$status"
  # Keep the GitHub issue STATE in lockstep with the board Status: a TERMINAL status closes the issue
  # (Done items are Closed — the convention the rest of the board follows); moving back OUT of a terminal
  # status reopens it. The state read only runs on the non-terminal branch (no cost on close).
  local slug; slug="$(_ghp_repo_slug)"
  if _ghp_status_closes "$status"; then
    gh issue close "$issue" --repo "$slug" >/dev/null 2>&1 && _ghp_ok "#$issue closed (Status=$status)" \
      || _ghp_warn "#$issue Status=$status but issue NOT closed — a Done item must be Closed; retry set-status"
  elif [ "$(gh issue view "$issue" --repo "$slug" --json state -q .state 2>/dev/null)" = CLOSED ]; then
    gh issue reopen "$issue" --repo "$slug" >/dev/null 2>&1 && _ghp_ok "#$issue reopened (Status=$status)" \
      || _ghp_warn "#$issue moved out of Done but NOT reopened"
  fi
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# read helpers
# ─────────────────────────────────────────────────────────────────────────────
cmd_epic_issue() { local o; o="$(_ghp_norm_order "${1:-}")" || return 2; _ghp_issue_by_marker "$(_ghp_epic_marker "$o")"; }
cmd_plan_issue() { local o; o="$(_ghp_norm_plan_order "${1:-}")" || return 2; _ghp_issue_by_marker "$(_ghp_plan_marker "$o")"; }

# next-plan <epic#> : echo the next free PLAN order under an EPIC (highest sub-issue PLAN order + 1).
cmd_next_plan() {
  _ghp_need || return 2
  local epic="${1:?epic# required}" owner name slug epic_order hi
  slug="$(_ghp_repo_slug)"; owner="${slug%%/*}"; name="${slug#*/}"
  epic_order="$(gh issue view "$epic" --repo "$slug" --json title -q .title 2>/dev/null | grep -oE '[0-9]{4}' | head -1)"
  [ -n "$epic_order" ] || { _ghp_err "could not resolve EPIC order for #$epic"; return 1; }
  hi="$(ghp_graphql -f owner="$owner" -f name="$name" -F num="$epic" -f query='
    query($owner:String!,$name:String!,$num:Int!){repository(owner:$owner,name:$name){issue(number:$num){
      subIssues(first:100){nodes{title}}}}}' 2>/dev/null \
    | jq -r '.data.repository.issue.subIssues.nodes[]?.title' \
    | grep -oE 'PLAN [0-9]{4}\.[0-9]{3}' | grep -oE '[0-9]{3}$' | sort -n | tail -1)"
  printf '%s.%03d\n' "$epic_order" "$(( 10#${hi:-000} + 1 ))"
}

# ─────────────────────────────────────────────────────────────────────────────
# --self-test — hermetic; pure helpers only (no gh, no network).
# ─────────────────────────────────────────────────────────────────────────────
cmd_self_test() {
  local fails=0
  _t() { if [ "$2" = "$3" ]; then _ghp_ok "$1"; else _ghp_err "$1 — expected [$3] got [$2]"; fails=$((fails+1)); fi; }
  _tfail() { if "$@" >/dev/null 2>&1; then _ghp_err "expected failure: $*"; fails=$((fails+1)); else _ghp_ok "rejects: $*"; fi; }

  _ghp_info "gh-pipeline.sh --self-test (pure helpers)"
  # order normalisation
  _t "norm 3 → 0003"        "$(_ghp_norm_order 3)"      "0003"
  _t "norm 0068 → 0068"     "$(_ghp_norm_order 0068)"   "0068"
  _t "norm 18 → 0018"       "$(_ghp_norm_order 18)"     "0018"
  _tfail _ghp_norm_order 3.1
  _tfail _ghp_norm_order abc
  _tfail _ghp_norm_order 12345
  # plan order normalisation
  _t "plan 68.1 → 0068.001" "$(_ghp_norm_plan_order 68.1)"    "0068.001"
  _t "plan 0068.002 keep"   "$(_ghp_norm_plan_order 0068.002)" "0068.002"
  _tfail _ghp_norm_plan_order 0068
  _tfail _ghp_norm_plan_order 0068.
  # title + marker composition (byte-exact contracts)
  _t "epic title"  "$(_ghp_epic_title 0068 'GitHub integration')" "EPIC 0068: GitHub integration"
  _t "plan title"  "$(_ghp_plan_title 0068.002 'A1')"             "PLAN 0068.002: A1"
  _t "epic marker" "$(_ghp_epic_marker 0068)"                     "<!-- pipeline-epic-0068 -->"
  _t "plan marker" "$(_ghp_plan_marker 0068.001)"                 "<!-- pipeline-plan-0068.001 -->"
  # marker matches the roadmapper-gh-fields.sh:70 grep contract
  _t "marker grep-compatible" \
     "$(printf '%s' "$(_ghp_plan_marker 0068.001)" | grep -oE '<!-- pipeline-(epic|plan)-[^>]*-->')" \
     "<!-- pipeline-plan-0068.001 -->"
  # desc marker-scrub: a caller desc can never carry (spoof) another item's idempotency marker
  _t "scrub strips a spoofed marker" \
     "$(_ghp_scrub_markers 'legit text <!-- pipeline-epic-0001 --> more')" "legit text  more"
  _t "scrub leaves clean text intact" \
     "$(_ghp_scrub_markers 'a normal description with no markers')" "a normal description with no markers"
  # SAFE _ghp_cache_get: dotted-path lookup as DATA, no jq-program injection
  local d; d="$(mktemp -d)"; PIPELINE_CACHE_DIR="$d" CFG_REG_ID="t" PIPELINE_PROJECT="t"
  printf '%s' '{"project_id":"PVT_x","project_number":4,"fields":{"Status":{"id":"F1","options":{"Backlog":"o1","Done":"o2"}}}}' > "$d/t.json"
  _t "cache_get .project_id"          "$(_ghp_cache_get '.project_id')"                    "PVT_x"
  _t "cache_get .project_number"      "$(_ghp_cache_get '.project_number')"                "4"
  _t "cache_get .fields.Status.id"    "$(_ghp_cache_get '.fields.Status.id')"              "F1"
  _t "cache_get missing → empty"      "$(_ghp_cache_get '.nope.nope')"                     ""
  # an injection-style path must NOT execute as a jq program — treated as literal (missing) segments
  _t "cache_get injection inert"      "$(_ghp_cache_get '.project_id"] | keys | .[0] // "PWN')" ""
  # status-option resolution (create-path seed + set-status share this): a valid Status resolves to its
  # option id; an option absent from the board fails closed (empty) — never a silent wrong/UNSET status.
  _t "status_oid Backlog → o1"        "$(_ghp_status_oid "$d/t.json" Backlog)"  "o1"
  _t "status_oid Done → o2"           "$(_ghp_status_oid "$d/t.json" Done)"     "o2"
  _t "status_oid absent → empty"      "$(_ghp_status_oid "$d/t.json" Nope)"     ""
  # cache HIT path returns from the cache with NO gh/refresh (the miss→refresh→retry path is proven live)
  _t "status_oid_fresh hit → o1"      "$(_ghp_status_oid_fresh Backlog)"        "o1"
  rm -rf "$d"
  # kind → native Type + label (bugs are Type=Bug + label=bug; features Type=Feature; enhancements labelled)
  _t "kind bug → Type Bug"            "$(_ghp_kind_type bug)"          "Bug"
  _t "kind feature → Type Feature"    "$(_ghp_kind_type feature)"      "Feature"
  _t "kind enhancement → Type Feature" "$(_ghp_kind_type enhancement)" "Feature"
  _t "kind task → Type Task"          "$(_ghp_kind_type task)"         "Task"
  _t "kind unknown → empty (reject)"  "$(_ghp_kind_type nope)"         ""
  _t "kind bug → label bug"           "$(_ghp_kind_label bug)"         "bug"
  _t "kind enhancement → label"       "$(_ghp_kind_label enhancement)" "enhancement"
  _t "kind feature → no label"        "$(_ghp_kind_label feature)"     ""
  # terminal-status → issue must be Closed (Done/Delivered close; working statuses stay Open)
  _tfail _ghp_status_closes "In Progress"
  _tfail _ghp_status_closes Backlog
  _t "status_closes Done"             "$(_ghp_status_closes Done && echo yes)"      "yes"
  _t "status_closes Delivered"        "$(_ghp_status_closes Delivered && echo yes)" "yes"
  # canonical Status option list (PLAN 0072.007): reconciled to the board's true lifecycle —
  # Review (under-review) + Revise (changes-requested) present; Delivered kept as the terminal
  # delivered state. This list drives first-time field creation AND the non-destructive drift warn;
  # option ADDS/EDITS themselves go via the web UI only (see board-status-runbook.md).
  _t "canonical Status options" \
     "$(IFS='|'; echo "${_GHP_STATUS_OPTIONS[*]}")" \
     "Backlog|To Do|In Progress|Review|Revise|Done|Delivered"

  if [ "$fails" -eq 0 ]; then _ghp_info "${_ghp_grn}✓ self-test passed${_ghp_rst}"; return 0
  else _ghp_info "${_ghp_red}✗ self-test: $fails failure(s)${_ghp_rst}"; return 1; fi
}

# ─────────────────────────────────────────────────────────────────────────────
# CLI dispatch (only when executed, never when sourced).
# ─────────────────────────────────────────────────────────────────────────────
_ghp_main() {
  case "${1:-}" in
    ensure-project)       shift; cmd_ensure_project "$@" ;;
    ensure-epic)          shift; cmd_ensure_epic "$@" ;;
    ensure-plan-subissue) shift; cmd_ensure_plan_subissue "$@" ;;
    set-status)           shift; cmd_set_status "$@" ;;
    set-kind)             shift; cmd_set_kind "$@" ;;
    epic-issue)           shift; cmd_epic_issue "$@" ;;
    plan-issue)           shift; cmd_plan_issue "$@" ;;
    next-plan)            shift; cmd_next_plan "$@" ;;
    preflight)            shift; cmd_preflight "$@" ;;
    --self-test)          cmd_self_test ;;
    ""|-h|--help)
      grep -E '^#   ' "${BASH_SOURCE[0]}" | sed 's/^#   //' >&2
      printf 'usage: gh-pipeline.sh {ensure-project [title]|ensure-epic <order> <desc> [kind]|ensure-plan-subissue <epic#> <order> <desc> [kind]|set-status <issue#> <Status>|set-kind <issue#> <bug|feature|enhancement|task>|epic-issue <order>|plan-issue <order>|next-plan <epic#>|preflight|--self-test}\n' >&2
      return 2 ;;
    *) _ghp_err "unknown verb: $1"; return 2 ;;
  esac
}

[ "$_GHP_SOURCED" -eq 0 ] && { _ghp_main "$@"; exit $?; }
return 0 2>/dev/null || true
