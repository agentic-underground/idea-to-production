#!/usr/bin/env bash
# identity.sh — the umbrella-org IDENTITY RESOLVER for the GEMBA reflex.
#
# WHAT IT DOES
#   Answers "where does this learning belong?" — resolving, from <project>/.i2p/identity.json,
#   a TARGET REPO (org/repo) and a SELF-vs-GEMBA verdict:
#     • SELF  — the learning is about THIS marketplace (improve it here, /<plugin>:self-improve).
#     • GEMBA — the learning is about a SIBLING marketplace (cross-repo; ask before filing).
#   One field — `github_org` — re-targets the WHOLE marketplace when the umbrella org is created:
#   every resolved target is `<github_org>/<repo>`, so flipping the org re-points every target at once.
#
#   WHEN .i2p/identity.json is ABSENT the system SEEDS it from `git remote -v`
#   (the github.com remote, same resolution as foundry/pr-review's gather-diff.sh) +
#   the `owner.name` in .claude-plugin/marketplace.json — so the resolver works on a fresh clone.
#
# RECORD SCHEMA (schema-versioned, like the other i2p artifacts):
#   {"schema":"identity/1.0","github_org":"<org>",
#    "self":{"repo":"<repo>","kind":"marketplace"},
#    "siblings":[{"name":"<n>","repo":"<repo>","kind":"marketplace","topics":[...]}]}
#
# USAGE
#   identity.sh resolve  <dir> [hint]   # → JSON: {verdict, org, repo, target, matched, reason}
#   identity.sh seed     <dir>          # write .i2p/identity.json if absent (idempotent); print it
#   identity.sh show     <dir>          # print the (seeded-if-absent) identity.json
#   identity.sh targets  <dir>          # → JSON array of every {label, target} (self + siblings)
#   Global flags (anywhere): --dry-run (never write a file), --org <org> (override github_org).
#
# The verdict for a `resolve` is chosen by matching the HINT against each sibling's name/repo/topics;
# no sibling matched ⇒ SELF. A token-fairness-class hint (e.g. "tf scheduler rate-limit") ⇒ GEMBA on
# the token-fairness sibling repo.
#
# Needs jq. Read-only / advisory; exits 0 on the happy path, 2 on a usage error.
set -uo pipefail

SCHEMA="identity/1.0"

dry_run=0; org_override=""
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    --org)     org_override="${2:-}"; shift 2 ;;
    *)         args+=("$1"); shift ;;
  esac
done
set -- "${args[@]:-}"

cmd="${1:-resolve}"; dir="${2:-.}"; hint="${3:-}"
dir="${dir%/}"
IDFILE="${dir}/.i2p/identity.json"

command -v jq >/dev/null 2>&1 || { echo "identity: jq required (no-op without it)" >&2; exit 0; }

have() { command -v "$1" >/dev/null 2>&1; }

# resolve_org — the org for every target: --org override > identity.json > git-remote/marketplace seed.
git_remote_owner() {
  # Pick the github.com remote (fallback origin, github), parse <owner> from its URL.
  local remote url
  remote="$(git -C "$dir" remote -v 2>/dev/null | awk '/github\.com/ {print $1; exit}')"
  [ -n "$remote" ] || { for r in origin github; do git -C "$dir" remote get-url "$r" >/dev/null 2>&1 && remote="$r" && break; done; }
  [ -n "$remote" ] || return 1
  url="$(git -C "$dir" remote get-url "$remote" 2>/dev/null)" || return 1
  # git@github.com:owner/repo.git  OR  https://github.com/owner/repo(.git)
  printf '%s\n' "$url" | sed -E 's#^.*github\.com[:/]+([^/]+)/.*$#\1#'
}
git_remote_repo() {
  local remote url
  remote="$(git -C "$dir" remote -v 2>/dev/null | awk '/github\.com/ {print $1; exit}')"
  [ -n "$remote" ] || { for r in origin github; do git -C "$dir" remote get-url "$r" >/dev/null 2>&1 && remote="$r" && break; done; }
  [ -n "$remote" ] || return 1
  url="$(git -C "$dir" remote get-url "$remote" 2>/dev/null)" || return 1
  printf '%s\n' "$url" | sed -E 's#^.*github\.com[:/]+[^/]+/([^/]+?)(\.git)?$#\1#'
}
marketplace_owner() {
  local mf="${dir}/.claude-plugin/marketplace.json"
  [ -r "$mf" ] || return 1
  jq -r '.owner.name // empty' "$mf" 2>/dev/null
}

