#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# delete-epic.sh — list (default) or permanently delete an EPIC and every PLAN linked to it as a
# native GitHub SUB-ISSUE (the authoritative parent/child relationship the project board renders).
#
# The plan set comes from the real GitHub relationship (`issue.subIssues`), NOT from scraping the
# EPIC's `## Plans` markdown table — the table is used only as an ADVISORY cross-check that WARNS on
# drift (a plan documented in the table but not linked as a sub-issue, or vice-versa). With --delete
# it PERMANENTLY deletes the EPIC + its linked plans (gh issue delete --yes → irreversible; removed
# from GitHub and the board; no history).
#
# Usage:
#   scripts/roadmap/delete-epic.sh <epic-order>            # LIST the targets (default; safe)
#   scripts/roadmap/delete-epic.sh <epic-order> --delete   # DELETE the targets (permanent)
#
#   <epic-order>  the 4-digit EPIC order, leading zeros optional (0003, 3, and 18 all work).
#
# Flow: run LIST, eyeball the targets, get an explicit go/no-go, then re-run with --delete.
# Deterministic + read-only in list mode. Requires `gh` (authenticated) + `jq`.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

bold=$'\033[1m'; red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { bold=""; red=""; green=""; yellow=""; dim=""; reset=""; }

ORDER_RAW="${1:-}"
MODE="list"
for a in "${@:2}"; do case "$a" in --delete) MODE="delete";; --list) MODE="list";; *) printf "unknown argument: %s\n" "$a" >&2; exit 2;; esac; done
[ -n "$ORDER_RAW" ] || { printf "usage: delete-epic.sh <epic-order> [--delete]\n" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { printf "%bgh CLI required%b\n" "$red" "$reset" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { printf "%bjq required%b\n" "$red" "$reset" >&2; exit 2; }

# Normalise to a 4-digit order ("3" → "0003"). SAFETY: the order is interpolated into the jq title
# regex, so it MUST be 1–4 digits — reject anything else (a stray "." or ".*" would broaden the match).
printf '%s' "$ORDER_RAW" | grep -qE '^[0-9]{1,4}$' || { printf "%bepic order must be 1–4 digits (got '%s')%b\n" "$red" "$ORDER_RAW" "$reset" >&2; exit 2; }
ORDER="$(printf '%04d' "$((10#$ORDER_RAW))")"

# Repo coordinates (portable — no hard-coded owner/name).
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
[ -n "$NWO" ] || { printf "%bcould not resolve the repo (gh auth?)%b\n" "$red" "$reset" >&2; exit 2; }
OWNER="${NWO%/*}"; NAME="${NWO#*/}"

# Resolve the EPIC issue from its order (the order lives in the title — a marketplace convention).
ALL="$(gh issue list --state all --limit 500 --json number,title,state 2>/dev/null)"
[ -n "$ALL" ] || { printf "%bcould not list issues (gh auth?)%b\n" "$red" "$reset" >&2; exit 2; }
epic_num="$(printf '%s' "$ALL" | jq -r --arg o "$ORDER" '.[] | select(.title|test("^EPIC "+$o+"[:.]")) | .number' | head -1)"
[ -n "$epic_num" ] && [ "$epic_num" != "null" ] || { printf "%bno EPIC %s found on %s%b\n" "$red" "$ORDER" "$NWO" "$reset" >&2; exit 1; }
epic_title="$(printf '%s' "$ALL" | jq -r --argjson n "$epic_num" '.[] | select(.number==$n) | .title')"
epic_state="$(printf '%s' "$ALL" | jq -r --argjson n "$epic_num" '.[] | select(.number==$n) | .state')"

# ── Plans = the EPIC's native GitHub sub-issues (authoritative). ─────────────────────────────────
subs="$(gh api graphql -f owner="$OWNER" -f name="$NAME" -F num="$epic_num" -f query='
  query($owner:String!, $name:String!, $num:Int!) {
    repository(owner:$owner, name:$name) {
      issue(number:$num) {
        subIssues(first:100) { nodes { number title state subIssuesSummary { total } } }
      }
    }
  }' 2>/dev/null)"
if [ -z "$subs" ] || ! printf '%s' "$subs" | jq -e '.data.repository.issue' >/dev/null 2>&1; then
  printf "%bcould not read sub-issues for #%s (GitHub API / permissions?)%b\n" "$red" "$epic_num" "$reset" >&2; exit 2
fi

declare -a T_NUM=() T_LABEL=()
T_NUM+=("$epic_num"); T_LABEL+=("[$epic_state] EPIC $ORDER — $epic_title")
nested_warn=""
while IFS=$'\t' read -r pn ps pt psub; do
  [ -n "$pn" ] || continue
  T_NUM+=("$pn"); T_LABEL+=("[$ps] $pt")
  [ "${psub:-0}" -gt 0 ] 2>/dev/null && nested_warn="${nested_warn} #${pn}(+${psub} of its own)"
done < <(printf '%s' "$subs" | jq -r '.data.repository.issue.subIssues.nodes[]? | "\(.number)\t\(.state)\t\(.title)\t\(.subIssuesSummary.total // 0)"')

# ── Advisory cross-check against the `## Plans` table (drift detection only — never the delete set). ─
epic_body="$(gh issue view "$epic_num" --json body -q .body 2>/dev/null)"
plans_section="$(printf '%s' "$epic_body" | awk '/^##[[:space:]]+Plans/{f=1;next} /^##[[:space:]]/{f=0} f')"
table_orders="$(printf '%s' "$plans_section" | grep -oE 'PLAN[_ ][0-9]{4}(\.[0-9]{3})?' | sed -E 's/^PLAN[_ ]//' | sort -u)"
drift=""
for po in $table_orders; do
  tnum="$(printf '%s' "$ALL" | jq -r --arg o "$po" '.[] | select(.title|test("^PLAN "+$o+"[:.]")) | .number' | head -1)"
  # in table but NOT a linked sub-issue → it will NOT be deleted; surface it.
  if [ -n "$tnum" ] && [ "$tnum" != "null" ]; then
    printf '%s\n' "${T_NUM[@]}" | grep -qx "$tnum" || drift="${drift} PLAN_${po}(#${tnum})"
  fi
done

printf "%bDeletion targets for EPIC %s%b (%d issue(s), from GitHub sub-issue links):\n" "$bold" "$ORDER" "$reset" "${#T_NUM[@]}"
for i in "${!T_NUM[@]}"; do printf "  %b#%s%b  %s\n" "$yellow" "${T_NUM[$i]}" "$reset" "${T_LABEL[$i]}"; done
[ -n "$drift" ] && printf "  %b⚠ in the ## Plans table but NOT linked as a sub-issue (will NOT be deleted):%s%b\n" "$yellow" "$drift" "$reset"
[ -n "$nested_warn" ] && printf "  %b⚠ these plans have their own sub-issues (not auto-expanded):%s%b\n" "$yellow" "$nested_warn" "$reset"

if [ "$MODE" != "delete" ]; then
  printf "\n%bLIST mode%b — nothing deleted. Re-run with %b--delete%b to permanently delete these %d issue(s).\n" \
    "$green" "$reset" "$bold" "$reset" "${#T_NUM[@]}"
  exit 0
fi

printf "\n%bDELETING %d issue(s) — permanent%b\n" "$red" "${#T_NUM[@]}" "$reset"
rc=0
for i in "${!T_NUM[@]}"; do
  if gh issue delete "${T_NUM[$i]}" --yes >/dev/null 2>&1; then printf "  %b✓%b deleted #%s\n" "$green" "$reset" "${T_NUM[$i]}"
  else printf "  %b✗%b FAILED to delete #%s\n" "$red" "$reset" "${T_NUM[$i]}"; rc=1; fi
done
exit "$rc"
