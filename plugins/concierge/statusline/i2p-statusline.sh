#!/usr/bin/env bash
# i2p-statusline-version: 2
# idea-to-production rich status line — two-line layout, wide gauges, caught widget.
# Reads JSON from stdin, renders a two-line ANSI status bar.
# Never exits non-zero; all fields degrade gracefully when absent.
#
# CANONICAL COPY — shipped by the `concierge` plugin. /concierge:statusline copies this
# to ~/.claude/statusline-command.sh and points settings.json at it (settings.json cannot
# expand ${CLAUDE_PLUGIN_ROOT}). Edit here; re-run /concierge:statusline to update.
#
# VERSION STAMP (`i2p-statusline-version:` above) — bump it on every renderer change. The
# SessionStart drift check (hooks/check-statusline-drift.sh) compares the installed copy's
# stamp/md5 against this shipped renderer and offers /concierge:statusline to refresh on drift.

set +e
input=$(cat)

# ---------------------------------------------------------------------------
# JSON extraction helper — jq with pure-bash fallback
# Usage: jget '.some.path // empty'
# ---------------------------------------------------------------------------
_jq_ok=''
command -v jq >/dev/null 2>&1 && _jq_ok=1

jget() {
  if [ -n "$_jq_ok" ]; then
    printf '%s' "$input" | jq -r "${1} // empty" 2>/dev/null || true
  else
    # Minimal pure-bash fallback: strip outer object braces then regex-grep
    # Only handles simple string/number leaf values at any depth via key name.
    local key
    key=$(printf '%s' "$1" | sed 's|.*\.\([a-zA-Z_][a-zA-Z0-9_]*\).*|\1|')
    printf '%s' "$input" \
      | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[^,}]*" 2>/dev/null \
      | head -1 \
      | sed 's/.*:[[:space:]]*//' \
      | tr -d '"' \
      | tr -d "'" \
      | sed 's/[[:space:]]*$//' \
      || true
  fi
}

# ---------------------------------------------------------------------------
# Extract all fields
# ---------------------------------------------------------------------------
user=$(whoami 2>/dev/null || echo "user")
host=$(hostname -s 2>/dev/null || echo "host")

cwd=$(jget '.workspace.current_dir')
[ -z "$cwd" ] && cwd=$(jget '.cwd')
[ -z "$cwd" ] && cwd=$(pwd 2>/dev/null || echo "")
# Abbreviate $HOME to ~
home_dir="$HOME"
[ -n "$home_dir" ] && cwd="${cwd/#$home_dir/\~}"

proj_dir=$(jget '.workspace.project_dir')
[ -n "$proj_dir" ] && proj_dir="${proj_dir/#$HOME/\~}"
[ "$proj_dir" = "$cwd" ] && proj_dir=""

model_name=$(jget '.model.display_name')
model_id=$(jget '.model.id')
version=$(jget '.version')
session_name=$(jget '.session_name')
output_style=$(jget '.output_style.name')

# Repo
repo_host=$(jget '.workspace.repo.host')
repo_owner=$(jget '.workspace.repo.owner')
repo_repo=$(jget '.workspace.repo.name')
repo=""
[ -n "$repo_owner" ] && [ -n "$repo_repo" ] && repo="${repo_owner}/${repo_repo}"

# Branch: prefer worktree.branch, then workspace.git_worktree, then git cmd
branch=$(jget '.worktree.branch')
[ -z "$branch" ] && branch=$(jget '.workspace.git_worktree')
if [ -z "$branch" ] && [ -n "$cwd" ]; then
  _gitcwd="${cwd/#\~/$HOME}"
  branch=$(git -C "$_gitcwd" symbolic-ref --short HEAD 2>/dev/null || true)
fi

# PR
pr_number=$(jget '.pr.number')
pr_state=$(jget '.pr.review_state')

# Context window
used_pct=$(jget '.context_window.used_percentage')
ctx_total=$(jget '.context_window.context_window_size')
ctx_used_tokens=$(jget '.context_window.total_input_tokens')

