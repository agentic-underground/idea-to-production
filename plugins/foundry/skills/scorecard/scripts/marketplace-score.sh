#!/usr/bin/env bash
# marketplace-score.sh — deterministic MARKETPLACE (plugin) improvement scorecard.
#
# Proves the marketplace is getting better over time by measuring ARTIFACTS — inspector findings,
# merged self-improve PRs, canonical-copy integrity, portability violations — never self-reported scores.
# Appends one event line to .foundry/MARKETPLACE_SCORECARD.jsonl and prints a summary.
#
# Usage:  marketplace-score.sh [marketplace-root]   (default: cwd; must be the marketplace source tree)
# Deps:   jq; gh optional (for merged-PR count). Exit 0 always.

set -uo pipefail
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "marketplace-score: cannot cd to $ROOT" >&2; exit 0; }
[[ -d plugins ]] || { echo "marketplace-score: $ROOT is not a marketplace source tree (no plugins/)" >&2; exit 0; }

# ---- canonical-copy integrity (booleans) ----
check_identical() {
  local n; n=$(md5sum $1 2>/dev/null | awk '{print $1}' | sort -u | wc -l | tr -d ' ')
  [[ "$n" == "1" ]] && echo true || echo false
}
check_sh_ok=$(check_identical "plugins/*/skills/check/scripts/check.sh")
core_ok=$(check_identical "plugins/*/knowledge/inspection-core.md")

# ---- portability violations: live ~/.claude couplings outside the allowlisted archive ----
# (mirrors the inspection-core portability sweep). Exclude the allowlisted archive AND the files that
# legitimately DESCRIBE the ~/.claude policy rather than couple to it (inspection-core.md, the inspector
# agents, and the foundry portability/policy knowledge) — those are policy text, not couplings.
port_viol=$(grep -rIn '~/\.claude' plugins/ 2>/dev/null \
  | grep -vE '/(docs/HISTORY|docs/MIGRATION|docs/DEPRECATED)\.md|/examples/|/doc/historical/' \
  | grep -vE '/knowledge/inspection-core\.md|/agents/inspector\.md|/knowledge/(policy|protocols)/' \
  | wc -l | tr -d ' ')

# integer-count of a header pattern in a file (grep -c prints "0" and exits 1 on no match — capture
# stdout, ignore the exit code, never let `|| echo 0` append a second line)
count_hdr() { local n; n=$(grep -cE "$1" "$2" 2>/dev/null); echo "${n:-0}"; }

# ---- inspection findings: tally the latest *_INSPECTION_REPORT.md in the tree, if any ----
crit=0 warn=0 sugg=0 reports=0
while IFS= read -r r; do
  [[ -z "$r" ]] && continue
  reports=$(( reports + 1 ))
  crit=$(( crit + $(count_hdr '^### CRITICAL' "$r") ))
  warn=$(( warn + $(count_hdr '^### WARNING' "$r") ))
  sugg=$(( sugg + $(count_hdr '^### SUGGESTION' "$r") ))
done < <(find . -maxdepth 2 -name '*_INSPECTION_REPORT.md' 2>/dev/null)

# ---- merged self-improve PRs (gh optional) ----
selfimprove_prs=null
if command -v gh >/dev/null 2>&1; then
  n=$(gh pr list --state merged --search 'self-improve in:title' --json number -q 'length' 2>/dev/null)
  [[ -n "$n" ]] && selfimprove_prs=$n
fi

# ---- plugin/skill/agent/command counts (growth signal) ----
plugins_n=$(find plugins -maxdepth 3 -path '*/.claude-plugin/plugin.json' 2>/dev/null | wc -l | tr -d ' ')
skills_n=$(find plugins -path '*/skills/*/SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
agents_n=$(find plugins -path '*/agents/*.md' 2>/dev/null | wc -l | tr -d ' ')
commands_n=$(find plugins -path '*/commands/*.md' 2>/dev/null | wc -l | tr -d ' ')
inspect_n=$(find plugins -path '*/commands/inspect.md' 2>/dev/null | wc -l | tr -d ' ')
selfimprove_n=$(find plugins -path '*/skills/self-improve/SKILL.md' 2>/dev/null | wc -l | tr -d ' ')

ts="${SCORECARD_TS:-}"
mkdir -p .foundry
line=$(jq -nc \
  --arg ts "$ts" \
  --argjson check "$check_sh_ok" --argjson core "$core_ok" --argjson port "$port_viol" \
  --argjson crit "$crit" --argjson warn "$warn" --argjson sugg "$sugg" --argjson reports "$reports" \
  --argjson prs "$selfimprove_prs" \
  --argjson plugins "$plugins_n" --argjson skills "$skills_n" --argjson agents "$agents_n" \
  --argjson commands "$commands_n" --argjson inspect "$inspect_n" --argjson selfimp "$selfimprove_n" \
  '{schema:"marketplace-scorecard/1.0", ts:$ts, event:"score",
    integrity:{check_sh_identical:$check, inspection_core_identical:$core, portability_violations:$port},
    inspection:{reports_seen:$reports, critical:$crit, warning:$warn, suggestion:$sugg},
    self_improve_prs_merged:$prs,
    coverage_of_self:{plugins:$plugins, skills:$skills, agents:$agents, commands:$commands,
                      inspect_commands:$inspect, self_improve_skills:$selfimp}}')
echo "$line" >> .foundry/MARKETPLACE_SCORECARD.jsonl

echo "MARKETPLACE SCORECARD"
echo "  integrity: check.sh identical=$check_sh_ok  inspection-core identical=$core_ok  ~/.claude violations=$port_viol"
echo "  inspection: $reports report(s) — CRITICAL $crit / WARNING $warn / SUGGESTION $sugg"
echo "  self-improve PRs merged: $selfimprove_prs"
echo "  self-coverage: $plugins_n plugins · $skills_n skills · $agents_n agents · $commands_n commands · $inspect_n inspect · $selfimprove_n self-improve"
echo "  → appended to .foundry/MARKETPLACE_SCORECARD.jsonl"
