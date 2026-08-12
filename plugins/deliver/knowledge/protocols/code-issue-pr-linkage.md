---
metadata:
  phase: [cross-cut]
---
# CODE ↔ ISSUE ↔ PR Linkage — the unified traceability contract

> **Single source of truth** for *how a unit of work is tied to its record* across the whole
> pipeline — branch, commit, PR, GitHub issue, project-board item, and the native EPIC→PLAN
> sub-issue graph. Each mechanism is defined once, here; the surfaces that previously described a
> mechanism inline ([`CLAUDE.md` → BOARD LINKAGE](../../../../CLAUDE.md),
> [`merge-governance.md`](merge-governance.md), [`commit-message.md`](commit-message.md), and
> [`.github/PULL_REQUEST_TEMPLATE.md`](../../../../.github/PULL_REQUEST_TEMPLATE.md)) now point here.
> The goal: an auditor — or a gate — can start at *any* artefact (a branch, a commit, a merged PR,
> an issue) and reach every other, with no ambiguity about which number means what.

This doc is **descriptive of what exists today** (the board-linkage layer, EPIC 0066) **plus the
frame EPIC 0068 builds into** (the vendored create/link layer, `Closes #N` auto-close, the
sub-issue graph, and the CI reconciliation surface). Where a mechanism is not yet wired, it is
marked **(A-slice)** against the slice that lands it.

---

## 0. Two number spaces — the hazard to internalise before anything else

There are **two independent `#N` numbering spaces** in this pipeline, and conflating them silently
corrupts state:

| Space | What `#N` means | Where it appears | Chosen by |
|---|---|---|---|
| **Roadmap item #** | the EPIC/PLAN *order* (`NNNN`, `NNNN.SSS`) | `pipeline/NNNN-*` branches, doc filenames `EPIC_NNNN.md`, the `ROADMAP:` commit footer, `<!-- pipeline-(epic\|plan)-NNNN -->` markers | **you** (a deliberate, human-chosen 1–4-digit order) |
| **GitHub issue #** | GitHub's own issue/PR autonumber | `Board: #N`, `Refs #N`, `Closes #N`, `GITHUB_ISSUE: #N`, sub-issue links | **GitHub** (a per-repo monotonic sequence you cannot pick) |

> **Never let a roadmap number close a GitHub issue.** GitHub treats `closes #7` in a merged commit
> as a closing keyword on *its* issue #7. So on an allowlisted GitHub origin the `ROADMAP:` footer
> MUST use a **non-closing** form — `ROADMAP: item #N` / `Refs roadmap #N` — and the *only* thing
> that closes an issue is the PR body's `Closes #<issue>`. Full rule + rationale:
> [`commit-message.md` §2](commit-message.md). This is the single most common way the two spaces
> get crossed.

A further consequence: **the project-board number is itself a third GitHub-chosen fact** — a
per-owner sequence (this repo's board happens to be `#4`, but that is a fact about *this* owner
only). Tooling MUST resolve the board by **title**, never a hardcoded `#4` (EPIC 0068 / A1).

---

## 1. The unified linkage table

Each row: a linkage **mechanism** → **where it is declared** → **what reads / enforces it** → the
**CI surface** that backstops it. "Offline-native" means the mechanism is legible with no network
and no `gh` — the authoritative form in `local_file` mode; "GitHub-bound" means it only has meaning
on a GitHub-connected, org-allowlisted origin.

| # | Mechanism | Kind | Where declared | Reads / enforces it | CI surface |
|---|---|---|---|---|---|
| 1 | **`pipeline/NNNN[.SSS]-*` branch** | offline-native | the git branch name | `verify-board-linkage.sh` `classify_linkage` (anchored `^pipeline/[0-9]{4}(\.[0-9]{3})?[-/]`) — self-declares board linkage | `verify.yml` `board-linkage` job (`BL_BRANCH`, offline) |
| 2 | **`Board: #N` / `Refs #N` trailer** | GitHub-bound | a commit message trailer **or** the PR body | `verify-board-linkage.sh` (leading word-boundary match; online existence probe via `gh`, advisory-degrades) | `verify.yml` `board-linkage` job (`--pr-body`, `BL_OFFLINE=1` — declaration only) |
| 3 | **`[no-board]: <reason>` exemption** | offline-native | a commit trailer **or** the PR body (line-start anchored) | `verify-board-linkage.sh` — trivial-work escape hatch; the reason is *logged, not silent*; empty reason → FAIL | `verify.yml` `board-linkage` job |
| 4 | **`GITHUB_ISSUE: #N` commit trailer** | GitHub-bound (allowlisted origins only) | a commit-message footer | [`commit-message.md` §2](commit-message.md); traces the commit to its tracking issue | claims harness (A8) — repo-scoped |
| 5 | **`Closes #N` in the PR body** | GitHub-bound (allowlisted origins only) | the PR body | GitHub auto-closes the issue on merge; policy in [`merge-governance.md`](merge-governance.md) "Org allowlist" | claims harness (A8) — every merged PLAN has `Closes #N` + a merged PR |
| 6 | **Native EPIC→PLAN sub-issue** | GitHub-bound | GraphQL `addSubIssue` at PLAN create (A1) | reader: `scripts/roadmap/delete-epic.sh` (`subIssues` GraphQL); writer: `scripts/roadmap/gh-pipeline.sh` (A1) | claims harness (A8) — every EPIC issue has ≥1 sub-issue |
| 7 | **`<!-- pipeline-(epic\|plan)-NNNN[.SSS] -->` marker** | GitHub-bound (idempotency) | the issue body (byte-exact) | `roadmapper-gh-fields.sh` `cmd_set_body` grep *preserves* the marker across body edits; the A1 writer's search-before-create dedup relies on it being byte-identical | — (idempotency contract, not a gate) |
| 8 | **Board Status (single-select)** | GitHub-bound (state, authoritative) | project-board item field | roadmapper `set-status` (A1); `gh project item-edit` | claims harness (A8) — **project-scoped** (needs `PROJECT_TOKEN`; advisory-skip if absent) |