# Effort / thinking
effort=$(jget '.effort.level')
thinking=$(jget '.thinking.enabled')

# Vim mode
vim_mode=$(jget '.vim.mode')

# Agent
agent_name=$(jget '.agent.name')
agent_type=$(jget '.agent.type')

# Worktree info
wt_name=$(jget '.worktree.name')
wt_branch=$(jget '.worktree.branch')

# Rate limits
five_h_pct=$(jget '.rate_limits.five_hour.used_percentage')
five_h_reset=$(jget '.rate_limits.five_hour.resets_at')
seven_d_pct=$(jget '.rate_limits.seven_day.used_percentage')
seven_d_reset=$(jget '.rate_limits.seven_day.resets_at')

# Session cost (authoritative cumulative session $ from the harness)
sess_cost_usd=$(jget '.cost.total_cost_usd')

# Adversarial catch counter — never crash if file missing or unreadable
catches_file="${HOME}/.claude/state/adversarial-catches.total"
catches=0
if [ -r "$catches_file" ]; then
  _raw=$(cat "$catches_file" 2>/dev/null | tr -dc '0-9' | head -c 10)
  [ -n "$_raw" ] && catches=$(( _raw + 0 )) 2>/dev/null || catches=0
fi

# ---------------------------------------------------------------------------
# ANSI color constants  ($'...' so the bytes are real at assignment time)
# ---------------------------------------------------------------------------
R=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

FG_BLACK=$'\033[30m'
FG_RED=$'\033[31m'
FG_GREEN=$'\033[32m'
FG_YELLOW=$'\033[33m'
FG_BLUE=$'\033[34m'
FG_MAGENTA=$'\033[35m'
FG_CYAN=$'\033[36m'
FG_WHITE=$'\033[37m'
FG_BBLACK=$'\033[90m'
FG_BRED=$'\033[91m'
FG_BGREEN=$'\033[92m'
FG_BYELLOW=$'\033[93m'
FG_BBLUE=$'\033[94m'
FG_BMAGENTA=$'\033[95m'
FG_BCYAN=$'\033[96m'
FG_BWHITE=$'\033[97m'

BG_BLACK=$'\033[40m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_BBLACK=$'\033[100m'

# ---------------------------------------------------------------------------
# Helper: render a bar gauge
#   gauge_bar <value_0_to_100> <width> <filled_char> <empty_char>
#   returns the bar string in $GAUGE_OUT, color in $GAUGE_COLOR
# ---------------------------------------------------------------------------
gauge_bar() {
  local pct="$1" width="${2:-10}" fc="${3:-█}" ec="${4:-░}"
  local filled empty i
  GAUGE_OUT=""
  GAUGE_COLOR="$FG_BGREEN"

  # Clamp
  pct=$(printf '%.0f' "${pct:-0}" 2>/dev/null) || pct=0
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100
  [ "$pct" -lt 0  ] 2>/dev/null && pct=0

  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))

  if [ "$pct" -ge 85 ]; then
    GAUGE_COLOR="$FG_BRED"
  elif [ "$pct" -ge 60 ]; then
    GAUGE_COLOR="$FG_BYELLOW"
  else
    GAUGE_COLOR="$FG_BGREEN"
  fi

  i=0; while [ $i -lt $filled ]; do GAUGE_OUT="${GAUGE_OUT}${fc}"; i=$(( i + 1 )); done
  i=0; while [ $i -lt $empty  ]; do GAUGE_OUT="${GAUGE_OUT}${ec}"; i=$(( i + 1 )); done
}

# ---------------------------------------------------------------------------
# Helper: format token count  e.g. 123456 -> 123k
# ---------------------------------------------------------------------------
fmt_tokens() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" = "null" ]; then echo ""; return; fi
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    printf '%dM' $(( n / 1000000 ))
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    printf '%dk' $(( n / 1000 ))
  else
    printf '%d' "$n"
  fi
}

