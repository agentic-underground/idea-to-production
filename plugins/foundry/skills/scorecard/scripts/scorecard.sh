#!/usr/bin/env bash
# scorecard.sh — deterministic PRODUCT quality scorecard.
#
# Measures ARTIFACTS, never self-reported scores — every number comes from a real file on disk, so it
# cannot be gamed. Reads only what is present and reports "n/a" for what is absent (honest by omission).
#
# Usage:  scorecard.sh [project-dir]   (default: cwd)
# Output: writes SCORECARD.json to the project root and prints a human summary to stdout.
# Deps:   jq. Exit 0 always.
#
# Sources (each optional):
#   coverage/coverage-summary.json   → branch/line/fn/stmt coverage % (Istanbul/nyc/vitest format)
#   tests/corpus/parity-baseline.json→ corpus fixture count + false-positive rate (if the project has one)
#   IDEA_COST.jsonl (root or doc/)   → real tokens / wall-clock / regressions from the last FOUNDRY cycle
#   SECURITY-REPORT.md               → SENTINEL gate verdict (PASS/REVIEW/BLOCK)
#   src/**/*.rules.* / rules/**      → rule count (detection-style products)
#   .i2p/degraded-capabilities.json  → degraded lenses (P1-17) → coverage is PARTIAL, never a silent PASS
#
# Degraded-capabilities contract (P1-17): per
# plugins/foundry/knowledge/protocols/degraded-capabilities.md §3.3 — "Never count a non-run as a pass."
# When a lens that PRODUCES a measured dimension is degraded, the dimension is labelled PARTIAL and the
# missing lens is NAMED, so "0 findings because clean" is never confused with "0 because the lens didn't
# run". A missing state file means "no known degradation" (NOT an error) → normal full report.

set -uo pipefail
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "scorecard: cannot cd to $ROOT" >&2; exit 0; }

jqr() { jq -r "$1" "$2" 2>/dev/null; }
NA='null'

# ---- coverage (Istanbul/nyc/vitest coverage-summary.json) ----
cov_branch=$NA cov_line=$NA cov_fn=$NA cov_stmt=$NA
covf=""
for c in coverage/coverage-summary.json coverage/coverage-final.json .nyc_output/coverage-summary.json; do
  [[ -f "$c" ]] && { covf="$c"; break; }
done
if [[ -n "$covf" && -f "$covf" ]]; then
  cov_branch=$(jqr '.total.branches.pct // empty' "$covf"); cov_branch=${cov_branch:-$NA}
  cov_line=$(jqr '.total.lines.pct // empty' "$covf"); cov_line=${cov_line:-$NA}
  cov_fn=$(jqr '.total.functions.pct // empty' "$covf"); cov_fn=${cov_fn:-$NA}
  cov_stmt=$(jqr '.total.statements.pct // empty' "$covf"); cov_stmt=${cov_stmt:-$NA}
fi

# ---- corpus false-positive rate (project-specific; optional) ----
corpus_fixtures=$NA corpus_fp=$NA
pb="tests/corpus/parity-baseline.json"
if [[ -f "$pb" ]]; then
  corpus_fixtures=$(jq -r 'if type=="array" then length elif .fixtures then (.fixtures|length) else (keys|length) end' "$pb" 2>/dev/null); corpus_fixtures=${corpus_fixtures:-$NA}
fi

# ---- rule count (detection-style products; optional) ----
rule_files=$NA
rc=$(find src rules -type f \( -name '*.rules.ts' -o -name '*.rules.js' -o -name '*.rule.json' \) 2>/dev/null | wc -l | tr -d ' ')
[[ "$rc" -gt 0 ]] && rule_files=$rc

# ---- test count (IDEA_COST authoritative; else heuristic file count) ----
test_count=$NA
icost=""
for f in IDEA_COST.jsonl doc/IDEA_COST.jsonl; do [[ -f "$f" ]] && { icost="$f"; break; }; done

