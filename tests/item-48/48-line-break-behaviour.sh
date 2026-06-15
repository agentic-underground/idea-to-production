#!/usr/bin/env bash
# Test: [48] statusline widget line-break control — break-before / break-after / none.
# Exercises the real renderer (plugins/concierge/statusline/i2p-statusline.sh) with sample
# stdin JSON and a per-test conf, asserting the line-2 composition acceptance criteria.
# Run from the repo root: bash tests/item-48/48-line-break-behaviour.sh
FAIL=0
R="plugins/concierge/statusline/i2p-statusline.sh"
[ -r "$R" ] || { echo "FAIL: renderer not found at $R"; exit 1; }

JSON='{"context_window":{"used_percentage":40,"context_window_size":1000000,"total_input_tokens":400000},"rate_limits":{"five_hour":{"used_percentage":30,"resets_at":1750000000},"seven_day":{"used_percentage":12,"resets_at":1750400000}},"cost":{"total_cost_usd":1.0}}'

# render line 2 (drop the identity line 1, strip ANSI)
line2() { printf '%s' "$JSON" | CLAUDE_I2P_STATUSLINE_CONF="$1" bash "$R" 2>/dev/null | sed -n '2,$p' | sed 's/\x1b\[[0-9;]*m//g'; }
mkconf() { local f; f="$(mktemp)"; printf '%b' "$1" >"$f"; printf '%s' "$f"; }
nonblank() { line2 "$1" | grep -c .; }
blanks()   { line2 "$1" | grep -c '^$'; }

# AC1 — default (no break keys): all line-2 widgets flow on ONE line.
c="$(mkconf '')"
[ "$(nonblank "$c")" = "1" ] || { echo "FAIL AC1: default should be 1 flowing line, got $(nonblank "$c")"; FAIL=1; }

# AC2 — break_rate_7d=before: 7d starts a new line (2 lines; line 2 begins with '7d').
c="$(mkconf 'break_rate_7d=before\n')"
[ "$(nonblank "$c")" = "2" ] || { echo "FAIL AC2: expected 2 lines, got $(nonblank "$c")"; FAIL=1; }
line2 "$c" | sed -n '2p' | grep -q '^7d ' || { echo "FAIL AC2: line 2 should start with '7d'"; FAIL=1; }

# AC3 — break_context=after: a break follows ctx (2 lines; line 1 is ctx only).
c="$(mkconf 'break_context=after\n')"
[ "$(nonblank "$c")" = "2" ] || { echo "FAIL AC3: expected 2 lines, got $(nonblank "$c")"; FAIL=1; }
line2 "$c" | sed -n '1p' | grep -q '│' && { echo "FAIL AC3: line 1 should be ctx alone (no separator)"; FAIL=1; }

# AC4 — collapse: context=after AND rate_5h=before ⇒ exactly ONE break, no blank line.
c="$(mkconf 'break_context=after\nbreak_rate_5h=before\n')"
[ "$(nonblank "$c")" = "2" ] || { echo "FAIL AC4: expected 2 lines (collapsed), got $(nonblank "$c")"; FAIL=1; }
[ "$(blanks "$c")" = "0" ] || { echo "FAIL AC4: expected 0 blank lines, got $(blanks "$c")"; FAIL=1; }

# AC6 — absent widget data: a break on a widget with no data has no effect.
# (no lifecycle/cost ledger in JSON ⇒ break_lifecycle=before must NOT add a line)
c="$(mkconf 'break_lifecycle=before\n')"
[ "$(nonblank "$c")" = "1" ] || { echo "FAIL AC6: break on absent widget must not add a line, got $(nonblank "$c")"; FAIL=1; }

# AC7 — invalid/missing value behaves as none.
c="$(mkconf 'break_context=sideways\n')"
[ "$(nonblank "$c")" = "1" ] || { echo "FAIL AC7: invalid value should behave as none, got $(nonblank "$c")"; FAIL=1; }

# Renderer parses cleanly.
bash -n "$R" || { echo "FAIL: renderer has a syntax error"; FAIL=1; }

[ "$FAIL" -eq 0 ] && echo "PASS: [48] line-break behaviour — AC1/2/3/4/6/7 hold" || exit 1