# ---------------------------------------------------------------------------
# Helper: format a USD amount  e.g. 0.5432 -> $0.54 ; 12.3 -> $12.30
# ---------------------------------------------------------------------------
fmt_usd() {
  local v="$1"
  [ -z "$v" ] || [ "$v" = "null" ] && return
  awk -v x="$v" 'BEGIN{ if (x+0 < 0) x=0; printf "$%.2f", x+0 }' 2>/dev/null
}

# ---------------------------------------------------------------------------
# Helper: format unix epoch as HH:MM
# ---------------------------------------------------------------------------
fmt_epoch_hhmm() {
  local ts="$1"
  [ -z "$ts" ] && return
  date -d "@${ts}" +%H:%M 2>/dev/null || date -r "$ts" +%H:%M 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Helper: separator glyphs
#   SEP   — slim inline separator for items within a line
#   MSEP  — wider separator for breathing space between meter blocks
# ---------------------------------------------------------------------------
SEP=" ${DIM}│${R} "
MSEP="   ${DIM}│${R}   "

# ---------------------------------------------------------------------------
# Product-lifecycle phase widget — reads the project-local .i2p/lifecycle.json
# (current_phase + phases[]) and renders an 8-pip progress track. Degrades to
# nothing when the file is absent. The state file is written by the i2p
# lifecycle helper (/i2p-help kickoff); this only READS it.
# ---------------------------------------------------------------------------
lifecycle_widget() {
  LC_OUT=""
  local proj="${cwd/#\~/$HOME}"
  [ -n "$proj" ] || return
  local lf="${proj}/.i2p/lifecycle.json"
  [ -r "$lf" ] || return
  local cur phases cyc cycstr=""
  if [ -n "$_jq_ok" ]; then
    cur=$(jq -r '.current_phase // empty' "$lf" 2>/dev/null)
    phases=$(jq -r '(.phases // []) | join(" ")' "$lf" 2>/dev/null)
    cyc=$(jq -r '.cycle // 1' "$lf" 2>/dev/null)
  fi
  [ -n "$cur" ] || return
  [ -n "$phases" ] || phases="DISCOVER IDEATE DESIGN BUILD ASSURE SECURE PUBLISH OPERATE"
  local i=0 idx=0 total=0 p
  for p in $phases; do total=$((total+1)); [ "$p" = "$cur" ] && idx=$total; done
  local track=""
  for p in $phases; do
    i=$((i+1))
    if [ "$p" = "$cur" ]; then
      track="${track}${BOLD}${FG_BCYAN}◉${R}"
    elif [ "$i" -lt "$idx" ]; then
      track="${track}${FG_BGREEN}●${R}"
    else
      track="${track}${FG_BBLACK}○${R}"
    fi
  done
  [ "${cyc:-1}" -gt 1 ] 2>/dev/null && cycstr=" ${FG_BMAGENTA}↻${cyc}${R}"
  LC_OUT="${FG_BBLACK}◆ lifecycle ${R}${track} ${BOLD}${FG_BCYAN}${cur}${R}${DIM} (${idx}/${total})${R}${cycstr}"
}

# ---------------------------------------------------------------------------
# Session-cost widget (always-on, first-order) — tokens from the capture-cost
# Stop hook's session.json; $ from the harness's authoritative cost.total_cost_usd
# (falling back to the hook's price-map estimate). Degrades to nothing if neither
# is available.
# ---------------------------------------------------------------------------
session_cost_widget() {
  SC_OUT=""
  local sj="${HOME}/.claude/state/i2p-cost/session.json"
  local tok="" usd=""
  if [ -n "$_jq_ok" ] && [ -r "$sj" ]; then
    tok=$(jq -r '.tokens // empty' "$sj" 2>/dev/null)
    usd=$(jq -r '.usd // empty' "$sj" 2>/dev/null)
  fi
  # Prefer the harness's authoritative session cost for the $ figure.
  [ -n "$sess_cost_usd" ] && usd="$sess_cost_usd"
  local tstr="" ustr=""
  [ -n "$tok" ] && tstr="$(fmt_tokens "$tok")"
  [ -n "$usd" ] && ustr="$(fmt_usd "$usd")"
  [ -n "$tstr" ] || [ -n "$ustr" ] || return
  local body=""
  [ -n "$tstr" ] && body="$tstr"
  [ -n "$tstr" ] && [ -n "$ustr" ] && body="${body} ${DIM}·${R} ${FG_BWHITE}${ustr}${R}${FG_BCYAN}"
  [ -z "$tstr" ] && [ -n "$ustr" ] && body="$ustr"
  SC_OUT="${FG_BBLACK}◇ ${FG_BCYAN}${body}${R}${DIM} session${R}"
}

# ---------------------------------------------------------------------------
# Lifecycle-cost widget — reads the project-local .i2p/cost.json totals and shows
# actual/estimate tokens (Δ%, coloured by over/under) + $. Only renders when a
# lifecycle cost ledger exists. Written by capture-cost.sh + the i2p cost.sh.
# ---------------------------------------------------------------------------
lifecycle_cost_widget() {
  LCC_OUT=""
  local proj="${cwd/#\~/$HOME}"
  [ -n "$proj" ] || return
  local cf="${proj}/.i2p/cost.json"
  [ -n "$_jq_ok" ] && [ -r "$cf" ] || return
  local act est usd
  act=$(jq -r '.totals.actual_tokens // 0' "$cf" 2>/dev/null)
  est=$(jq -r '.totals.estimate_tokens // 0' "$cf" 2>/dev/null)
  usd=$(jq -r '.totals.actual_usd // 0' "$cf" 2>/dev/null)
  case "$act" in (''|*[!0-9]*) act=0 ;; esac
  case "$est" in (''|*[!0-9]*) est=0 ;; esac
  [ "$act" -gt 0 ] 2>/dev/null || [ "$est" -gt 0 ] 2>/dev/null || return
  local astr estr delta clr=""
  astr="$(fmt_tokens "$act")"
  if [ "$est" -gt 0 ] 2>/dev/null; then
    estr="/~$(fmt_tokens "$est")"
    local pct; pct=$(awk -v a="$act" -v e="$est" 'BEGIN{ if(e>0) printf "%d", (a-e)*100/e; else print 0 }')
    if   [ "$pct" -gt 15 ] 2>/dev/null; then clr="$FG_BRED"
    elif [ "$pct" -lt -15 ] 2>/dev/null; then clr="$FG_BGREEN"
    else clr="$FG_BYELLOW"; fi
    local sign=""; [ "$pct" -gt 0 ] 2>/dev/null && sign="+"
    delta=" ${clr}(${sign}${pct}%)${R}"
  else
    estr=""; delta=""
  fi
  local ustr=""; [ -n "$usd" ] && ustr="${DIM} · ${FG_BWHITE}$(fmt_usd "$usd")${R}"
  LCC_OUT="${FG_BBLACK}◈ life ${FG_BCYAN}${astr}${R}${DIM}${estr}${R}${delta}${ustr}"
}

# ---------------------------------------------------------------------------
# Build the output
# ---------------------------------------------------------------------------

# ── LINE 1 ──────────────────────────────────────────────────────────────────
# identity/context: user@host:cwd │ branch │ repo │ PR │ model │ version │
#                   output-style │ vim-mode │ effort/thinking │ session │
#                   worktree │ agent
# ─────────────────────────────────────────────────────────────────────────────

printf "${BOLD}${FG_BGREEN}%s${R}${DIM}@${R}${FG_GREEN}%s${R}" "$user" "$host"

if [ -n "$cwd" ]; then
  printf "${DIM}:${R}${BOLD}${FG_BBLUE}%s${R}" "$cwd"
fi

if [ -n "$proj_dir" ]; then
  printf " ${DIM}(proj:${FG_BLUE}%s${R}${DIM})${R}" "$proj_dir"
fi

# Branch
if [ -n "$branch" ]; then
  printf "${SEP}${FG_BMAGENTA} %s${R}" "$branch"
fi

# Repo
if [ -n "$repo" ]; then
  _repo_disp="$repo"
  [ -n "$repo_host" ] && _repo_disp="${repo_host}/${repo}"
  printf "${SEP}${DIM}${FG_BCYAN}⬡ %s${R}" "$_repo_disp"
fi

# PR
if [ -n "$pr_number" ]; then
  case "$pr_state" in
    approved)           pr_icon=" " ; pr_clr="${FG_BGREEN}"   ;;
    changes_requested)  pr_icon=" " ; pr_clr="${FG_BRED}"     ;;
    draft)              pr_icon="◌ " ; pr_clr="${FG_BBLACK}"   ;;
    pending|*)          pr_icon=" " ; pr_clr="${FG_BYELLOW}"   ;;
  esac
  printf "${SEP}${pr_clr}${pr_icon}PR #%s${R}" "$pr_number"
  [ -n "$pr_state" ] && printf " ${DIM}(%s)${R}" "$pr_state"
