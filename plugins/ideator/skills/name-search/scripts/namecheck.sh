#!/usr/bin/env bash
# namecheck.sh — deterministic, token-free bulk availability check for product names.
#
# The NAME-SEARCH skill's verify step. The LLM does charter/generate/challenge/synthesis;
# THIS script does every availability/adoption check (zero LLM tokens) and emits JSON the
# report consumes.
#
# Usage:
#   namecheck.sh [flags] name1 name2 ...
#   echo -e "name1\nname2" | namecheck.sh [flags]
#
# Flags:
#   --syllables=N | --syllables=MIN-MAX   target syllable count/range (advisory). default: 2-3
#   --registries=npm,pypi,crates,github   which registries to probe. default: npm,github,pypi,crates
#   --adoption                            for TAKEN names, classify CLEAR/LOW_ADOPTION/ABANDONED/TAKEN
#                                         via GitHub stars+last-push and npm staleness/deprecation
#   --json                                emit JSON (the only output mode; accepted for explicitness)
#   --neighbors[=N]                       GitHub login-neighbour / typo-squat proximity per name
#                                         (total_count==0 ⇒ no account AND no neighbours). Search API
#                                         is RATE-LIMITED (10/min unauth, 30/min with token); a probe
#                                         that can't complete is reported "unknown", never upgraded.
#   --domains[=com,dev,io,ai]             domain availability via RDAP (404=available, 200=registered).
#                                         default TLDs when bare: com,dev,io,ai
#   --connotation                         cross-language profanity/slang screen against the bundled
#                                         references/connotation-wordlist.tsv (advisory flags only)
#   --max-names=N                         safety cap on list size (default 50)
#   -h | --help                           show this help
#
# Env:
#   GITHUB_TOKEN / GH_TOKEN   if set, used as Bearer auth (5000/hr core, 30/min search vs 60/hr & 10/min).
#   NAMECHECK_PARALLEL        max concurrent name checks (default 10).
#   NAMECHECK_WORDLIST        override path to the connotation wordlist (.tsv: term<TAB>lang<TAB>severity).
#
# Verdicts (per name):
#   CLEAR        free everywhere checked            → recommendable
#   LOW_ADOPTION taken but few stars/downloads      → recommendable WITH caveat   (needs --adoption)
#   ABANDONED    taken but stale (>3y) / deprecated  → recommendable WITH caveat   (needs --adoption)
#   TAKEN        taken + active/adopted              → not recommendable
#   UNKNOWN      could not confirm (rate-limit/err)  → not recommendable, re-check
#
# A taken registry whose probe could not complete is reported "unknown" and NEVER upgraded to a
# verdict. Dependency-light: curl + jq only. Exit 0 always (per-name failures surface in evidence).

set -uo pipefail

# ---- tunable adoption thresholds ----
STARS_LOW=${NAMECHECK_STARS_LOW:-10}        # < this many stars on the top GitHub repo → low adoption
ABANDON_YEARS=${NAMECHECK_ABANDON_YEARS:-3} # last push/publish older than this → abandoned

PARALLEL=${NAMECHECK_PARALLEL:-10}

# ---- defaults ----
SYL_TARGET="2-3"
REGISTRIES="npm,github,pypi,crates"
ADOPTION=false
MAX_NAMES=50
NEIGHBORS=false
DOMAINS=""            # empty = off; "com,dev,io,ai" etc when requested
CONNOTATION=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORDLIST="${NAMECHECK_WORDLIST:-${SCRIPT_DIR}/../references/connotation-wordlist.tsv}"

# print the header comment block (line 2 → just before `set -uo pipefail`), as help
usage() { sed -n '2,/^set -uo/p' "$0" | sed '/^set -uo/d; s/^# \{0,1\}//'; }

# ---- GitHub auth header (optional) ----
GH_AUTH=()
_tok="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
[[ -n "$_tok" ]] && GH_AUTH=(-H "Authorization: Bearer ${_tok}")

# ---- helpers ----
json_str() { printf '%s' "$1" | jq -Rs '.'; }

# Improved syllable heuristic (advisory only). Vowel-cluster count with silent-e and -le handling.
syllables() {
  local w base
  w=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z')
  [[ -z "$w" ]] && { echo 1; return; }
  base=$(echo "$w" | grep -oE '[aeiouy]+' | wc -l | tr -d ' ')
  base=${base:-0}
  # -le ending preceded by a consonant keeps its syllable (table, cradle): no silent-e cut
  if [[ "$w" =~ [^aeiou]le$ ]]; then
    :
  # silent trailing 'e' (clare, vele): drop one if it leaves at least one
  elif [[ "$w" =~ e$ ]] && [[ $base -gt 1 ]]; then
    base=$(( base - 1 ))
  fi
  [[ $base -lt 1 ]] && base=1
  echo "$base"
}