# Read the LAST VALID JSON object line-wise — never slurp (`jq -s`). A single malformed
# line in IDEA_COST.jsonl must NOT zero every metric: skip corrupt lines, keep the last
# good record. `jq -c .` drops any line it can't parse (2>/dev/null swallows the per-line
# error); `tail -1` takes the most recent survivor. Then each field is read from $icost_last
# with a plain `jq -r` (no -s). If a corrupt line was skipped, warn once on stderr.
icost_last=""
if [[ -n "$icost" ]]; then
  icost_last=$(grep -v '^[[:space:]]*$' "$icost" | jq -c . 2>/dev/null | tail -1)
  _icost_nonblank=$(grep -cv '^[[:space:]]*$' "$icost")
  _icost_valid=$(grep -v '^[[:space:]]*$' "$icost" | jq -c . 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$_icost_nonblank" -gt "$_icost_valid" ]]; then
    echo "scorecard: WARNING — $((_icost_nonblank - _icost_valid)) malformed line(s) in $icost skipped; using last valid record" >&2
  fi
fi
icf() { [[ -n "$icost_last" ]] && printf '%s' "$icost_last" | jq -r "$1 // empty" 2>/dev/null; }

if [[ -n "$icost_last" ]]; then
  test_count=$(icf '.artefact_counts.test_count_total'); test_count=${test_count:-$NA}
fi
if [[ "$test_count" == "$NA" ]]; then
  tc=$(grep -rlE "\b(it|test|describe)\(|def test_|@Test" \
        --include='*.test.*' --include='*.spec.*' --include='test_*.py' . 2>/dev/null | wc -l | tr -d ' ')
  [[ "$tc" -gt 0 ]] && test_count="${tc} files"
fi

# ---- real cost from the last FOUNDRY cycle (only a real cycle can record tokens) ----
tokens_total=$NA elapsed_s=$NA regressions=$NA est_acc=$NA cost_note=""
if [[ -n "$icost_last" ]]; then
  tokens_total=$(icf '.token_accounting.tokens_total'); tokens_total=${tokens_total:-$NA}
  elapsed_s=$(icf '.time_accounting.elapsed_s'); elapsed_s=${elapsed_s:-$NA}
  regressions=$(icf '.quality.regressions_introduced'); regressions=${regressions:-$NA}
  est_acc=$(icf '.token_accounting.estimation_accuracy_pct'); est_acc=${est_acc:-$NA}
elif [[ -z "$icost" ]]; then
  cost_note="no IDEA_COST.jsonl — token/wall-clock omitted (only a real FOUNDRY cycle records them)"
else
  cost_note="IDEA_COST.jsonl present but no valid record — token/wall-clock omitted"
fi

# ---- P2-1: coverage regression vs the last-N baseline records (detect-auto, flag only) ----
# IDEA_COST.jsonl is the tracked per-run ledger (one record per cycle). A run can regress coverage
# silently — branch coverage drops with no justification. Here we compare the CURRENT run's branch
# coverage (the live coverage-summary.json above, falling back to the last record's recorded value)
# against the WORST of the previous N records' `quality.final_branch_coverage_pct`, and FLAG a drop.
#
# This is additive and tolerant by design: older records that predate the field are simply skipped
# (`select(...!=null)`), so the baseline shrinks gracefully rather than erroring. The flag is a
# scorecard signal, never an exit-1 — a regression may be legitimate, so a run can JUSTIFY it by
# carrying a pragma marker on its record (`quality.coverage_regression_pragma`, a non-empty reason
# string); when present the drop is recorded as justified and not flagged. N is small (5) so the
# baseline tracks recent reality, not ancient history.
COV_BASELINE_N=5
cov_regression=null        # null = not evaluated; true/false once we have a baseline + a current value
cov_baseline_min=$NA cov_regression_pragma="" cov_baseline_count=0
if [[ -n "$icost" ]]; then
  # Current branch coverage: prefer the live coverage file (already parsed above), else the last
  # record's own recorded branch coverage (so a run with no fresh coverage file still compares).
  cov_now="$cov_branch"
  if [[ "$cov_now" == "$NA" && -n "$icost_last" ]]; then
    cov_now=$(printf '%s' "$icost_last" | jq -r '.quality.final_branch_coverage_pct // empty' 2>/dev/null)
    cov_now=${cov_now:-$NA}
  fi
  # Previous N records' branch coverage (exclude the current/last record itself), worst (min) = the
  # baseline floor a non-justified run must not fall below.
  read -r cov_baseline_min cov_baseline_count < <(
    grep -v '^[[:space:]]*$' "$icost" | jq -c . 2>/dev/null | head -n -1 \
      | tail -n "$COV_BASELINE_N" \
      | jq -rs '[ .[] | .quality.final_branch_coverage_pct | select(. != null) ]
                | if length==0 then "null 0" else "\(min) \(length)" end' 2>/dev/null
  )
  cov_baseline_min=${cov_baseline_min:-$NA}; cov_baseline_count=${cov_baseline_count:-0}
  # The justifying pragma on the current run's record (additive; absent → unjustified).
  if [[ -n "$icost_last" ]]; then
    cov_regression_pragma=$(printf '%s' "$icost_last" | jq -r '.quality.coverage_regression_pragma // empty' 2>/dev/null)
  fi
  if [[ "$cov_now" != "$NA" && "$cov_baseline_min" != "$NA" && "$cov_baseline_count" -gt 0 ]]; then
    if awk "BEGIN{exit !($cov_now < $cov_baseline_min)}"; then
      # A drop below the recent floor. Justified only if a pragma reason is present on the record.
      if [[ -n "$cov_regression_pragma" ]]; then cov_regression=false; else cov_regression=true; fi
    else
      cov_regression=false
    fi
  fi
fi

# ---- SENTINEL gate verdict ----
sec_verdict='"n/a"'
for s in SECURITY-REPORT.md doc/SECURITY-REPORT.md; do
  if [[ -f "$s" ]]; then
    v=$(grep -oE '\b(PASS|REVIEW|BLOCK)\b' "$s" | head -1)
    [[ -n "$v" ]] && sec_verdict="\"$v\""
    break
  fi
done

# ---- degraded capabilities (P1-17 — never count a non-run as a pass) ----
# Read <project>/.i2p/degraded-capabilities.json (the authoritative state-file carrier, §1).
# A missing file = no known degradation = normal full report (NOT an error). For each degraded
# `capability`, route the affected scorecard dimension to PARTIAL and name the missing lens.
#
# capability family → affected dimension:
#   lens.security  → security_gate         (the security lens did not run)
#   lens.coverage  → coverage.*            (a coverage/test lens did not run)
#   lens.corpus    → corpus.*              (the corpus parity lens did not run)
#   tool.*/mcp.*   → recorded as a degradation note (may narrow a dimension a producer mapped to it)
degraded_security=0 degraded_coverage=0 degraded_corpus=0
degraded_names=()        # one element per degradation: "capability (reason; since since_phase)"
dcf=".i2p/degraded-capabilities.json"
if [[ -f "$dcf" ]]; then
  # Enumerate degraded records tolerantly (readers tolerate extra keys; tolerate a malformed file).
  while IFS=$'\t' read -r cap reason since; do
    [[ -z "$cap" ]] && continue
    case "$cap" in
      lens.security*) degraded_security=1 ;;
      lens.coverage*) degraded_coverage=1 ;;
      lens.corpus*)   degraded_corpus=1 ;;
    esac
    degraded_names+=("${cap} (${reason:-unavailable}; since ${since:-?})")
  done < <(jq -r '.degraded[]? | [.capability, (.reason // "unavailable"), (.since_phase // "?")] | @tsv' "$dcf" 2>/dev/null)
