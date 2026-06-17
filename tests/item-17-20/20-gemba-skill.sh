#!/usr/bin/env bash
# Test: [20] the gemba skill — SKILL.md frontmatter, /gemba command, README mention, script wiring.
# Run from the repo root: bash tests/item-17-20/20-gemba-skill.sh
FAIL=0
SKILL="plugins/operate/skills/gemba/SKILL.md"
CMD="plugins/operate/commands/gemba.md"
README="plugins/operate/README.md"
DIR="plugins/operate/skills/gemba/scripts"

[ -r "$SKILL" ] || { echo "FAIL: $SKILL not found"; exit 1; }

# Frontmatter: name: gemba + a non-empty description (verify-prereqs §C/J requirement).
fm="$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f{print}' "$SKILL")"
echo "$fm" | grep -Eq '^name:[[:space:]]*gemba[[:space:]]*$' || { echo "FAIL: SKILL.md frontmatter name must be 'gemba'"; FAIL=1; }
echo "$fm" | grep -Eq '^description:' || { echo "FAIL: SKILL.md frontmatter missing description"; FAIL=1; }

# The skill orchestrates the three (+detector) scripts via ${CLAUDE_PLUGIN_ROOT} — thin skill, fat scripts.
for s in identity.sh learnings.sh overdue-learnings.sh raise-feedback.sh; do
  grep -q "$s" "$SKILL" || { echo "FAIL: SKILL.md does not reference $s"; FAIL=1; }
  [ -x "$DIR/$s" ] || { echo "FAIL: $DIR/$s missing or not executable"; FAIL=1; }
done
grep -q 'CLAUDE_PLUGIN_ROOT' "$SKILL" || { echo "FAIL: SKILL.md must resolve scripts via \${CLAUDE_PLUGIN_ROOT}"; FAIL=1; }

# The three steps are named: capture · route · raise.
for kw in capture route raise; do
  grep -qi "$kw" "$SKILL" || { echo "FAIL: SKILL.md missing the '$kw' step"; FAIL=1; }
done
# Canonical learnings shape is named.
grep -q 'incident-report' "$SKILL" || { echo "FAIL: SKILL.md should reference the incident-report.md learnings shape"; FAIL=1; }
grep -q 'proposed-solutions' "$SKILL" || { echo "FAIL: SKILL.md should reference proposed-solutions.md"; FAIL=1; }

# The /gemba command file exists and carries a description.
[ -r "$CMD" ] || { echo "FAIL: $CMD not found"; FAIL=1; }
[ -r "$CMD" ] && { awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f{print}' "$CMD" | grep -Eq '^description:' \
  || { echo "FAIL: $CMD missing a description frontmatter"; FAIL=1; }; }

# The README names the /gemba command (verify-prereqs §C/J: README must name the skill's /command).
grep -q '`/gemba`' "$README" || { echo "FAIL: $README does not name the /gemba command"; FAIL=1; }

[ "$FAIL" -eq 0 ] && echo "PASS: [20] gemba skill wiring (frontmatter · command · README · scripts)" || exit 1
