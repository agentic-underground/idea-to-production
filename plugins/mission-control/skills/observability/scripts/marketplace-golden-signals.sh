#!/usr/bin/env bash
# marketplace-golden-signals.sh — dogfood MISSION-CONTROL's observability on the MARKETPLACE ITSELF
# (self-healing plan P2-18, "cobbler's children"). The marketplace ships an OPERATE observability lens
# but never turned it on its OWN runtime/health; this script does, mapping the four golden signals onto
# the marketplace's own deterministic surface, and emitting a HEALTH SUMMARY the HUD or a CI artifact reads.
#
# It runs as an EXTERNAL CI job (.github/workflows/verify.yml :: marketplace-golden-signals) — NOT from
# inside a session — by deliberate design: a self-observability lens must survive the thing it observes
# (a crashed mission-control cannot observe its own crash), exactly as the P1-11 gitleaks job is the
# external SECURITY slice of the same self-observation substrate. This is the HEALTH slice of that substrate.
#
# THE FOUR GOLDEN SIGNALS, mapped to the marketplace's own runtime (deterministic, no telemetry backend):
#   • TRAFFIC    — the demand/surface the marketplace serves: live plugins, skills, agents, commands, hooks.
#   • ERRORS     — the failure rate of that surface: broken intra-repo doc references + non-executable hooks
#                  (a dead reference is a 404 a user hits; a non-runnable hook is a failed request).
#   • LATENCY    — the cold-start cost to bring the substrate up: time to enumerate + jq-validate every
#                  plugin manifest (the closest deterministic proxy for "time to serve" in a static repo).
#   • SATURATION — headroom against the constrained resource: the doc-reference error budget consumed.
#
# OUTPUT: a JSON health summary to stdout AND (when --out <path>) to a file (the CI artifact / HUD feed).
# VERDICT: HEALTHY / WATCH / UNHEALTHY by the golden-signal error budget, mirroring /operate-gate's rule
#   (a lens that cannot run never returns HEALTHY). Exit 0 (HEALTHY/WATCH) or 1 (UNHEALTHY) so CI gates on it.
#
# Grounded in ../SKILL.md (the four golden signals) and ../../../knowledge/operate-canon.md §1 (SRE).
# Self-contained: resolves everything from the repo root it is invoked in; needs jq + standard coreutils.
set -uo pipefail

