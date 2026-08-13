#!/usr/bin/env bash
# resolve-review-profile.sh — resolve a project's PR-review profile to a lens directive.
# PLAN 0073.002 (EPIC 0073). Deterministic, offline, token-free. Read by /deliver:pr-review §2a to
# decide the composed reviewer's lenses: a declared profile OVERRIDES the diff-auto-select; absent ⇒ auto.
#
# Usage:
#   resolve-review-profile.sh [profile-file]   # default: .deliver/review-profile.md (cwd = project root)
#   resolve-review-profile.sh --self-test      # hermetic checks, no filesystem beyond a tmp fixture dir
#
# Output (exactly one line on stdout — the DIRECTIVE the skill consumes):
#   auto                                → run §2a auto-select (~3 load-bearing lenses by diff fingerprint)
#   fixed: CORRECTNESS,REGRESSION,DOC…  → compose EXACTLY these lenses into the one reviewer
#   holistic                            → one undifferentiated holistic pass (no lens decomposition)
#
# The shape is always ONE composed reviewer (PLAN 0073.001); the profile only changes WHICH lenses it
# carries — never the agent count. Malformed / unknown input FAILS SAFE to `auto` (with a stderr warn),
# so a broken profile can never silently narrow the gate below the adaptive default.

set -euo pipefail

# The canonical lens vocabulary (pr-review SKILL §2a). A declared lens must be one of these.
_RRP_LENSES="CORRECTNESS REGRESSION DOCUMENT SECURITY ARCHITECTURE PERFORMANCE API-CONTRACT OBSERVABILITY LICENSING PROMPT-INJECTION I18N DOC-ACCESSIBILITY DOC-LAYOUT"

_rrp_warn() { printf 'resolve-review-profile: %s\n' "$1" >&2; }

# _rrp_is_lens <token> : 0 if token is a canonical lens (exact, case-sensitive uppercased match).
_rrp_is_lens() { local t="$1" l; for l in $_RRP_LENSES; do [ "$t" = "$l" ] && return 0; done; return 1; }

# _rrp_field <key> <body> : echo the value of a `Key: value` line (first match, case-insensitive key),
# trimmed. A line after a `#` comment marker is ignored via a simple pre-strip. A MISSING key is not an
# error — the trailing `|| true` swallows grep's no-match so the pipeline stays rc=0 (else `set -e` +
# `pipefail` would abort the whole resolver on a Mode-less/comment-only file instead of failing safe).
_rrp_field() {
  local key="$1" body="$2"
  printf '%s\n' "$body" \
    | sed -e 's/[[:space:]]*#.*$//' \
    | grep -iE "^[[:space:]]*${key}[[:space:]]*:" \
    | head -1 \
    | sed -E "s/^[[:space:]]*[^:]*:[[:space:]]*//; s/[[:space:]]*$//" \
    || true
}

# _rrp_norm_lenses <csv> : uppercase + split on comma/space, keep only canonical lenses, dedup, CSV out.
_rrp_norm_lenses() {
  local raw="$1" tok out="" seen=" "
  raw="$(printf '%s' "$raw" | tr 'a-z' 'A-Z' | tr ',' ' ')"
  for tok in $raw; do
    _rrp_is_lens "$tok" || { _rrp_warn "ignoring unknown lens '$tok'"; continue; }
    case "$seen" in *" $tok "*) continue;; esac
    seen="$seen$tok "; out="${out:+$out,}$tok"
  done
  printf '%s' "$out"
}

# _rrp_resolve <body> : the pure core — body in, directive out. FAILS SAFE to `auto`.
_rrp_resolve() {
  local body="$1" mode lenses
  mode="$(_rrp_field mode "$body" | tr 'A-Z' 'a-z')"
  case "$mode" in
    holistic) printf 'holistic\n'; return 0 ;;
    fixed)
      lenses="$(_rrp_norm_lenses "$(_rrp_field lenses "$body")")"
      if [ -z "$lenses" ]; then
        _rrp_warn "Mode: fixed but no valid 'Lenses:' — falling back to auto"; printf 'auto\n'
      else
        printf 'fixed: %s\n' "$lenses"
      fi
      return 0 ;;
    ""|auto) printf 'auto\n'; return 0 ;;
    *) _rrp_warn "unknown Mode: '$mode' — falling back to auto"; printf 'auto\n'; return 0 ;;
  esac
}

