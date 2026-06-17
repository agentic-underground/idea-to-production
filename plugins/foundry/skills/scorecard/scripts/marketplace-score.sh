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

# ---- portability violations: ILLEGITIMATE live ~/.claude couplings only ----
# Counts a coupling only where it is a real portability defect — a reference in an agent/hook/command/skill
# that SHOULD resolve through ${CLAUDE_PLUGIN_ROOT}. Excludes the references that LEGITIMATELY use ~/.claude
# and can never be zero:
#   • the allowlisted archive (docs/history, examples) and the policy text that DESCRIBES the rule
#     (inspection-core.md, inspector agents, foundry policy/protocols knowledge);
#   • the i2p status line + welcome hooks (statusline/ scripts + the statusline-install/statusline-widgets
#     skills + commands + the welcome/offer/drift hooks, folded in from the retired concierge) — they MUST
#     write ~/.claude because settings.json cannot expand ${CLAUDE_PLUGIN_ROOT}, and opt-out state lives
#     under ~/.claude/hook-state;
#   • i2p instrumentation + lifecycle cost state, which live under the global ~/.claude/state/ ledger;
#   • the scorecard's own files (this script, its SKILL/command/schema) and the glossary/self-improve prose
#     that name the metric — self-references, not couplings.
port_viol=$(grep -rIn '~/\.claude' plugins/ 2>/dev/null \
  | grep -vE '/(docs/HISTORY|docs/MIGRATION|docs/DEPRECATED)\.md|/examples/|/docs/historical/' \
  | grep -vE '/knowledge/inspection-core\.md|/agents/inspector\.md|/knowledge/(policy|protocols)/' \
  | grep -vE '/i2p/(statusline/|skills/statusline-install/|skills/statusline-widgets/|commands/statusline\.md|commands/statusline-widgets\.md|hooks/(offer-welcome|offer-statusline|offer-doc-alert|check-statusline-drift)\.sh)' \
  | grep -vE '/i2p/knowledge/instrumentation\.md|/i2p/skills/lifecycle/scripts/cost\.sh|/i2p/hooks/scripts/offer-cache-update\.sh' \
  | grep -vE '/foundry/skills/scorecard/|/foundry/commands/scorecard\.md|/foundry/knowledge/orchestration/scorecard-schema\.md|/foundry/knowledge/glossary\.md|/foundry/skills/self-improve/SKILL\.md' \
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

# ---- P2-13: canon-restatement detector (a scorecard TREND, not a gate) ----
# The self-architecture doc (knowledge/architecture/self-architecture.md §"The one real drift to fix")
# names agents restating canon — an inlined model-tier/pricing table, verbatim test-contract prose, or
# pasted SOLID definitions — as "the one thing to fix": a reverse edge into the pure `knowledge/` core.
# The fix is reference-WITH-a-certainty-marker, not a pasted copy. This detector counts the restatements
# that lack such a reference, so the number can TREND DOWN as self-improve replaces copies with citations.
#
# Per agent file we look for three restatement signals, and count one only when the SAME file carries NO
# citation to the canonical source (a `knowledge/...` path or a certainty marker on the relevant fact):
#   • model-tier  — a markdown TABLE ROW inlining a hardcoded model id (claude-haiku/sonnet/opus-*),
#                   the canon of which lives in knowledge/orchestration/tier-assignment.md;
#   • SOLID       — three or more of the five SOLID principle names spelled out as definitions,
#                   the canon of which lives in knowledge/architecture/solid.md;
#   • test-contract — the five-level performance-instrumented test-contract prose,
#                   the canon of which lives in knowledge/testing/test-policy.md.
# A file that NAMES the canonical doc (or marks the fact with a certainty marker) is referencing, not
# restating, and is NOT counted. Conservative by construction: a borderline file under-counts rather than
# inflating the trend.
canon_restatements=0
canon_files=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # Does this file cite the canon (a knowledge path) or mark the fact? Then its inlined facts are
  # references-with-context, not drift — skip the file's signals that have a matching citation.
  cites_tier=$(grep -cE 'knowledge/orchestration/tier-assignment|certainty-markers' "$f" 2>/dev/null); cites_tier=${cites_tier:-0}
  cites_solid=$(grep -cE 'knowledge/architecture/solid\.md|knowledge/architecture/clean-code' "$f" 2>/dev/null); cites_solid=${cites_solid:-0}
  cites_test=$(grep -cE 'knowledge/testing/test-policy|knowledge/testing/test-contract' "$f" 2>/dev/null); cites_test=${cites_test:-0}
  hit=0
  # model-tier table row with a hardcoded model id, and no tier-assignment citation
  if [[ "$cites_tier" -eq 0 ]] && grep -qE '^\|.*claude-(haiku|sonnet|opus)-[0-9]' "$f" 2>/dev/null; then
    hit=$(( hit + 1 ))
  fi
  # SOLID definitions inlined (≥3 of the 5 principle names), no solid.md citation
  if [[ "$cites_solid" -eq 0 ]]; then
    solid_n=$(grep -oiE 'single.responsibility|open.closed|liskov|interface.segregation|dependency.inversion' "$f" 2>/dev/null | sort -u | wc -l | tr -d ' ')
    [[ "$solid_n" -ge 3 ]] && hit=$(( hit + 1 ))
  fi
  # five-level test-contract prose inlined, no test-policy citation
  if [[ "$cites_test" -eq 0 ]] && grep -qiE 'five.level|5.level' "$f" 2>/dev/null && grep -qiE 'test.contract' "$f" 2>/dev/null; then
    hit=$(( hit + 1 ))
  fi
  if [[ "$hit" -gt 0 ]]; then
    canon_restatements=$(( canon_restatements + hit ))
    canon_files+=("${f#./}:${hit}")
  fi
done < <(find plugins -path '*/agents/*.md' 2>/dev/null)
canon_files_json=$(printf '%s\n' "${canon_files[@]}" | grep -v '^$' | jq -Rsc 'split("\n") | map(select(length>0))' 2>/dev/null)
[[ -z "$canon_files_json" || "$canon_files_json" == "null" ]] && canon_files_json="[]"

# ---- P2-17: per-element finding counts retained across runs (closed-loop regression measure) ----
# self-improve's covenant is "halve the distance to flawless" — but until now that was eyeballed at PR
# time: the ledger trended only AGGREGATE findings, so it could not assert that a SPECIFIC element
# (agent/skill/knowledge doc) got better. Here we tally findings PER ELEMENT from the inspection reports
# — each finding in inspection-core's format carries a `**File:** \`path\`` line, so the element is the
# path it points at — and emit a {element: count} map. self-improve's closed-loop assertion (documented
# in its SKILL.md) reads the PREVIOUS run's map from this same ledger and asserts the count for the
# element it just touched DROPPED run-over-run (or WARNS that it did not). Additive: readers that predate
# the field default to an empty map, so older ledger lines still parse.
# Stream every "**File:** `path`" finding path (one line per finding) into a tab/count rollup via jq —
# no associative array, so it stays robust under `set -u` (an empty array tripped `${#a[@]}` on some
# bash builds). `group_by` turns the path list into {path: count}; empty input → {}.
per_element_json=$(
  while IFS= read -r r; do
    [[ -z "$r" ]] && continue
    grep -oE '\*\*File:\*\*[[:space:]]*`[^`]+`' "$r" 2>/dev/null | grep -oE '`[^`]+`' | tr -d '`'
  done < <(find . -maxdepth 2 -name '*_INSPECTION_REPORT.md' 2>/dev/null) \
  | jq -Rsc 'split("\n") | map(select(length>0))
             | (group_by(.) | map({(.[0]): length}) | add) // {}' 2>/dev/null
)
[[ -z "$per_element_json" || "$per_element_json" == "null" ]] && per_element_json="{}"

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
  --argjson canon "$canon_restatements" --argjson canonfiles "$canon_files_json" \
  --argjson perelem "$per_element_json" \
  '{schema:"marketplace-scorecard/1.0", ts:$ts, event:"score",
    integrity:{check_sh_identical:$check, inspection_core_identical:$core, portability_violations:$port},
    inspection:{reports_seen:$reports, critical:$crit, warning:$warn, suggestion:$sugg},
    self_improve_prs_merged:$prs,
    canon_restatements:{count:$canon, files:$canonfiles},
    per_element_findings:$perelem,
    coverage_of_self:{plugins:$plugins, skills:$skills, agents:$agents, commands:$commands,
                      inspect_commands:$inspect, self_improve_skills:$selfimp}}')
