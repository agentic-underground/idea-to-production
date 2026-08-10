#!/usr/bin/env bash
# verify-routing.sh — the context-routing PRE-PUSH GATE.
#
# Proves the marketplace's "context-fulfilment router" holds: (a) context stays LEAN — a task loads
# only what it needs — and (b) every PATH is REACHABLE — no skill/command/agent is unroutable and no
# route is dead. Deterministic, token-free, offline. Run it before you `git push`:
#
#     bash scripts/verify-routing.sh              # ✓/✗/⚠ table, exit 0 iff no hard FAIL
#     bash scripts/verify-routing.sh --strict     # also fail on WARN (flip the warn-then-flip checks)
#
# House style mirrors scripts/verify-prereqs.sh (section/pass/fail + a `fails` counter + exit 0|1).
# The single central ledger is scripts/routing/collisions.tsv; per-skill facts live in frontmatter.
# The pattern (and how to extend this suite) is documented in docs/guide/routing-tests.md.
#
# WARN-THEN-FLIP: checks that pass today gate hard (R1-R4, R8); checks that depend on unlanded
# context-routing RFC slices (R5 phase tags, R6 description budget, R7 roadmap seed-wording) WARN
# until those slices land, then flip to hard-FAIL (remove them from the WARN_CHECKS list below, or
# run --strict). The suite is a RED routing-contract the RFC implementation turns GREEN.

set -uo pipefail

strict=0
for arg in "$@"; do
  case "$arg" in
    --strict) strict=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) printf "unknown argument: %s (supported: --strict)\n" "$arg" >&2; exit 2 ;;
  esac
done

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"
LEDGER="scripts/routing/collisions.tsv"

red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; yellow=""; bold=""; dim=""; reset=""; }

fails=0
warns=0
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; fails=$((fails+1)); }
warn() { printf "  %b⚠ %s%b\n" "$yellow" "$1" "$reset"; warns=$((warns+1)); }
section() { printf "\n%b%s%b\n" "$bold" "$1" "$reset"; }
note() { printf "    %b%s%b\n" "$dim" "$1" "$reset"; }

# ── helpers ──────────────────────────────────────────────────────────────────

# frontmatter <file> : emit the leading ---…--- YAML block (exclusive of the fences).
frontmatter() {
  awk 'NR==1 && $0=="---"{inb=1;next} inb && $0=="---"{exit} inb' "$1"
}

# ledger_rows <kind> : emit the tab-rows of collisions.tsv whose first column == kind.
ledger_rows() {
  [ -f "$LEDGER" ] || return 0
  awk -F'\t' -v k="$1" '/^#/||NF<2{next} $1==k{print}' "$LEDGER"
}

# section_exists <plugin:name> : 0 if a skill dir OR command file OR agent file by that name exists.
section_exists() {
  local p="${1%%:*}" n="${1#*:}"
  [ -d "plugins/$p/skills/$n" ] || [ -f "plugins/$p/commands/$n.md" ] || [ -f "plugins/$p/agents/$n.md" ]
}

# All plugin dirs, sorted.
mapfile -t PLUGINS < <(find plugins -mindepth 1 -maxdepth 1 -type d | sort)

printf "%b%s%b\n" "$bold" "Context-routing pre-push gate — $(printf '%s' "$repo" | sed "s#$HOME#~#")" "$reset"

# ─────────────────────────────────────────────────────────────────────────────
# R1. Reachability — every skill/command/agent is routable (or declared orphan-by-design).
# ─────────────────────────────────────────────────────────────────────────────
section "R1. Reachability — no unroutable skill / command / agent"
declare -A ORPHAN=()
while IFS=$'\t' read -r kind key rest; do ORPHAN["$key"]=1; done < <(ledger_rows orphan)
r1_ok=1

# Commands are inherently reachable (a command file IS a slash command).
# Skills: reachable iff frontmatter names a /command, carries a quoted trigger phrase, OR is orphan-declared.
while IFS= read -r sdir; do
  name="$(basename "$sdir")"; plugin="$(basename "$(dirname "$(dirname "$sdir")")")"
  fm="$(frontmatter "$sdir/SKILL.md")"
  has_slash=0; has_phrase=0
  printf '%s' "$fm" | grep -qE '(^|[^[:alnum:]])/[a-z][a-z0-9:_-]+' && has_slash=1
  printf '%s' "$fm" | grep -qE '"[^"]+"' && has_phrase=1
  [ -f "plugins/$plugin/commands/$name.md" ] && has_slash=1
  if [ "$has_slash" -eq 0 ] && [ "$has_phrase" -eq 0 ] && [ -z "${ORPHAN[$plugin:$name]:-}" ]; then
    r1_ok=0; fail "unroutable skill $plugin:$name — no /command, no trigger phrase, not declared orphan in $LEDGER"
  fi
