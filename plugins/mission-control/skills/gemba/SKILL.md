---
name: gemba
description: >
  The GEMBA reflex — the one-step capture → route → raise loop that turns a learning seen at the
  workface (a test gap, a missing guard, a cross-repo defect) into a tracked, filed feedback issue.
  Trigger with /mission-control:gemba (or "capture this learning", "raise feedback on this gap",
  "this belongs in another repo — file it", "gemba this"). Captures the event into
  doc/learnings/<slug>/{incident-report,proposed-solutions}.md + a ledger record, routes it by identity
  (SELF → improve here / auto-file; GEMBA → ask before filing on the sibling), and raises it via
  raise-feedback.sh — recording open→filed back to the learning ledger. Thin skill, fat scripts:
  it orchestrates identity.sh, learnings.sh, and raise-feedback.sh. Self-improving: every learning the
  workface surfaces becomes a tracked, de-duplicated issue instead of evaporating.
metadata:
  type: reflex
  lens: gemba
  output: doc/learnings/<slug>/{incident-report,proposed-solutions}.md + a filed issue + a ledger record
  model: inherit
---

# GEMBA

*Gemba* (現場) — "the actual place" — is the lean discipline of going to where the work happens to see
the truth for yourself. A learning seen at the workface (a coverage gap a reviewer caught, an alert that
should exist, a defect that actually belongs to a *sibling* marketplace) is worthless if it evaporates
when the session ends. This reflex makes that learning durable in one step: **capture → route → raise**.

It is a **thin** skill: it *orchestrates* three fat, tested scripts and owns no logic of its own. Resolve
every path through `${CLAUDE_PLUGIN_ROOT}`.

```
${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/identity.sh        # where does this belong? → target + SELF/GEMBA
${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/learnings.sh       # the append-only learning ledger (open|filed|closed)
${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/overdue-learnings.sh  # surface un-filed learnings (a re-entry signal)
${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/raise-feedback.sh  # gh-api issue filer (dedup · autonomy · dry-run)
```

## The three steps

### 1. CAPTURE — write the learning down (durable, schema-versioned)

Pick a stable **event slug** (`<date>-<short-what>`, e.g. `2026-06-17-coverage-gap-x`). Write the
canonical learnings shape — the same two-file shape as
[`docs/internal/token-fairness-learnings/…`](../../../../docs/internal/token-fairness-learnings):

```
doc/learnings/<slug>/incident-report.md     # what happened, the timeline, root cause(s), metrics
doc/learnings/<slug>/proposed-solutions.md  # the fix(es): root cause closed, file/function touched, tests
```

Then record the learning to the ledger as **open** (note the brief path so it is traceable):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/learnings.sh" open <project> <slug> "<one-line title>" \
  --origin <plugin|repo> --phase <lifecycle phase> --kind test-gap|guard|defect \
  --target "<org/repo>" --verdict self|gemba --severity low|medium|high|critical \
  --brief doc/learnings/<slug>/
```

The ledger is the append-only, schema-versioned `<project>/.i2p/learnings.jsonl` (record schema
`learnings/1.0`: `{schema,id,event,origin,phase,kind,target,verdict,severity,title,brief_path,issue_url,status,ts}`
— the same append-friendly, latest-record-wins discipline as the incident action-item ledger).

### 2. ROUTE — resolve where it belongs (identity decides)

Ask `identity.sh` for the target repo + SELF-vs-GEMBA verdict from a "where does this belong?" hint
(keywords describing the learning — a token-fairness-class hint routes to the sibling):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/identity.sh" resolve <project> "<hint>"
# → {"verdict":"self"|"gemba", "org":…, "repo":…, "target":"<org>/<repo>", "matched":…, "reason":…}
```

- **SELF** — the learning improves THIS marketplace. Either auto-file here, or hand to the relevant
  plugin's `/<plugin>:self-improve` (which applies on a branch and opens a PR — it **never** self-merges).
- **GEMBA** — the learning belongs to a **sibling** marketplace (cross-repo). **Ask the operator before
  filing.** `raise-feedback.sh` enforces this: a sibling target REFUSES to file without `--confirm`.

`github_org` is the single re-targeting field: when the umbrella org is created, flipping it re-points
every target at once (verify with `identity.sh targets <project> --org <new> --dry-run`).

### 3. RAISE — file the feedback issue, record it back

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/raise-feedback.sh" --dir <project> \
  --hint "<hint>" --title "<title>" --body-file doc/learnings/<slug>/incident-report.md \
  --slug <slug> [--confirm]   # --confirm REQUIRED for a sibling (gemba) target
# preview first — composes the body, files nothing, even for a sibling:
#   … --dry-run
```

`raise-feedback.sh` **dedups** by a stable slug marker before filing (an identical learning is suppressed,
not re-filed), honours **autonomy** (same-repo files automatically; a sibling refuses without `--confirm`),
and prints the issue URL on success. Record the filing back to the ledger:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/learnings.sh" filed <project> <slug> --issue "<url>"
```

## Overdue learnings — the re-entry signal

A captured learning that was never filed is a divergence between what the workface taught and what
re-entered the lifecycle. The detector surfaces it (never auto-files, never gates):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/gemba/scripts/overdue-learnings.sh" --dir <project> [--hours 24] [--strict]
```

Un-filed learnings past the threshold are a **re-entry signal** for
[`../iterate/SKILL.md`](../iterate/SKILL.md): `/iterate` turns a production signal into a new
OPPORTUNITY that re-enters DISCOVER (↻), so the learning lands as backlog instead of rotting.

## Self-improvement covenant

Covenant: [`../../knowledge/covenant.md`](../../knowledge/covenant.md). Every learning the workface
surfaces should leave the session as a tracked, de-duplicated issue routed to the repo that owns it —
folded in once, upstream, so the gap cannot quietly recur.
