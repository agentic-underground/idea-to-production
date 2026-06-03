#!/usr/bin/env bash
# gather-diff.sh — assemble an adversarial-review packet for a PR number or a git range.
#
# Usage:
#   gather-diff.sh                 # current branch vs merge-base with the default base branch
#   gather-diff.sh <base>..<head>  # a range (2-dot is normalised to 3-dot — PR-diff semantics)
#   gather-diff.sh <base>...<head> # explicit 3-dot range
#   gather-diff.sh <PR#>           # a GitHub PR number — REQUIRES `gh` (a bare token is not enough)
#   ...any --post / extra flags are ignored here (posting is handled by the calling skill).
#
# Emits a markdown packet on stdout: range, changed-file churn, full unified diff, and — for a PR —
# title/body/CI when reachable. It will NOT emit a misleading empty packet: if a PR cannot be
# resolved/fetched it aborts loudly (a reviewer must never read "no changes" as a pass).
set -uo pipefail

# First non-flag arg is the target; ignore --post and other flags (the skill handles posting).
arg=""
for a in "$@"; do case "$a" in --*) ;; *) [ -z "$arg" ] && arg="$a" ;; esac; done

have() { command -v "$1" >/dev/null 2>&1; }
die()  { echo "gather-diff: $*" >&2; exit 3; }

# Pick the remote that points at github.com (fallback: origin, then github).
remote="$(git remote -v 2>/dev/null | awk '/github\.com/ {print $1; exit}')"
[ -n "$remote" ] || { for r in origin github; do git remote get-url "$r" >/dev/null 2>&1 && remote="$r" && break; done; }

# Resolve the default base branch.
base_ref="${remote:+$remote/}main"
git rev-parse --verify -q "$base_ref" >/dev/null 2>&1 || base_ref="main"

pr_meta=""
if [[ "$arg" =~ ^[0-9]+$ ]]; then
  # ---- PR number path — gh is mandatory; never silently diff an empty/stale ref --------------
  pr="$arg"
  have gh || die "PR #$pr requested but \`gh\` is not installed (a bare \$GH_TOKEN is not used here). Install gh, or pass an explicit <base>..<head> range."
  base="$(gh pr view "$pr" --json baseRefName -q .baseRefName 2>/dev/null)"
  head="$(gh pr view "$pr" --json headRefName -q .headRefName 2>/dev/null)"
  [ -n "$head" ] && [ -n "$base" ] || die "could not resolve PR #$pr via gh (wrong number, no access, or no PR). NOT emitting an empty packet."
  pr_meta="$(gh pr view "$pr" --json title,body,statusCheckRollup \
              --template '### PR #'"$pr"' — {{.title}}
**base:** '"$base"'  **head:** '"$head"'
**CI:** {{range .statusCheckRollup}}{{.name}}={{.conclusion}} {{end}}

{{.body}}
' 2>/dev/null)"
  git fetch -q "$remote" "$head" 2>/dev/null || die "could not fetch head branch '$head' for PR #$pr from '$remote'. NOT emitting an empty packet."
  range="${base}...FETCH_HEAD"
elif [[ "$arg" == *...* ]]; then
  range="$arg"                       # explicit 3-dot
elif [[ "$arg" == *..* ]]; then
  range="${arg/../...}"              # normalise 2-dot → 3-dot (review-relevant diff)
else
  mb="$(git merge-base "$base_ref" HEAD 2>/dev/null)"
  range="${mb:-$base_ref}...HEAD"
fi

# Sanity: the range must be diffable.
git diff "$range" >/dev/null 2>&1 || die "range '$range' is not diffable (bad ref?)."

echo "# Adversarial PR-review packet"
echo
echo "**Range:** \`${range}\`"
echo
[ -n "$pr_meta" ] && { echo "$pr_meta"; echo; }

echo "## Changed files (churn)"
echo '```'
git diff --stat "$range"
echo '```'
echo
echo "## Full unified diff"
# 4-backtick fence so triple-backticks inside the diff (this repo is markdown-heavy) don't close it.
echo '````diff'
git diff "$range"
echo '````'