done < <(find plugins -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' | sort)

# Agents: reachable iff spawned-by-design (marker), user-triggerable (phrase), or orphan-declared.
agent_orphans=0
while IFS= read -r af; do
  name="$(basename "$af" .md)"; plugin="$(basename "$(dirname "$(dirname "$af")")")"
  fm="$(frontmatter "$af")"
  if printf '%s' "$fm" | grep -qiE 'spawned|invoke|triggered by|role parameter|on-demand|run the inspector|inspect |value.?handler'; then
    continue
  fi
  printf '%s' "$fm" | grep -qE '"[^"]+"' && continue
  [ -n "${ORPHAN[$plugin:$name]:-}" ] && continue
  r1_ok=0; fail "unroutable agent $plugin:$name — no spawn marker, no trigger phrase, not declared orphan"
  agent_orphans=$((agent_orphans+1))
done < <(find plugins -mindepth 3 -maxdepth 3 -type f -path '*/agents/*.md' | sort)

[ "$r1_ok" -eq 1 ] && pass "every skill & command is routable; every agent is spawned-by-design, user-triggerable, or declared"

# ─────────────────────────────────────────────────────────────────────────────
# R2. Ledger integrity — every section named in collisions.tsv exists on disk.
# ─────────────────────────────────────────────────────────────────────────────
section "R2. Ledger integrity — no dangling reference in $LEDGER"
r2_ok=1
if [ ! -f "$LEDGER" ]; then
  fail "$LEDGER missing — the routing ledger is the suite's source of truth"; r2_ok=0
else
  # collision rows: every member plugin:section must exist.
  while IFS=$'\t' read -r kind key members signal note; do
    IFS=',' read -ra ms <<< "$members"
    for m in "${ms[@]}"; do
      m="$(printf '%s' "$m" | tr -d ' ')"; [ -z "$m" ] && continue
      section_exists "$m" || { fail "$key: member '$m' does not exist on disk"; r2_ok=0; }
    done
    [ -z "$(printf '%s' "$signal" | tr -d ' ')" ] && { fail "$key: collision has an empty disambiguation signal"; r2_ok=0; }
  done < <(ledger_rows collision)
  # orphan rows: the key section must exist. (defect rows intentionally name a MISSING route — they
  # are exempt here and are validated by R3 instead.)
  while IFS=$'\t' read -r kind key rest; do
    section_exists "$key" || { fail "orphan row: key '$key' does not exist on disk"; r2_ok=0; }
  done < <(ledger_rows orphan)
fi
[ "$r2_ok" -eq 1 ] && pass "every collision member, orphan, and defect key resolves to a real section"

# ─────────────────────────────────────────────────────────────────────────────
# R3. Dead slash routes — a description names /plugin:cmd that resolves to nothing.
#   FAIL: nothing (no command, no skill) by that name AND not ledgered as a defect.
#   WARN: ledgered defect (tracked), or a slash that names a skill with no command file (inert).
# ─────────────────────────────────────────────────────────────────────────────
section "R3. Dead slash routes — every /plugin:cmd resolves"
declare -A DEFECT=()
while IFS=$'\t' read -r kind key rest; do DEFECT["$key"]=1; done < <(ledger_rows defect)
r3_ok=1
# collect every distinct /plugin:cmd referenced in any SKILL.md or command frontmatter
mapfile -t refs < <(
  for f in plugins/*/skills/*/SKILL.md plugins/*/commands/*.md; do frontmatter "$f"; done \
    | grep -oE '/(deliver|design|discover|i2p|ideate|operate|publish|secure):[a-z0-9-]+' | sort -u
)
for ref in "${refs[@]}"; do
  p="${ref%%:*}"; p="${p#/}"; cmd="${ref#*:}"
  [ -f "plugins/$p/commands/$cmd.md" ] && continue                      # real command → OK
  key="$p:$cmd"
  if [ -n "${DEFECT[$key]:-}" ]; then
    warn "known dead route $ref — command file missing (tracked in ledger)"
  elif [ -d "plugins/$p/skills/$cmd" ] || [ -f "plugins/$p/agents/$cmd.md" ]; then
    warn "$ref names a skill/agent but has no command file — typing it is inert (advisory)"
  else
    fail "dead route $ref — no command, skill, or agent by that name (add the command or fix the reference)"
    r3_ok=0
  fi
done
[ "$r3_ok" -eq 1 ] && pass "no untracked dead slash route (${#refs[@]} namespaced references checked)"

# ─────────────────────────────────────────────────────────────────────────────
# R4. Declared collisions — an identical quoted trigger phrase in >1 section must be ledgered.
#   (Deterministic leanness assertion: an undeclared phrase that could load N skills is a defect.)
# ─────────────────────────────────────────────────────────────────────────────
section "R4. Declared collisions — every shared trigger phrase is disambiguated"
r4_ok=1
# Build: normalized-phrase -> space-separated list of plugin:section that quote it.
declare -A PHRASE_SECTS=()
while IFS= read -r sdir; do
  name="$(basename "$sdir")"; plugin="$(basename "$(dirname "$(dirname "$sdir")")")"
  while IFS= read -r ph; do
    ph="$(printf '%s' "$ph" | tr '[:upper:]' '[:lower:]')"
    # ignore trivially short/edge phrases (single words, glob fragments)
    [ "${#ph}" -ge 8 ] || continue
    case " ${PHRASE_SECTS[$ph]:-} " in *" $plugin:$name "*) : ;; *) PHRASE_SECTS[$ph]="${PHRASE_SECTS[$ph]:-} $plugin:$name" ;; esac
  done < <(frontmatter "$sdir/SKILL.md" | grep -oE '"[^"]{6,}"' | tr -d '"')
done < <(find plugins -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' | sort)
# Ledger family membership sets.
mapfile -t FAM_MEMBERS < <(ledger_rows collision | awk -F'\t' '{gsub(/ /,"",$3); print $3}')
covered() { # $1=space-sep sections; covered if some family's member set ⊇ them
  local want="$1" fam s ok
  for fam in "${FAM_MEMBERS[@]}"; do
    ok=1
    for s in $want; do case ",$fam," in *",$s,"*) : ;; *) ok=0; break ;; esac; done
    [ "$ok" -eq 1 ] && return 0
  done
  return 1
}
collisions_found=0
for ph in "${!PHRASE_SECTS[@]}"; do
  read -ra sects <<< "${PHRASE_SECTS[$ph]}"
  [ "${#sects[@]}" -ge 2 ] || continue
  collisions_found=$((collisions_found+1))
  if ! covered "${sects[*]}"; then
    fail "undeclared collision: phrase \"$ph\" claimed by ${sects[*]} — add a collision row to $LEDGER"
    r4_ok=0
  fi
done
[ "$r4_ok" -eq 1 ] && pass "every shared exact trigger phrase is covered by a declared collision family ($collisions_found shared phrase(s), $(ledger_rows collision | wc -l | tr -d ' ') families)"

# ─────────────────────────────────────────────────────────────────────────────
# R5. Phase tag (RFC C1) — WARN-THEN-FLIP. Every skill should carry metadata.phase.
# ─────────────────────────────────────────────────────────────────────────────
section "R5. Phase tag present (metadata.phase) — RFC C1 [warn-then-flip]"
tagged=0; total=0; untagged_list=""
while IFS= read -r sdir; do
  total=$((total+1))
  if frontmatter "$sdir/SKILL.md" | grep -qE '^[[:space:]]*phase:[[:space:]]*\['; then
    tagged=$((tagged+1))
  else
    untagged_list="$untagged_list $(basename "$(dirname "$(dirname "$sdir")")"):$(basename "$sdir")"
  fi
done < <(find plugins -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' | sort)
if [ "$tagged" -eq "$total" ]; then
  pass "all $total skills carry a metadata.phase list"
else
  warn "$tagged/$total skills carry metadata.phase — lands in RFC slice 1 (untagged fail OPEN until then)"
  note "flip to hard-FAIL once slice 1 tags every skill (remove R5 from warn-then-flip / run --strict)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# R6. Description budget (RFC C5) — WARN-THEN-FLIP. ≤ 60 words / 400 chars.
# ─────────────────────────────────────────────────────────────────────────────
section "R6. Description budget ≤ 60 words / 400 chars — RFC C5 [warn-then-flip]"
over=0; worst=""; worstn=0
while IFS= read -r sdir; do
  name="$(basename "$(dirname "$(dirname "$sdir")")"):$(basename "$sdir")"
  # description: block scalar — take from `description:` to the next top-level key.
  desc="$(frontmatter "$sdir/SKILL.md" | awk '
    /^description:/{cap=1; sub(/^description:[ \t>|]*/,""); if($0!="")print; next}
    cap && /^[a-zA-Z_]+:/{exit}
    cap{print}')"
  words="$(printf '%s' "$desc" | wc -w | tr -d ' ')"
  if [ "$words" -gt 60 ]; then
    over=$((over+1)); [ "$words" -gt "$worstn" ] && { worstn=$words; worst=$name; }
  fi
