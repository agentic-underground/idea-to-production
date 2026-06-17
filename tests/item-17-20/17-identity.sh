#!/usr/bin/env bash
# Test: [17] identity.sh — target + SELF/GEMBA resolution, seeding, one-field re-targeting.
# Run from the repo root: bash tests/item-17-20/17-identity.sh
FAIL=0
S="plugins/mission-control/skills/gemba/scripts/identity.sh"
[ -r "$S" ] || { echo "FAIL: script not found at $S"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }

bash -n "$S" || { echo "FAIL: syntax error in $S"; exit 1; }

# A sandbox project with a marketplace.json owner (so seeding has something to read) and no git remote.
TMP="$(mktemp -d)"; mkdir -p "$TMP/.claude-plugin"
cat > "$TMP/.claude-plugin/marketplace.json" <<'JSON'
{ "owner": { "name": "whatbirdisthat" } }
JSON

# AC2 — no identity file ⇒ seeded from marketplace owner; resolve returns valid JSON.
res="$(bash "$S" resolve "$TMP" 2>/dev/null)"
echo "$res" | jq . >/dev/null 2>&1 || { echo "FAIL: resolve did not emit JSON: $res"; FAIL=1; }
[ -f "$TMP/.i2p/identity.json" ] || { echo "FAIL: identity.json not seeded"; FAIL=1; }
org="$(echo "$res" | jq -r '.org')"
[ "$org" = "whatbirdisthat" ] || { echo "FAIL: seeded org should be whatbirdisthat, got '$org'"; FAIL=1; }

# AC1a — this-repo (no hint) ⇒ verdict self.
v="$(echo "$res" | jq -r '.verdict')"
[ "$v" = "self" ] || { echo "FAIL: no-hint verdict should be self, got '$v'"; FAIL=1; }

# AC1b — a token-fairness-class hint ⇒ verdict gemba + the token-fairness sibling repo.
gres="$(bash "$S" resolve "$TMP" "tf scheduler rate-limit budget" 2>/dev/null)"
[ "$(echo "$gres" | jq -r '.verdict')" = "gemba" ] || { echo "FAIL: tf-class hint should be gemba"; FAIL=1; }
[ "$(echo "$gres" | jq -r '.repo')" = "token-fairness" ] || { echo "FAIL: tf-class hint should resolve repo token-fairness"; FAIL=1; }
[ "$(echo "$gres" | jq -r '.matched')" = "token-fairness" ] || { echo "FAIL: matched sibling should be token-fairness"; FAIL=1; }

# AC3 — flipping github_org re-points EVERY target (shown via --dry-run, no file written).
tgt_default="$(bash "$S" targets "$TMP" 2>/dev/null)"
tgt_flipped="$(bash "$S" targets "$TMP" --org acme --dry-run 2>/dev/null)"
echo "$tgt_flipped" | jq -e 'all(.[]; .target | startswith("acme/"))' >/dev/null 2>&1 \
  || { echo "FAIL: --org acme should re-point every target to acme/*, got: $tgt_flipped"; FAIL=1; }
echo "$tgt_default" | jq -e 'all(.[]; .target | startswith("whatbirdisthat/"))' >/dev/null 2>&1 \
  || { echo "FAIL: default targets should be under whatbirdisthat/, got: $tgt_default"; FAIL=1; }
# both self AND the sibling re-pointed (more than one target)
[ "$(echo "$tgt_flipped" | jq 'length')" -ge 2 ] || { echo "FAIL: expected ≥2 targets (self + sibling)"; FAIL=1; }

# --dry-run must not have mutated the persisted github_org.
[ "$(jq -r '.github_org' "$TMP/.i2p/identity.json")" = "whatbirdisthat" ] \
  || { echo "FAIL: --dry-run flip leaked into the persisted identity.json"; FAIL=1; }

# A resolve with --org flip re-points the resolved self target too.
fself="$(bash "$S" resolve "$TMP" "" --org acme 2>/dev/null)"
[ "$(echo "$fself" | jq -r '.target')" = "acme/$(echo "$res" | jq -r '.repo')" ] \
  || { echo "FAIL: --org flip should re-point the resolved self target"; FAIL=1; }

# REGRESSION (#112 — HIGH) — git-remote seeding strips a trailing `.git` from the repo (both URL
# forms). GNU sed ERE has no non-greedy `+?`, so the old `(\.git)?$` left `repo.git` → a 404 on filing.
# SSH form: git@github.com:owner/some-repo.git
for url_form in "git@github.com:owner/some-repo.git" "https://github.com/owner/some-repo.git"; do
  GTMP="$(mktemp -d)"
  git -C "$GTMP" init -q
  git -C "$GTMP" remote add origin "$url_form"
  gres="$(bash "$S" resolve "$GTMP" 2>/dev/null)"
  grepo="$(echo "$gres" | jq -r '.repo')"
  [ "$grepo" = "some-repo" ] \
    || { echo "FAIL: git-remote seed should strip .git (form '$url_form'): repo='$grepo'"; FAIL=1; }
  case "$grepo" in *.git) echo "FAIL: seeded self.repo retains a .git suffix (form '$url_form'): '$grepo'"; FAIL=1 ;; esac
  rm -rf "$GTMP"
done

# REGRESSION (#112 — MEDIUM) — over-broad gemba routing. A single generic sibling-topic word anywhere
# in the hint must NOT hijack the route to the sibling repo. "token bucket bug in mission-control"
# carries the topic word "token" but is about THIS repo ⇒ self, not token-fairness.
rself="$(bash "$S" resolve "$TMP" "token bucket bug in mission-control" 2>/dev/null)"
[ "$(echo "$rself" | jq -r '.verdict')" = "self" ] \
  || { echo "FAIL: 'token bucket bug in mission-control' should route to self, got '$(echo "$rself" | jq -r '.verdict')'"; FAIL=1; }
# A sibling-topic substring inside another word must not match either (still a strong-signal test below).
rfoun="$(bash "$S" resolve "$TMP" "the scheduler in foundry" 2>/dev/null)"
[ "$(echo "$rfoun" | jq -r '.verdict')" = "self" ] \
  || { echo "FAIL: 'the scheduler in foundry' should route to self (one generic topic word)"; FAIL=1; }
# A real sibling reference (≥2 distinct sibling tokens as whole words) STILL routes to gemba — the
# tightening narrows incidental single-word collisions without losing a genuine cross-repo signal.
rtf="$(bash "$S" resolve "$TMP" "tf scheduler is starving the budget" 2>/dev/null)"
[ "$(echo "$rtf" | jq -r '.verdict')" = "gemba" ] \
  || { echo "FAIL: 'tf scheduler ... budget' (3 sibling tokens) should still route to gemba"; FAIL=1; }
[ "$(echo "$rtf" | jq -r '.matched')" = "token-fairness" ] \
  || { echo "FAIL: a genuine tf hint should match the token-fairness sibling"; FAIL=1; }

rm -rf "$TMP"
[ "$FAIL" -eq 0 ] && echo "PASS: [17] identity.sh resolve/seed/re-target" || exit 1