> **Mechanisms 1 and 3 are the only offline-native forms of linkage.** Everything else
> (`Board:`/`Refs`/`Closes`/`GITHUB_ISSUE:`/sub-issues/markers/Status) is **GitHub-bound** — it has
> meaning only on a GitHub-connected, org-allowlisted, opted-in origin. In `local_file` mode the
> `pipeline/NNNN-*` branch is the authoritative linkage; a `Board:`/`Refs` trailer still *satisfies
> the gate as a declaration*, but its `#N` resolves to nothing offline — do not treat the trailers as
> co-equal to the branch (EPIC 0070 / C2 makes this explicit in `CLAUDE.md`).

### How the board-linkage gate classifies (mechanisms 1–3)

`verify-board-linkage.sh` reduces a branch + its commit messages (or a PR body) to exactly one
verdict, with **genuine linkage winning over an exemption** so a stray `[no-board]` mention can
never mask real linkage:

```
branch   → pipeline/NNNN[.SSS]-* branch name        (mechanism 1)  ─┐
trailer  → Board:/Refs #N, leading word-boundary     (mechanism 2)  ├─ LINKED  → PASS
exempt   → [no-board]: <non-empty reason>, line-start (mechanism 3) ─── EXEMPT → PASS (reason logged)
unlinked → none of the above                                        ─── FAIL   → "declare it or log [no-board]"
```

Patterns are **anchored** so prose can't spoof linkage: `rework the dashboard #7` is not a `Board`
trailer, and `docs: describe the [no-board]: convention` is not an exemption. The declaration check
is deterministic + offline (this is the block); the *existence* of a declared issue is a best-effort
online probe that **degrades to advisory** when `gh`/network is absent — never a false PASS by
silence.

---

## 2. Gate-surface matrix — `.pipeline/verify` vs `.github/workflows/verify.yml`

Two enforcement surfaces, deliberately divided. The **pre-push gate is authoritative**; CI is the
**backstop** for a push that skipped it — the marketplace's standing framing (pre-push gates, not CI,
are the real gate).

| Property | `.pipeline/verify` (pre-push) | `.github/workflows/verify.yml` (CI) |
|---|---|---|
| **Role** | authoritative gate — runs before code leaves the machine | backstop + repo-wide assertions a single branch can't self-check |
| **Speed / cost** | fast, offline, token-free | may install tools (gitleaks), hit the network |
| **Scope** | **this branch** (branch name, its commits, working tree) | the **PR** (`pull_request` event) + whole-repo signals |
| **Board linkage** | `verify-board-linkage.sh --self-test` (logic) **+** live run (this branch, online existence probe) | `board-linkage` job: `--self-test` + `--pr-body` (declaration only, `BL_OFFLINE=1`) — *same script*, so the two can never disagree |
| **Failure mode** | blocks the push | blocks the merge |
| **GitHub-integration claims (A8)** | live run is **advisory-only** (`exit 0`); only `--self-test` blocks — never brick a push on hand-edited board drift or lapsed auth | `github-integration` job **(A8 — not yet wired)**: repo-scoped always; project-scoped only when `PROJECT_TOKEN` present, else advisory-skip |

The load-bearing rule: **CI reuses the pre-push scripts** (`verify-board-linkage.sh` runs on both
sides), so a check can never pass one surface and fail the other for the same input. New gates model
this — a pure classifier + `--self-test` fixtures + offline-degrades-to-advisory
(`verify-board-linkage.sh` is the template).

> **Why the claims harness stays advisory in `.pipeline/verify`.** A harness that hard-failed
> *online* (a hand-closed issue, a lapsed `gh` auth after opt-in) would brick every push of every
> branch. The precedent is degrade-loud-and-continue, never brick: print findings, `exit 0`; only
> the deterministic `--self-test` blocks. The repo-wide assertions ride CI, where a `PROJECT_TOKEN`
> can reach Projects v2 (the default Actions `GITHUB_TOKEN` cannot).

---

## 3. Where each surface points here

- [`CLAUDE.md` → BOARD LINKAGE](../../../../CLAUDE.md) — the convention every branch/PR follows
  (mechanisms 1–3); defers here for the full mechanism table + the two-number-space hazard.
- [`merge-governance.md`](merge-governance.md) — the org allowlist that decides *whether* issues/PRs
  are raised at all (mechanisms 4–5 apply only on a match); defers here for the linkage catalogue.
- [`commit-message.md`](commit-message.md) — owns the `GITHUB_ISSUE: #N` trailer + the
  non-closing `ROADMAP:` form (mechanism 4 + the §0 hazard); defers here for the cross-artefact map.
- [`.github/PULL_REQUEST_TEMPLATE.md`](../../../../.github/PULL_REQUEST_TEMPLATE.md) — the PR body's
  `Board: #N` placeholder (mechanism 2) + the `[no-board]` escape (mechanism 3).

Related: [`context-sentinel.md`](context-sentinel.md) (machine-readable in-flight state — the
sentinel layer, distinct from this durable-linkage layer); `scripts/roadmap/delete-epic.sh` (the
sub-issue *reader* whose contract the A1 writer must match).