# curl wrapper: returns HTTP status code, or "err" on transport failure. No -f (we want 4xx codes).
http_code() { curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$@" 2>/dev/null || echo "err"; }
# curl wrapper: returns body (empty on failure)
http_body() { curl -s --max-time 8 "$@" 2>/dev/null || echo ""; }

# map an HTTP code to a status string for a "404=free / 200=taken" registry
code_status() {
  case "$1" in
    404) echo "free" ;;
    200) echo "taken" ;;
    *)   echo "unknown" ;;
  esac
}

# epoch seconds for an ISO-8601 timestamp, or empty
iso_epoch() { [[ -n "$1" && "$1" != "null" ]] && date -d "$1" +%s 2>/dev/null || echo ""; }

# ---- neighbour / typo-squat proximity (GitHub login search) ----
# total_count==0 ⇒ no account AND no neighbours. Search API is rate-limited; an incomplete probe
# (403/422/err) is reported "unknown" and NEVER upgraded. Emits a JSON object.
check_neighbors() {
  local name="$1" body total samples flag
  body=$(http_body "${GH_AUTH[@]}" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/search/users?q=${name}+in:login&per_page=6&sort=followers")
  total=$(echo "$body" | jq -r '.total_count // "err"' 2>/dev/null)
  # MUST be an integer before any arithmetic: a network-derived value in `[[ x -eq y ]]` is an
  # arithmetic/command-substitution sink. Anything non-numeric (rate-limit/err/API drift) → unknown.
  if [[ ! "$total" =~ ^[0-9]+$ ]]; then
    printf '{"status":"unknown","count":null,"flag":"unknown","samples":[]}'; return
  fi
  samples=$(echo "$body" | jq -c '[.items[]?.login][0:6]' 2>/dev/null); [[ -z "$samples" ]] && samples="[]"
  if (( total == 0 )); then flag="clean"; else flag="neighbours"; fi
  printf '{"status":"checked","count":%s,"flag":"%s","samples":%s}' "$total" "$flag" "$samples"
}

# RDAP probe with exponential backoff on transient/rate-limit responses. rdap.org (esp. the .com
# Verisign endpoint) returns 429 under burst; without a retry that surfaces as a spurious "unknown".
# Retries only the retryable codes (429 / 5xx / timeout / transport-err); 200/404 and other definitive
# codes return immediately. Up to 3 attempts, sleeping 1s then 2s.
rdap_code() {
  local url="$1" code tries=0
  while :; do
    code=$(http_code -L "$url")
    case "$code" in
      200|404) echo "$code"; return ;;       # definitive
      429|000|err|5??) : ;;                   # retryable — fall through to backoff
      *) echo "$code"; return ;;              # non-retryable (400/403/…)
    esac
    tries=$(( tries + 1 ))
    [[ $tries -ge 3 ]] && { echo "$code"; return; }
    sleep "$tries"
  done
}

# ---- domain availability via RDAP (404=available, 200=registered, else unknown) ----
# Emits a JSON object keyed by TLD. rdap.org is a bootstrap redirector → follow with -L; rdap_code
# adds backoff so a rate-limited probe isn't mistaken for "unknown".
check_domains() {
  local name="$1" tlds="$2" out="" tld code st first=true _tlds
  IFS=',' read -ra _tlds <<< "$tlds"
  for tld in "${_tlds[@]}"; do
    tld=$(echo "$tld" | tr -d '[:space:]'); [[ -z "$tld" ]] && continue
    code=$(rdap_code "https://rdap.org/domain/${name}.${tld}")
    case "$code" in 404) st="available" ;; 200) st="registered" ;; *) st="unknown" ;; esac
    [[ "$first" == true ]] && first=false || out="${out},"
    out="${out}\"${tld}\":\"${st}\""
  done
  printf '{%s}' "$out"
}