echo "$line" >> .foundry/MARKETPLACE_SCORECARD.jsonl

echo "MARKETPLACE SCORECARD"
echo "  integrity: check.sh identical=$check_sh_ok  inspection-core identical=$core_ok  ~/.claude violations=$port_viol"
echo "  inspection: $reports report(s) — CRITICAL $crit / WARNING $warn / SUGGESTION $sugg"
echo "  self-improve PRs merged: $selfimprove_prs"
# P2-13: canon-restatement trend — agents inlining canon (model-tier table / SOLID / test-contract)
# without a certainty-marker citation. Trend it DOWN; self-improve replaces each copy with a reference.
echo "  canon-restatements: $canon_restatements (agents inlining canon without a citation — trend → 0)"
if [[ ${#canon_files[@]} -gt 0 ]]; then
  for _cf in "${canon_files[@]}"; do echo "    · ${_cf%%:*} (${_cf##*:} signal[s])"; done
fi
# P2-17: per-element finding map — the closed-loop measure self-improve asserts against run-over-run.
_pe_n=$(printf '%s' "$per_element_json" | jq -r 'length' 2>/dev/null); _pe_n=${_pe_n:-0}
echo "  per-element findings: $_pe_n element(s) carrying open findings (self-improve asserts each drops run-over-run)"
echo "  self-coverage: $plugins_n plugins · $skills_n skills · $agents_n agents · $commands_n commands · $inspect_n inspect · $selfimprove_n self-improve"
echo "  → appended to .foundry/MARKETPLACE_SCORECARD.jsonl"
