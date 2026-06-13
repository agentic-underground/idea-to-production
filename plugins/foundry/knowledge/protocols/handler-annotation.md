# Handler Annotation — turning the issue into a value-add log

> The cheap, always-on layer. As a work item passes through each value-handler/value-station,
> the handler appends a short **value-add annotation** to that item's GitHub issue. Read
> bottom-to-top, the issue's comment thread becomes an ordered log of *how the work was done* —
> who touched it, what they did, what value they added, and what it cost. No model fan-out, no
> separate report: one `gh issue comment` per completed contribution.

The issue itself is raised by the delivery step under the org-allowlist rule in
[`merge-governance.md`](merge-governance.md) (*"Org allowlist — when issues + PRs are raised at
all"*). This contract says nothing new about *whether* an issue exists; it defines what a handler
appends **once one does** — and the fallback when one does not.

---

## WHEN a handler annotates

A handler emits **exactly one** annotation at the moment it finishes its contribution to an item —
after its work is done and verified (tests green / artefact produced), as the last act before it
hands control back to the phase agent. One handler invocation → one annotation. Do not annotate
mid-work, and do not annotate on refusal (a handler that declines its task adds no value to log).

## WHERE the annotation goes

Resolve the item's issue number the same way the rest of the conveyor does — the `GITHUB_ISSUE: #N`
trailer / the issue the delivery step created per
[`merge-governance.md`](merge-governance.md). Then:

- **The item has an issue and `gh` is available + authenticated** → append a comment:
  ```
  gh issue comment <N> --body-file <annotation>
  ```
- **The item has NO issue** (origin owner is **not** on the allowlist, or `gh` is unavailable /
  unauthenticated — treated identically per `merge-governance.md`) → **lose nothing.** Append the
  *same* commentary as one line to the local log instead — the project's `IDEA_COST.jsonl`
  sidecar log, `doc/HANDLER_LOG.jsonl` (one JSON object per line: `{ "id", "issue": null,
  "annotation": <the rendered body>, "completed_at" }`), or the system log if no JSONL sink exists.
  The annotation is recorded either way; only its destination changes.

> This mirrors the conveyor's existing degradation rule: no-issue / no-`gh` is never an error —
> skip the GitHub write, record locally, continue.

---

## The comment template

Source the cost figures from this item's record in `IDEA_COST.jsonl`
([`../orchestration/idea-cost-schema.md`](../orchestration/idea-cost-schema.md)) — **reuse those
fields, do not invent a parallel schema.** The annotation is a *human-readable projection* of a few
of them, not a second ledger.

```markdown
### 🛠 <HANDLER_NAME> — <phase>

**Activity:** <one line: what this handler did to the item — the verb + the object>
**Value added:** <one line: the concrete value this contribution left behind — the artefact,
the coverage, the decision, the green slice>

**Cost** (from `IDEA_COST.jsonl`):
- tokens: <token_accounting.tokens_total> (in <tokens_in> / out <tokens_out>)
- phase time: <time_accounting.phase_durations_s.<phase>>s
- change: +<change_accounting.lines_added> / −<change_accounting.lines_removed>, <files_touched> files

<!-- annotation:handler=<HANDLER_NAME> phase=<phase> item=<id> -->
```

Field rules:

- **`<HANDLER_NAME>`** — the handler's identity exactly as it appears in
  `pipeline_accounting.value_handlers_used` (e.g. `PYTHON-AGENT`, `RUST-AGENT`).
- **`<phase>`** — the pipeline phase the handler ran in (`test` | `implement` | `story` | the
  handler's own station), matching the `phase_durations_s` keys in the cost schema.
- **`<id>`** — the roadmap item id (`IDEA_COST.jsonl` `id`, e.g. `ROADMAP-11`).
- Quote only the cost fields that exist for this contribution. If a figure is not yet recorded
  (e.g. the item's cost record is still being assembled), write `—` for that figure rather than
  fabricating a number. **Never block the annotation on a missing cost field.**
- The trailing HTML comment is a stable, greppable marker so the ordered log can be re-derived
  (`gh issue view <N> --json comments`) and so re-runs can detect an already-posted annotation.

### Worked example

```markdown
### 🛠 PYTHON-AGENT — implement

**Activity:** Implemented the JWT issuance + refresh service to turn the TEST phase's red suite green.
**Value added:** 31 unit + 8 integration tests passing at 100% line/branch coverage; auth service is now injectable and pinned.

**Cost** (from `IDEA_COST.jsonl`):
- tokens: 61000 (in 42300 / out 18700)
- phase time: 1680s
- change: +487 / −23, 10 files

<!-- annotation:handler=PYTHON-AGENT phase=implement item=ROADMAP-3 -->
```

---

## What this is and is NOT

- It **is** the cheap, always-on documentation layer — one deterministic comment per handler, no
  reviewer fan-out, no LLM judging. It runs on every item regardless of merge mode.
- It is **not** a substitute for the commit trail, the PR body, or the adversarial review — those
  remain as defined in [`merge-governance.md`](merge-governance.md). The annotation log explains
  *how the sausage was made*, item by item; governance still decides *who merges*.
- It does **not** define cost fields — those are owned solely by
  [`../orchestration/idea-cost-schema.md`](../orchestration/idea-cost-schema.md). If a cost field
  changes there, this projection follows; this document never restates the schema.