# ---- cross-language connotation screen (offline; substring match against the wordlist) ----
# Emits a JSON array of {term,lang,severity} for each wordlist term (len>=3) contained in the name.
check_connotation() {
  local name="$1" out="" first=true term lang sev t
  [[ -f "$WORDLIST" ]] || { printf '[]'; return; }
  while IFS=$'\t' read -r term lang sev _; do
    [[ -z "$term" || "$term" == \#* ]] && continue
    [[ ${#term} -lt 3 ]] && continue
    t=$(echo "$term" | tr '[:upper:]' '[:lower:]')
    if [[ "$name" == *"$t"* ]]; then
      [[ "$first" == true ]] && first=false || out="${out},"
      out="${out}{\"term\":$(json_str "$term"),\"lang\":$(json_str "${lang:-?}"),\"severity\":$(json_str "${sev:-flag}")}"
    fi
  done < "$WORDLIST"
  printf '[%s]' "$out"
}

check_name() {
  local raw="$1"
  local name
  name=$(echo "$raw" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')

  local has=",$REGISTRIES,"
  local npm_status="skipped" npm_code="-"
  local hyp_status="skipped" hyp_ev="-"
  local pypi_status="skipped" pypi_code="-"
  local crates_status="skipped" crates_code="-"
  local gh_status="skipped" gh_user="-" gh_org="-"

  # ---- npm exact + hyphenated ----
  if [[ "$has" == *",npm,"* ]]; then
    npm_code=$(http_code "https://registry.npmjs.org/${name}")
    npm_status=$(code_status "$npm_code")
    hyp_status="free"
    local len=${#name}
    if [[ $len -ge 5 ]]; then
      local mid=$(( len / 2 )) variants=()
      [[ $mid -ge 3 && $mid -le $(( len - 3 )) ]] && variants+=("${name:0:$mid}-${name:$mid}")
      [[ 4 -ne $mid && 4 -le $(( len - 3 )) ]] && variants+=("${name:0:4}-${name:4}")
      for v in "${variants[@]:-}"; do
        [[ -z "$v" ]] && continue
        local vc; vc=$(http_code "https://registry.npmjs.org/${v}")
        hyp_ev="${v}:${vc}"
        [[ "$vc" == "200" ]] && { hyp_status="taken"; break; }
        [[ "$vc" != "404" ]] && hyp_status="unknown"
      done
    fi
  fi

  # ---- pypi ----
  if [[ "$has" == *",pypi,"* ]]; then
    pypi_code=$(http_code "https://pypi.org/pypi/${name}/json")
    pypi_status=$(code_status "$pypi_code")
  fi

  # ---- crates.io (needs a User-Agent) ----
  if [[ "$has" == *",crates,"* ]]; then
    crates_code=$(http_code -H "User-Agent: namecheck (idea-to-production)" \
      "https://crates.io/api/v1/crates/${name}")
    crates_status=$(code_status "$crates_code")
  fi

  # ---- GitHub user/org ----
  if [[ "$has" == *",github,"* ]]; then
    gh_user=$(http_code "${GH_AUTH[@]}" -H "Accept: application/vnd.github+json" \
      "https://api.github.com/users/${name}")
    gh_org="skipped"
    [[ "$gh_user" != "200" ]] && gh_org=$(http_code "${GH_AUTH[@]}" \
      -H "Accept: application/vnd.github+json" "https://api.github.com/orgs/${name}")
    if [[ "$gh_user" == "200" || "$gh_org" == "200" ]]; then gh_status="taken"
    elif [[ "$gh_user" == "404" && ( "$gh_org" == "404" || "$gh_org" == "skipped" ) ]]; then gh_status="free"
    else gh_status="unknown"; fi
  fi

  # ---- aggregate availability ----
  local statuses=("$npm_status" "$hyp_status" "$pypi_status" "$crates_status" "$gh_status")
  local any_taken=false any_unknown=false
  for s in "${statuses[@]}"; do
    [[ "$s" == "taken" ]] && any_taken=true
    [[ "$s" == "unknown" ]] && any_unknown=true
  done

  # ---- adoption tier (opt-in; only meaningful when something is taken) ----
  local adopt_tier="n/a" stars="null" last_push="null" npm_dep="false"
  if [[ "$ADOPTION" == "true" && "$any_taken" == "true" ]]; then
    # GitHub: top repo match → stars + last push
    local body; body=$(http_body "${GH_AUTH[@]}" -H "Accept: application/vnd.github+json" \
      "https://api.github.com/search/repositories?q=${name}&sort=stars&per_page=1")
    stars=$(echo "$body" | jq -r '.items[0].stargazers_count // empty' 2>/dev/null)
    last_push=$(echo "$body" | jq -r '.items[0].pushed_at // empty' 2>/dev/null)
    [[ -z "$stars" ]] && stars="null"
    [[ -z "$last_push" ]] && last_push="null"
    # npm: deprecation + staleness
    if [[ "$npm_status" == "taken" ]]; then
      local npmbody; npmbody=$(http_body "https://registry.npmjs.org/${name}")
      local dep; dep=$(echo "$npmbody" | jq -r '(.versions[.["dist-tags"].latest].deprecated // .deprecated) | if . then "true" else "false" end' 2>/dev/null)
      [[ "$dep" == "true" ]] && npm_dep="true"
      local npm_mod; npm_mod=$(echo "$npmbody" | jq -r '.time.modified // empty' 2>/dev/null)
      [[ -n "$npm_mod" && "$last_push" == "null" ]] && last_push="$npm_mod"
    fi
    # classify
    local now epoch_push age_years=999
    now=$(date +%s)
    epoch_push=$(iso_epoch "$last_push")
    [[ -n "$epoch_push" ]] && age_years=$(( (now - epoch_push) / 31536000 ))
    if [[ "$npm_dep" == "true" || $age_years -ge $ABANDON_YEARS ]]; then
      adopt_tier="ABANDONED"
    elif [[ "$stars" =~ ^[0-9]+$ && "$stars" -lt $STARS_LOW ]]; then
      adopt_tier="LOW_ADOPTION"
    else
      adopt_tier="TAKEN"
    fi
  fi

  # ---- verdict + recommendable ----
  local verdict recommendable caveats="[]"
  if [[ "$any_taken" == "true" ]]; then
    if [[ "$adopt_tier" == "ABANDONED" || "$adopt_tier" == "LOW_ADOPTION" ]]; then
      verdict="$adopt_tier"; recommendable=true
      caveats=$(printf '%s' "name is taken but ${adopt_tier}; verify before adopting" | jq -Rs '[.]')
    else
      verdict="TAKEN"; recommendable=false
    fi
  elif [[ "$any_unknown" == "true" ]]; then
    verdict="UNKNOWN"; recommendable=false
    caveats=$(printf '%s' "one or more registries could not be confirmed; re-check" | jq -Rs '[.]')
  else
    verdict="CLEAR"; recommendable=true
  fi

  # ---- syllables (advisory) ----
  local syl syl_ok=true; syl=$(syllables "$name")
  local lo hi
  if [[ "$SYL_TARGET" == *-* ]]; then lo=${SYL_TARGET%-*}; hi=${SYL_TARGET#*-}; else lo=$SYL_TARGET; hi=$SYL_TARGET; fi
  # numeric-guard the (CLI-derived) bounds before arithmetic — never let a flag value reach `[[ -lt ]]`
  [[ "$lo" =~ ^[0-9]+$ ]] || lo=0
  [[ "$hi" =~ ^[0-9]+$ ]] || hi=9999
  { [[ "$syl" -lt "$lo" ]] || [[ "$syl" -gt "$hi" ]]; } && syl_ok=false

  # ---- back-compat: clean mirror (old binary shape) ----
  local clean=false
  [[ "$verdict" == "CLEAR" && "$syl_ok" == "true" ]] && clean=true

  local evidence="npm:${npm_code} npm-hyp:[${hyp_ev}] pypi:${pypi_code} crates:${crates_code} gh-user:${gh_user} gh-org:${gh_org}"
  [[ "$ADOPTION" == "true" && "$any_taken" == "true" ]] && evidence="${evidence} stars:${stars} last-push:${last_push} npm-deprecated:${npm_dep}"

  local sp; [[ "$last_push" == "null" || -z "$last_push" ]] && sp="null" || sp="\"${last_push}\""
  local st; [[ "$stars" == "null" || -z "$stars" ]] && st="null" || st="$stars"

  # ---- optional extra checks (opt-in; ADDITIVE — they never affect the verdict computed above) ----
  local nb_json='{"status":"skipped"}' dm_json='{}' cn_json='[]'
  [[ "$NEIGHBORS" == "true" ]] && nb_json=$(check_neighbors "$name")
  [[ -n "$DOMAINS" ]] && dm_json=$(check_domains "$name" "$DOMAINS")
  [[ "$CONNOTATION" == "true" ]] && cn_json=$(check_connotation "$name")

  local base
  base=$(printf '{"name":%s,"normalized":%s,"syllables":%d,"syllableTarget":%s,"syllablesOk":%s,"registries":{"npmExact":{"status":%s,"code":%s},"npmHyphen":{"status":%s,"evidence":%s},"pypi":{"status":%s,"code":%s},"crates":{"status":%s,"code":%s},"github":{"status":%s,"userCode":%s,"orgCode":%s}},"adoption":{"tier":%s,"stars":%s,"lastPush":%s,"npmDeprecated":%s},"verdict":%s,"recommendable":%s,"caveats":%s,"clean":%s,"evidence":%s}' \
    "$(json_str "$raw")" "$(json_str "$name")" "$syl" "$(json_str "$SYL_TARGET")" "$syl_ok" \
    "$(json_str "$npm_status")" "$(json_str "$npm_code")" \
    "$(json_str "$hyp_status")" "$(json_str "$hyp_ev")" \
    "$(json_str "$pypi_status")" "$(json_str "$pypi_code")" \
    "$(json_str "$crates_status")" "$(json_str "$crates_code")" \
    "$(json_str "$gh_status")" "$(json_str "$gh_user")" "$(json_str "$gh_org")" \
    "$(json_str "$adopt_tier")" "$st" "$sp" "$npm_dep" \
    "$(json_str "$verdict")" "$recommendable" "$caveats" "$clean" \
    "$(json_str "$evidence")")

  # Default invocations emit the base object byte-for-byte (back-compat). When an extra check is
  # requested, merge its fields in (jq appends keys, preserving the original order).
  if [[ "$NEIGHBORS" == "true" || -n "$DOMAINS" || "$CONNOTATION" == "true" ]]; then
    printf '%s' "$base" | jq -c \
      --argjson nb "$nb_json" --argjson dm "$dm_json" --argjson cn "$cn_json" \
      '. + {neighbors:$nb, domains:$dm, connotationFlags:$cn}'
  else
    printf '%s' "$base"
  fi
}

export -f check_name http_code http_body json_str syllables code_status iso_epoch \
  check_neighbors check_domains check_connotation rdap_code
export SYL_TARGET REGISTRIES ADOPTION STARS_LOW ABANDON_YEARS
export NEIGHBORS DOMAINS CONNOTATION WORDLIST
export GH_AUTH 2>/dev/null || true

# ---- parse args ----
names=()
for arg in "$@"; do
  case "$arg" in
    --syllables=*) SYL_TARGET="${arg#*=}" ;;
    --registries=*) REGISTRIES="${arg#*=}" ;;
    --adoption) ADOPTION=true ;;
    --neighbors|--neighbours) NEIGHBORS=true ;;
    --neighbors=*|--neighbours=*) NEIGHBORS=true ;;
    --domains) DOMAINS="com,dev,io,ai" ;;
    --domains=*) DOMAINS="${arg#*=}" ;;
    --connotation) CONNOTATION=true ;;
    --json) : ;;
    --max-names=*) MAX_NAMES="${arg#*=}" ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "namecheck: unknown flag $arg" >&2; exit 2 ;;
    *) names+=("$arg") ;;
  esac
