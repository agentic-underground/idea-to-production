#!/usr/bin/env bash
# verify-prereqs.sh — CI guard for the PREREQUISITES ↔ plugins contract.
#
# Asserts the deterministic invariants that keep the docs, the canonical dependency
# manifests, and the shipped MCP servers from drifting apart. Runnable locally
# (`bash scripts/verify-prereqs.sh`) and in CI (.github/workflows/verify.yml).
#
# Checks (each prints PASS/FAIL; the script exits 1 if any FAILs):
#   A. check.sh is byte-identical across all plugins (the canonical-copy promise).
#   B. every requirements.tsv row is well-formed (4 TAB fields, valid tier, non-empty probe).
#   C. the shipped MCP servers in plugins/*/.mcp.json match the "Shipped by the marketplace"
#      table in PREREQUISITES/40-mcp.md exactly (no claimed-but-absent / shipped-but-undocumented).
#   D. no PREREQUISITES/*.md table Probe cell fetches-and-executes remote code
#      (`npx -y <pkg>` / `uvx <pkg>`) — a probe must check presence, not download a package.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"

red=$'\033[31m'; green=$'\033[32m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; bold=""; dim=""; reset=""; }

fails=0
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; fails=$((fails+1)); }
section() { printf "\n%b%s%b\n" "$bold" "$1" "$reset"; }

# ── A. check.sh byte-identical across all plugins ────────────────────────────
section "A. check.sh canonical-copy parity"
mapfile -t checks < <(find plugins -path '*/skills/check/scripts/check.sh' | sort)
if [ "${#checks[@]}" -lt 2 ]; then
  fail "expected ≥2 check.sh copies, found ${#checks[@]}"
else
  sums="$(md5sum "${checks[@]}" | awk '{print $1}' | sort -u)"
  if [ "$(printf '%s\n' "$sums" | wc -l)" -eq 1 ]; then
    pass "${#checks[@]} copies identical ($sums)"
  else
    fail "check.sh copies diverge across plugins:"; md5sum "${checks[@]}" | sed 's/^/      /'
  fi
fi

# ── B. requirements.tsv rows well-formed ─────────────────────────────────────
section "B. requirements.tsv well-formed"
tsv_ok=1
while IFS= read -r tsv; do
  # awk: every non-comment/non-blank/non-header row must have 4 TAB fields,
  # a valid tier in column 3, and a non-empty probe in column 2.
  errs="$(awk -F'\t' '
    /^#/ || /^[[:space:]]*$/ { next }   # the header row is itself a `# name…` comment, so /^#/ skips it
    {
      if (NF!=4)                                            print "      "FILENAME":"NR": expected 4 TAB fields, got "NF
      else if ($2=="")                                      print "      "FILENAME":"NR": empty probe ("$1")"
      else if ($3!="required" && $3!="recommended" && $3!="optional") print "      "FILENAME":"NR": bad tier \""$3"\" ("$1")"
    }
  ' "$tsv")"
  if [ -n "$errs" ]; then tsv_ok=0; fail "malformed rows in $tsv:"; printf '%s\n' "$errs"; fi
done < <(find plugins -path '*/skills/check/requirements.tsv' | sort)
[ "$tsv_ok" -eq 1 ] && pass "all requirements.tsv rows well-formed (4 fields, valid tier, non-empty probe)"

