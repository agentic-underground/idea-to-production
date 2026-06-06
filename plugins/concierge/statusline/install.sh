#!/usr/bin/env bash
# install.sh — turn the idea-to-production status line ON (or OFF).
#
#   bash install.sh            # copy the renderer to ~/.claude and point settings.json at it
#   bash install.sh off        # remove the statusLine entry from settings.json
#
# Run by /concierge:statusline. Portable: copies the plugin's renderer to
# ~/.claude/statusline-command.sh (settings.json cannot expand ${CLAUDE_PLUGIN_ROOT}),
# then atomically sets the statusLine command, preserving all other settings keys.
# Prints a merry toast on success. Never destructive beyond the statusLine key.
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="${PLUGIN_ROOT}/statusline/i2p-statusline.sh"
DST="${HOME}/.claude/statusline-command.sh"
SETTINGS="${HOME}/.claude/settings.json"
mode="${1:-on}"

mkdir -p "${HOME}/.claude" 2>/dev/null || { echo "✗ cannot write ~/.claude"; exit 1; }

# --- settings.json mutation helper (jq if present; else a careful fallback) ---
set_statusline() {  # $1 = command string, or "" to remove
  local cmd="$1" tmp
  [ -f "$SETTINGS" ] || printf '{}\n' > "$SETTINGS"
  tmp="${SETTINGS}.tmp.$$"
  if command -v jq >/dev/null 2>&1; then
    if [ -n "$cmd" ]; then
      jq --arg c "$cmd" '.statusLine = {"type":"command","command":$c}' "$SETTINGS" > "$tmp" 2>/dev/null \
        && mv -f "$tmp" "$SETTINGS" || { rm -f "$tmp"; return 1; }
    else
      jq 'del(.statusLine)' "$SETTINGS" > "$tmp" 2>/dev/null \
        && mv -f "$tmp" "$SETTINGS" || { rm -f "$tmp"; return 1; }
    fi
  else
    # No jq: only safe to handle the common case via python3 if available.
    if command -v python3 >/dev/null 2>&1; then
      CMD="$cmd" python3 - "$SETTINGS" <<'PY' || return 1
import json,os,sys
p=sys.argv[1]
try:
    d=json.load(open(p))
except Exception:
    d={}
c=os.environ.get("CMD","")
if c:
    d["statusLine"]={"type":"command","command":c}
else:
    d.pop("statusLine",None)
json.dump(d,open(p,"w"),indent=2)
open(p,"a").write("\n")
PY
    else
      echo "✗ need jq or python3 to edit settings.json safely"; return 1
    fi
  fi
}

R=$'\033[0m'; B=$'\033[1m'; G=$'\033[92m'; Y=$'\033[93m'; C=$'\033[96m'

if [ "$mode" = "off" ] || [ "$mode" = "--off" ] || [ "$mode" = "disable" ]; then
  set_statusline "" && printf "%s\n" "${Y}Status line turned off.${R} (Restart or /reload to apply.)" \
    || { echo "✗ failed to update settings.json"; exit 1; }
  exit 0
fi

[ -f "$SRC" ] || { echo "✗ renderer not found at $SRC"; exit 1; }
cp "$SRC" "$DST" 2>/dev/null && chmod +x "$DST" 2>/dev/null || { echo "✗ cannot install renderer to $DST"; exit 1; }
set_statusline "bash ${DST}" || { echo "✗ failed to update settings.json"; exit 1; }

# --- merry toast ---
printf "%s\n" "${B}${G}🎉 Status line engaged!${R} ${C}idea-to-production${R} is now live at the bottom of your terminal —"
printf "%s\n" "   gauges (context · rate limits), the ${B}product-lifecycle phase${R}, and the ${B}⚔ caught${R} reviewer tally."
printf "%s\n" "   ${Y}Tip:${R} run ${B}/concierge:statusline off${R} to remove it. Restart Claude Code (or /reload) to see it."
exit 0