done
# numeric-guard the CLI-derived cap before it reaches `[[ -gt ]]` arithmetic
[[ "$MAX_NAMES" =~ ^[0-9]+$ ]] || MAX_NAMES=50
# stdin names if none on argv
if [[ ${#names[@]} -eq 0 ]]; then
  while IFS= read -r line; do [[ -n "$line" ]] && names+=("$line"); done
fi
export SYL_TARGET REGISTRIES ADOPTION NEIGHBORS DOMAINS CONNOTATION WORDLIST

if [[ ${#names[@]} -eq 0 ]]; then echo "[]"; exit 0; fi
if [[ ${#names[@]} -gt $MAX_NAMES ]]; then
  echo "namecheck: ${#names[@]} names exceeds --max-names=$MAX_NAMES; truncating (raise the cap to check more)" >&2
  names=("${names[@]:0:$MAX_NAMES}")
fi

# ---- run in parallel, preserve input order via indexed temp files ----
tmpdir=$(mktemp -d); trap 'rm -rf "$tmpdir"' EXIT
running=0; pids=()
for i in "${!names[@]}"; do
  ( check_name "${names[$i]}" > "${tmpdir}/${i}.json" ) &
  pids+=($!); running=$(( running + 1 ))
  if [[ $running -ge $PARALLEL ]]; then wait "${pids[0]}"; pids=("${pids[@]:1}"); running=$(( running - 1 )); fi
done
for pid in "${pids[@]:-}"; do [[ -n "$pid" ]] && wait "$pid"; done

# ---- assemble JSON array ----
echo "["
first=true
for i in "${!names[@]}"; do
  [[ "$first" == "true" ]] && first=false || echo ","
  cat "${tmpdir}/${i}.json"
done
echo "]"
