#!/usr/bin/env bash
# ensure-browser.sh — idempotent DETECT → HEAL → VERIFY for the headless browser
# the marketplace's two browser resolvers (puppeteer/mmdc and the Playwright MCP)
# depend on. It is the self-verifying browser heal and the single source of truth
# for the browser env (PUPPETEER_EXECUTABLE_PATH / ms-playwright slot).
#
# The incident it answers: "browser not installed" is reported while a real,
# launchable Chrome already sits on disk in a sibling cache slot. The ONLY WAY is
# DIAGNOSE before installing — locate an existing browser, re-point the consumer
# (PUPPETEER_EXECUTABLE_PATH for puppeteer/mmdc; repair the empty ms-playwright
# stub slot for the MCP), then VERIFY the healed path actually launches.
#
# Modes:
#   --check   diagnose only (DEFAULT) — print what was found where, what is a
#             stub, what env would be exported; exit 0 if healthy, non-zero if not.
#   --fix     repair empty ms-playwright stub slots (atomic, self-loop guarded,
#             family-type guarded), then verify; export the resolver env.
#
# Safe-auto contract: a slot is only called "healed" once the
# healed binary VERIFIES a real headless launch. When unsure, REPORT — never heal.
#
# Idempotent: a second run is a no-op. Handles a missing $HOME and missing tools
# gracefully. No external repo references — the detect logic is canon here.
#
# Usage:  bash scripts/ensure-browser.sh [--check|--fix] [--quiet]
#         eval "$(bash scripts/ensure-browser.sh --fix --print-env)"   # to adopt env in a shell
set -uo pipefail

TAB=$'\t'   # field delimiter for the internal table rows (paths may contain anything but a TAB/NUL)

# ── presentation ─────────────────────────────────────────────────────────────
red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; yellow=""; bold=""; dim=""; reset=""; }

MODE="check"
QUIET=0
PRINT_ENV=0
for arg in "$@"; do
  case "$arg" in
    --check)     MODE="check" ;;
    --fix)       MODE="fix" ;;
    --print-env) PRINT_ENV=1; QUIET=1 ;;   # emit only `export …` lines, for eval
    --quiet)     QUIET=1 ;;
    -h|--help)
      sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) printf '%sunknown argument: %s%s\n' "$red" "$arg" "$reset" >&2; exit 2 ;;
  esac
done

say()  { [ "$QUIET" -eq 1 ] || printf '%b\n' "$*"; }
note() { [ "$QUIET" -eq 1 ] || printf '  %s%b%s\n' "$dim" "$*" "$reset"; }
ok()   { [ "$QUIET" -eq 1 ] || printf '  %b✓%b %b\n' "$green" "$reset" "$*"; }
warn() { [ "$QUIET" -eq 1 ] || printf '  %b!%b %b\n' "$yellow" "$reset" "$*"; }
bad()  { [ "$QUIET" -eq 1 ] || printf '  %b✗%b %b\n' "$red" "$reset" "$*"; }

# ── tool guards — degrade gracefully if a core tool is missing ───────────────
have() { command -v "$1" >/dev/null 2>&1; }
: "${HOME:=}"                       # tolerate an unset $HOME
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  # fall back to a sane guess so the globs below don't blow up; the user is told.
  HOME_WARN="HOME is unset or not a directory — cache discovery will be limited"
  HOME="${HOME:-/nonexistent-home}"
else
  HOME_WARN=""
fi

PW_ROOT="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
PUP_ROOT="$HOME/.cache/puppeteer"

# ── helpers ──────────────────────────────────────────────────────────────────
# is_launchable BIN — true iff BIN runs a headless render of about:blank.
is_launchable() {
  local bin="$1"
  [ -n "$bin" ] && [ -x "$bin" ] || return 1
  "$bin" --headless=new --no-sandbox --dump-dom about:blank >/dev/null 2>&1
}

# canon_path P — best-effort canonical absolute path (realpath if present).
canon_path() {
  if have realpath; then realpath -m -- "$1" 2>/dev/null || printf '%s' "$1"
  else printf '%s' "$1"; fi
}