fi

# Apply PARTIAL labelling. A degraded lens turns its dimension to "partial" — distinct from a clean
# numeric/PASS — so a reader can tell "0 because clean" from "0 because the lens didn't run".
sec_status="full"; cov_status="full"; corpus_status="full"
if [[ "$degraded_security" == 1 ]]; then sec_verdict='"PARTIAL"'; sec_status="partial"; fi
[[ "$degraded_coverage" == 1 ]] && cov_status="partial"
[[ "$degraded_corpus" == 1 ]] && corpus_status="partial"

# Note: date is captured by the caller/agent; the script avoids embedding a timestamp so re-runs are
# deterministic. Pass one in via SCORECARD_TS if you want it recorded.
ts="${SCORECARD_TS:-}"

# ---- assemble SCORECARD.json ----
qq() { [[ "$1" == "$NA" || -z "$1" ]] && echo "null" || echo "\"$1\""; }
num() { [[ "$1" == "$NA" || -z "$1" ]] && echo "null" || echo "$1"; }

# degraded block — a machine-readable list of the lenses that did NOT run (empty array = none).
degraded_json="[]"
if [[ -f "$dcf" ]]; then
  degraded_json="$(jq -c '[.degraded[]? | {capability, reason: (.reason // "unavailable"), since_phase: (.since_phase // null)}]' "$dcf" 2>/dev/null)"
  [[ -z "$degraded_json" || "$degraded_json" == "null" ]] && degraded_json="[]"
