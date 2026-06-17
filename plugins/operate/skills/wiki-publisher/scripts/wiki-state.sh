#!/usr/bin/env bash
# wiki-state.sh — detect a GitHub origin + read the one-shot opt-in gate for WIKI-PUBLISHER.
#
# Read-only. NEVER writes the user's repo and NEVER writes opt-out state — it only DETECTS the
# situation and prints the exact marker paths the AGENT writes (under ~/.claude/hook-state) on the
# operator's say-so, mirroring CONCIERGE's offer-welcome.sh. Always exits 0; degrades gracefully when
# git is absent or the dir is not a repo.
#
# Prints one status line:
#   github=<owner/repo|no> declined=<0|1> optout=<0|1> docs=<count> repo-key=<key>
# followed by the two marker paths (declined / optout) for convenience.
set -uo pipefail

DIR="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="${2:-$PWD}"; shift 2 ;;
    *) shift ;;
  esac
done

HOME_DIR="${HOME:-/tmp}"
STATE_DIR="${HOME_DIR}/.claude/hook-state"

# --- derive owner/repo from a github.com origin (SSH or HTTPS); else "no" ---
gh_slug="no"
if command -v git >/dev/null 2>&1; then
  url="$(git -C "$DIR" remote get-url origin 2>/dev/null || true)"
  case "$url" in
    git@github.com:*)        gh_slug="${url#git@github.com:}"; gh_slug="${gh_slug%.git}" ;;
    https://github.com/*)    gh_slug="${url#https://github.com/}"; gh_slug="${gh_slug%.git}" ;;
    ssh://git@github.com/*)  gh_slug="${url#ssh://git@github.com/}"; gh_slug="${gh_slug%.git}" ;;
    *) gh_slug="no" ;;
  esac
fi

# --- one-shot gate keys (same hashing convention as concierge offer-welcome.sh) ---
hash_path() {
  if   command -v sha1sum >/dev/null 2>&1; then printf '%s' "$1" | sha1sum | cut -c1-12
  elif command -v shasum  >/dev/null 2>&1; then printf '%s' "$1" | shasum  | cut -c1-12
  elif command -v md5sum  >/dev/null 2>&1; then printf '%s' "$1" | md5sum  | cut -c1-12
  else printf '%s' "$1" | cksum | tr -d ' ' | cut -c1-12; fi
}
repo_key="$(basename "$DIR" 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')-$(hash_path "$DIR")"
DECLINED="${STATE_DIR}/operate-wiki-declined/${repo_key}"
OPTOUT="${STATE_DIR}/operate-wiki-optout"

declined=0; [ -e "$DECLINED" ] && declined=1
optout=0;   [ -e "$OPTOUT" ]   && optout=1

# --- count PUBLISH per-item docs (doc/articles/**.md), if any ---
docs=0
if [ -d "$DIR/doc/articles" ]; then
  docs="$(find "$DIR/doc/articles" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
fi

printf 'github=%s declined=%s optout=%s docs=%s repo-key=%s\n' \
  "$gh_slug" "$declined" "$optout" "$docs" "$repo_key"
printf 'decline-marker: mkdir -p %q\n' "$DECLINED"
printf 'optout-marker:  mkdir -p %q\n' "$OPTOUT"
exit 0