# ── 1 · RESOLVE a real, launchable chrome binary (in priority order) ─────────
# Sets RESOLVED (path) and RESOLVED_SRC (human label) on success; empty on miss.
RESOLVED=""
RESOLVED_SRC=""
declare -a FOUND_TABLE=()   # "source|path|status" rows for the diagnosis table

record() { FOUND_TABLE+=("$1$TAB$2$TAB$3"); }

resolve_browser() {
  local cand=""

  # (a) system PATH
  for c in chromium chromium-browser google-chrome google-chrome-stable; do
    if have "$c"; then
      cand="$(command -v "$c")"
      record "system PATH ($c)" "$cand" "present"
      if [ -z "$RESOLVED" ]; then RESOLVED="$cand"; RESOLVED_SRC="system PATH ($c)"; fi
    fi
  done
  [ -n "$RESOLVED" ] || record "system PATH" "chromium / chromium-browser / google-chrome" "absent"

  # (b) a POPULATED ms-playwright chromium slot.
  #     Prefer the full chromium-* (not *headless_shell*): full chrome renders
  #     real pages; the headless_shell is a different binary kept for the MCP.
  local full="" shell="" slot bin
  for slot in "$PW_ROOT"/*chromium*/chrome-linux; do
    [ -d "$slot" ] || continue
    bin="$slot/chrome"
    case "$slot" in
      *headless_shell*)
        # the chrome-linux of a headless_shell slot ships `headless_shell`, not `chrome`
        if [ -x "$slot/headless_shell" ]; then
          record "ms-playwright (headless_shell)" "$slot/headless_shell" "present (headless-only)"
          [ -z "$shell" ] && shell="$slot/headless_shell"
        elif [ -x "$bin" ]; then
          record "ms-playwright (headless_shell)" "$bin" "present"
          [ -z "$shell" ] && shell="$bin"
        else
          record "ms-playwright (headless_shell)" "$slot" "STUB (no binary)"
        fi
        ;;
      *)
        if [ -x "$bin" ]; then
          record "ms-playwright (chromium)" "$bin" "present"
          [ -z "$full" ] && full="$bin"
        else
          record "ms-playwright (chromium)" "$slot" "STUB (no binary)"
        fi
        ;;
    esac
  done
  if [ -z "$RESOLVED" ] && [ -n "$full" ];  then RESOLVED="$full";  RESOLVED_SRC="ms-playwright chromium slot"; fi
  if [ -z "$RESOLVED" ] && [ -n "$shell" ]; then RESOLVED="$shell"; RESOLVED_SRC="ms-playwright headless_shell"; fi

  # (c) a populated puppeteer slot. The layout is
  #     chrome/<channel>-<ver>/chrome-linux*/chrome — glob both chrome-linux and
  #     chrome-linux64, and REQUIRE the binary (a half-extracted slot has none).
  local pbin
  if [ -d "$PUP_ROOT/chrome" ]; then
    for pbin in "$PUP_ROOT"/chrome/*/chrome-linux*/chrome; do
      [ -x "$pbin" ] || continue
      record "puppeteer cache" "$pbin" "present"
      if [ -z "$RESOLVED" ]; then RESOLVED="$pbin"; RESOLVED_SRC="puppeteer cache"; fi
    done
    # report a present-but-unextracted puppeteer slot so the diagnosis is honest
    local pdir
    for pdir in "$PUP_ROOT"/chrome/*/chrome-linux*; do
      [ -d "$pdir" ] || continue
      [ -x "$pdir/chrome" ] || record "puppeteer cache" "$pdir" "STUB (no binary)"
    done
  fi
}

# ── 2 · HEAL empty ms-playwright MCP stub slots (atomic, guarded) ────────────
# For each *chromium* chrome-linux slot LACKING its binary, if a sibling
# populated slot of the SAME FAMILY exists, atomically replace the empty slot
# dir with a symlink to the populated chrome-linux. Family guard: never link a
# full chromium binary into a *headless_shell* slot (different binaries). Only
# heal stubs whose slot dir name marks them as MCP/full chromium stubs; leave
# headless_shell stubs alone (report them). Self-loop guarded.
declare -a HEALED=()   # "slot" rows actually healed+verified
declare -a SKIPPED=()  # "slot|reason" rows reported, not healed

heal_stubs() {
  local do_fix="$1"   # 1 = actually mutate, 0 = report only
  local slot bin family populated canon_slot canon_pop

  # locate the populated FULL chromium chrome-linux (the heal donor)
  populated=""
  for slot in "$PW_ROOT"/*chromium*/chrome-linux; do
    case "$slot" in *headless_shell*) continue;; esac
    if [ -x "$slot/chrome" ]; then populated="$slot"; break; fi
  done

  for slot in "$PW_ROOT"/*chromium*/chrome-linux; do
    [ -d "$slot" ] || continue
    case "$slot" in
      *headless_shell*) family="headless_shell" ;;
      *)                family="chromium" ;;
    esac
    bin="$slot/chrome"
    [ "$family" = "headless_shell" ] && bin="$slot/headless_shell"
    # already populated → nothing to do (idempotent)
    [ -x "$bin" ] && continue

    if [ "$family" = "headless_shell" ]; then
      # TYPE GUARD: do not substitute a full chromium for a headless_shell stub —
      # different binaries, could give wrong rendering. Report, never heal.
      SKIPPED+=("$slot$TAB""headless_shell stub — different binary family, not auto-healed (report only)")
      continue
    fi

    # a full-chromium stub. We need a populated donor of the same family.
    if [ -z "$populated" ] || [ ! -x "$populated/chrome" ]; then
      SKIPPED+=("$slot$TAB""no populated chromium donor on disk — run: npx playwright install --with-deps chromium")
      continue
    fi

    # SELF-LOOP GUARD: never link a slot to itself (or to a path inside itself).
    canon_slot="$(canon_path "$slot")"
    canon_pop="$(canon_path "$populated")"
    if [ "$canon_slot" = "$canon_pop" ]; then
      continue   # the donor IS this slot; nothing to heal
    fi
    case "$canon_pop/" in
      "$canon_slot"/*) SKIPPED+=("$slot$TAB""donor is nested under the stub — refusing self-loop"); continue;;
    esac

    if [ "$do_fix" -ne 1 ]; then
      SKIPPED+=("$slot$TAB""EMPTY chromium stub — would heal → symlink to $populated (run --fix)")
      continue
    fi

    # ATOMIC replace: remove the empty stub dir, symlink the populated chrome-linux.
    if rm -rf -- "$slot" && ln -sfn -- "$populated" "$slot"; then
      # VERIFY: only call it healed if the healed path actually launches.
      if is_launchable "$slot/chrome"; then
        HEALED+=("$slot")
      else
        SKIPPED+=("$slot$TAB""healed symlink does NOT launch — manual fix: npx playwright install --with-deps chromium")
      fi
    else
      SKIPPED+=("$slot$TAB""could not replace stub dir (permissions?) — manual fix needed")
    fi
  done
}

# ── env single-source-of-truth (P0-2) ────────────────────────────────────────
print_env_block() {
  # emit to stdout, prefixed for eval; uses the resolved binary
  printf 'export PUPPETEER_EXECUTABLE_PATH=%q\n' "$RESOLVED"
  printf 'export PUPPETEER_SKIP_DOWNLOAD=1\n'
  printf 'export PLAYWRIGHT_BROWSERS_PATH=%q\n' "$PW_ROOT"
}

# ── run ───────────────────────────────────────────────────────────────────────
[ -n "$HOME_WARN" ] && { [ "$QUIET" -eq 1 ] || warn "$HOME_WARN"; }

resolve_browser

# --print-env: emit only export lines (for `eval "$(… --print-env)"`) ─────────
if [ "$PRINT_ENV" -eq 1 ]; then
  [ "$MODE" = "fix" ] && heal_stubs 1 >/dev/null 2>&1
  if [ -z "$RESOLVED" ]; then
    printf '# ensure-browser: no launchable browser found — run: npx playwright install --with-deps chromium\n' >&2
    exit 3
  fi
  print_env_block
  exit 0
fi

say ""
say "${bold}ensure-browser — DETECT → HEAL → VERIFY${reset}"
say "${dim}mode: --$MODE   playwright root: $PW_ROOT${reset}"

# ── diagnosis table ──────────────────────────────────────────────────────────
say ""
say "${bold}DETECT — browser binaries on disk${reset}"
if [ "${#FOUND_TABLE[@]}" -eq 0 ]; then
  bad "nothing probed (no \$HOME caches?)"
else
  for row in "${FOUND_TABLE[@]}"; do
    IFS=$'\t' read -r src path status <<<"$row"
    case "$status" in
      present*)  ok  "$(printf '%-34s %s' "$src" "$path")  ${dim}[$status]${reset}" ;;
      STUB*)     warn "$(printf '%-34s %s' "$src" "$path")  ${yellow}[$status]${reset}" ;;
      *)         note "$(printf '%-34s %s' "$src" "$path")  [$status]" ;;
    esac
  done
fi

# ── resolution result ─────────────────────────────────────────────────────────
say ""
say "${bold}RESOLVE — launchable browser the consumers will use${reset}"
if [ -z "$RESOLVED" ]; then
  bad "no chrome binary resolved on this machine"
  say ""
  say "  ${bold}Remediation:${reset} npx playwright install --with-deps chromium"
  exit 3
fi
ok "resolved: ${bold}$RESOLVED${reset}"
note "via: $RESOLVED_SRC"

# ── env that WOULD / WILL be exported (P0-2) ──────────────────────────────────
say ""
say "${bold}ENV — single-source-of-truth (P0-2)${reset}"
note "PUPPETEER_EXECUTABLE_PATH=$RESOLVED"
note "PUPPETEER_SKIP_DOWNLOAD=1"
note "PLAYWRIGHT_BROWSERS_PATH=$PW_ROOT"
say "  ${dim}adopt in a shell:  eval \"\$(bash scripts/ensure-browser.sh --$MODE --print-env)\"${reset}"
# make them live for any child of THIS process too
export PUPPETEER_EXECUTABLE_PATH="$RESOLVED"
export PUPPETEER_SKIP_DOWNLOAD=1
export PLAYWRIGHT_BROWSERS_PATH="$PW_ROOT"

# ── heal (or preview heal) ────────────────────────────────────────────────────
say ""
if [ "$MODE" = "fix" ]; then
  say "${bold}HEAL — repair empty ms-playwright stub slots${reset}"
  heal_stubs 1
else
  say "${bold}HEAL (preview) — empty ms-playwright stub slots${reset}"
  heal_stubs 0
fi
if [ "${#HEALED[@]}" -eq 0 ] && [ "${#SKIPPED[@]}" -eq 0 ]; then
  ok "no empty chromium stub slots — nothing to heal"
fi
for slot in "${HEALED[@]:-}"; do
  [ -n "$slot" ] && ok "healed+verified: $slot ${dim}→ $(readlink -f "$slot" 2>/dev/null || echo "$slot")${reset}"
done
for row in "${SKIPPED[@]:-}"; do
  [ -n "$row" ] || continue
  IFS=$'\t' read -r slot reason <<<"$row"
  warn "$slot"
  note "$reason"
done

# ── verify the resolved binary actually launches ─────────────────────────────
say ""
say "${bold}VERIFY — does the resolved browser launch headless?${reset}"
verify_fail=0
if is_launchable "$RESOLVED"; then
  ok "launch OK: $RESOLVED --headless=new --dump-dom about:blank"
else
  bad "the resolved binary did NOT launch (missing system libs?)"
  note "manual fix: npx playwright install-deps   (or install the chromium shared libraries)"
  verify_fail=1
fi

# ── exit health ───────────────────────────────────────────────────────────────
say ""
# unhealed full-chromium stubs are an unhealthy state in --check; in --fix they
# were either healed or are genuinely un-healable (reported).
unhealed_full=0
for row in "${SKIPPED[@]:-}"; do
  [ -n "$row" ] || continue
  case "$row" in
    *"EMPTY chromium stub"*|*"does NOT launch"*|*"could not replace"*) unhealed_full=$((unhealed_full+1));;
  esac
done

if [ "$verify_fail" -ne 0 ]; then
  bad "UNHEALTHY — a browser is on disk but does not launch on this box"
  exit 4
fi
if [ "$MODE" = "check" ] && [ "$unhealed_full" -ne 0 ]; then
  warn "DEGRADED — $unhealed_full empty chromium stub slot(s) present; run --fix to repair"
  exit 5
fi
ok "${bold}HEALTHY — browser resolved, env set, launch verified.${reset}"
say "  ${green}Light is green, trap is clean.${reset}"
exit 0
