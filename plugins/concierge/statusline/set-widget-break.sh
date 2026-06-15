#!/usr/bin/env bash
# set-widget-break.sh — persist a line-2 status-line widget's line-break attribute.
#
#   set-widget-break.sh <widget-key> <before|after|none> [conf-path]
#
# Idempotently upserts `break_<key>=<value>` into the i2p-statusline conf
# (default ~/.claude/i2p-statusline.conf, or $CLAUDE_I2P_STATUSLINE_CONF),
# PRESERVING every other line (visibility keys, other widgets' breaks). Called
# by the /concierge:statusline-widgets skill for each selected widget. Re-running
# with the same args is a no-op-equivalent (the line is replaced, never duplicated).
set -uo pipefail

key="${1:-}"
val="${2:-}"
conf="${3:-${CLAUDE_I2P_STATUSLINE_CONF:-$HOME/.claude/i2p-statusline.conf}}"

case "$val" in
  before|after|none) ;;
  *) printf '✗ value must be before|after|none (got %q)\n' "$val" >&2; exit 2 ;;
esac
case "$key" in
  '' ) printf '✗ widget key required\n' >&2; exit 2 ;;
  *[!a-zA-Z0-9_]* ) printf '✗ invalid widget key: %q\n' "$key" >&2; exit 2 ;;
esac

mkdir -p "$(dirname "$conf")" 2>/dev/null || true
[ -f "$conf" ] || : > "$conf"

line="break_${key}=${val}"
tmp="${conf}.tmp.$$"
if grep -qE "^break_${key}=" "$conf" 2>/dev/null; then
  sed "s|^break_${key}=.*|${line}|" "$conf" > "$tmp" && mv -f "$tmp" "$conf"
else
  cp "$conf" "$tmp" 2>/dev/null || : > "$tmp"
  printf '%s\n' "$line" >> "$tmp" && mv -f "$tmp" "$conf"
fi
printf '✓ %s  (%s)\n' "$line" "$conf"
