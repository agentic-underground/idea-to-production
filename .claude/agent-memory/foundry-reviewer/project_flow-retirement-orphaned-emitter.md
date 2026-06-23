---
name: flow-retirement-orphaned-emitter
description: PR #150 retired flow plugin; deletion orphaned the P1-24 MCP-liveness emitter — RESOLVED in commit eafadce by re-homing mcp-liveness.sh into i2p's hook substrate at the same relative path
metadata:
  type: project
---

**RESOLVED (commit `eafadce`, verified 2026-06-22).** Re-homed `mcp-liveness.sh` →
`plugins/i2p/hooks/scripts/mcp-liveness.sh` (exec, smoke-exec exit 0), wired into i2p
hooks.json:20 SessionStart. Internal refs fixed: path comment plugins/flow→plugins/i2p,
flow-mcp example comment removed, emitter id flow:→i2p:sessionstart-mcp-liveness (zero
`flow` substrings remain). The 4 canon/consumer docs reference the emitter GENERICALLY
(relative `hooks/scripts/mcp-liveness.sh` + generic id `sessionstart-mcp-liveness` +
"SessionStart hook substrate"), so same-relative-path re-homing kept them accurate — no
doc edits needed, repo-wide dangling-flow-path scan clean. verify-prereqs + .pipeline/verify
both exit 0. Verdict: PASS. The history below is the ORIGINAL finding, kept for the lesson.

---

PR #150 (chore/retire-flow-plugin) deleted `plugins/flow/` entirely. The flow deletion
is clean on the obvious axes (marketplace.json=8 plugins valid, verify-prereqs N=9/O=8/A=8/H=8,
.pipeline/verify green, no dangling /flow: code refs, carriage-agent unreferenced, verify.yml
has no orphan flow-mcp-ruby needs:). The flow-mcp prose hits in mcp-language-choice.md are an
explicitly-marked historical post-mortem (lines 9-12) — legitimate; the `plugins/flow/flow-mcp/`
paths there are inside backtick inline-code so check I correctly skips them.

THE REGRESSION the deletion left: flow's `hooks/scripts/mcp-liveness.sh` was the ONLY
implementation of the **P1-24 SessionStart MCP-liveness emitter** — a cross-plugin protocol
where foundry's degraded-capabilities.md is canon, operate is the consumer, and the "SessionStart
hook substrate" is the producer that writes `.i2p/degraded-capabilities.json` when an MCP dies.
It was wired under flow's `${CLAUDE_PLUGIN_ROOT}` in flow/hooks/hooks.json (operate's hooks.json
only ever ran inject-kaizen). The PR deleted the producer with NO replacement and did NOT touch
the docs that still describe it as live: degraded-capabilities.md:88/:127, operate-canon.md:128,
operate-gate/SKILL.md:133, phase-sensor/SKILL.md:48.

**Why:** consumers (scorecard.sh, operate-gate) read the state file but treat missing-file as
"no degradation" (fail-safe) — so nothing crashes, which is why it's HIGH not CRITICAL. But the
net effect INVERTS the protocol's own §3.3 rule ("never count a non-run as a pass"): MCP deaths
now go undetected and silently PASS.

**Owner-string drift (commit eafadce re-review):** the count-drift fixes (9→8, "eight specialists"→
"seven", inject-kaizen byte-identical "eight plugins", masthead DELIVER owner→foundry, 40-mcp four→
three) all landed clean. BUT the spot-check caught a LIVE surface the rename missed:
`plugins/i2p/commands/flow.md` L9-10 + L14-15 still call DELIVER "owned by the **flow** plugin —
`/flow` / `/flow-setup`" — pointing at the retired plugin. Its own SKILL.md (`skills/flow/SKILL.md`,
which the command body links to) WAS correctly updated to roadmapper/(+FLEET)/operate, so the command
contradicts its skill. Lesson: a command FILE and its SKILL drift independently — when re-reviewing a
rename, grep the command/*.md bodies too, not just the skill+README+masthead.

**How to apply:** When reviewing a plugin-RETIREMENT PR, the canonical-copy/count checks
(verify-prereqs) will NOT catch a deleted *cross-plugin producer* whose consumers live elsewhere.
Always ask: did the retired plugin host any hook/emitter/script that a SURVIVING plugin's docs or
skills reference? grep surviving plugins for the deleted plugin's unique script names + any
protocol IDs (P1-NN) the deleted plugin owned. Fix = either re-home the emitter into a surviving
plugin's hook substrate (operate can't host it per heal-itself rule — likely foundry or i2p) OR
update the four+ canon/consumer docs to mark P1-24 emitter retired. Links: [[fail-open-guard-class]]
(same fail-safe-that-hides-a-gap shape).
