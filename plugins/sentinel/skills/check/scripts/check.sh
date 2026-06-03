#!/usr/bin/env bash
# check.sh — verify this plugin's external tool dependencies are installed & reachable.
#
# CANONICAL COPY — keep byte-identical across foundry/sentinel/pressroom skills/check/scripts/.
# Only the sibling requirements.tsv differs per plugin. (Inspector/CI may assert the copies match.)
#
# Reads requirements.tsv sitting next to this script:
#   name <TAB> probe-command <TAB> tier(required|recommended|optional) <TAB> install-hint
# A row PASSES when `bash -c "<probe-command>"` exits 0.
#
# Usage:  bash check.sh [--strict] [--tier=required|recommended|optional] [path/to/requirements.tsv]
#   --strict   exit non-zero if any REQUIRED tool is missing (default: advisory, always exit 0)
#   --tier=X   only check rows of tier X
#
# Advisory by default: a missing tool is reported, not fatal — the plugins degrade gracefully.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# requirements.tsv lives in the skill root (one level up from scripts/)
tsv="${here}/../requirements.tsv"
[ -f "$tsv" ] || tsv="${here}/requirements.tsv"
strict=0
only_tier=""

for arg in "$@"; do
  case "$arg" in
    --strict)   strict=1 ;;
    --tier=*)   only_tier="${arg#--tier=}" ;;
    *)          tsv="$arg" ;;
  esac
done

[ -f "$tsv" ] || { echo "requirements.tsv not found: $tsv" >&2; exit 2; }

green=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; bold=$'\033[1m'; reset=$'\033[0m'
[ -t 1 ] || { green=""; red=""; dim=""; bold=""; reset=""; }

declare -i n_ok=0 n_miss=0 req_miss=0
# plugin name = .../plugins/<plugin>/skills/check/scripts  → 3 levels up from here
plugin_name="$(basename "$(cd "$here/../../.." && pwd)")"
printf "%b\n" "${bold}Dependency check — ${plugin_name}${reset}"
printf "%b\n" "${dim}$tsv${reset}"

current_tier=""
while IFS=$'\t' read -r name probe tier hint; do
  # skip comments / blanks / header
  [ -z "${name:-}" ] && continue
  case "$name" in \#*) continue ;; esac
  [ "$name" = "name" ] && continue
  [ -n "$only_tier" ] && [ "$tier" != "$only_tier" ] && continue

  if [ "$tier" != "$current_tier" ]; then
    current_tier="$tier"
    printf "\n%b\n" "${bold}[${tier}]${reset}"
  fi

  if bash -c "$probe" >/dev/null 2>&1; then
    printf "  %b✓%b %-26s\n" "$green" "$reset" "$name"
    n_ok+=1
  else
    printf "  %b✗%b %-26s %b%s%b\n" "$red" "$reset" "$name" "$dim" "→ $hint" "$reset"
    n_miss+=1
    [ "$tier" = "required" ] && req_miss+=1
  fi
done < "$tsv"

printf "\n%b\n" "${bold}${n_ok} present, ${n_miss} missing${reset} (${req_miss} required)."
if [ "$strict" -eq 1 ] && [ "$req_miss" -gt 0 ]; then
  printf "%b\n" "${red}STRICT: required tool(s) missing — failing.${reset}"
  exit 1
fi
exit 0
