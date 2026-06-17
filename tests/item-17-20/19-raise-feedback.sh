#!/usr/bin/env bash
# Test: [19] raise-feedback.sh — dry-run · dedup · autonomy (same-repo auto / sibling needs --confirm).
# Run from the repo root: bash tests/item-17-20/19-raise-feedback.sh
# Uses a MOCK `gh` on PATH — NEVER touches a real GitHub repo.
FAIL=0
R="plugins/mission-control/skills/gemba/scripts/raise-feedback.sh"
[ -r "$R" ] || { echo "FAIL: $R not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
bash -n "$R" || { echo "FAIL: syntax error in $R"; exit 1; }

# Sandbox project (marketplace owner so identity seeds; no git remote ⇒ self = the temp basename).
TMP="$(mktemp -d)"; mkdir -p "$TMP/.claude-plugin"
cat > "$TMP/.claude-plugin/marketplace.json" <<'JSON'
{ "owner": { "name": "whatbirdisthat" } }
JSON

# Mock gh: search/issues controlled by GH_MOCK_DUP; POST returns a fixed url. Records the calls.
MOCK="$(mktemp -d)"; CALLS="$MOCK/calls.log"
cat > "$MOCK/gh" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$CALLS"
all="\$*"
if printf '%s' "\$all" | grep -q 'search/issues'; then
  # GH_MOCK_SEARCH_FAIL=1 simulates a transient search failure (gh exits non-zero, no output).
  if [ "\${GH_MOCK_SEARCH_FAIL:-0}" = "1" ]; then exit 4; fi
  if [ "\${GH_MOCK_DUP:-0}" = "1" ]; then echo "https://github.com/o/r/issues/9"; else echo ""; fi
  exit 0
fi
if printf '%s' "\$all" | grep -q 'POST'; then
  cat >/dev/null   # consume the --input - payload
  echo "https://github.com/o/r/issues/42"
  exit 0
fi
echo ""
EOF
chmod +x "$MOCK/gh"

# AC1a — --dry-run composes a correct body and files NOTHING (no gh on PATH at all).
out="$(bash "$R" --dir "$TMP" --title "Add abuse test for X" --body "Why this matters." --dry-run 2>&1)"
echo "$out" | grep -q "dry-run" || { echo "FAIL: dry-run should announce itself"; FAIL=1; }
echo "$out" | grep -q "gemba-feedback-slug: add-abuse-test-for-x" || { echo "FAIL: dry-run body should embed the stable slug marker"; FAIL=1; }
echo "$out" | grep -q "Why this matters." || { echo "FAIL: dry-run body should contain the supplied body"; FAIL=1; }
echo "$out" | grep -q "verdict=self" || { echo "FAIL: this-repo target should resolve verdict self"; FAIL=1; }

# AC2a — same-repo (self) files WITHOUT a prompt (mock gh, no dup).
out="$(PATH="$MOCK:$PATH" bash "$R" --dir "$TMP" --title "Add abuse test for X" --body "B" 2>&1)"; rc=$?
[ $rc -eq 0 ] || { echo "FAIL: same-repo file should exit 0, got $rc"; FAIL=1; }
echo "$out" | grep -q "filed on whatbirdisthat/" || { echo "FAIL: same-repo should file on the self target"; FAIL=1; }
grep -q 'POST' "$CALLS" || { echo "FAIL: same-repo should issue a gh api POST"; FAIL=1; }

# AC1b — a SECOND identical call is suppressed by DEDUP (search returns a hit; NO new POST).
: > "$CALLS"
out="$(PATH="$MOCK:$PATH" GH_MOCK_DUP=1 bash "$R" --dir "$TMP" --title "Add abuse test for X" --body "B" 2>&1)"; rc=$?
[ $rc -eq 0 ] || { echo "FAIL: deduped call should exit 0, got $rc"; FAIL=1; }
echo "$out" | grep -qi "DEDUP" || { echo "FAIL: identical second call should be deduped"; FAIL=1; }
grep -q 'POST' "$CALLS" && { echo "FAIL: deduped call must NOT POST a new issue"; FAIL=1; }

# AC2b — a SIBLING (gemba) repo REFUSES without --confirm (exit 3) and files nothing.
: > "$CALLS"
out="$(PATH="$MOCK:$PATH" bash "$R" --dir "$TMP" --hint "tf scheduler rate-limit budget" --title "tf gate blind" --body "B" 2>&1)"; rc=$?
[ $rc -eq 3 ] || { echo "FAIL: sibling without --confirm should exit 3, got $rc"; FAIL=1; }
echo "$out" | grep -qi "REFUSED" || { echo "FAIL: sibling refusal should say REFUSED"; FAIL=1; }
echo "$out" | grep -q "tf gate blind" || { echo "FAIL: refusal should print the would-be issue title"; FAIL=1; }
grep -q 'POST' "$CALLS" && { echo "FAIL: refused sibling must NOT POST"; FAIL=1; }

# AC2b' — the SAME sibling WITH --confirm files (mock gh).
: > "$CALLS"
out="$(PATH="$MOCK:$PATH" bash "$R" --dir "$TMP" --hint "tf scheduler rate-limit budget" --title "tf gate blind" --body "B" --confirm 2>&1)"; rc=$?
[ $rc -eq 0 ] || { echo "FAIL: sibling with --confirm should file (exit 0), got $rc"; FAIL=1; }
echo "$out" | grep -q "filed on whatbirdisthat/token-fairness" || { echo "FAIL: --confirm sibling should file on token-fairness"; FAIL=1; }
grep -q 'POST' "$CALLS" || { echo "FAIL: --confirm sibling should POST"; FAIL=1; }

# A sibling --dry-run composes (does not refuse) — preview is always safe.
out="$(bash "$R" --dir "$TMP" --hint "tf scheduler rate-limit" --title "tf gate blind" --dry-run 2>&1)"; rc=$?
[ $rc -eq 0 ] || { echo "FAIL: sibling --dry-run should compose (exit 0), got $rc"; FAIL=1; }
echo "$out" | grep -q "verdict=gemba" || { echo "FAIL: sibling --dry-run should report verdict gemba"; FAIL=1; }

# REGRESSION (#112 — MEDIUM) — dedup must FAIL CLOSED. A transient search error (gh exits non-zero)
# must NOT be read as "no duplicate → file"; the script must refuse to file and exit non-zero, and
# must NOT POST a new issue (otherwise a flaky search spams duplicates on the auto-file path).
: > "$CALLS"
out="$(PATH="$MOCK:$PATH" GH_MOCK_SEARCH_FAIL=1 bash "$R" --dir "$TMP" --title "Add abuse test for X" --body "B" 2>&1)"; rc=$?
[ $rc -ne 0 ] || { echo "FAIL: a failed dedup search must exit non-zero (fail closed), got $rc"; FAIL=1; }
echo "$out" | grep -qi "dedup search failed" || { echo "FAIL: a failed dedup search should explain it refused to file"; FAIL=1; }
grep -q 'POST' "$CALLS" && { echo "FAIL: a failed dedup search must NOT POST a new issue"; FAIL=1; }

# REGRESSION (#112 — MEDIUM) — an explicit --slug is SLUGIFIED too (never injected verbatim into the
# dedup query). A messy "Foo Bar: baz" must normalise to the same marker as the title path would.
out="$(bash "$R" --dir "$TMP" --title "Whatever title" --slug 'Foo Bar: baz' --body "B" --dry-run 2>&1)"; rc=$?
[ $rc -eq 0 ] || { echo "FAIL: --slug dry-run should compose (exit 0), got $rc"; FAIL=1; }
echo "$out" | grep -q "gemba-feedback-slug: foo-bar-baz" || { echo "FAIL: explicit --slug should be slugified to 'foo-bar-baz', got: $out"; FAIL=1; }
# And the SLUG: line printed by --dry-run reflects the normalised slug (no spaces/colons leak through).
echo "$out" | grep -Eq '^SLUG:[[:space:]]+foo-bar-baz$' || { echo "FAIL: --dry-run SLUG line should show the normalised slug foo-bar-baz"; FAIL=1; }

rm -rf "$TMP" "$MOCK"
[ "$FAIL" -eq 0 ] && echo "PASS: [19] raise-feedback dry-run/dedup/autonomy" || exit 1
