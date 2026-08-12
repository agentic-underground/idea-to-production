#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# delete-epic.sh — list (default) or permanently delete an EPIC and every PLAN it contains.
#
# Resolves an EPIC issue by title ("EPIC <NNNN>: …"), parses its `## Plans` table for the
# `PLAN_<XXXX>.md` doc names it references, maps each to its issue ("PLAN <XXXX>: …"), and
# prints the full deletion target set. With --delete it PERMANENTLY deletes them (gh issue
# delete --yes → irreversible, removed from GitHub and the project board, no history kept).
#
# Usage:
#   scripts/roadmap/delete-epic.sh <epic-order>            # LIST the targets (default; safe)
#   scripts/roadmap/delete-epic.sh <epic-order> --delete   # DELETE the targets (permanent)
#
#   <epic-order>  the 4-digit EPIC order, leading zeros optional (0003, 3, and 18 all work).
#
# The intended flow: run LIST, eyeball the targets, get an explicit go/no-go, then re-run with
# --delete. Deterministic, read-only in list mode. Requires `gh` (authenticated) + `jq`.
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
# regex, so it MUST be exactly 4 digits — reject anything else (a stray "." or ".*" would otherwise
# broaden the match and target the wrong issues). Fail closed on a non-numeric / out-of-range value.
printf '%s' "$ORDER_RAW" | grep -qE '^[0-9]{1,4}$' || { printf "%bepic order must be 1–4 digits (got '%s')%b\n" "$red" "$ORDER_RAW" "$reset" >&2; exit 2; }
ORDER="$(printf '%04d' "$((10#$ORDER_RAW))")"
printf '%s' "$ORDER" | grep -qE '^[0-9]{4}$' || { printf "%bnormalised order '%s' is not 4 digits%b\n" "$red" "$ORDER" "$reset" >&2; exit 2; }

# One fetch of every issue (number,title,state); look everything up from it.
ALL="$(gh issue list --state all --limit 500 --json number,title,state 2>/dev/null)"
[ -n "$ALL" ] || { printf "%bcould not list issues (gh auth?)%b\n" "$red" "$reset" >&2; exit 2; }

epic_num="$(printf '%s' "$ALL" | jq -r --arg o "$ORDER" '.[] | select(.title|test("^EPIC "+$o+"[:.]")) | .number' | head -1)"
[ -n "$epic_num" ] && [ "$epic_num" != "null" ] || { printf "%bno EPIC %s found on this repo%b\n" "$red" "$ORDER" "$reset" >&2; exit 1; }
epic_title="$(printf '%s' "$ALL" | jq -r --argjson n "$epic_num" '.[] | select(.number==$n) | .title')"
epic_state="$(printf '%s' "$ALL" | jq -r --argjson n "$epic_num" '.[] | select(.number==$n) | .state')"
epic_body="$(gh issue view "$epic_num" --json body -q .body 2>/dev/null)"

# Plans: the plan orders listed in the EPIC's `## Plans` table (the authoritative set). Scope STRICTLY
# to that section (from "## Plans" to the next "## ") so a prose mention of some other plan elsewhere in
# the body can never be swept into the delete set. Handle BOTH table formats this repo uses:
#   • older migration epics — doc links `[PLAN_0019.md]`      → "PLAN_0019"
#   • newer epics           — text rows  `PLAN 0067.001 — …`  → "PLAN 0067.001"
# and both plan-numbering schemes: distinct 4-digit orders (0019) and sub-numbered orders (0067.001).
plans_section="$(printf '%s' "$epic_body" | awk '/^##[[:space:]]+Plans/{f=1;next} /^##[[:space:]]/{f=0} f')"
plan_orders="$(printf '%s' "$plans_section" | grep -oE 'PLAN[_ ][0-9]{4}(\.[0-9]{3})?' | sed -E 's/^PLAN[_ ]//' | sort -u)"

declare -a T_NUM=() T_LABEL=()
T_NUM+=("$epic_num"); T_LABEL+=("[$epic_state] EPIC $ORDER — $epic_title")
missing=""
for po in $plan_orders; do
  pn="$(printf '%s' "$ALL" | jq -r --arg o "$po" '.[] | select(.title|test("^PLAN "+$o+"[:.]")) | .number' | head -1)"
  if [ -n "$pn" ] && [ "$pn" != "null" ]; then
    pt="$(printf '%s' "$ALL" | jq -r --argjson n "$pn" '.[] | select(.number==$n) | .title')"
    ps="$(printf '%s' "$ALL" | jq -r --argjson n "$pn" '.[] | select(.number==$n) | .state')"
    T_NUM+=("$pn"); T_LABEL+=("[$ps] $pt")
  else
    missing="${missing} PLAN_${po}"
  fi
done

printf "%bDeletion targets for EPIC %s%b (%d issue(s)):\n" "$bold" "$ORDER" "$reset" "${#T_NUM[@]}"
for i in "${!T_NUM[@]}"; do printf "  %b#%s%b  %s\n" "$yellow" "${T_NUM[$i]}" "$reset" "${T_LABEL[$i]}"; done
[ -n "$missing" ] && printf "  %b(note: no live issue for:%s — already deleted / never created)%b\n" "$dim" "$missing" "$reset"

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
