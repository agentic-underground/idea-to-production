---
name: flow-plugin-universal-trio-gap
description: RESOLVED by PR #132 — flow now ships the universal check/inspect/self-improve trio; catalog claim restored
metadata:
  type: project
---

**RESOLVED (PR #132, `feat/flow-universal-trio`, reviewed 2026-06-18 → PASS).** flow now ships the
full trio: `skills/{check,self-improve}/SKILL.md`, `commands/{check,inspect}.md`, `agents/inspector.md`,
plus `knowledge/{inspection-core.md,covenant.md}`. check.sh is byte-identical canonical (9 copies,
verify-prereqs Check A green). requirements.tsv is flow-mcp-specific (curl/sha256sum/jq/cargo/gh).
self-improve opens a PR and NEVER self-merges; inspector is read-only (guardrailed by inspection-core).
SLASH_COMMANDS.md flow-exception note removed — the universal "every plugin ships the trio" claim now holds.

--- historical context (the gap, now closed) ---

The newly-stood-up `flow` plugin (DELIVER, ex-deliver flow surface, see [[flow-plugin-standup]])
shipped only `commands/{flow,pull,flow-setup}.md` + `skills/{flow,pull}` — it had **none** of the
universal trio `check` / `inspect` / `self-improve` (neither command nor skill), unlike all 8 other
plugins.

**Why:** `self-improve` lives as a *skill* (`plugins/<p>/skills/self-improve/SKILL.md`) in 8 plugins
(all but flow) and as a *command* only in deliver; `check`/`inspect` are commands in 8 plugins (all
but flow). So a blanket "every plugin ships check/inspect/self-improve" line is false for flow.

**How to apply:** When reviewing docs/SLASH_COMMANDS.md or any "common to every plugin" claim, the
`/flow:check`, `/flow:inspect`, `/flow:self-improve` rows do NOT resolve — flag the universal claim
as inaccurate until flow gains the trio (or the doc excepts flow). Don't extend this to the other
8 — `/<plugin>:self-improve` legitimately resolves via the skill path there.