# ── C. shipped .mcp.json servers ⟺ 40-mcp.md "Shipped" table ──────────────────
section "C. shipped MCP servers ⟺ 40-mcp.md"
if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 not found — required to read plugins/*/.mcp.json"
else
shipped_json="$(
  for f in plugins/*/.mcp.json; do
    python3 -c "import json,sys; print('\n'.join(json.load(open('$f')).get('mcpServers',{}).keys()))" 2>/dev/null
  done | sort -u | grep -v '^$'
)"
# Parse the table under "## Shipped by the marketplace" until the next "## " heading; the server
# name is the FIRST backticked token of each body row (assumes the `Server` column stays leftmost).
shipped_doc="$(
  awk '
    /^## Shipped by the marketplace/ { intbl=1; next }
    intbl && /^## / { exit }
    intbl && /^\|/ {
      if ($0 ~ /Server/ || $0 ~ /^\|[ :|-]+\|/) next   # header / separator
      if (match($0, /`[^`]+`/)) print substr($0, RSTART+1, RLENGTH-2)
    }
  ' PREREQUISITES/40-mcp.md | sort -u
)"
if [ "$shipped_json" = "$shipped_doc" ]; then
  pass "shipped servers match: $(echo "$shipped_json" | paste -sd' ' -)"
else
  fail "mismatch between .mcp.json and 40-mcp.md 'Shipped' table:"
  printf "      %bin .mcp.json :%b %s\n" "$dim" "$reset" "$(echo "$shipped_json" | paste -sd' ' -)"
  printf "      %bin 40-mcp.md :%b %s\n" "$dim" "$reset" "$(echo "$shipped_doc"  | paste -sd' ' -)"
fi
fi

# ── D. no Probe cell fetches-and-executes remote code ────────────────────────
section "D. Probe cells don't fetch remote code"
# For every markdown table that has a Probe column, flag any Probe cell whose command would
# DOWNLOAD AND RUN a package via an ephemeral runner — the property, not a flag-spelling:
#   • uvx / bunx / pnpm dlx     (always fetch an uninstalled tool), or
#   • npx -y/--yes …            (auto-install), or
#   • npx …@scope/pkg / pkg@ver (an explicit remote package spec).
# A probe must check presence (`command -v <launcher>`), never fetch. Bare `npx <localtool>
# --version` (e.g. vitest/playwright as project deps) is the established version-style convention
# and is NOT flagged. The Probe column is located per-table via the separator row, and reset at
# every table boundary (blank line / non-table line) so adjacent tables can't inherit an index.
# NOTE: the boolean below is kept on a SINGLE line on purpose — mawk (the default `awk` on
# Debian/Ubuntu + GitHub's ubuntu-latest) rejects a parenthesised expression split across lines.
# awk stderr is captured; a parse/runtime error fails the check loudly (never a vacuous PASS).
d_err="$(mktemp)"
offenders="$(
  for f in PREREQUISITES/*.md; do
    awk -F'|' -v file="$f" '
      function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
      { sep=$0; gsub(/[ \t|:-]/,"",sep) }
      /^\|/ && sep=="" { pcol=0; n=split(prev,h,"|"); for(i=1;i<=n;i++) if(trim(h[i])=="Probe") pcol=i; indata=1; prev=$0; next }
      /^[ \t]*$/ || /^[^|]/ { pcol=0; indata=0; prev=$0; next }
      { if (indata && pcol>0) { p=trim($pcol); gsub(/`/,"",p); if (p !~ /command -v/ && (p ~ /(^|[^[:alnum:]_])(uvx|bunx)([ \t]|$)/ || p ~ /pnpm[ \t]+dlx/ || p ~ /npx[ \t]+(-y|--yes)/ || p ~ /npx[ \t]+[^ \t]*@/)) print file" :: "p } prev=$0 }
    ' "$f" 2>>"$d_err"
  done
)"
if [ -s "$d_err" ]; then
  fail "awk error while scanning Probe cells — check D did not run:"; sed 's/^/      /' "$d_err"; rm -f "$d_err"
elif [ -z "$offenders" ]; then
  rm -f "$d_err"
  pass "no Probe cell downloads a package to test presence (use \`command -v …\`)"
else
  rm -f "$d_err"
  fail "Probe cells that fetch-and-execute remote code (use \`command -v <launcher>\` instead):"
  printf '%s\n' "$offenders" | sed 's/^/      /'
fi

# ── verdict ──────────────────────────────────────────────────────────────────
printf "\n"
if [ "$fails" -eq 0 ]; then
  printf "%b✓ PREREQUISITES contract verified — all checks passed.%b\n" "$green" "$reset"
  exit 0
else
  printf "%b✗ %d check(s) failed.%b\n" "$red" "$fails" "$reset"
  exit 1
fi
