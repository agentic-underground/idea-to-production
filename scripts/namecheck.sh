#!/usr/bin/env bash
# namecheck.sh — bulk availability check for product/package names
# Usage:  namecheck.sh name1 name2 name3 ...
#    or:  echo -e "name1\nname2" | namecheck.sh
#
# Checks per name (run in parallel, up to 10 concurrent):
#   • npm exact            — registry.npmjs.org/<name>  (404=free)
#   • npm hyphenated       — tries 1-2 split positions  (all 404=free)
#   • GitHub user/org      — api.github.com/users + /orgs  (both 404=clear)
#   • syllable count       — vowel-cluster heuristic
#
# Outputs: JSON array of verify objects, one per name.
# brandClear is always true here; brand/TM checks require web search and are
# deferred to the adversarial-challenge phase.
#
# Exit codes: 0 always (individual check failures are reported in evidence).

set -uo pipefail

PARALLEL=${NAMECHECK_PARALLEL:-10}

# ---- helpers ----
json_str() { printf '%s' "$1" | jq -Rs '.'; }

syllables() {
  local s
  s=$(echo "$1" | tr '[:upper:]' '[:lower:]' | grep -oE '[aeiou]+' | wc -l | tr -d ' ')
  echo "${s:-1}"
}

http_get() {
  # -s silent, no -f (so 4xx doesn't fail — we want the status code)
  curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$@" 2>/dev/null || echo "err"
}

check_name() {
  local raw="$1"
  local name
  name=$(echo "$raw" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')

  # ---- npm exact ----
  local npm_code
  npm_code=$(http_get "https://registry.npmjs.org/${name}")
  local npm_exact_free=false
  [[ "$npm_code" == "404" ]] && npm_exact_free=true

  # ---- npm hyphenated variants ----
  local npm_hyp_free=true
  local hyp_evidence="none"
  local len=${#name}
  if [[ $len -ge 5 ]]; then
    local variants=()
    local mid=$(( len / 2 ))
    [[ $mid -ge 3 && $mid -le $(( len - 3 )) ]] && variants+=("${name:0:$mid}-${name:$mid}")
    [[ 4 -ne $mid && 4 -ge 3 && 4 -le $(( len - 3 )) ]] && variants+=("${name:0:4}-${name:4}")
    for v in "${variants[@]:-}"; do
      [[ -z "$v" ]] && continue
      local vc
      vc=$(http_get "https://registry.npmjs.org/${v}")
      hyp_evidence="${v}:${vc}"
      if [[ "$vc" == "200" ]]; then
        npm_hyp_free=false
        break
      fi
    done
  fi

  # ---- GitHub user/org (skip org check if user already found) ----
  local gh_user
  gh_user=$(http_get -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/users/${name}")
  local gh_org="skipped"
  if [[ "$gh_user" != "200" ]]; then
    gh_org=$(http_get -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/orgs/${name}")
  fi
  local github_clear=true
  { [[ "$gh_user" == "200" ]] || [[ "$gh_org" == "200" ]]; } && github_clear=false

  # ---- syllables ----
  local syl
  syl=$(syllables "$name")

  # ---- clean flag ----
  local clean=false
  if [[ "$npm_exact_free" == "true" ]] && \
     [[ "$npm_hyp_free" == "true" ]] && \
     [[ "$github_clear" == "true" ]] && \
     [[ "$syl" -le 3 ]]; then
    clean=true
  fi

  local evidence="npm:${npm_code} npm-hyp:[${hyp_evidence}] gh-user:${gh_user} gh-org:${gh_org}"

  printf '{"name":%s,"npmExactFree":%s,"npmHyphenFree":%s,"githubClear":%s,"brandClear":true,"syllables":%d,"clean":%s,"evidence":%s}' \
    "$(json_str "$raw")" \
    "$npm_exact_free" "$npm_hyp_free" "$github_clear" \
    "$syl" "$clean" \
    "$(json_str "$evidence")"
}

export -f check_name http_get json_str syllables

# ---- collect names from args or stdin ----
names=()
if [[ $# -gt 0 ]]; then
  names=("$@")
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && names+=("$line")
  done
fi

if [[ ${#names[@]} -eq 0 ]]; then
  echo "[]"
  exit 0
fi

# ---- run checks in parallel, preserving input order via indexed temp files ----
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

total=${#names[@]}
running=0
pids=()
indices=()

for i in "${!names[@]}"; do
  (check_name "${names[$i]}" > "${tmpdir}/${i}.json") &
  pids+=($!)
  indices+=("$i")
  running=$(( running + 1 ))
  if [[ $running -ge $PARALLEL ]]; then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
    indices=("${indices[@]:1}")
    running=$(( running - 1 ))
  fi
done
# wait for remaining
for pid in "${pids[@]:-}"; do
  [[ -n "$pid" ]] && wait "$pid"
done

# ---- assemble JSON array in original order ----
echo "["
first=true
for i in "${!names[@]}"; do
  [[ "$first" == "true" ]] && first=false || echo ","
  cat "${tmpdir}/${i}.json"
done
echo "]"