fi

cat > SCORECARD.json <<EOF
{
  "schema": "product-scorecard/1.0",
  "generated_ts": $(qq "$ts"),
  "project": "$(basename "$ROOT")",
  "coverage": {
    "status": "$cov_status",
    "branch_pct": $(num "$cov_branch"),
    "line_pct": $(num "$cov_line"),
    "function_pct": $(num "$cov_fn"),
    "statement_pct": $(num "$cov_stmt")
  },
  "coverage_regression": {
    "flagged": $cov_regression,
    "baseline_n": $cov_baseline_count,
    "baseline_min_branch_pct": $(num "$cov_baseline_min"),
    "current_branch_pct": $(num "${cov_now:-$NA}"),
    "justified_by_pragma": $([[ -n "$cov_regression_pragma" ]] && echo "true" || echo "false")
  },
  "corpus": { "status": "$corpus_status", "fixtures": $(num "$corpus_fixtures"), "false_positive_pct": $(num "$corpus_fp") },
  "rules": $(num "$rule_files"),
  "tests": $(qq "$test_count"),
  "security_gate": $sec_verdict,
  "security_status": "$sec_status",
  "degraded": $degraded_json,
  "cost": {
    "tokens_total": $(num "$tokens_total"),
    "elapsed_s": $(num "$elapsed_s"),
    "regressions_introduced": $(num "$regressions"),
    "estimation_accuracy_pct": $(num "$est_acc"),
    "note": $(qq "$cost_note")
  }
}
EOF

# ---- human summary ----
_cov_tag=""; [[ "$cov_status" == "partial" ]] && _cov_tag="  [PARTIAL — coverage lens did not run]"
_corpus_tag=""; [[ "$corpus_status" == "partial" ]] && _corpus_tag="  [PARTIAL — corpus lens did not run]"
echo "PRODUCT SCORECARD — $(basename "$ROOT")"
echo "  coverage:  branch ${cov_branch}%  line ${cov_line}%  fn ${cov_fn}%  stmt ${cov_stmt}%${_cov_tag}"
# P2-1: coverage regression vs the last-N (=${COV_BASELINE_N}) IDEA_COST baselines — flag only, never blocks.
if [[ "$cov_regression" == "true" ]]; then
  echo "  ⚠ REGRESSION: branch coverage ${cov_branch}% < recent floor ${cov_baseline_min}% (last ${cov_baseline_count} runs) with NO justifying pragma"
elif [[ "$cov_regression" == "false" && -n "$cov_regression_pragma" ]]; then
  echo "  coverage-Δ:  branch dropped below the ${cov_baseline_count}-run floor (${cov_baseline_min}%) — JUSTIFIED: ${cov_regression_pragma}"
elif [[ "$cov_baseline_count" -gt 0 && "$cov_branch" != "$NA" ]]; then
  echo "  coverage-Δ:  no regression — branch ${cov_branch}% ≥ ${cov_baseline_count}-run floor ${cov_baseline_min}%"
fi
echo "  corpus:    ${corpus_fixtures} fixtures   FP ${corpus_fp}%${_corpus_tag}"
echo "  rules:     ${rule_files}"
echo "  tests:     ${test_count}"
echo "  security:  $(echo "$sec_verdict" | tr -d '\"')$([[ "$sec_status" == "partial" ]] && echo "  [PARTIAL — security lens did not run]")"
_el="$elapsed_s"; [[ "$_el" != "$NA" ]] && _el="${_el}s"
echo "  cost:      tokens ${tokens_total}  elapsed ${_el}  regressions ${regressions}"
[[ -n "$cost_note" ]] && echo "             ($cost_note)"
# Disclose every degraded lens by name (the three contract fields) — never swallow the gap.
if [[ ${#degraded_names[@]} -gt 0 ]]; then
  echo "  COVERAGE IS PARTIAL — the following lens(es) did not run (0 findings ≠ 0 problems):"
  for _d in "${degraded_names[@]}"; do
    echo "    · ${_d}"
  done
fi
echo "  → wrote SCORECARD.json"
