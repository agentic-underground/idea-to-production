#!/usr/bin/env bash
# DEV_SYSTEM Phase Sensor for FOUNDRY.
# Detects the current development phase of each IN PROGRESS ROADMAP feature
# by inspecting artifact presence, then advises the skill for that phase.
# Operates on the PROJECT the plugin is installed into — never outside that project.
# EARS: 009-013  Feature: [2] DEV_SYSTEM Phase Sensor
set -euo pipefail

# Project root (Claude Code sets CLAUDE_PROJECT_DIR for hooks); the plugin root for phase defs.
PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$PROJECT}"
LOG="${PROJECT}/.claude/cache/phase-sensor.log"
ROADMAP="${PROJECT}/ROADMAP.md"
SPEC="${PROJECT}/doc/SPECIFICATION.ears.md"
FEATURES_DIR="${PROJECT}/doc/features"
TESTS_DIR="${PROJECT}/tests"
PHASES_DIR="${PLUGIN}/skills/phase-sensor/phases"

mkdir -p "${PROJECT}/.claude/cache"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }

# When called from a PostToolUse hook, stdin is a pipe containing JSON tool context.
# [ -p /dev/stdin ] distinguishes a live pipe (hook) from a TTY or /dev/null.
# Fast-exit if the modified file is not ROADMAP.md — avoids per-edit overhead.
if [ -p /dev/stdin ]; then
    hook_json=$(cat)
    # An event without a file_path (e.g. a SessionStart-style event) makes the
    # grep exit non-zero; under `pipefail` that would kill the whole hook. Tolerate
    # it: a missing file_path must yield an empty string and a clean no-op (exit 0).
    hook_file=$(printf '%s' "$hook_json" \
        | grep -o '"file_path":"[^"]*"' | head -1 \
        | sed 's/"file_path":"//;s/"//' || true)
    if [ -n "$hook_file" ] && [[ "$hook_file" != *ROADMAP.md* ]]; then
        exit 0
    fi
fi

# EARS-013: nothing to do if ROADMAP is absent or has no IN PROGRESS features
[ -f "$ROADMAP" ] || { echo "No ROADMAP.md at ${ROADMAP}"; exit 0; }

# ---- ROADMAP ↔ sentinel-state cross-check (P1-6) ----
# A ROADMAP item's STATUS must agree with its terminal completion sentinel in the
# sentinel audit log (`docs/internal/FOUNDRY_PLAN.md` under `## Sentinel Audit Log`, per
# knowledge/protocols/context-sentinel.md). The end-of-life sentinel is
# DELIVERY_COMPLETE; the terminal-pending one is AWAITING_MERGE. When a roadmap
# item is marked COMPLETE but the audit log carries NO DELIVERY_COMPLETE for it,
# the two records disagree — surface the SPECIFIC mismatch and never auto-fix.
# This is DETECT-only (the plan's "detect-auto"): a WARN, not a state change.
# The check is silent when the records are consistent, or when there is no audit
# log to cross-check against (nothing to contradict).
cross_check_sentinels() {
    local plan="${PROJECT}/docs/internal/FOUNDRY_PLAN.md"
    [ -f "$plan" ] || return 0          # no audit log → nothing to cross-check
    # Pull only the sentinel-audit-log region so stray prose can't false-match.
    local audit
    audit=$(awk '/^## +Sentinel Audit Log/{a=1; next} a && /^## /{a=0} a{print}' "$plan")
    [ -n "$audit" ] || return 0          # log section absent/empty → nothing to assert

    local n
    # Each ROADMAP header carries its id as `## [N] ...`; map COMPLETE/AWAITING MERGE
    # items to the sentinel that must witness them.
    while IFS= read -r header; do
        n=$(printf '%s' "$header" | grep -o '\[[0-9]*\]' | tr -d '[]')
        [ -n "$n" ] || continue
        # Find this item's declared STATUS (first STATUS line in its block).
        local status
        status=$(awk -v n="$n" '
            $0 ~ ("^## \\[" n "\\]") { in_f=1; next }
            in_f && /^## \[/          { in_f=0 }
            in_f && /STATUS:/ { sub(/.*STATUS:[ \t]*/, ""); sub(/[ \t].*/, "", $0); print; exit }
        ' "$ROADMAP")
        case "$status" in
            COMPLETE)
                if ! printf '%s\n' "$audit" | grep -q "SENTINEL::DELIVERY_COMPLETE::ROADMAP-${n}::"; then
                    echo "WARN [${n}] ROADMAP STATUS: COMPLETE but no SENTINEL::DELIVERY_COMPLETE::ROADMAP-${n} in sentinel audit log — completion is unwitnessed; verify the item actually delivered to main."
                    log "  [${n}] CROSS-CHECK MISMATCH: COMPLETE without DELIVERY_COMPLETE sentinel"
                    sensor_exit=1
                fi
                ;;
            AWAITING)
                # `AWAITING MERGE` truncates to `AWAITING` after the status split above.
                if ! printf '%s\n' "$audit" | grep -qE "SENTINEL::(AWAITING_MERGE|DELIVERY_COMPLETE)::ROADMAP-${n}::"; then
                    echo "WARN [${n}] ROADMAP STATUS: AWAITING MERGE but no SENTINEL::AWAITING_MERGE::ROADMAP-${n} in sentinel audit log — the awaiting-merge state is unwitnessed."
                    log "  [${n}] CROSS-CHECK MISMATCH: AWAITING MERGE without AWAITING_MERGE sentinel"
                    sensor_exit=1
                fi
                ;;
        esac
    done < <(grep '^## \[[0-9]' "$ROADMAP")
}

