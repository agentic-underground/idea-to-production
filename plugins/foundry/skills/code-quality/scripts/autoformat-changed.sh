#!/usr/bin/env bash
# autoformat-changed.sh — scoped auto-format (P1-19).
#
# Self-heal for the "lint/format failure halts the gate for trivial style" class. Instead of failing
# a review gate on whitespace, this formats ONLY the files that the change-set already touches, proves
# the formatter did not spill outside that set, lands the result in a SEPARATE commit, and signals the
# gate to re-run. It NEVER reformats the whole repo — a repo-wide reformat is exactly the unsafe,
# review-blind blast radius this exists to prevent.
#
# SAFETY CONTRACT (review M-SAFETY / P1-19):
#   1. CHANGE-SET SCOPED   — only files in `git diff --name-only <base>` are formatted.
#   2. SUBSET ASSERTION    — after formatting, the set of files the format actually MODIFIED must be a
#                            SUBSET of the touched set. If formatting would touch ANYTHING outside the
#                            change set, ABORT (revert the format) and exit non-zero — never commit a
#                            spill. This is the load-bearing guarantee.
#   3. SEPARATE COMMIT     — the style fix lands as its own commit ("style: auto-format changed files"),
#                            never mixed into the feature commit, so it is trivially reviewable/revertable.
#   4. SIGNAL RE-RUN       — exit 10 tells the caller "I changed the tree; re-run the gate".
#
# Usage:
#   autoformat-changed.sh [--base <ref>] [--dry-run] [--formatter '<cmd> {}'] [project-dir]
#
#   --base <ref>      Diff base to compute the change set (default: HEAD — i.e. staged+unstaged working
#                     changes vs the last commit). Use a branch/SHA to scope to a PR's whole diff.
#   --dry-run         Compute + format + assert subset, but do NOT commit. Reports what it WOULD do.
#   --formatter CMD   Override formatter detection. `{}` is replaced by the file list (space-joined).
#                     If `{}` is absent the file list is appended.
#   project-dir       Repo to operate in (default: cwd).
#
# Exit codes:
#   0   nothing to do (no changed files, or already well-formatted) — gate may proceed unchanged
#   10  formatted + committed (or, with --dry-run, WOULD format) — caller MUST re-run the gate
#   2   ABORT — formatting would spill outside the change set (subset assertion failed); tree reverted
#   3   environment error (not a git repo / no formatter and none supplied)
#
# Formatter detection (first match wins) — documented so a project without one still gets the
# change-set-scoping logic via --formatter:
#   prettier   → node_modules/.bin/prettier (or `npx prettier`) when package.json present
#   black      → `black` when pyproject.toml / setup.cfg present
#   ruff       → `ruff format` when ruff is configured
#   rustfmt    → `cargo fmt` when Cargo.toml present
#   gofmt      → `gofmt -w` when go.mod present

set -uo pipefail

BASE="HEAD"
DRY_RUN=0
FORMATTER_OVERRIDE=""
ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)      BASE="${2:?--base needs a ref}"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --formatter) FORMATTER_OVERRIDE="${2:?--formatter needs a command}"; shift 2 ;;
    -*)          echo "autoformat: unknown flag $1" >&2; exit 3 ;;
    *)           ROOT="$1"; shift ;;
  esac
done
ROOT="${ROOT:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "autoformat: cannot cd to $ROOT" >&2; exit 3; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "autoformat: not a git repo: $ROOT" >&2; exit 3; }

note() { echo "autoformat: $*" >&2; }

