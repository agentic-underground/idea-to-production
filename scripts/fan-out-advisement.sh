#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# fan-out-advisement.sh — EPIC 0071 / PLAN 0071.003 (CS3) — the honest fan-out advisement.
#
# Computes whether the next-N board items can be FANNED OUT (built in parallel) or must go one at a
# time — the "only if they actually can" truth the CLEAR-SAFE covenant promises
# (plugins/deliver/knowledge/protocols/clear-safe.md → "The fan-out advisement"). A pair of items fans
# out IFF both per-pair predicates hold — (1) no declared dependency AND (2) disjoint touched-files —
# and one always-on execution constraint applies to any fan-out: GitHub writes + the merge SERIALIZE.
#
# SOURCE OF TRUTH — hybrid, parse-or-degrade-to-SERIAL. Each PLAN issue body may carry two line-anchored
# trailers (the board is authoritative; the docs/roadmap mirror is skipped for recent EPICs):
#
#     Depends-on: none                 |  Depends-on: 0071.002, 0071.003      (ORDER number-space NNNN.SSS)
#     Touches: scripts/x.sh, plugins/deliver/knowledge/protocols/clear-safe.md, docs/roadmap/
#
# Deps are ORDER numbers (never #issue — orders exist at decomposition, issue numbers do not; this dodges
# the two-number-space hazard). `Depends-on: none` = explicitly independent (counts as annotated); a
# MISSING Depends-on or Touches ⇒ the item is UNANNOTATED ⇒ every pair with it is SERIAL. This is
# monotone-safe: missing information only ever makes the verdict MORE serial, never less — silence can
# never oversell parallelism, which is the covenant's whole ethos. Reason precedence (fixed):
#     unreadable > unannotated > dependency > shared-file
#
# The caller supplies the next-N as positional issue numbers IN BOARD ORDER (CS3 does not itself discover
# "next" — that is the resume pointer's free-text semantics, kept with the caller so this stays pure and
# one-slice). Output: a human advisement (the covenant report's string) by default, or a machine TSV
# (--machine) that the CS4 `resume … in a workflow` verb consumes (wave = build-these; held = why-not).
# Both renderings come off ONE compute path, so they can never disagree (the verify-board-linkage lesson).
#
# House style mirrors verify-clear-safe.sh (CS2): pure classifiers (no git/gh/fs) + one gatherer + a
# hermetic --self-test with a DERIVED row count. Test hooks: FO_FIXTURE overrides gather_bodies wholesale
# (one blob, `@@ITEM <n>` record separators; `@@UNREADABLE` marks a fetch failure); FO_OFFLINE=1 skips gh.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

red=$'\033[31m'; green=$'\033[32m'; bold=$'\033[1m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; bold=""; reset=""; }
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; }

# ── PURE classifiers — no git/gh/fs, so --self-test drives them with fixtures ─────────────────────────

# parse_order <body> → echo NNNN[.SSS] from the `<!-- pipeline-(plan|epic)-NNNN[.SSS] -->` marker, else empty.
parse_order() {
  printf '%s' "$1" | grep -oE 'pipeline-(plan|epic)-[0-9]{4}(\.[0-9]{3})?' \
    | grep -oE '[0-9]{4}(\.[0-9]{3})?' | head -1
}

# parse_deps <body> → echo MISSING (no trailer) | none | "0071.002, 0071.003" (raw csv). Line-ANCHORED:
# a mid-line prose mention of "Depends-on" must NOT parse (the anchoring discipline board-linkage taught).
parse_deps() {
  local line
  line="$(printf '%s\n' "$1" | grep -iE '^[[:space:]]*Depends-on:' | head -1)"
  [ -z "$line" ] && { printf 'MISSING'; return; }
  printf '%s' "$line" | sed -E 's/^[[:space:]]*Depends-on:[[:space:]]*//I; s/[[:space:]]+$//'
}

# parse_touches <body> → echo MISSING (no trailer) | "path, path" (raw csv). Line-anchored, same as deps.
parse_touches() {
  local line
  line="$(printf '%s\n' "$1" | grep -iE '^[[:space:]]*Touches:' | head -1)"
  [ -z "$line" ] && { printf 'MISSING'; return; }
  printf '%s' "$line" | sed -E 's/^[[:space:]]*Touches:[[:space:]]*//I; s/[[:space:]]+$//'
}