sensor_exit=0
cross_check_sentinels

if ! grep -q "STATUS: IN PROGRESS" "$ROADMAP"; then
    echo "No features currently IN PROGRESS — nothing to evaluate"
    exit "$sensor_exit"
fi

# Process each IN PROGRESS feature
while IFS= read -r header; do
    feature_num=$(printf '%s' "$header" | grep -o '\[[0-9]*\]' | tr -d '[]')
    feature_title=$(printf '%s' "$header" | sed 's/^## \[[0-9]*\] //')

    log "Evaluating: [${feature_num}] ${feature_title}"

    # Extract plan file path from the feature's "Development Plan Reference" line
    plan_ref=$(awk -v n="${feature_num}" '
        $0 ~ ("^## \\[" n "\\]") { in_f=1; next }
        in_f && /^## \[/          { in_f=0 }
        in_f && /Development Plan Reference/ {
            getline; gsub(/[` \t\r]/, ""); print; exit
        }
    ' "$ROADMAP")

    # ---- Artifact-based phase detection ----
    # Each check advances the phase counter; the final value is the phase we
    # need to work on RIGHT NOW (lowest incomplete phase).
    phase=0

    # Phase 0 complete → plan file exists and is non-empty
    if [ -n "$plan_ref" ] \
        && [ -f "${PROJECT}/${plan_ref}" ] \
        && [ -s "${PROJECT}/${plan_ref}" ]; then
        phase=1
        log "  [${feature_num}] ✓ Phase 0 done: plan at ${plan_ref}"
    fi

    # Phase 1 complete → EARS IDs (### EARS-NNN) present in spec
    if [ "$phase" -ge 1 ] \
        && [ -f "$SPEC" ] \
        && grep -q "^### EARS-" "$SPEC"; then
        phase=2
        log "  [${feature_num}] ✓ Phase 1 done: EARS IDs in SPECIFICATION.ears.md"
    fi

    # Phase 2 complete → at least one .feature file exists
    if [ "$phase" -ge 2 ] \
        && compgen -G "${FEATURES_DIR}/*.feature" > /dev/null 2>&1; then
        phase=3
        log "  [${feature_num}] ✓ Phase 2 done: .feature file(s) present"
    fi

    # Phase 3 complete → at least one test file exists
    # Phase 4 (tests red) is transient and not detectable statically — skip to 5
    if [ "$phase" -ge 3 ] \
        && compgen -G "${TESTS_DIR}/test-*.bats" > /dev/null 2>&1; then
        phase=5
        log "  [${feature_num}] ✓ Phase 3 done: test file(s) present (phase 4 transient)"
    fi

    log "  [${feature_num}] Current phase: ${phase}"

    # ---- Install the skill for the current (incomplete) phase ----
    phase_def="${PHASES_DIR}/phase-${phase}.md"

    if [ ! -f "$phase_def" ]; then
        log "  [${feature_num}] No definition for phase ${phase} — nothing to install"
        continue
    fi

    skill_name=$(grep "^INSTALLS_SKILL:" "$phase_def" \
        | sed 's/^INSTALLS_SKILL:[[:space:]]*//' | head -1)

    if [ -z "$skill_name" ]; then
        log "  [${feature_num}] Phase ${phase} definition has no INSTALLS_SKILL directive"
        continue
    fi

    skill_md="${PROJECT}/.claude/skills/${skill_name}/SKILL.md"

    # EARS-013 / idempotency: skill already present → skip without committing
    if [ -f "$skill_md" ]; then
        log "  [${feature_num}] '${skill_name}' already installed — skipping"
        continue
    fi

    # Extract the embedded SKILL.md (everything after the ---SKILL--- marker)
    mkdir -p "${PROJECT}/.claude/skills/${skill_name}"
    awk '/^---SKILL---/{found=1; next} found{print}' "$phase_def" > "$skill_md"

    if [ ! -s "$skill_md" ]; then
        log "  [${feature_num}] Error: embedded SKILL.md in phase-${phase}.md is empty"
        rm -f "$skill_md"
        sensor_exit=1
        continue
    fi

    # EARS-012: record transition. The skill is installed into the PROJECT's local
    # .claude/skills/. A PostToolUse hook must NEVER auto-commit the user's repository —
    # advise the transition and let the user (or the orchestrator) commit deliberately.
    log "  [${feature_num}] TRANSITION → phase ${phase}: installed '${skill_name}' to .claude/skills/"

    printf '[phase-sensor] Feature [%s] advanced to phase %s — installed "%s" into .claude/skills/. Review and commit when ready.\n' \
        "$feature_num" "$phase" "$skill_name"

done < <(awk '
    /^## \[[0-9]/ { header=$0; check=1; next }
    check && /STATUS: IN PROGRESS/ { print header; check=0; next }
    check && /^## \[/              { check=0 }
' "$ROADMAP")

exit "$sensor_exit"
