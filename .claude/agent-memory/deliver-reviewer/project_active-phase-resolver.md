---
name: active-phase-resolver
description: active-phase.sh is the shared hardened phase resolver for EPIC 0067 context-population hooks; adversarially cleared in PR #297 (0067.002)
metadata:
  type: project
---

`plugins/i2p/hooks/scripts/active-phase.sh` (`i2p_active_phase`) is the single SOURCED resolver
of the active lifecycle phase for EPIC 0067 hooks (phase-pointer.sh + phase-gated roadmap-routing.sh).
Its untrusted `.i2p/focus` parse is **byte-identical** to the hardened [[i2p-focus-routing-injection]]
parse: `awk '/^phase:/{sub(...); print $1; exit}' | tr -d [:space:] | tr lower upper`, then re-validated
against the closed 9-phase allowlist via `case "$allow" in *" $phase "*)`. Plus a jq-validated
`.i2p/lifecycle.json .current_phase` fallback, also allowlist-gated.

**Why:** it reads UNTRUSTED files and injects into every agent's SessionStart `additionalContext`.

**How to apply (when reviewing 0067.003/004 or any new reader):** the parse was adversarially cleared
in PR #297 — glob metachars (`*`/`?`/`[]`) fail closed because `"$phase"` is QUOTED in the case pattern
(literal match, verified empirically); JSON/shell metachars, CRLF, Unicode nbsp, NUL, multi-line,
lifecycle object-values all fail closed to empty → safe default; every path exits 0, emits valid JSON
(jq present AND absent), never leaks the untrusted value. Output can only ever be one of 9 fixed A–Z
phase names. Non-gating residuals: the jq-absent manual escaper (`${esc//\\/..}`+`${esc//\"/..}`) does
NOT escape control bytes, but CTX/MSG are fixed templates + an allowlisted phase so no control byte is
reachable (parity with focus-routing.sh, intended). Future slices must keep any new phase reader routed
through `i2p_active_phase`, not re-parse `.i2p/focus` inline.
