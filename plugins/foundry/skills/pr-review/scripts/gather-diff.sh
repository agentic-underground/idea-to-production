#!/usr/bin/env bash
# gather-diff.sh — assemble an adversarial-review packet for a PR number or a git range.
#
# Usage:
#   gather-diff.sh                 # current branch vs merge-base with origin/main (or main)
#   gather-diff.sh <base>..<head>  # explicit range
#   gather-diff.sh <PR#>           # a GitHub PR number (needs gh OR $GH_TOKEN + a github remote)
#
# Emits a markdown packet on stdout: range, changed-file churn, full unified diff, and — for a PR —
# title/body/CI when reachable. Never fails the review for missing PR metadata; it reports the gap.
set -uo pipefail

arg="${1:-}"
have() { command -v "$1" >/dev/null 2>&1; }

# Resolve the default base branch.
base_ref="origin/main"; git rev-parse --verify -q "$base_ref" >/dev/null 2>&1 || base_ref="main"

pr_meta=""
if [[ "$arg" =~ ^[0-9]+$ ]]; then
  # ---- PR number path ---------------------------------------------------------
  pr="$arg"
  if have gh; then
    pr_meta="$(gh pr view "$pr" --json title,body,headRefName,baseRefName,statusCheckRollup \
                 --template '### PR #'"$pr"' — {{.title}}
**base:** {{.baseRefName}}  **head:** {{.headRefName}}

{{.body}}
' 2>/dev/null)"
    head="$(gh pr view "$pr" --json headRefName -q .headRefName 2>/dev/null)"
    base="$(gh pr view "$pr" --json baseRefName -q .baseRefName 2>/dev/null)"
    git fetch -q github "$head" 2>/dev/null || git fetch -q origin "$head" 2>/dev/null || true
    range="${base:-main}...FETCH_HEAD"
  else
    pr_meta="> ⚠ PR metadata unavailable: \`gh\` not installed and no \$GH_TOKEN. Reviewing the diff only."
    range="${base_ref}...HEAD"
  fi
elif [[ "$arg" == *..* ]]; then
  range="$arg"
else
  # ---- current branch path ----------------------------------------------------
  mb="$(git merge-base "$base_ref" HEAD 2>/dev/null)"
  range="${mb:-$base_ref}...HEAD"
fi

echo "# Adversarial PR-review packet"
echo
echo "**Range:** \`${range}\`"
echo
[ -n "$pr_meta" ] && { echo "$pr_meta"; echo; }

echo "## Changed files (churn)"
echo '```'
git diff --stat "$range" 2>/dev/null || echo "(could not compute diff stat for $range)"
echo '```'
echo
echo "## Full unified diff"
echo '```diff'
git diff "$range" 2>/dev/null || echo "(could not compute diff for $range)"
echo '```'
