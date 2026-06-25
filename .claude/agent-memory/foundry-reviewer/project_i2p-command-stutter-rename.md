---
name: i2p-command-stutter-rename
description: PR #122/#99 stripped i2p- command stutter (/i2p:i2p-check→/i2p:check); what to check on i2p rename waves
metadata:
  type: project
---

PR #122 (roadmap #99, branch chore/normalise-i2p-command-prefix, commit b79257a) renamed the i2p plugin's 5 command FILES `i2p-{help,flow,lifecycle,review,check}.md` → `{help,flow,lifecycle,review,check}.md` so they invoke `/i2p:help` … `/i2p:check` (the `/i2p:` namespace already encodes the plugin — `/i2p:i2p-check` was a stutter). Stream 1 of epic #93.

**Why:** marketplace-v2 identity work; consistency mandated by the #99 card.

**How to apply — regression hot-spots when reviewing i2p rename waves:**
- The lifecycle EXIT-SIGNAL is the load-bearing functional link: every phase-owner plugin (discover/ideator/atelier/foundry/security/publish/operate) calls `/i2p:lifecycle done <PHASE>`. lifecycle.sh dispatches init|status|set|advance|`done`; `done` is order-safe + idempotent (no-op unless at PHASE, refuses on corrupt, wraps OPERATE↻DISCOVER). A stale `/i2p-lifecycle` would silently stall the state machine. See [[flow-server-status-lane-model]] for the broader lifecycle model.
- Statusline filenames LEGITIMATELY keep the i2p- prefix: `statusline/i2p-statusline.sh` + `~/.claude/i2p-statusline.conf` + `$CLAUDE_I2P_STATUSLINE_CONF` are filenames/env-vars, NOT commands — do NOT flag them. The rename only touched `/i2p-help`→`/i2p:help` inside their comments.
- command+skill SAME-NAME coexistence must hold: the 5 skills `skills/{check,flow,help,lifecycle,review}/SKILL.md` are NOT renamed/deleted; renamed commands link `../skills/<name>/SKILL.md`.
- Excluded-from-stale-grep (provenance, by design): `.i2p/roadmap/{backlog,done}/` cards (110/103/93/113 still cite `/i2p-flow` etc. as future-work / the #99 card quotes old→new intentionally), `docs/SLASH_COMMANDS.md` (user's git-tracked feedback channel — separate reconcile #113), `docs/historical/`, `docs/internal/`.
- verify-prereqs Check H = **8 plugins** (concierge folded into i2p per #98); §I/§J pass. Plugin identity unchanged by the rename.

Reviewed REGRESSION: PASS — verify-prereqs exit 0, skills intact, exit-signal sound, statusline filenames uncorrupted, shipped-surface stale grep empty.
