#!/usr/bin/env bash
# offer-welcome.sh — i2p SessionStart hook. The mirror image of inject-welcome.sh:
# inject-welcome RENDERS a welcome when <project>/.claude/welcome.md is present; this hook
# ACTS when it is ABSENT (proactively OFFER to author one) or STALE versus the product
# lifecycle (instruct a silent, managed refresh). Guidance only — a splash, nothing more.
#
# Never blocks, always exits 0, and NEVER writes the user's repo: it only stat-reads the
# repo. Opt-out state lives under ~/.claude/hook-state (the AGENT writes those markers, on
# the user's say-so, using the exact commands embedded below). Two opt-outs are honoured —
# a per-repo "declined" marker and a global "never offer anywhere" marker.
#
# The hook only DETECTS the situation; the AGENT (which already has the repo's CLAUDE.md /
# README and the emergent lifecycle artifacts in reach) composes the in-the-know proposal
# or the managed refresh from the contract handed over in additionalContext.
set -uo pipefail

HOME_DIR="${HOME:-/tmp}"

# --- read the SessionStart stdin JSON (cwd); jq with a bash fallback (mirrors inject-welcome) ---
payload=""
[ -t 0 ] || payload="$(cat 2>/dev/null || true)"
json_field() {
  printf '%s' "$payload" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//;s/\"\$//"
}
project_dir=""
if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
  project_dir="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
fi
[ -n "$project_dir" ] || project_dir="$(json_field cwd)"
[ -n "$project_dir" ] || project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

WELCOME_FILE="${project_dir}/.claude/welcome.md"
LF="${project_dir}/.i2p/lifecycle.json"

# --- opt-out gates (state lives under ~/.claude/hook-state, never the repo) ----------------
STATE_DIR="${HOME_DIR}/.claude/hook-state"
OPTOUT="${STATE_DIR}/i2p-welcome-optout"
[ -e "$OPTOUT" ] && exit 0   # global "never offer in any repo".

hash_path() {  # short, collision-resistant digest of the repo path (graceful tool fallback)
  if   command -v sha1sum >/dev/null 2>&1; then printf '%s' "$1" | sha1sum | cut -c1-12
  elif command -v shasum  >/dev/null 2>&1; then printf '%s' "$1" | shasum  | cut -c1-12
  elif command -v md5sum  >/dev/null 2>&1; then printf '%s' "$1" | md5sum  | cut -c1-12
  else printf '%s' "$1" | cksum | tr -d ' ' | cut -c1-12; fi
}
repo_key="$(basename "$project_dir" 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')-$(hash_path "$project_dir")"
DECLINED="${STATE_DIR}/i2p-welcome-declined/${repo_key}"
[ -e "$DECLINED" ] && exit 0   # user declined for this repo.

# --- read the lifecycle phase (cheap; only when a lifecycle is running) --------------------
phase=""; cycle=""
if [ -r "$LF" ] && command -v jq >/dev/null 2>&1; then
  phase="$(jq -r '.current_phase // empty' "$LF" 2>/dev/null)"
  cycle="$(jq -r '.cycle // 1' "$LF" 2>/dev/null)"
fi

# --- decide the situation ------------------------------------------------------------------
MSG=""; CTX=""

if [ ! -f "$WELCOME_FILE" ]; then
  # NO welcome → offer to author one (smart-gated, in-the-know, lifecycle-aware).
  MSG="👋 This repo has no welcome experience yet — I can set up a short, repo-aware greeting that routes whoever opens it to what people do here. Just ask, or run /i2p:define-welcome."
  life=""
  if [ -n "$phase" ]; then
    life="This repo is in an idea-to-production lifecycle at the ${phase} phase, so make the offer reflect what the product is BECOMING: read the small emergent artifact(s) for this phase (DISCOVER: .market-scanner/goal.md or doc/opportunities/; IDEATE: doc/idea/<slug>/ IDEA brief + any coined name; DESIGN: docs/guide/design/mockups/<slug>/rationale.md; BUILD: doc/SUBJECT_MATTER_UNDERSTANDING.md or ROADMAP.md) and offer a greeting that names the emerging product and routes the next person to the next step. On accept, the welcome is then kept up to date automatically as phases advance. "
  fi
  CTX="i2p has no welcome experience for this repository (no .claude/welcome.md) and may offer to author one.
