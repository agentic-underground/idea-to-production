#!/usr/bin/env bash
# Test: [48] set-widget-break.sh — idempotent upsert of break_<key> preserving the conf.
# Run from the repo root: bash tests/item-48/48-set-widget-break.sh
FAIL=0
S="plugins/i2p/statusline/set-widget-break.sh"
[ -r "$S" ] || { echo "FAIL: helper not found at $S"; exit 1; }

conf="$(mktemp)"; rm -f "$conf"   # start from a non-existent conf

# Seed with a visibility key + an unrelated break key (must be preserved).
printf 'rate_7d=1\nbreak_lifecycle=after\n' > "$conf"

# 1) upsert a new key (creates the line)
bash "$S" context before "$conf" >/dev/null || { echo "FAIL: upsert returned non-zero"; FAIL=1; }
grep -qx 'break_context=before' "$conf" || { echo "FAIL: break_context=before not written"; FAIL=1; }

# 2) re-upsert same key with a new value → REPLACED, not duplicated
bash "$S" context after "$conf" >/dev/null
[ "$(grep -c '^break_context=' "$conf")" = "1" ] || { echo "FAIL: break_context duplicated, got $(grep -c '^break_context=' "$conf")"; FAIL=1; }
grep -qx 'break_context=after' "$conf" || { echo "FAIL: break_context not updated to after"; FAIL=1; }

# 3) other lines preserved
grep -qx 'rate_7d=1' "$conf" || { echo "FAIL: visibility key not preserved"; FAIL=1; }
grep -qx 'break_lifecycle=after' "$conf" || { echo "FAIL: unrelated break key not preserved"; FAIL=1; }

# 4) invalid value → exit 2, conf unchanged
before_hash="$(md5sum "$conf" | awk '{print $1}')"
bash "$S" context sideways "$conf" >/dev/null 2>&1 && { echo "FAIL: invalid value should exit non-zero"; FAIL=1; }
[ "$(md5sum "$conf" | awk '{print $1}')" = "$before_hash" ] || { echo "FAIL: conf changed on invalid value"; FAIL=1; }

# 5) invalid key → exit 2
bash "$S" 'bad key' before "$conf" >/dev/null 2>&1 && { echo "FAIL: invalid key should exit non-zero"; FAIL=1; }

# 6) upsert into a non-existent conf creates it
conf2="$(mktemp)"; rm -f "$conf2"
bash "$S" catches before "$conf2" >/dev/null || { echo "FAIL: upsert into new conf failed"; FAIL=1; }
grep -qx 'break_catches=before' "$conf2" || { echo "FAIL: new conf not created with key"; FAIL=1; }

bash -n "$S" || { echo "FAIL: helper has a syntax error"; FAIL=1; }
rm -f "$conf" "$conf2"
[ "$FAIL" -eq 0 ] && echo "PASS: [48] set-widget-break upsert/preserve/validate" || exit 1
