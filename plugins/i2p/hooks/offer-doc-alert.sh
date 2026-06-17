#!/usr/bin/env bash
# offer-doc-alert.sh — i2p SessionStart hook. A one-shot heads-up that announces the
# repo's new ROADMAP documentation behaviour, exactly once per repo. Unlike offer-welcome.sh
# (which proposes an action), this hook simply INFORMS: from now on, roadmap items are
# documented via emoji commits, process-issues (on allowlisted origins), per-item
# professional docs, and the opt-in wiki. Guidance only — a splash, nothing more.
#
# Never blocks, always exits 0, and NEVER writes the user's repo: it only stat-reads the
# repo. Shown-once + opt-out state live under ~/.claude/hook-state (the AGENT writes those
# markers, on the user's say-so, using the exact commands embedded below). Two gates are
# honoured — a per-repo "already shown" marker and a global "never alert anywhere" marker.
#
# The hook only DETECTS that the alert is due; the AGENT surfaces the one-time notice from
# the contract handed over in additionalContext.
set -uo pipefail

HOME_DIR="${HOME:-/tmp}"

# --- read the SessionStart stdin JSON (cwd); jq with a bash fallback (mirrors offer-welcome) ---
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

# --- opt-out gates (state lives under ~/.claude/hook-state, never the repo) ----------------
STATE_DIR="${HOME_DIR}/.claude/hook-state"
OPTOUT="${STATE_DIR}/i2p-doc-alert-optout"
[ -e "$OPTOUT" ] && exit 0   # global "never alert in any repo".

hash_path() {  # short, collision-resistant digest of the repo path (graceful tool fallback)
  if   command -v sha1sum >/dev/null 2>&1; then printf '%s' "$1" | sha1sum | cut -c1-12
  elif command -v shasum  >/dev/null 2>&1; then printf '%s' "$1" | shasum  | cut -c1-12
  elif command -v md5sum  >/dev/null 2>&1; then printf '%s' "$1" | md5sum  | cut -c1-12
  else printf '%s' "$1" | cksum | tr -d ' ' | cut -c1-12; fi
}
repo_key="$(basename "$project_dir" 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')-$(hash_path "$project_dir")"
SHOWN="${STATE_DIR}/i2p-doc-alert-shown/${repo_key}"
[ -e "$SHOWN" ] && exit 0   # already shown for this repo.

# --- compose the one-time alert ------------------------------------------------------------
MSG="🗺️ Heads-up: from now on, ROADMAP items in this repo are documented as you go — emoji-prefixed commits, a process-issue per item (on allowlisted origins only), a per-item professional doc, and the opt-in wiki. (One-time notice.)"

CTX="i2p one-time DOCUMENTATION ALERT for this repository (not shown here before). Surface it ONCE, near the start of your reply, then continue with whatever the user asked — do not let it derail the actual task. Announce the new ROADMAP documentation behaviour that now applies from here on:
  1. EMOJI COMMITS — each roadmap item's work lands in emoji-prefixed commits documenting it.
  2. PROCESS-ISSUES — a tracking issue is opened per item, but ONLY on allowlisted origins (skip silently on others).
  3. PER-ITEM PROFESSIONAL DOCS — each item gets its own professional documentation page.
  4. OPT-IN WIKI — the wiki is updated too, but only when wiki publishing is opted in.
Keep it to a sentence or two; this is informational, not a request for action.
THIS IS A ONE-SHOT: after surfacing it, mark it shown so it never repeats here — run  mkdir -p '${SHOWN}' . To suppress this alert EVERYWHERE, run  mkdir -p '${OPTOUT}' . Only ever write under ~/.claude/hook-state — never write this state into the user's repository."

# --- emit as SessionStart output (jq, with a pure-bash JSON-escape fallback) ----------------
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg m "$MSG" --arg c "$CTX" \
    '{systemMessage:$m, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}'
else
  jsonesc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"; s="${s//$'\n'/\\n}"; printf '%s' "$s"; }
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(jsonesc "$MSG")" "$(jsonesc "$CTX")"
fi
exit 0
