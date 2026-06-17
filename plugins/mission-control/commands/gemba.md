---
description: The GEMBA reflex — capture a learning at the workface, route it by identity (SELF/GEMBA), and raise a tracked, de-duplicated feedback issue on the repo that owns it.
---

Run the **gemba** skill.

The one-step **capture → route → raise** reflex for a learning seen at the workface (a coverage gap, a
missing guard, a defect that belongs to a sibling marketplace). `$ARGUMENTS` is the learning to capture
(free text) and/or an optional "where does this belong?" hint.

- **capture** — write the canonical learnings shape into `doc/learnings/<slug>/{incident-report,proposed-solutions}.md`
  and record it to the append-only ledger `.i2p/learnings.jsonl` as `open` (via `scripts/learnings.sh`).
- **route** — resolve the target repo + a **SELF**-vs-**GEMBA** verdict from `.i2p/identity.json`
  (via `scripts/identity.sh`). SELF → improve here / `/<plugin>:self-improve` (never self-merge);
  GEMBA (a sibling repo) → **ask before filing**.
- **raise** — file the feedback issue on the resolved target via `scripts/raise-feedback.sh`
  (REST-only `gh api`, **dedup** by stable slug, **autonomy**: same-repo auto, sibling needs `--confirm`,
  `--dry-run` composes only), then record the filing back to the ledger (`learnings.sh filed --issue <url>`).

Un-filed learnings past a threshold are surfaced by `scripts/overdue-learnings.sh` as a re-entry signal
for `/iterate`. Thin skill, fat scripts — the SKILL orchestrates the three scripts under
`${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/`.