# seed_json — compose a default identity.json from the git remote + marketplace owner.
seed_json() {
  local org repo
  org="$(git_remote_owner 2>/dev/null || true)"
  [ -n "$org" ] || org="$(marketplace_owner 2>/dev/null || true)"
  [ -n "$org" ] || org="OWNER"
  repo="$(git_remote_repo 2>/dev/null || true)"
  [ -n "$repo" ] || repo="$(basename "$(cd "$dir" 2>/dev/null && pwd || echo idea-to-production)")"
  jq -nc --arg s "$SCHEMA" --arg org "$org" --arg repo "$repo" '
    {schema:$s, github_org:$org,
     self:{repo:$repo, kind:"marketplace"},
     siblings:[
       {name:"token-fairness", repo:"token-fairness", kind:"marketplace",
        topics:["token","scheduler","rate-limit","budget","fairness","tf"]}
     ]}'
}

# load_identity — read identity.json, else seed it. Honours --dry-run (compose, never write).
load_identity() {
  if [ -r "$IDFILE" ]; then
    cat "$IDFILE"
    return 0
  fi
  local seeded; seeded="$(seed_json)"
  if [ "$dry_run" -eq 0 ]; then
    mkdir -p "${dir}/.i2p" 2>/dev/null && printf '%s\n' "$seeded" | jq '.' > "$IDFILE" 2>/dev/null \
      && echo "identity: seeded ${IDFILE} from git remote + marketplace owner" >&2
  else
    echo "identity: (--dry-run) would seed ${IDFILE}" >&2
  fi
  printf '%s' "$seeded"
}

# effective_org — apply the --org override on top of whatever identity provides.
effective_org() {
  local id="$1"
  if [ -n "$org_override" ]; then printf '%s' "$org_override"; else
    printf '%s' "$id" | jq -r '.github_org // "OWNER"'
  fi
}

case "$cmd" in
  seed|show)
    id="$(load_identity)"
    org="$(effective_org "$id")"
    printf '%s' "$id" | jq --arg org "$org" '.github_org=$org'
    ;;

  targets)
    id="$(load_identity)"
    org="$(effective_org "$id")"
    printf '%s' "$id" | jq -c --arg org "$org" '
      [ {label:"self", target:($org + "/" + (.self.repo))} ]
      + ( (.siblings // []) | map({label:.name, target:($org + "/" + .repo)}) )'
    ;;

  resolve)
    id="$(load_identity)"
    org="$(effective_org "$id")"
    # Match the hint (lowercased) against each sibling's name/repo/topics. First match wins ⇒ GEMBA.
    lc_hint="$(printf '%s' "$hint" | tr '[:upper:]' '[:lower:]')"
    printf '%s' "$id" | jq -c --arg org "$org" --arg hint "$lc_hint" '
      . as $id
      | ($id.siblings // []) as $sibs
      | ( [ $sibs[]
            | . as $s
            | ([ .name, .repo ] + (.topics // []))
              | map(ascii_downcase)
              | map(select($hint != "" and ($hint | contains(.)) ))
              | if length > 0 then $s else empty end
          ] | .[0] ) as $hit
      | if $hit == null
        then { verdict:"self",  org:$org, repo:$id.self.repo,
               target:($org + "/" + $id.self.repo), matched:null,
               reason:(if $hint=="" then "no hint — defaults to self"
                       else "no sibling matched hint — self" end) }
        else { verdict:"gemba", org:$org, repo:$hit.repo,
               target:($org + "/" + $hit.repo), matched:$hit.name,
               reason:("hint matched sibling " + $hit.name) }
        end'
    ;;

  *)
    echo "usage: identity.sh {resolve <dir> [hint]|seed <dir>|show <dir>|targets <dir>} [--dry-run] [--org <org>]" >&2
    exit 2 ;;
esac