REPO_ROOT="${1:-.}"; OUT=""
# crude flag parse: [REPO_ROOT] [--out <path>]
shift || true
while [ $# -gt 0 ]; do case "$1" in --out) OUT="${2:-}"; shift 2 ;; *) shift ;; esac; done
cd "$REPO_ROOT" 2>/dev/null || { echo "marketplace-golden-signals: cannot cd to '$REPO_ROOT'" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || { echo "marketplace-golden-signals: jq required" >&2; exit 2; }
[ -d plugins ] || { echo "marketplace-golden-signals: no plugins/ here — run from the marketplace root" >&2; exit 2; }

# ── TRAFFIC — the served surface (deterministic enumeration) ──────────────────────────────
plugins_n=$(find plugins -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
skills_n=$(find plugins/*/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
agents_n=$(find plugins/*/agents -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
commands_n=$(find plugins/*/commands -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
hooks_n=$(find plugins/*/hooks -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')

# ── LATENCY — cold-start: time to enumerate + jq-validate every plugin manifest (ms) ──────
manifests=$(find plugins/*/.claude-plugin/plugin.json 2>/dev/null)
manifests_n=$(printf '%s\n' "$manifests" | grep -c . || true)
t0=$(date +%s%N 2>/dev/null || echo 0)
manifest_errors=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  jq -e . "$m" >/dev/null 2>&1 || manifest_errors=$((manifest_errors + 1))
done <<< "$manifests"
t1=$(date +%s%N 2>/dev/null || echo 0)
latency_ms=$(( (t1 - t0) / 1000000 )); [ "$latency_ms" -lt 0 ] && latency_ms=0

# ── ERRORS — the failure rate of the served surface ───────────────────────────────────────
# (a) broken intra-repo references: relative .md/.sh/.tsv/.json links in SKILL/agent/command/knowledge
#     docs that don't resolve on disk (a dead reference is a 404 a user/agent hits — CI check I's lens).
docs=$(find plugins -type f \( -name '*.md' \) 2>/dev/null)
ref_total=0; ref_broken=0
while IFS= read -r doc; do
  [ -n "$doc" ] || continue
  ddir="$(dirname "$doc")"
  # markdown links to relative paths ending in a tracked extension, minus any #anchor / ?query
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    case "$link" in http*|\#*|/*|'') continue ;; esac
    target="${link%%#*}"; target="${target%%\?*}"
    [ -n "$target" ] || continue
    ref_total=$((ref_total + 1))
    [ -e "$ddir/$target" ] || ref_broken=$((ref_broken + 1))
  done < <(grep -oE '\]\(([^)]+\.(md|sh|tsv|json))\)' "$doc" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//')
done <<< "$docs"

# (b) non-executable / non-runnable hooks (a hook that can't run is a failed request).
hooks_broken=0
while IFS= read -r h; do
  [ -n "$h" ] || continue
  bash -n "$h" 2>/dev/null || hooks_broken=$((hooks_broken + 1))
done < <(find plugins/*/hooks -name '*.sh' 2>/dev/null)

errors_total=$(( ref_broken + manifest_errors + hooks_broken ))

# ── SATURATION — error budget consumed against the reference surface ──────────────────────
# budget: the reference surface is the constrained resource; saturation = broken/total refs.
sat_pct=0
if [ "${ref_total:-0}" -gt 0 ]; then
  sat_pct=$(awk -v b="$ref_broken" -v t="$ref_total" 'BEGIN{ printf "%.2f", (b/t)*100 }')
fi

# ── VERDICT — mirror /operate-gate: any hard error → WATCH/UNHEALTHY, never a false HEALTHY ─
verdict="HEALTHY"; rc=0
if [ "$manifest_errors" -gt 0 ] || [ "$hooks_broken" -gt 0 ] || [ "$ref_broken" -gt 0 ]; then
  verdict="WATCH"; rc=0
fi
# An UNHEALTHY threshold: a manifest that won't parse or a hook that won't run is a hard outage of the
# substrate (not mere drift) → fail CI. Broken doc refs alone are WATCH (degraded, not down).
if [ "$manifest_errors" -gt 0 ] || [ "$hooks_broken" -gt 0 ]; then
  verdict="UNHEALTHY"; rc=1
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"
summary="$(jq -nc \
  --arg schema "marketplace-health/1.0" --arg ts "$ts" --arg verdict "$verdict" \
  --argjson plugins "${plugins_n:-0}" --argjson skills "${skills_n:-0}" \
  --argjson agents "${agents_n:-0}" --argjson commands "${commands_n:-0}" --argjson hooks "${hooks_n:-0}" \
  --argjson latency_ms "${latency_ms:-0}" --argjson manifests "${manifests_n:-0}" \
  --argjson ref_total "${ref_total:-0}" --argjson ref_broken "${ref_broken:-0}" \
  --argjson manifest_errors "${manifest_errors:-0}" --argjson hooks_broken "${hooks_broken:-0}" \
  --argjson errors_total "${errors_total:-0}" --arg saturation_pct "${sat_pct:-0}" \
  '{schema:$schema, ts:$ts, verdict:$verdict,
    golden_signals: {
      traffic:    {plugins:$plugins, skills:$skills, agents:$agents, commands:$commands, hooks:$hooks},
      latency:    {manifest_validate_ms:$latency_ms, manifests:$manifests},
      errors:     {total:$errors_total, broken_refs:$ref_broken, manifest_parse_errors:$manifest_errors, broken_hooks:$hooks_broken},
      saturation: {ref_error_budget_consumed_pct:($saturation_pct|tonumber), refs_checked:$ref_total}
    }}')"

printf '%s\n' "$summary" | jq .
[ -n "$OUT" ] && { printf '%s\n' "$summary" > "$OUT" 2>/dev/null && echo "marketplace-golden-signals: health summary → $OUT" >&2; }

echo "marketplace-golden-signals: verdict=${verdict} — ${plugins_n} plugins / ${skills_n} skills / ${agents_n} agents serving; ${errors_total} error(s); saturation ${sat_pct}%" >&2
exit "$rc"