# _blank <val> → 0 if val has NO character other than whitespace/commas (present-but-empty).
_blank() { case "$(printf '%s' "$1" | tr -d '[:space:],')" in "") return 0 ;; *) return 1 ;; esac; }

# item_state <body> → unreadable | unannotated | annotated.
# A trailer whose LINE is missing OR whose VALUE trims to empty (the label typed, the value forgotten —
# the most likely authoring slip) is UNANNOTATED. This fails to the conservative verdict: an empty
# `Touches:` must NOT be read as "touches nothing" (→ falsely parallel) — silence never oversells
# parallelism (`Depends-on: none` is the explicit-independence sentinel and survives, being non-empty).
item_state() {
  printf '%s' "$1" | grep -q '@@UNREADABLE' && { echo unreadable; return; }
  local d t; d="$(parse_deps "$1")"; t="$(parse_touches "$1")"
  { [ "$d" = MISSING ] || _blank "$d"; } && { echo unannotated; return; }
  { [ "$t" = MISSING ] || _blank "$t"; } && { echo unannotated; return; }
  echo annotated
}

# _csv_has <csv> <token> → 0 if the whitespace-trimmed csv contains token exactly.
_csv_has() {
  local x; local IFS=','
  for x in $1; do x="${x//[[:space:]]/}"; [ "$x" = "$2" ] && return 0; done
  return 1
}

# _path_match <a> <b> → 0 iff equal, or one is a DIRECTORY prefix (trailing '/') of the other.
_path_match() {
  [ "$1" = "$2" ] && return 0
  case "$1" in */) [ "${2#"$1"}" != "$2" ] && return 0 ;; esac
  case "$2" in */) [ "${1#"$2"}" != "$1" ] && return 0 ;; esac
  return 1
}

# paths_overlap <csvA> <csvB> → echo the FIRST overlapping path (A's order), empty + rc1 if disjoint.
paths_overlap() {
  local pa pb; local IFS=','
  local -a A=() B=(); read -ra A <<< "$1"; read -ra B <<< "$2"
  for pa in "${A[@]}"; do
    pa="$(printf '%s' "$pa" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"; [ -z "$pa" ] && continue
    for pb in "${B[@]}"; do
      pb="$(printf '%s' "$pb" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"; [ -z "$pb" ] && continue
      _path_match "$pa" "$pb" && { printf '%s' "$pa"; return 0; }
    done
  done
  return 1
}

# pair_verdict <stA ordA depsA touchA issA> <stB ordB depsB touchB issB> → echo `parallel` | `serial<TAB>reason`.
# Reason precedence is the fixed order of these tests: unreadable > unannotated > dependency > shared-file.
pair_verdict() {
  local stA=$1 ordA=$2 depsA=$3 touchA=$4 issA=$5 stB=$6 ordB=$7 depsB=$8 touchB=$9 issB=${10} ov
  [ "$stA" = unreadable ] && { printf 'serial\tunreadable:#%s' "$issA"; return; }
  [ "$stB" = unreadable ] && { printf 'serial\tunreadable:#%s' "$issB"; return; }
  [ "$stA" = unannotated ] && { printf 'serial\tunannotated:#%s' "$issA"; return; }
  [ "$stB" = unannotated ] && { printf 'serial\tunannotated:#%s' "$issB"; return; }
  _csv_has "$depsA" "$ordB" && { printf 'serial\tdependency:%s' "$ordB"; return; }
  _csv_has "$depsB" "$ordA" && { printf 'serial\tdependency:%s' "$ordA"; return; }
  ov="$(paths_overlap "$touchA" "$touchB")" && [ -n "$ov" ] && { printf 'serial\tshared-file:%s' "$ov"; return; }
  printf 'parallel'
}

# humanize_reason <reason> → a report-friendly clause.
humanize_reason() {
  case "$1" in
    unannotated:*) printf '%s carries no Depends-on/Touches annotations (annotate to unlock fan-out)' "${1#unannotated:}" ;;
    dependency:*)  printf 'depends on %s' "${1#dependency:}" ;;
    shared-file:*) printf 'shares %s' "${1#shared-file:}" ;;
    unreadable:*)  printf "%s's body could not be read (gh offline/unavailable)" "${1#unreadable:}" ;;
    *)             printf '%s' "$1" ;;
  esac
}