# ── 1. CHANGE SET — the ONLY files we are allowed to touch ────────────────────
# Working changes vs base, plus untracked files (a freshly-added file is part of the change set too).
mapfile -t CHANGED < <(
  { git diff --name-only "$BASE" -- 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u | grep -v '^[[:space:]]*$'
)
# Keep only files that still exist (a deletion is in the diff but cannot be formatted).
EXISTING=()
for f in "${CHANGED[@]}"; do [[ -f "$f" ]] && EXISTING+=("$f"); done

if [[ ${#EXISTING[@]} -eq 0 ]]; then
  note "no changed files to format (base=$BASE) — nothing to do."
  exit 0
fi
note "change set (${#EXISTING[@]} file(s)) vs $BASE: ${EXISTING[*]}"

# ── 2. FORMATTER — detect, or take the override ───────────────────────────────
# A formatter command receives the file list. We build a function run_formatter that applies it
# in place to JUST the change-set files.
FORMATTER_DESC=""
run_formatter() {  # args: files…
  if [[ -n "$FORMATTER_OVERRIDE" ]]; then
    local cmd="$FORMATTER_OVERRIDE"
    if [[ "$cmd" == *"{}"* ]]; then
      cmd="${cmd//\{\}/$*}"
      bash -c "$cmd"
    else
      bash -c "$cmd \"\$@\"" _ "$@"
    fi
    return $?
  fi
  # auto-detect
  if [[ -f package.json ]] && { [[ -x node_modules/.bin/prettier ]] || command -v prettier >/dev/null 2>&1; }; then
    local pf="node_modules/.bin/prettier"; [[ -x "$pf" ]] || pf="prettier"
    "$pf" --write "$@"; return $?
  fi
  if { [[ -f pyproject.toml ]] || [[ -f setup.cfg ]]; } && command -v black >/dev/null 2>&1; then
    black -q "$@"; return $?
  fi
  if command -v ruff >/dev/null 2>&1 && { [[ -f pyproject.toml ]] || [[ -f ruff.toml ]]; }; then
    ruff format "$@"; return $?
  fi
  if [[ -f Cargo.toml ]] && command -v rustfmt >/dev/null 2>&1; then
    rustfmt "$@"; return $?
  fi
  if [[ -f go.mod ]] && command -v gofmt >/dev/null 2>&1; then
    gofmt -w "$@"; return $?
  fi
  return 127  # no formatter
}

if [[ -n "$FORMATTER_OVERRIDE" ]]; then
  FORMATTER_DESC="override: $FORMATTER_OVERRIDE"
else
  # Probe detection without running, for the abort message.
  if [[ -f package.json ]] && { [[ -x node_modules/.bin/prettier ]] || command -v prettier >/dev/null 2>&1; }; then FORMATTER_DESC="prettier"
  elif { [[ -f pyproject.toml ]] || [[ -f setup.cfg ]]; } && command -v black >/dev/null 2>&1; then FORMATTER_DESC="black"
  elif command -v ruff >/dev/null 2>&1 && { [[ -f pyproject.toml ]] || [[ -f ruff.toml ]]; }; then FORMATTER_DESC="ruff format"
  elif [[ -f Cargo.toml ]] && command -v rustfmt >/dev/null 2>&1; then FORMATTER_DESC="rustfmt"
  elif [[ -f go.mod ]] && command -v gofmt >/dev/null 2>&1; then FORMATTER_DESC="gofmt -w"
  else
    note "no formatter detected and no --formatter supplied — cannot auto-format."
    note "  (the change-set-scoping logic is intact; pass --formatter '<cmd> {}' to use it.)"
    exit 3
  fi
fi
note "formatter: $FORMATTER_DESC"

# ── 3. SNAPSHOT, FORMAT in place, then ASSERT subset ──────────────────────────
# To distinguish "the FORMATTER changed this file" from "the user already had a working-tree edit
# here", we hash a snapshot of the WHOLE worktree's tracked+untracked content BEFORE formatting, then
# re-hash AFTER. A file the formatter touched is one whose content hash changed across run_formatter —
# nothing else. (Comparing git-status vs HEAD would wrongly attribute the user's own change-set edits
# to the formatter and commit them under a "style:" message.)
BACKUP="$(mktemp -d)"
trap 'rm -rf "$BACKUP"' EXIT
snapshot_hashes() {  # prints "<sha>\t<path>" for every tracked-or-untracked, non-ignored file
  { git ls-files; git ls-files --others --exclude-standard; } | sort -u | while IFS= read -r f; do
    [[ -f "$f" ]] && printf '%s\t%s\n' "$(git hash-object "$f" 2>/dev/null)" "$f"
  done
}
declare -A BEFORE=()
while IFS=$'\t' read -r h f; do [[ -n "$f" ]] && BEFORE["$f"]="$h"; done < <(snapshot_hashes)
# Back up the pre-format content of every existing file so we can restore exactly on abort/dry-run.
i=0; declare -A BAKPATH=()
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  bp="$BACKUP/$i"; cp "$f" "$bp"; BAKPATH["$f"]="$bp"; i=$((i+1))
done < <(printf '%s\n' "${!BEFORE[@]}")

run_formatter "${EXISTING[@]}"
fmt_rc=$?
if [[ $fmt_rc -ne 0 && $fmt_rc -ne 127 ]]; then
  note "formatter exited $fmt_rc — aborting (no commit)."
  exit 3
fi

# AFTER hashes → files the formatter ACTUALLY changed = hash differs from BEFORE (or newly created).
declare -A AFTER=()
while IFS=$'\t' read -r h f; do [[ -n "$f" ]] && AFTER["$f"]="$h"; done < <(snapshot_hashes)

declare -A ALLOWED=()
for f in "${EXISTING[@]}"; do ALLOWED["$f"]=1; done

FORMATTED=()   # files the formatter changed AND are in the change set → may be committed
SPILL=()       # files the formatter changed that are OUTSIDE the change set → forbidden
for f in "${!AFTER[@]}"; do
  if [[ "${AFTER[$f]}" != "${BEFORE[$f]:-}" ]]; then
    if [[ -n "${ALLOWED[$f]:-}" ]]; then FORMATTED+=("$f"); else SPILL+=("$f"); fi
  fi
done

restore() { local f bp; for f in "$@"; do bp="${BAKPATH[$f]:-}"; if [[ -n "$bp" ]]; then cp "$bp" "$f"; else rm -f "$f"; fi; done; }

# SUBSET ASSERTION: the formatter must not have changed anything outside the change set.
if [[ ${#SPILL[@]} -gt 0 ]]; then
  note "SUBSET ASSERTION FAILED — formatting spilled OUTSIDE the change set:"
  for f in "${SPILL[@]}"; do note "    spill: $f"; done
  note "  reverting the format (no commit) — the gate stays red, deterministically, not silently widened."
  # Restore the FULL pre-format content of everything the formatter touched (spill AND change set) —
  # the run is rejected wholesale, leaving the tree exactly as the user had it.
  restore "${SPILL[@]}" "${FORMATTED[@]}"
  exit 2
fi

if [[ ${#FORMATTED[@]} -eq 0 ]]; then
  note "change set already well-formatted — nothing to commit."
  exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  note "[dry-run] WOULD commit auto-format of: ${FORMATTED[*]}"
  note "[dry-run] subset assertion PASSED (no spill). Reverting working-tree format for dry-run."
  restore "${FORMATTED[@]}"
  exit 10
fi
TO_STAGE=("${FORMATTED[@]}")

# ── 4. SEPARATE COMMIT + signal re-run ────────────────────────────────────────
git add -- "${TO_STAGE[@]}"
git commit -q -m "style: auto-format changed files

Scoped auto-format (P1-19): formatted only the ${#TO_STAGE[@]} file(s) already in the change set
(base=$BASE) with $FORMATTER_DESC. Post-format diff asserted ⊆ change set (no spill). Separate
commit so the style fix is independently reviewable/revertable; gate signalled to re-run." \
  || { note "commit failed"; exit 3; }

note "committed style: auto-format changed files (${#TO_STAGE[@]} file(s)). Re-run the gate."
exit 10
