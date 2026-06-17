#!/usr/bin/env bash
# Test: [100][101] lifecycle v2 — the nine-phase DELIVER + BUILD⇄ASSURE⇄SECURE loop model.
# Covers the state machine (lifecycle.sh) + cost seeding (cost.sh) + the canonical doc (#100).
# Run from the repo root: bash tests/item-100-101/100-101-lifecycle-v2.sh
# Requires jq (the write paths need it; the suite skips with a clear note when jq is absent).
set -uo pipefail
FAIL=0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
S="${ROOT}/plugins/i2p/skills/lifecycle/scripts/lifecycle.sh"
C="${ROOT}/plugins/i2p/skills/lifecycle/scripts/cost.sh"
DOC="${ROOT}/plugins/i2p/knowledge/product-lifecycle.md"
[ -r "$S" ] || { echo "FAIL: lifecycle.sh not found at $S"; exit 1; }
[ -r "$C" ] || { echo "FAIL: cost.sh not found at $C"; exit 1; }
[ -r "$DOC" ] || { echo "FAIL: product-lifecycle.md not found at $DOC"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq absent — write-path assertions need jq"; exit 0; }

ok()   { echo "  ok: $1"; }
bad()  { echo "  FAIL: $1"; FAIL=1; }
phase(){ jq -r '.current_phase' "$1/.i2p/lifecycle.json"; }
field(){ jq -r ".$2 // empty" "$1/.i2p/lifecycle.json"; }

# --- 1) bash -n clean on both scripts -----------------------------------------
bash -n "$S" || bad "lifecycle.sh has a syntax error"
bash -n "$C" || bad "cost.sh has a syntax error"

# --- 2) PHASES is the nine-phase v2 string in BOTH scripts --------------------
NINE="DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE"
grep -q "PHASES=\"${NINE}\"" "$S" && ok "lifecycle.sh PHASES is the 9-phase v2 string" \
  || bad "lifecycle.sh PHASES is not the 9-phase v2 string"
grep -q "PHASES=\"${NINE}\"" "$C" && ok "cost.sh PHASES is the 9-phase v2 string" \
  || bad "cost.sh PHASES is not the 9-phase v2 string"

# --- 3) init writes the 9 phases + the loop fields ---------------------------
T="$(mktemp -d)"; bash "$S" --dir "$T" init demo >/dev/null
nphases="$(jq -r '.phases | length' "$T/.i2p/lifecycle.json")"
[ "$nphases" = "9" ] && ok "init wrote 9 phases" || bad "init wrote $nphases phases, expected 9"
[ "$(field "$T" loop_state)" = "BUILD" ] && ok "init seeded loop_state=BUILD" \
  || bad "init loop_state=$(field "$T" loop_state), expected BUILD"
[ "$(field "$T" loop_pass)" = "1" ] && ok "init seeded loop_pass=1" \
  || bad "init loop_pass=$(field "$T" loop_pass), expected 1"

# --- 4) the DELIVER transition: IDEATE → DELIVER → DESIGN --------------------
bash "$S" --dir "$T" set IDEATE >/dev/null
bash "$S" --dir "$T" advance   >/dev/null    # IDEATE -> DELIVER
[ "$(phase "$T")" = "DELIVER" ] && ok "IDEATE advances to DELIVER" \
  || bad "IDEATE advanced to $(phase "$T"), expected DELIVER"
bash "$S" --dir "$T" advance >/dev/null      # DELIVER -> DESIGN
[ "$(phase "$T")" = "DESIGN" ] && ok "DELIVER advances to DESIGN" \
  || bad "DELIVER advanced to $(phase "$T"), expected DESIGN"

# --- 5) loop back-edge: fail ASSURE re-enters BUILD, does NOT reach PUBLISH ---
bash "$S" --dir "$T" set BUILD  >/dev/null
bash "$S" --dir "$T" done BUILD >/dev/null    # BUILD -> ASSURE (loop_state=ASSURE)
[ "$(field "$T" loop_state)" = "ASSURE" ] && ok "BUILD done sets loop_state=ASSURE" \
  || bad "loop_state=$(field "$T" loop_state) at ASSURE, expected ASSURE"
before_pass="$(field "$T" loop_pass)"
bash "$S" --dir "$T" fail ASSURE >/dev/null
[ "$(phase "$T")" = "BUILD" ] && ok "fail ASSURE re-enters BUILD" \
  || bad "fail ASSURE left phase at $(phase "$T"), expected BUILD"
[ "$(field "$T" loop_state)" = "BUILD" ] && ok "fail ASSURE sets loop_state=BUILD" \
  || bad "fail ASSURE loop_state=$(field "$T" loop_state), expected BUILD"
[ "$(field "$T" loop_pass)" = "$((before_pass + 1))" ] && ok "fail ASSURE records the iteration (loop_pass++)" \
  || bad "loop_pass=$(field "$T" loop_pass), expected $((before_pass + 1))"
[ "$(phase "$T")" != "PUBLISH" ] && ok "fail ASSURE does NOT advance to PUBLISH" \
  || bad "fail ASSURE wrongly advanced to PUBLISH"

# fail only accepts the loop GATES — BUILD / garbage are rejected without touching state
bash "$S" --dir "$T" set ASSURE >/dev/null
snap="$(jq -S . "$T/.i2p/lifecycle.json" | md5sum)"
bash "$S" --dir "$T" fail BUILD  >/dev/null 2>&1
bash "$S" --dir "$T" fail BOGUS  >/dev/null 2>&1
[ "$(jq -S . "$T/.i2p/lifecycle.json" | md5sum)" = "$snap" ] && ok "fail rejects non-gate args without mutating state" \
  || bad "fail mutated state on a non-gate arg"

# --- 6) loop exit: all three satisfied → SECURE advances to PUBLISH ----------
bash "$S" --dir "$T" set BUILD   >/dev/null
bash "$S" --dir "$T" done BUILD  >/dev/null    # -> ASSURE
bash "$S" --dir "$T" done ASSURE >/dev/null    # -> SECURE
[ "$(phase "$T")" = "SECURE" ] && ok "clean BUILD→ASSURE→SECURE walk" \
  || bad "expected SECURE, got $(phase "$T")"
bash "$S" --dir "$T" done SECURE >/dev/null    # loop exit -> PUBLISH
[ "$(phase "$T")" = "PUBLISH" ] && ok "all-three-satisfied: SECURE exits the loop to PUBLISH" \
  || bad "SECURE exit went to $(phase "$T"), expected PUBLISH"

# --- 7) OPERATE↻ wrap preserved + bump_cycle ---------------------------------
bash "$S" --dir "$T" set OPERATE  >/dev/null
cyc_before="$(jq -r '.cycle' "$T/.i2p/lifecycle.json")"
bash "$S" --dir "$T" done OPERATE >/dev/null   # wrap -> DISCOVER, cycle++
[ "$(phase "$T")" = "DISCOVER" ] && ok "OPERATE wraps to DISCOVER (↻)" \
  || bad "OPERATE wrap went to $(phase "$T"), expected DISCOVER"
[ "$(jq -r '.cycle' "$T/.i2p/lifecycle.json")" = "$((cyc_before + 1))" ] && ok "OPERATE wrap bumps the cycle" \
  || bad "cycle not bumped on wrap"
rm -rf "$T"

# --- 8) additive schema: a LEGACY 8-phase file (no loop fields) still loads ---
L="$(mktemp -d)"; mkdir -p "$L/.i2p"
cat > "$L/.i2p/lifecycle.json" <<'EOF'
{"product":"legacy","current_phase":"ASSURE","phases":["DISCOVER","IDEATE","DESIGN","BUILD","ASSURE","SECURE","PUBLISH","OPERATE"],"cycle":1,"started_at":"2026-01-01T00:00:00Z","history":[{"phase":"ASSURE","at":"2026-01-01T00:00:00Z"}]}
EOF
out="$(bash "$S" --dir "$L" get 2>/dev/null)"; rc=$?
{ [ "$rc" = "0" ] && [ "$out" = "ASSURE" ]; } && ok "legacy 8-phase file: get succeeds without error" \
  || bad "legacy get failed (rc=$rc, out=$out)"
bash "$S" --dir "$L" status >/dev/null 2>&1 && ok "legacy 8-phase file: status succeeds without error" \
  || bad "legacy status failed"
# corrupt-vs-not-started distinction preserved
printf 'not json{' > "$L/.i2p/lifecycle.json"
bash "$S" --dir "$L" get >/dev/null 2>&1; [ $? -ne 0 ] && ok "corrupt file still refused (get exits non-zero)" \
  || bad "corrupt file not refused"
N="$(mktemp -d)"
bash "$S" --dir "$N" status 2>&1 | grep -q "not started" && ok "absent file reads as not-started (distinct from corrupt)" \
  || bad "absent file did not read as not-started"
rm -rf "$L" "$N"

# --- 9) cost.sh seeds DELIVER with a non-zero estimate -----------------------
K="$(mktemp -d)"; bash "$C" estimate "$K" >/dev/null
deliver_est="$(jq -r '.phases.DELIVER.estimate_tokens // 0' "$K/.i2p/cost.json")"
{ [ -n "$deliver_est" ] && [ "$deliver_est" -gt 0 ] 2>/dev/null; } && ok "cost.sh seeds DELIVER (estimate=$deliver_est)" \
  || bad "cost.sh did not seed a non-zero DELIVER estimate (got $deliver_est)"
ncost="$(jq -r '.phases | keys | length' "$K/.i2p/cost.json")"
[ "$ncost" = "9" ] && ok "cost.sh seeds all nine phases" || bad "cost.sh seeded $ncost phases, expected 9"
rm -rf "$K"

# --- 10) canonical doc (#100): no stale 8-phase wording, v2 model present ----
if grep -nq '(n/8)\|/8)\|8 phases\|BUILD ▸ ASSURE ▸ SECURE ▸ PUBLISH' "$DOC"; then
  bad "product-lifecycle.md still carries stale 8-phase wording"
else ok "product-lifecycle.md has no stale 8-phase wording"; fi
grep -q 'DELIVER' "$DOC" && ok "doc names the DELIVER phase" || bad "doc does not mention DELIVER"
grep -q 'BUILD ⇄ ASSURE ⇄ SECURE' "$DOC" && ok "doc describes the BUILD⇄ASSURE⇄SECURE loop" \
  || bad "doc does not describe the loop"
grep -q 'nine working phases' "$DOC" && ok "doc states nine working phases" || bad "doc does not state nine phases"

[ "$FAIL" -eq 0 ] && echo "PASS: [100][101] lifecycle v2 — DELIVER phase + BUILD⇄ASSURE⇄SECURE loop" || exit 1