fi

# Model
if [ -n "$model_name" ]; then
  printf "${SEP}${BOLD}${FG_BMAGENTA}⬡ %s${R}" "$model_name"
elif [ -n "$model_id" ]; then
  printf "${SEP}${BOLD}${FG_BMAGENTA}⬡ %s${R}" "$model_id"
fi

# Version
[ -n "$version" ] && printf "${SEP}${DIM}v%s${R}" "$version"

# Output style (skip "default")
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
  printf "${SEP}${FG_BBLACK}style:${FG_BYELLOW}%s${R}" "$output_style"
fi

# Vim mode
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    INSERT)      vm_clr="${FG_BGREEN}" ;;
    NORMAL)      vm_clr="${FG_BCYAN}"  ;;
    VISUAL*)     vm_clr="${FG_BYELLOW}" ;;
    *)           vm_clr="${FG_BWHITE}" ;;
  esac
  printf "${SEP}${vm_clr}[%s]${R}" "$vim_mode"
fi

# Effort
if [ -n "$effort" ]; then
  case "$effort" in
    low)    ef_clr="${FG_BBLACK}"      ; ef_icon="○" ;;
    medium) ef_clr="${FG_BYELLOW}"     ; ef_icon="◑" ;;
    high)   ef_clr="${FG_BRED}"        ; ef_icon="●" ;;
    xhigh)  ef_clr="${FG_BRED}"        ; ef_icon="◉" ;;
    max)    ef_clr="${BOLD}${FG_BRED}" ; ef_icon="⊛" ;;
    *)      ef_clr="${FG_BWHITE}"      ; ef_icon="·" ;;
  esac
  printf "${SEP}${ef_clr}%s effort:%s${R}" "$ef_icon" "$effort"
