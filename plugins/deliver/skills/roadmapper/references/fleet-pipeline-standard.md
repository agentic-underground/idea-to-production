# The FLEET pipeline standard — migration contract (self-contained)

> Condensed, actionable form of the frozen standard (`015` + the **v2 schema `017`**). Bundled with the
> skill so it works on a box without the FLEET monorepo. Each rule is load-bearing because the **engine
> parses it with a regex/awk** — wrong shape ⇒ the build silently skips or mis-reads the project.

## v2 (017) — decompose into EPIC → PLAN → change (the CURRENT model)

Modern projects use the **3-level** shape (continuous delivery). Prefer this when decomposing new work:

- **EPIC** = a collection of ordered **PLANs** → **`EPIC_NNNN.md`** (uniform `TYPE_NNNN.md` naming). The
  epic doc carries an ordered **`## Plans` table** — the same `| order | plan | state |` grammar as the
  top manifest, one level down. The engine parses it **section-scoped** (between `## Plans` and the next
  `## `), so keep it its own section.
- **PLAN** = a reviewable, Issue-sized chunk (several commits) → its own **`PLAN_NNNN.md`** (own global
  4-digit id; addressable as "review PLAN_0123"). Metadata back-references its `**Epic**`; no state in the
  plan doc (state lives in the epic's `## Plans` table).
- **change** = one commit.
- **Completion rolls up:** an EPIC is `completed` when all its PLANs are. The engine builds **one PLAN at
  a time**, in order, resuming across ticks.
- **Delivery (registry `delivery: auto|direct|pr`, default `auto` = derive from origin):**
  - **git.local ⇒ direct** — each GREEN plan ff-merges to `main` (transient branch, deleted); no PRs.
  - **github ⇒ pr** — plans accumulate on the EPIC branch + an **Issue** per plan; on EPIC completion a
    **PR** opens; with the registry **`admin_merge: true`** grant the engine `gh pr merge --admin`'s its
    own PR (continuous delivery, never pauses); without it, the EPIC is marked `delivered` (PR open).
- **Floor unchanged:** nothing lands without a GREEN repo-declared `.pipeline/verify`. Never blind-merge.
- **Roadmap-authoring units:** when an epic/plan's job IS to write the roadmap (e.g. migrate v1→v2,
  decompose a capability), declare `| **Authoring** | \`true\` |` in its `## Metadata` so the builder's
  forbidden-mutation guard stands down and the agent may create/edit the manifest + EPIC/PLAN docs. It
  still cannot merge/push/lease or mark its OWN row `completed`, and the GREEN gate still applies. This is
  how a project's FIRST pipeline job can be "bring the roadmap onto v2."

`.pipeline.md` (the EPIC manifest) keeps the SAME 5-column grammar below; only the `epic` column links
`EPIC_NNNN.md` and the state gains a terminal `delivered`. The `EPIC_{order}.md` form goes in the registry
`epic_glob`. A flat epic (no `## Plans`) still works — it's one implicit plan (v1 below). **Full v2 spec:**
`docs/massive-uplift/017_pipeline_v2_plans.md`.

---

## v1 (015) — the flat model (still valid; back-compat)

> This is the condensed v1 contract. A flat epic (no `## Plans` table) builds exactly as below. When you
> scaffold, produce these four artifacts (v2 adds the `## Plans` table + `PLAN_NNNN.md` docs on top).

A project is "pipeline-ready" when it has all four:

1. a **registry entry** in `~/.claude/pipeline-projects.json`,
2. a **`.pipeline.md` manifest**,
3. one **`NNNN_EPIC.md`** per work item,
4. a **`.pipeline/verify`** gate.

---

## 1. Registry entry — `~/.claude/pipeline-projects.json`

The per-machine, multi-project registry the engine reads. One box may declare several projects; the
engine builds the highest-`priority` one with a selectable item.

```json
{
  "version": 1,
  "projects": {
    "<project-id>": {
      "repo": "/home/user/Code/<Project>",          // REQUIRED — absolute path to the reference checkout on THIS box
      "manifest": "docs/roadmap/.pipeline.md",        // REQUIRED — repo-relative path to the manifest
      "epic_glob": "docs/roadmap/{order}_EPIC.md",    // REQUIRED — literal {order} token, substituted with the 4-digit order
      "verify": ".pipeline/verify",                   // REQUIRED — repo-relative path to the gate
      "branch_prefix": "pipeline",                    // REQUIRED — build branches are <prefix>/NNNN-slug
      "merge_target": "main",                          // REQUIRED — the integration ref a GREEN build lands on
      "remote": "origin",                              // REQUIRED — git remote name, or null if the repo has NO remote
      "forbidden_mutation": "docs/roadmap/.pipeline.md", // REQUIRED — path the agent must NOT edit (usually the manifest)
      "merge_mode": "propose",                         // optional — "propose" (default for non-FLEET) | "merge"
      "qualify": { "protected_remote": false, "human_authored_gate": false }, // optional auto-merge qualification
      "priority": 0                                    // optional — higher wins when several projects have items
    }
  }
}
```