_rrp_resolve_file() {
  local file="${1:-.deliver/review-profile.md}"
  [ -f "$file" ] || { printf 'auto\n'; return 0; }   # absent ⇒ auto (the documented default)
  _rrp_resolve "$(cat "$file")"
}

_rrp_self_test() {
  local fails=0
  _t() { if [ "$2" = "$3" ]; then printf '  ✓ %s\n' "$1"; else printf '  ✗ %s — expected [%s] got [%s]\n' "$1" "$3" "$2"; fails=$((fails+1)); fi; }

  echo "resolve-review-profile.sh --self-test (pure resolver)"
  _t "empty body → auto"                "$(_rrp_resolve '')"                                              "auto"
  _t "explicit Mode: auto → auto"       "$(_rrp_resolve 'Mode: auto')"                                    "auto"
  _t "Mode: holistic → holistic"        "$(_rrp_resolve 'Mode: holistic')"                                "holistic"
  _t "fixed + lenses → fixed csv"       "$(_rrp_resolve $'Mode: fixed\nLenses: correctness, regression, document' 2>/dev/null)" "fixed: CORRECTNESS,REGRESSION,DOCUMENT"
  _t "fixed lenses uppercased"          "$(_rrp_resolve $'Mode: fixed\nLenses: Security, API-Contract' 2>/dev/null)"            "fixed: SECURITY,API-CONTRACT"
  _t "fixed drops unknown lens"         "$(_rrp_resolve $'Mode: fixed\nLenses: correctness, bogus, docs?' 2>/dev/null)"          "fixed: CORRECTNESS"
  _t "fixed dedups"                     "$(_rrp_resolve $'Mode: fixed\nLenses: docs, DOCUMENT, document' 2>/dev/null)"           "fixed: DOCUMENT"
  _t "fixed w/ no valid lens → auto"    "$(_rrp_resolve $'Mode: fixed\nLenses: nope, bogus' 2>/dev/null)"                        "auto"
  _t "fixed w/ no Lenses line → auto"   "$(_rrp_resolve 'Mode: fixed' 2>/dev/null)"                                             "auto"
  _t "unknown mode → auto"              "$(_rrp_resolve 'Mode: turbo' 2>/dev/null)"                                             "auto"
  _t "comment after value ignored"      "$(_rrp_resolve $'Mode: holistic   # temporary' 2>/dev/null)"                           "holistic"
  _t "case-insensitive key"             "$(_rrp_resolve $'mODe: fixed\nLENSES: correctness' 2>/dev/null)"                       "fixed: CORRECTNESS"
  # 'docs' is NOT a canonical lens token — only DOCUMENT is; prove the alias is rejected (not silently kept)
  _t "bare 'docs' is not a lens"        "$(_rrp_resolve $'Mode: fixed\nLenses: docs' 2>/dev/null)"                              "auto"
  # file path — drive the LIVE top-level path (_rrp_resolve_file), not just the inner resolver, so a
  # `set -e`/`pipefail` abort on the real entrypoint is caught here (the inner-only tests above mask it
  # via nested $(…)). A PRESENT but Mode-less file MUST fail safe to `auto`, never crash/emit empty.
  local d; d="$(mktemp -d)"
  _t "absent file → auto"               "$(_rrp_resolve_file "$d/nope.md")"                               "auto"
  : > "$d/empty.md";                    _t "present empty file → auto"    "$(_rrp_resolve_file "$d/empty.md")"    "auto"
  printf '<!-- comment only -->\n' > "$d/c.md"; _t "comment-only file → auto" "$(_rrp_resolve_file "$d/c.md")" "auto"
  printf 'prose, no Mode line\n' > "$d/pr.md";  _t "Mode-less prose → auto"  "$(_rrp_resolve_file "$d/pr.md")"  "auto"
  printf 'Mode: fixed\nLenses: correctness, regression, document\n' > "$d/p.md"
  _t "present file parsed"              "$(_rrp_resolve_file "$d/p.md" 2>/dev/null)"                       "fixed: CORRECTNESS,REGRESSION,DOCUMENT"
  rm -rf "$d"

  if [ "$fails" -eq 0 ]; then echo "✓ self-test passed"; return 0; else echo "✗ self-test: $fails failure(s)"; return 1; fi
}

case "${1:-}" in
  --self-test) _rrp_self_test ;;
  -h|--help)   grep -E '^#( |$)' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
  *)           _rrp_resolve_file "${1:-.deliver/review-profile.md}" ;;
esac