SMART-GATE — only raise this on a genuine cold/vague open. Read the user's first message: if it is a greeting or vague/exploratory opener (\"hi\", \"what is this?\", \"where do I start?\", or an empty turn) you may surface the offer. If they opened with a concrete task, DO THE TASK and stay silent — nothing is spent, you will be prompted again on the next cold open. Raise it at most once this session; never on a resume or after compaction. If this repo is essentially empty (no README/CLAUDE.md and no lifecycle running) there is nothing to greet yet — stay silent.
MAKE IT IN-THE-KNOW, not a bland \"want a greeting?\": tailor it from what you ALREADY have in context — the auto-loaded CLAUDE.md/AGENTS.md plus a quick bounded skim of README.md if useful (do NOT deep-scan; that is the opt-in step). ${life}Aim for one or two sentences, e.g. \"This looks like X — people mostly do A/B/C here. I can set up a greeting that meets whoever opens it next and routes them there. Want me to?\"
ON OPT-IN: run /i2p:define-welcome (the deeper read; it writes a phase-stamped .claude/welcome.md).
ON DECLINE for this repo: run  mkdir -p '${DECLINED}'  so you will not prompt again here. NEVER-anywhere: run  mkdir -p '${OPTOUT}' . Only ever write under ~/.claude/hook-state — never write opt-out state into the user's repository."

elif [ -n "$phase" ]; then
  # Welcome EXISTS and a lifecycle is running → is the (managed) welcome stale vs the phase?
  stamp_line="$(grep -m1 'i2p:welcome' "$WELCOME_FILE" 2>/dev/null || true)"
  st_phase="$(printf '%s' "$stamp_line" | grep -o 'for_phase=[A-Za-z_]*' | head -1 | cut -d= -f2)"
  st_cycle="$(printf '%s' "$stamp_line" | grep -o 'cycle=[0-9]*' | head -1 | cut -d= -f2)"
  # Only act on a STAMPED welcome whose stamp differs (a hand-authored, unstamped welcome is left alone).
  if [ -n "$st_phase" ] && { [ "$st_phase" != "$phase" ] || { [ -n "$st_cycle" ] && [ -n "$cycle" ] && [ "$st_cycle" != "$cycle" ]; }; }; then
    CTX="This repository's i2p welcome is MANAGED and is now STALE: it is stamped for the ${st_phase} phase (cycle ${st_cycle:-1}) but the product lifecycle has advanced to ${phase} (cycle ${cycle:-1}). Keep it current: near the start of your reply, silently regenerate .claude/welcome.md to reflect the current phase's emergent artifacts by running  /i2p:define-welcome refresh  (artifact-driven, ask the user nothing), then add ONE line to your reply: \"↻ refreshed the welcome for ${phase}\". This is a quiet file update, not a greeting — do it whether the user opened cold or with a task.
VERIFY-AND-DISCLOSE (the refresh is not done until you confirm it landed): after regenerating, RE-READ the first 'i2p:welcome' stamp line of .claude/welcome.md and confirm it now reads  for_phase=${phase} cycle=${cycle:-1} . If it matches, you are done. If the stamp does NOT match (it still says for_phase=${st_phase} / cycle=${st_cycle:-1}, or no stamp is present), the refresh SILENTLY FAILED — do NOT leave the stale stamp unmentioned and do NOT auto-rewrite it here: instead DISCLOSE it to the user with exactly  \"⚠ welcome refresh did not take — stamp still ${st_phase}\"  so the failure is visible. Verify-and-disclose only; never hand-patch the stamp from this hook's instruction.
To stop managing this welcome: per-repo  mkdir -p '${DECLINED}' , globally  mkdir -p '${OPTOUT}' . Only write under ~/.claude/hook-state, never the repo."
  fi
fi
# (welcome present + no lifecycle, or present + current → silent: inject-welcome handles it.)

[ -n "$CTX" ] || exit 0

# --- emit as SessionStart output (jq, with a pure-bash JSON-escape fallback) ----------------
if command -v jq >/dev/null 2>&1; then
  if [ -n "$MSG" ]; then
    jq -cn --arg m "$MSG" --arg c "$CTX" \
      '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
  else
    jq -cn --arg c "$CTX" \
      '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
  fi
else
  jsonesc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"; printf '%s' "$s"; }
  ec="$(jsonesc "$CTX")"
  if [ -n "$MSG" ]; then
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(jsonesc "$MSG")" "$ec"
  else
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ec"
  fi
fi
exit 0
