#!/usr/bin/env bash
# FOUNDRY delivery-phase git-hygiene advisory (P1-12).
#
# DETECT-and-PROPOSE only — this script NEVER deletes a branch or removes a
# worktree. After a delivery transaction lands, merged feature branches and
# stale/orphaned worktrees accumulate; left unattended they clutter the repo and
# obscure what is still in flight. This advisory surfaces them and prints the
# EXACT cleanup commands for a human to run deliberately. It changes nothing.
#
# Run from the project being delivered (or pass the repo dir as $1).
# Referenced by agents/ds-step-9-commit-push.md as the closing hygiene step.
set -euo pipefail

REPO="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"
cd "$REPO" 2>/dev/null || { echo "git-hygiene: not a directory: $REPO"; exit 0; }

# Not a git repo → nothing to advise (clean no-op).
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "git-hygiene: not a git work tree — nothing to advise"; exit 0; }

# The trunk to measure "merged" against: prefer main, then master.
BASE=main
if ! git show-ref --verify --quiet "refs/heads/${BASE}"; then
    if git show-ref --verify --quiet refs/heads/master; then
        BASE=master
    else
        echo "git-hygiene: no main/master branch — skipping merged-branch advice"
        BASE=""
    fi
fi

CURRENT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

echo "── git-hygiene advisory (PROPOSE-only; nothing deleted) ──"

# ---- 1. Merged-but-undeleted local branches ----
# `git branch --merged BASE` lists branches whose tip is reachable from BASE.
# Exclude BASE itself and the currently checked-out branch (the leading "* ").
merged=""
if [ -n "$BASE" ]; then
    merged=$(git branch --merged "$BASE" 2>/dev/null \
        | sed 's/^[* +] *//' \
        | grep -vxE "${BASE}|${CURRENT}" || true)
fi

if [ -n "$merged" ]; then
    # Space-join for a copy-pasteable command.
    list=$(printf '%s' "$merged" | paste -sd' ' -)
    comma=$(printf '%s' "$merged" | paste -sd',' - | sed 's/,/, /g')
    echo "stale branches: ${comma} — to clean: git branch -d ${list}"
else
    echo "stale branches: none"
fi

# ---- 2. Orphaned / stale worktrees ----
# `git worktree list --porcelain` emits a `worktree <path>` line per worktree,
# and a bare `prunable` line for ones whose backing dir is gone. The main
# worktree is the repo root itself — never propose removing it.
main_wt=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
prunable=""
stale=""
wt_path=""
while IFS= read -r line; do
    case "$line" in
        "worktree "*) wt_path="${line#worktree }" ;;
        "prunable"*)
            [ -n "$wt_path" ] && [ "$wt_path" != "$main_wt" ] && prunable="${prunable}${wt_path}\n"
            ;;
        "")  # end of a record
            wt_path="" ;;
    esac
done < <(git worktree list --porcelain 2>/dev/null || true)

# Also flag linked worktrees whose path no longer exists on disk (orphaned),
# in case `prunable` was not emitted.
while IFS= read -r wt; do
    [ -z "$wt" ] && continue
    [ "$wt" = "$main_wt" ] && continue
    if [ ! -d "$wt" ]; then
        stale="${stale}${wt}\n"
    fi
done < <(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p')

orphaned=$(printf '%b%b' "$prunable" "$stale" | sed '/^$/d' | sort -u || true)

if [ -n "$orphaned" ]; then
    joined=$(printf '%s' "$orphaned" | paste -sd', ' - | sed 's/,/, /g')
    echo "orphaned worktrees: ${joined}"
    while IFS= read -r wt; do
        [ -z "$wt" ] && continue
        echo "  to clean: git worktree remove ${wt}"
    done < <(printf '%s\n' "$orphaned")
    echo "  (or, to clear all gone worktrees at once: git worktree prune)"
else
    echo "orphaned worktrees: none"
fi

echo "── end advisory — no branch or worktree was deleted ──"
exit 0