done < <(find plugins -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' | sort)
if [ "$over" -eq 0 ]; then
  pass "every skill description is within the 60-word budget"
else
  warn "$over skill description(s) over the 60-word budget (worst: $worst @ ${worstn}w) — RFC C5 compression"
  note "flip to hard-FAIL as the per-plugin C5 slices land"
fi

# ─────────────────────────────────────────────────────────────────────────────
# R7. Roadmap seed-wording (RFC C3) — WARN-THEN-FLIP. Every EPIC/PLAN carries Phase + Loads tags.
# ─────────────────────────────────────────────────────────────────────────────
section "R7. Roadmap seed-wording (Phase + Loads tags) — RFC C3 [warn-then-flip]"
mapfile -t roadmap_items < <(find docs/roadmap plugins/deliver/skills/roadmapper/references/examples \
  -type f \( -name 'EPIC_*.md' -o -name 'PLAN_*.md' \) 2>/dev/null | sort)
if [ "${#roadmap_items[@]}" -eq 0 ]; then
  warn "no EPIC/PLAN items found (docs/roadmap/ empty — board-mode) — nothing to check yet"
else
  r7_missing=0
  for it in "${roadmap_items[@]}"; do
    grep -qE '^\|[[:space:]]*\*\*(Phase|Loads)\*\*' "$it" || { r7_missing=$((r7_missing+1)); note "missing Phase/Loads tag: $it"; }
  done
  if [ "$r7_missing" -eq 0 ]; then
    pass "all ${#roadmap_items[@]} roadmap item(s) carry Phase + Loads seed-wording"
  else
    warn "$r7_missing/${#roadmap_items[@]} roadmap item(s) lack Phase/Loads tags — RFC C3 (roadmapper emission)"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# R8. Lexicon ↔ ledger sync — the human STANDARD LEXICON stays in step with the machine ledger.
# ─────────────────────────────────────────────────────────────────────────────
section "R8. Lexicon ↔ ledger sync"
LEXICON="docs/guide/lexicon.md"
if [ ! -f "$LEXICON" ]; then
  warn "$LEXICON not present yet — lexicon sync deferred"
else
  r8_ok=1
  # every collision family-id and every defect key must be named in the lexicon.
  while IFS=$'\t' read -r kind key rest; do
    grep -qF "$key" "$LEXICON" || { fail "lexicon missing ledger entry '$key' (collisions.tsv ↔ lexicon.md drift)"; r8_ok=0; }
  done < <(ledger_rows collision; ledger_rows defect)
  [ "$r8_ok" -eq 1 ] && pass "every ledger collision-family & defect is documented in $LEXICON"
fi

# ── verdict ──────────────────────────────────────────────────────────────────
printf "\n"
effective_fails=$fails
[ "$strict" -eq 1 ] && effective_fails=$((fails + warns))
if [ "$effective_fails" -eq 0 ]; then
  if [ "$warns" -gt 0 ]; then
    printf "%b✓ routing gate passed%b  %b(%d warning(s) — warn-then-flip / tracked defects)%b\n" \
      "$green" "$reset" "$dim" "$warns" "$reset"
  else
    printf "%b✓ routing gate passed — context stays lean, every path is reachable.%b\n" "$green" "$reset"
  fi
  exit 0
else
  printf "%b✗ %d routing check(s) failed%b" "$red" "$fails" "$reset"
  [ "$strict" -eq 1 ] && [ "$warns" -gt 0 ] && printf "%b + %d warning(s) (--strict)%b" "$red" "$warns" "$reset"
  printf "\n"
  exit 1
fi
