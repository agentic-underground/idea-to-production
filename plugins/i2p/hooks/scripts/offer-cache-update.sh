#!/usr/bin/env bash
# offer-cache-update.sh — i2p SessionStart advisory. ONE quiet, once-per-session nudge
# when the INSTALLED marketplace-cache version of a plugin LAGS the repo's
# .claude-plugin/marketplace.json — suggesting `/plugin marketplace update`. Never blocks,
# never nags (atomic sentinel), always prints valid JSON (or nothing).
#
# ── Detectability (the honest part) ────────────────────────────────────────────────
# The "installed cache version" is harness-internal. On THIS harness it IS reliably
# discoverable: Claude Code records every installed plugin's version in
#   ~/.claude/plugins/installed_plugins.json  →  .plugins["<name>@<marketplace>"][].version
# and the marketplace's source location in
#   ~/.claude/plugins/known_marketplaces.json →  .["<marketplace>"].installLocation
# We resolve the repo this plugin was installed FROM (so we compare against the SAME
# marketplace the cache tracks, not a hard-coded path), read its
#   <repo>/.claude-plugin/marketplace.json → .plugins[].version,
# and compare per-plugin. If the installed version < repo version for ANY plugin, the
# cache lags → advise `/plugin marketplace update`.
#
# This degrades to SILENCE — never a false advisory — whenever the comparison cannot be
# made reliably: no jq, either state file missing/unreadable, the marketplace not found
# in known_marketplaces.json, its installLocation absent, or no marketplace.json there.
# A staleness advisory that fires when it can't actually tell would be noise; we refuse
# to fake it. (Versions are compared with sort -V; equal/newer installed → silent.)
set -uo pipefail

# Drain the SessionStart payload on stdin; we don't need it.
[ -t 0 ] || cat >/dev/null 2>&1 || true

STATE_DIR="${HOME}/.claude/hook-state"
SENTINEL="${STATE_DIR}/i2p-cache-update-advised"
INSTALLED="${HOME}/.claude/plugins/installed_plugins.json"
KNOWN="${HOME}/.claude/plugins/known_marketplaces.json"

# Cannot decide without jq or the harness state → stay silent (never a false advisory).
command -v jq >/dev/null 2>&1 || exit 0
[ -r "$INSTALLED" ] && [ -r "$KNOWN" ] || exit 0

# Once-per-session-machine gate FIRST: mkdir succeeds exactly once. If we already advised
# (or lost the race), exit before doing any work — guarantees we never nag.
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
mkdir "$SENTINEL" 2>/dev/null || exit 0

# Identify which marketplace THIS plugin came from by matching its install path against
# every known marketplace's installLocation. ${CLAUDE_PLUGIN_ROOT} is .../<repo or cache>/...;
# we find the marketplace whose installLocation is a prefix of it, then read that repo's
# marketplace.json. Falls back to scanning all marketplaces if no prefix matches.
plugin_root="${CLAUDE_PLUGIN_ROOT:-}"

# Build: for each known marketplace, (name, installLocation). Then for the one whose
# installLocation prefixes our plugin_root (or, failing that, each in turn) read its
# marketplace.json and compare versions.
lagging=""
checked=0
while IFS=$'\t' read -r mkt loc; do
  [ -n "$loc" ] || continue
  mfile="${loc%/}/.claude-plugin/marketplace.json"
  [ -r "$mfile" ] || continue
  jq -e . "$mfile" >/dev/null 2>&1 || continue   # skip an unreadable/corrupt manifest

  # If we know our own plugin_root, only consider the marketplace that contains us.
  if [ -n "$plugin_root" ] && [ "$checked" = "0" ]; then
    case "$plugin_root" in
      "${loc%/}"/*) : ;;            # this is our marketplace — proceed
      *) continue ;;               # not ours — skip
    esac
  fi

  # Compare each plugin's repo version against its installed cache version.
  # repo: .plugins[] | name+version. installed: .plugins["name@mkt"][].version (any entry).
  while IFS=$'\t' read -r name repov; do
    [ -n "$name" ] && [ -n "$repov" ] || continue
    instv="$(jq -r --arg k "${name}@${mkt}" '.plugins[$k][0].version // empty' "$INSTALLED" 2>/dev/null)"
    [ -n "$instv" ] || continue                  # not installed → nothing to advise
    [ "$instv" = "$repov" ] && continue          # up to date
    # installed < repo  ⇔  sorted ascending puts installed first AND they differ.
    earliest="$(printf '%s\n%s\n' "$instv" "$repov" | sort -V | head -1)"
    if [ "$earliest" = "$instv" ]; then
      lagging="${lagging:+$lagging, }${name} ${instv}→${repov}"
    fi
  done < <(jq -r '.plugins[] | [.name, (.version // "")] | @tsv' "$mfile" 2>/dev/null)

  checked=1
done < <(jq -r '. | to_entries[] | [.key, (.value.installLocation // "")] | @tsv' "$KNOWN" 2>/dev/null)

# No lag detected (or could not determine) → silent. We already claimed the sentinel, so
# this stays a once-per-session check even when it's a no-op (no nag on every session).
[ -n "$lagging" ] || exit 0

MSG="📦 Your installed idea-to-production plugin cache lags the marketplace (${lagging}). Run /plugin marketplace update to refresh."
CTX="The installed marketplace plugin cache is behind the repo's marketplace.json for: ${lagging}. If relevant, suggest the user run /plugin marketplace update to pull the newer plugin versions. Mention at most once; do not nag."

jq -cn --arg m "$MSG" --arg c "$CTX" \
  '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
exit 0