- **`remote: null` ⇒ the project is EXCLUDED** from both merge and propose (it can't be pushed). Never
  fabricate a remote — if the repo has none, set `null` and tell the operator to add one first.
- **`merge_mode` defaults to `propose`** for any non-FLEET project: a GREEN build opens/updates an
  annotated PR and **does not auto-merge** until the repo *qualifies* (protected remote + a
  **human-authored** gate) or the box is run unattended. This is the safe default — keep it unless the
  operator explicitly vouches for the gate.
- `epic_glob` uses a literal `{order}` token: `docs/roadmap/{order}_EPIC.md` → `docs/roadmap/0003_EPIC.md`
  for order `0003`.
- The manifest's sibling `.pipeline-ignore` (one epic basename per line) hard-hides rows from the engine.

Write the registry with `jq` (merge, don't clobber other projects):
```bash
REG=~/.claude/pipeline-projects.json
[ -f "$REG" ] || echo '{"version":1,"projects":{}}' > "$REG"
jq --arg id "<project-id>" --argjson p '<the project object above>' \
   '.projects[$id] = $p' "$REG" > "$REG.tmp" && mv "$REG.tmp" "$REG"
```

---

## 2. `.pipeline.md` manifest — the state source of truth

A 5-column table. **The leading `|` and the first three columns are load-bearing** — the engine's
in-place state rewriter targets awk field `$4` (state) keyed on `$2` (order), and the leading pipe makes
the empty cell `$1`.

```markdown
# <Project> pipeline

## Pick rule
Items are sorted ASCENDING by order; the engine pulls the first `available` row that is the top row or
immediately below a `completed` row. State lives HERE, not in the epic files.

| order | epic | state | constructs | branch |
| --- | --- | --- | --- | --- |
| `0000` | [0000_EPIC.md](./0000_EPIC.md) | `available` | first work item | `pipeline/0000-slug` |
| `0001` | [0001_EPIC.md](./0001_EPIC.md) | `available` | second work item | `pipeline/0001-slug` |
```

Load-bearing rules:
- Every pipeline row **MUST start with a leading `|`**, and the first three visible columns **MUST** be
  `order`, `epic`, `state` in that order.
- **`order` is exactly four digits** (`^[0-9]{4}$`) — `0000`, `0007`, never `7` or `07`.
- States: **`available`** (selectable) · **`engaged`** (a build is mid-flight; resumes next tick) ·
  **`completed`** (set ONLY on merge+push) · **`hold`** (parked, visible but skipped).
- New items start `available`. Never set `completed` by hand — the builder sets it on merge.

---

## 3. `NNNN_EPIC.md` — one per work item

The build agent reads this file. Required shape:

```markdown
[breadcrumb up to the repo root]   <!-- if the repo enforces a doc-link convention; else omit -->

# <Imperative epic title>          <!-- first `# ` heading is scraped for the merge-commit message -->

## Metadata
| | |
| --- | --- |
| **Epic** | `NNNN` |
| **Constructs** | what this build produces |
| **Source** | the design/spec it derives from |
| **Branch** | `pipeline/NNNN-slug` |

## Construction process
Ordered steps the agent follows. (FLEET uses the three-beat: author → adversarially review → build.)

## Definition of done
A checklist that includes the deterministic gate (`.pipeline/verify`) AND the epic's functional checks.

## Execution contract (for the builder)
One-line happy path + the failure posture (a failed tick leaves the row `engaged` to resume).
```

**THE single most common breakage: `**Branch**` and its value MUST be on ONE physical line.** The engine
scrapes the branch with `grep -E '\*\*Branch\*\*' | grep -oE '<branch_prefix>/[0-9]{4}-[A-Za-z0-9-]+'`.
A Metadata row that wraps across lines makes the scrape return nothing and the build dies. Keep the
manifest's `branch` cell and the epic's `**Branch**` value identical.

---

## 4. `.pipeline/verify` — the deterministic gate

The merge gate. One shell command per line (run from the repo root, in order); **every command must exit
0** for the build to be GREEN. `#` comments and blank lines ignored.

```sh
# .pipeline/verify — what "green" means for <Project>. Deterministic, offline, fast.
npm test            # or: pytest -q / cargo test / make check / go test ./... — the project's real gate
npm run lint
```

Rules that protect against a blind merge:
- **No gate ⇒ RED.** If `.pipeline/verify` is missing AND nothing is auto-detected, the build is RED and
  **never merges**. Always create a real gate.
- **Auto-detected gates are `propose`-only.** If the engine falls back to detecting `make docs-check` /
  `npm test` / `pytest` / `cargo test`, that gate is NOT repo-declared and **can never auto-merge** under
  any mode/autonomy — it opens a PR at most. A repo-declared `.pipeline/verify` is what unlocks merging.
- **Deterministic + offline + fast** — no network, no clock dependence; the harness re-runs it
  independently and must get the same result. Heavy/functional checks belong in the epic's DoD, run by
  the agent on top of the gate.
- A **self-authored** gate does NOT qualify a repo for *attended* auto-merge — a human must vouch for the
  gate (`qualify.human_authored_gate`) before it earns auto-merge while attended.

---

## The merge decision (so you set `merge_mode`/`qualify` correctly)

| gate provenance | `merge_mode` | autonomy | qualify both-true | remote | outcome |
| --- | --- | --- | --- | --- | --- |
| GREEN, repo-declared | `merge` | any | — | set | **merge** |
| GREEN, repo-declared | `propose` | attended | yes | set | **merge** |
| GREEN, repo-declared | `propose` | attended | no | set | **propose** (PR) |
| GREEN, repo-declared | `propose` | unattended | — | set | **merge** (human-merge waived) |
| GREEN, **auto-detected** | any | any | — | set | **propose** only — never auto-merges |
| any | any | any | — | **null** | **excluded** |
| RED / no gate | any | any | any | any | **never merges** |

Safe default for a freshly-migrated project: `merge_mode: propose`, `qualify` both `false`. It will open
PRs on green; flip to `merge` / set `qualify` only once a human has reviewed the gate.

---

## v2 board variant (018) — a GitHub Project IS the board (github-origin repos only)

For a repo whose origin is **GitHub**, you may put the schedule + state on a **user-owned GitHub Project
(v2) Kanban** instead of the local `.pipeline.md`. The board is then **authoritative**: the engine reads
`next` from the **To Do** column and writes Status there. This is opt-in (the default stays the manifest);
once chosen it is **sticky** (the registry `board` field). Full spec: `docs/massive-uplift/018_github_projects_board.md`.

**Mapping:** EPIC = a GitHub **Issue** = a Project **item**; PLAN = a native **sub-issue** of that epic =
a Project **sub-item**. **Status columns ↔ state:** `Backlog`=staged (the gate — not picked) ·
`To Do`=available (engine picks the **top** by board position) · `In Progress`=engaged · `Done`=completed ·
`Delivered`=PR open, no admin grant. **"Next" = the top card of To Do.** Backlog is the human gate: items
land there with fields set; the operator promotes Backlog→To Do to hand an epic to the autonomous line.

**What changes vs the manifest path:**
- **No `.pipeline.md`** and **no `## Plans` table** — the board holds the EPIC→PLAN hierarchy + every
  item's state. You still write the **`EPIC_NNNN.md` / `PLAN_NNNN.md` docs** (the build instructions the
  agent reads), but the EPIC doc OMITS `## Plans`.
- The **registry entry** carries `board: github_project` (+ `project_owner` if not `@me`); `delivery` and
  `admin_merge` work exactly as the github manifest path. `manifest`/`forbidden_mutation` are unused in
  board mode (the engine never reads them) — set `epic_glob` so the builder can find `EPIC_NNNN.md`.
- The board itself is created/updated by the **bundled board tool** (a sibling of the engine):
  `../../scripts/pipeline-gh-project.sh`. Requires a `gh` logged in with a **`project`-scope** token.

**The board tool — verbs you call when producing (idempotent, search-before-create):**
```sh
GHP=../../scripts/pipeline-gh-project.sh        # relative to this skill; PIPELINE_PROJECT=<id> selects the repo
PIPELINE_PROJECT=<id> bash "$GHP" ensure-project                 # find-or-create + link the Project, columns + fields
PIPELINE_PROJECT=<id> bash "$GHP" ensure-epic-item   NNNN "<title>"   # Issue + board item, seeded Backlog
PIPELINE_PROJECT=<id> bash "$GHP" ensure-plan-subitem EPIC PLAN "<t>"  # sub-issue of the epic + board sub-item, Backlog
PIPELINE_PROJECT=<id> bash "$GHP" board                          # render the board by column (verify)
PIPELINE_PROJECT=<id> bash "$GHP" next                           # what the engine would pick (proves the gate)
```
`ensure-*` set **Status + Pipeline Order** on each item and the **title/body** on the issue; richer fields
(Priority/Size/Estimate/dates) are board metadata you can set later in the UI — they don't gate scheduling.

**Floor unchanged:** the GREEN `.pipeline/verify` gate, the lease, and the no-blind-merge rule all still
apply. The board changes *where next/state live*, not whether work is allowed to land.