fi

# Thinking
if [ "$thinking" = "true" ]; then
  printf "${SEP}${FG_BMAGENTA}⟳ thinking${R}"
fi

# Session name
if [ -n "$session_name" ]; then
  printf "${SEP}${FG_BBLACK}▸ ${FG_BCYAN}%s${R}" "$session_name"
fi

# Worktree
if [ -n "$wt_name" ]; then
  printf "${SEP}${FG_BBLACK}wt:${FG_CYAN}%s${R}" "$wt_name"
fi

# Agent
if [ -n "$agent_name" ]; then
  printf "${SEP}${FG_BBLACK}agent:${FG_BYELLOW}%s${R}" "$agent_name"
  [ -n "$agent_type" ] && printf "${DIM}(%s)${R}" "$agent_type"
fi

printf "\n"

# ── LINE 2 ──────────────────────────────────────────────────────────────────
# Meters spread generously: context-window │ 5h rate │ 7d rate │ lifecycle │
#                           ⚔ caught │ <plugin-contributed widgets>
# ─────────────────────────────────────────────────────────────────────────────

line2_parts=()

# Context window — 28-cell bar
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct" 2>/dev/null) || used_int=0
  gauge_bar "$used_int" 28 "█" "░"
  _tokens_str=""
  _tok=$(fmt_tokens "$ctx_used_tokens")
  _total=$(fmt_tokens "$ctx_total")
  [ -n "$_tok" ] && [ -n "$_total" ] && _tokens_str="  ${DIM}${_tok}/${_total}${R}"
  [ -n "$_tok" ] && [ -z "$_total" ] && _tokens_str="  ${DIM}${_tok}${R}"
  line2_parts+=("${FG_BBLACK}ctx ${GAUGE_COLOR}${GAUGE_OUT}${R}  ${GAUGE_COLOR}${used_int}%  used${R}${_tokens_str}")
