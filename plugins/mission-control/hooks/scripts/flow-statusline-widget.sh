#!/usr/bin/env bash
# flow-statusline-version: 1
# Statusline widget: a clickable (OSC 8) link to the live flow board.
# Installed by flowctl into ~/.claude/state/statusline-widgets.d/flow.sh. The
# canonical i2p-statusline renderer feeds it the harness JSON on stdin and appends
# the single segment it prints to line 2. Prints NOTHING unless the daemon is alive
# for the cwd's project — so it lights up exactly when the board is reachable.
set +e
input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || exit 0
FLOW="$cwd/.flow"
pid="$(cat "$FLOW/pid" 2>/dev/null)" || exit 0
[ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || exit 0
port="$(cat "$FLOW/port" 2>/dev/null)"; tok="$(cat "$FLOW/token" 2>/dev/null)"
[ -n "$port" ] && [ -n "$tok" ] || exit 0
ip="$(hostname -I 2>/dev/null | awk '{print $1}')"; [ -n "$ip" ] || ip="127.0.0.1"
url="http://$ip:$port/?token=$tok"
# OSC 8 hyperlink wrapping a magenta label; terminals that ignore OSC 8 show the label as plain text.
printf '\033]8;;%s\033\\\033[95m⬢ flow ↗\033[0m\033]8;;\033\\' "$url"
exit 0
