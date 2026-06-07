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

# ---- SENTINEL gate verdict ----
sec_verdict='"n/a"'
for s in SECURITY-REPORT.md doc/SECURITY-REPORT.md; do
  if [[ -f "$s" ]]; then
    v=$(grep -oE '\b(PASS|REVIEW|BLOCK)\b' "$s" | head -1)
    [[ -n "$v" ]] && sec_verdict="\"$v\""
    break
  fi
done

# Note: date is captured by the caller/agent; the script avoids embedding a timestamp so re-runs are
# deterministic. Pass one in via SCORECARD_TS if you want it recorded.
ts="${SCORECARD_TS:-}"

# ---- assemble SCORECARD.json ----
qq() { [[ "$1" == "$NA" || -z "$1" ]] && echo "null" || echo "\"$1\""; }
num() { [[ "$1" == "$NA" || -z "$1" ]] && echo "null" || echo "$1"; }

cat > SCORECARD.json <<EOF
{
  "schema": "product-scorecard/1.0",
  "generated_ts": $(qq "$ts"),
  "project": "$(basename "$ROOT")",
  "coverage": {
    "branch_pct": $(num "$cov_branch"),
    "line_pct": $(num "$cov_line"),
    "function_pct": $(num "$cov_fn"),
    "statement_pct": $(num "$cov_stmt")
  },
  "corpus": { "fixtures": $(num "$corpus_fixtures"), "false_positive_pct": $(num "$corpus_fp") },
  "rules": $(num "$rule_files"),
  "tests": $(qq "$test_count"),
  "security_gate": $sec_verdict,
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
echo "PRODUCT SCORECARD — $(basename "$ROOT")"
echo "  coverage:  branch ${cov_branch}%  line ${cov_line}%  fn ${cov_fn}%  stmt ${cov_stmt}%"
echo "  corpus:    ${corpus_fixtures} fixtures   FP ${corpus_fp}%"
echo "  rules:     ${rule_files}"
echo "  tests:     ${test_count}"
echo "  security:  $(echo "$sec_verdict" | tr -d '\"')"
_el="$elapsed_s"; [[ "$_el" != "$NA" ]] && _el="${_el}s"
echo "  cost:      tokens ${tokens_total}  elapsed ${_el}  regressions ${regressions}"
[[ -n "$cost_note" ]] && echo "             ($cost_note)"
echo "  → wrote SCORECARD.json"