fi

# 5-hour rate limit — 20-cell bar
if [ -n "$five_h_pct" ]; then
  pct_int=$(printf '%.0f' "$five_h_pct" 2>/dev/null) || pct_int=0
  gauge_bar "$pct_int" 20 "▰" "▱"
  _reset_str=""
  [ -n "$five_h_reset" ] && _reset_str="  ${DIM}↺$(fmt_epoch_hhmm "$five_h_reset")${R}"
  line2_parts+=("${FG_BBLACK}5h ${GAUGE_COLOR}${GAUGE_OUT}${R}  ${GAUGE_COLOR}${pct_int}%${R}${_reset_str}")
fi

# 7-day rate limit — 20-cell bar
if [ -n "$seven_d_pct" ]; then
  pct_int=$(printf '%.0f' "$seven_d_pct" 2>/dev/null) || pct_int=0
  gauge_bar "$pct_int" 20 "▰" "▱"
  _reset_str=""
  [ -n "$seven_d_reset" ] && _reset_str="  ${DIM}↺$(fmt_epoch_hhmm "$seven_d_reset")${R}"
  line2_parts+=("${FG_BBLACK}7d ${GAUGE_COLOR}${GAUGE_OUT}${R}  ${GAUGE_COLOR}${pct_int}%${R}${_reset_str}")
fi

# Product-lifecycle phase
lifecycle_widget
[ -n "$LC_OUT" ] && line2_parts+=("$LC_OUT")

# Session spend — always-on, first-order (tokens + $)
session_cost_widget
[ -n "$SC_OUT" ] && line2_parts+=("$SC_OUT")

# Lifecycle spend vs estimate (only when a lifecycle cost ledger exists)
lifecycle_cost_widget
[ -n "$LCC_OUT" ] && line2_parts+=("$LCC_OUT")

# Adversarial catch counter — always rendered on line 2
if [ "$catches" -gt 0 ] 2>/dev/null; then
  _caught_clr="${BOLD}${FG_BYELLOW}"
else
  _caught_clr="${DIM}${FG_BBLACK}"
fi
line2_parts+=("${_caught_clr}⚔ caught ${catches}${R}")

# Plugin-contributed widgets (extension point): any marketplace plugin may drop an
# executable segment-printer in ~/.claude/state/statusline-widgets.d/*.sh. Each is
# fed the same stdin JSON and prints ONE already-colored segment (no newline). A
# failing or empty widget is skipped — it can never break the line.
_widget_dir="${HOME}/.claude/state/statusline-widgets.d"
if [ -d "$_widget_dir" ]; then
  for _w in "$_widget_dir"/*.sh; do
    [ -r "$_w" ] || continue
    _seg=$(printf '%s' "$input" | bash "$_w" 2>/dev/null) || _seg=""
    [ -n "$_seg" ] && line2_parts+=("$_seg")
  done
fi

if [ "${#line2_parts[@]}" -gt 0 ]; then
  first=1
  for part in "${line2_parts[@]}"; do
    if [ "$first" = "1" ]; then
      printf "%s" "$part"
      first=0
    else
      printf "%s%s" "$MSEP" "$part"
    fi
  done
  printf "\n"
fi