# ── I/O gatherer (overridable by env; bypassed entirely by --self-test) ───────────────────────────────
# gather_bodies <n...> → a single blob: `@@ITEM <n>` separator then that issue's body (or `@@UNREADABLE`).
gather_bodies() {
  [ -n "${FO_FIXTURE+x}" ] && { printf '%s' "$FO_FIXTURE"; return; }
  local n have_gh=1
  { [ -n "${FO_OFFLINE:-}" ] || ! command -v gh >/dev/null 2>&1; } && have_gh=0
  for n in "$@"; do
    printf '@@ITEM %s\n' "$n"
    if [ "$have_gh" = 1 ] && gh issue view "$n" --json body -q .body >/tmp/.fo_body.$$ 2>/dev/null; then
      cat /tmp/.fo_body.$$; printf '\n'
    else
      printf '@@UNREADABLE\n'
    fi
  done
  rm -f /tmp/.fo_body.$$ 2>/dev/null
}

# _body_of <n> — extract issue <n>'s body from $BODIES_BLOB (set by run_advise).
_body_of() {
  awk -v want="@@ITEM $1" '$0==want{g=1;next} /^@@ITEM /{g=0} g{print}' <<< "$BODIES_BLOB"
}

# ── the driver — parse the next-N, compute every pair + the greedy wave, render both forms ────────────
run_advise() {
  local machine=0
  [ "${1:-}" = "--machine" ] && { machine=1; shift; }
  [ "$#" -lt 1 ] && { printf 'usage: fan-out-advisement.sh [--machine] <issue#> [<issue#> ...]\n' >&2; return 2; }
  local -a ISS=("$@") ORD=() ST=() DEP=() TCH=()
  BODIES_BLOB="$(gather_bodies "${ISS[@]}")"

  local n body
  for n in "${ISS[@]}"; do
    body="$(_body_of "$n")"
    ORD+=("$(parse_order "$body")"); ST+=("$(item_state "$body")")
    DEP+=("$(parse_deps "$body")"); TCH+=("$(parse_touches "$body")")
  done
  local N=${#ISS[@]}

  # order→present? and issue→present? (for depends-outside vs misannotated-issue-number notes)
  local present=" " issset=" "; local k
  for ((k=0; k<N; k++)); do present+="${ORD[$k]} "; issset+="${ISS[$k]} "; done

  # machine header + item lines.
  local out=""
  out+="schema	1"$'\n'
  for ((k=0; k<N; k++)); do out+="item	${ISS[$k]}	${ORD[$k]:-?}	${ST[$k]}"$'\n'; done

  # all pairs (i<j).
  local i j v kind reason
  for ((i=0; i<N; i++)); do
    for ((j=i+1; j<N; j++)); do
      v="$(pair_verdict "${ST[$i]}" "${ORD[$i]}" "${DEP[$i]}" "${TCH[$i]}" "${ISS[$i]}" \
                        "${ST[$j]}" "${ORD[$j]}" "${DEP[$j]}" "${TCH[$j]}" "${ISS[$j]}")"
      kind="${v%%$'\t'*}"; reason="${v#*$'\t'}"; [ "$kind" = parallel ] && reason=""
      out+="pair	${ISS[$i]}	${ISS[$j]}	${kind}	${reason}"$'\n'
    done
  done

  # depends-outside notes (a dep on an item not in the given set — surfaced, never flips a verdict).
  local d
  for ((i=0; i<N; i++)); do
    [ "${DEP[$i]}" = MISSING ] || [ "${DEP[$i]}" = none ] && continue
    local IFS=','
    for d in ${DEP[$i]}; do
      d="${d//[[:space:]]/}"; [ -z "$d" ] && continue
      case "$present" in
        *" $d "*) : ;;  # a real in-set order dependency — already handled by pair_verdict.
        *) case "$issset" in
             # a dep token that is an ISSUE number in the set is a two-number-space mis-authoring
             # (deps must be orders) — say so distinctly rather than the misleading "depends-outside".
             *" $d "*) out+="note	${ISS[$i]}	misannotated-issue-number:${d}"$'\n' ;;
             *)        out+="note	${ISS[$i]}	depends-outside:${d}"$'\n' ;;
           esac ;;
      esac
    done
    unset IFS
  done

  # greedy PREFIX wave — walk in given order; an item joins iff parallel with every current member.
  local -a WAVE=() HELD=() HELDR=()
  for ((i=0; i<N; i++)); do
    local ok=1 blk=""
    local w
    for w in "${WAVE[@]}"; do
      # WAVE stores positions; compare item i with member position w.
      v="$(pair_verdict "${ST[$i]}" "${ORD[$i]}" "${DEP[$i]}" "${TCH[$i]}" "${ISS[$i]}" \
                        "${ST[$w]}" "${ORD[$w]}" "${DEP[$w]}" "${TCH[$w]}" "${ISS[$w]}")"
      if [ "${v%%$'\t'*}" = serial ]; then ok=0; blk="${v#*$'\t'}"; break; fi
    done
    if [ "$ok" = 1 ]; then WAVE+=("$i"); else HELD+=("$i"); HELDR+=("$blk"); fi
  done

  for w in "${WAVE[@]}"; do out+="wave	${ISS[$w]}"$'\n'; done
  for ((i=0; i<${#HELD[@]}; i++)); do out+="held	${ISS[${HELD[$i]}]}	${HELDR[$i]}"$'\n'; done
  out+="constraint	serialized-merge"$'\n'

  # the human advisement sentence (also embedded as the `advice` machine line).
  local advice
  advice="$(_advice_sentence)"
  out+="advice	${advice}"$'\n'

  if [ "$machine" = 1 ]; then printf '%s' "$out"; return 0; fi
  # human render.
  printf "%b%s%b\n" "$bold" "Fan-out advisement — EPIC 0071 / CS3" "$reset"
  printf "  %s\n" "$advice"
  return 0
}

# _advice_sentence — build the honest prose from WAVE/HELD (reads the driver's locals via dynamic scope).
_advice_sentence() {
  local wave_issues=() h
  for w in "${WAVE[@]}"; do wave_issues+=("#${ISS[$w]}"); done
  local s=""
  if [ "${#WAVE[@]}" -ge 2 ]; then
    s="the next ${#WAVE[@]} — $(_join ', ' "${wave_issues[@]}") — can be built in parallel (no declared dependency, disjoint touched-files)."
  else
    s="the next ${N} must go one at a time."
  fi
  for ((h=0; h<${#HELD[@]}; h++)); do
    s+=" #${ISS[${HELD[$h]}]} held: $(humanize_reason "${HELDR[$h]}")."
  done
  s+=" GitHub/board writes and the merge serialize — a fan-out is parallel build + review, then a serialized merge + STATE update, not an atomic merge."
  printf '%s' "$s"
}

_join() { local sep="$1"; shift; local out="" x; for x in "$@"; do out+="${out:+$sep}$x"; done; printf '%s' "$out"; }

# ── self-test: exercise the pure classifiers + a full --machine run via FO_FIXTURE. Derived row count. ─
self_test() {
  local failures=0 total=0
  unset FO_FIXTURE FO_OFFLINE   # HERMETIC — no ambient fixture may leak into a row.
  eq() { total=$((total+1)); if [ "$2" = "$1" ]; then printf "  %b✓%b %s\n" "$green" "$reset" "$3"
    else printf "  %b✗ %s (want '%s', got '%s')%b\n" "$red" "$3" "$1" "$2" "$reset"; failures=$((failures+1)); fi; }
  # has <label> <blob> <ERE> — assert the pattern IS present (if/then avoids SC2015's A&&B||C form).
  has() { total=$((total+1)); if printf '%s\n' "$2" | grep -qE "$3"; then printf "  %b✓%b %s\n" "$green" "$reset" "$1"
    else printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; failures=$((failures+1)); fi; }
  printf "%b%s%b\n" "$bold" "fan-out-advisement.sh --self-test" "$reset"

  # parse_order — from the marker.
  eq 0071.003 "$(parse_order 'blah <!-- pipeline-plan-0071.003 --> more')" "parse_order: plan marker → 0071.003"
  eq 0071     "$(parse_order '<!-- pipeline-epic-0071 -->')"               "parse_order: epic marker → 0071"

  # parse_deps / parse_touches — MISSING vs none vs csv; line-anchored.
  eq MISSING  "$(parse_deps 'a body with no trailer')"                     "parse_deps: no trailer → MISSING"
  eq none     "$(parse_deps 'x'$'\n''Depends-on: none')"                   "parse_deps: 'none' → none"
  eq "0071.002, 0071.003" "$(parse_deps 'Depends-on: 0071.002, 0071.003')" "parse_deps: csv preserved"
  eq MISSING  "$(parse_deps 'see the Depends-on: field docs mid-line')"    "parse_deps: mid-line prose NOT parsed (anchored)"
  eq MISSING  "$(parse_touches 'no trailer here')"                         "parse_touches: no trailer → MISSING"
  eq "scripts/x.sh, docs/roadmap/" "$(parse_touches 'Touches: scripts/x.sh, docs/roadmap/')" "parse_touches: csv preserved"

  # item_state.
  eq unreadable  "$(item_state '@@UNREADABLE')"                                          "item_state: unreadable"
  eq unannotated "$(item_state 'Depends-on: none')"                                      "item_state: deps but no Touches → unannotated"
  eq annotated   "$(item_state 'Depends-on: none'$'\n''Touches: scripts/x.sh')"          "item_state: both trailers → annotated"
  # Finding 1 pins — a present-but-EMPTY value must fail to unannotated, never sail through as annotated.
  eq unannotated "$(item_state 'Depends-on: none'$'\n''Touches:')"                       "item_state: blank Touches value → unannotated (Finding 1)"
  eq unannotated "$(item_state 'Depends-on: none'$'\n''Touches:   ')"                     "item_state: whitespace-only Touches → unannotated"
  eq unannotated "$(item_state 'Depends-on: none'$'\n''Touches: ,')"                      "item_state: comma-only Touches → unannotated"
  eq unannotated "$(item_state 'Depends-on:'$'\n''Touches: a.sh')"                        "item_state: blank Depends-on value → unannotated"
  eq annotated   "$(item_state 'Depends-on: none'$'\n''Touches: a.sh')"                   "item_state: 'none' deps survive (non-empty sentinel)"

  # _csv_has / _path_match / paths_overlap (exit-code / value asserts — no A&&B||C, so shellcheck-clean).
  _csv_has "0071.002, 0071.003" 0071.003; eq 0 "$?" "_csv_has: token present → rc0"
  _csv_has "0071.002" 0071.009;           eq 1 "$?" "_csv_has: token absent → rc1"
  eq scripts/x.sh "$(paths_overlap 'scripts/x.sh, a.md' 'b.md, scripts/x.sh')" "paths_overlap: equal path → hit"
  eq scripts/     "$(paths_overlap 'scripts/' 'scripts/verify.sh')"            "paths_overlap: dir prefix → hit"
  paths_overlap 'scripts/foo.sh' 'scripts/foo.sh.bak' >/dev/null; eq 1 "$?"    "paths_overlap: non-boundary prefix → miss (rc1)"

  # pair_verdict — precedence + each reason.
  eq parallel "$(pair_verdict annotated 0071.003 none 'a.sh' 330 annotated 0071.004 none 'b.sh' 331)" "pair_verdict: independent+disjoint → parallel"
  eq "$(printf 'serial\tdependency:0071.003')" "$(pair_verdict annotated 0071.003 none 'a.sh' 330 annotated 0071.004 0071.003 'b.sh' 331)" "pair_verdict: B depends on A → serial dependency"
  eq "$(printf 'serial\tshared-file:clear-safe.md')" "$(pair_verdict annotated 0071.003 none 'clear-safe.md' 330 annotated 0071.004 none 'clear-safe.md, x.sh' 331)" "pair_verdict: shared file → serial"
  eq "$(printf 'serial\tunannotated:#331')" "$(pair_verdict annotated 0071.003 none 'a.sh' 330 unannotated 0071.004 MISSING MISSING 331)" "pair_verdict: unannotated → serial (precedence over disjoint)"
  eq "$(printf 'serial\tunreadable:#330')" "$(pair_verdict unreadable 0071.003 MISSING MISSING 330 unannotated 0071.004 MISSING MISSING 331)" "pair_verdict: unreadable wins over unannotated"

  # ── full --machine runs through FO_FIXTURE ──
  local m
  # two annotated, independent, disjoint → both in wave, parallel pair.
  m="$(FO_FIXTURE="$(printf '@@ITEM 330\n<!-- pipeline-plan-0071.003 -->\nDepends-on: none\nTouches: scripts/fan-out-advisement.sh\n@@ITEM 331\n<!-- pipeline-plan-0071.004 -->\nDepends-on: none\nTouches: scripts/resume-workflow.sh\n')" run_advise --machine 330 331)"
  has "machine: independent disjoint → parallel pair" "$m" '^pair	330	331	parallel'
  eq 2 "$(printf '%s\n' "$m" | grep -c '^wave	')"                 "machine: both items in wave"
  has "machine: serialized-merge constraint emitted" "$m" '^constraint	serialized-merge'

  # Finding 1 smoking-gun pin: both slices REALLY edit clear-safe.md, but #330 left Touches blank.
  # Must NOT be falsely parallel — the blank value degrades #330 to unannotated ⇒ serial.
  m="$(FO_FIXTURE="$(printf '@@ITEM 330\n<!-- pipeline-plan-0071.003 -->\nDepends-on: none\nTouches:\n@@ITEM 331\n<!-- pipeline-plan-0071.004 -->\nDepends-on: none\nTouches: clear-safe.md\n')" run_advise --machine 330 331)"
  has "machine: blank Touches ⇒ serial, NOT falsely parallel (Finding 1)" "$m" '^pair	330	331	serial	unannotated'

  # dependency → held.
  m="$(FO_FIXTURE="$(printf '@@ITEM 330\n<!-- pipeline-plan-0071.003 -->\nDepends-on: none\nTouches: a.sh\n@@ITEM 331\n<!-- pipeline-plan-0071.004 -->\nDepends-on: 0071.003\nTouches: b.sh\n')" run_advise --machine 330 331)"
  has "machine: dependent item held with dependency reason" "$m" '^held	331	dependency:0071.003'

  # unreadable (offline) → all serial.
  m="$(FO_FIXTURE="$(printf '@@ITEM 330\n@@UNREADABLE\n@@ITEM 331\n@@UNREADABLE\n')" run_advise --machine 330 331)"
  has "machine: unreadable bodies → serial" "$m" '^pair	330	331	serial	unreadable'

  # depends-outside note (dep ORDER not in the given set).
  m="$(FO_FIXTURE="$(printf '@@ITEM 330\n<!-- pipeline-plan-0071.003 -->\nDepends-on: 0068.009\nTouches: a.sh\n')" run_advise --machine 330)"
  has "machine: dep outside set → depends-outside note" "$m" '^note	330	depends-outside:0068.009'

  # Finding 2 pin: an ISSUE number in Depends-on (wrong number space) → distinct misannotated note.
  m="$(FO_FIXTURE="$(printf '@@ITEM 330\n<!-- pipeline-plan-0071.003 -->\nDepends-on: 331\nTouches: a.sh\n@@ITEM 331\n<!-- pipeline-plan-0071.004 -->\nDepends-on: none\nTouches: b.sh\n')" run_advise --machine 330 331)"
  has "machine: issue# in Depends-on → misannotated-issue-number note (Finding 2)" "$m" '^note	330	misannotated-issue-number:331'

  # constraint emitted even with an EMPTY-ish wave-of-one (single unannotated item).
  m="$(FO_FIXTURE="$(printf '@@ITEM 331\n<!-- pipeline-plan-0071.004 -->\n')" run_advise --machine 331)"
  has "machine: constraint emitted for single unannotated item" "$m" '^constraint	serialized-merge'

  # usage — no args → exit 2.
  ( run_advise ) >/dev/null 2>&1; eq 2 "$?" "usage: no args → exit 2"

  if [ "$failures" -eq 0 ]; then printf "%b✓ self-test passed (%d rows)%b\n" "$green" "$total" "$reset"; return 0
  else printf "%b✗ self-test: %d of %d row(s) failed%b\n" "$red" "$failures" "$total" "$reset"; return 1; fi
}

case "${1:-}" in
  --self-test) self_test ;;
  -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
  --machine) run_advise "$@" ;;
  "") printf 'usage: fan-out-advisement.sh [--machine] <issue#> [<issue#> ...]\n' >&2; exit 2 ;;
  *) run_advise "$@" ;;
esac
