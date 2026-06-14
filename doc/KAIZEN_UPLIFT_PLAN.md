# KAIZEN UPLIFT PLAN — weave a GEMBA feedback reflex + a missing-handler decision gate into the fabric

> **How to kick this off (next session):** open this repo and say *"execute KAIZEN_UPLIFT_PLAN.md"*.
> It is a large, multi-PR build — **stamp it through the token-fairness scheduler first**
> (`tf plan --class large`), and run it as **two sequenced PRs** (Primitive 1, then Primitive 2),
> each gated by `/foundry:pr-review`, never self-merged. Carry an explicit `+Xk` budget if any wave
> fans out (and remember the L2/convergence caveats from `doc/token-fairness-learnings/`).

---

## Why (the problem this solves)

When an idea-to-production plugin hits something it can't finish well — a **missing value-handler**
(the user picked rust+tauri and the conveyor thrashed), a painful tooling detour (building a PDF via
embedded **typst** took forever), a reviewer BLOCK, an outright failure — it should **instinctively
react**: capture the event (incident + problems + learnings) and route it into the **GitHub issue→PR
feedback loop**, so the fix lands once, upstream, for everyone. We did this *by hand* for the
token-fairness scheduler this session (issue #2 + draft PR #3 + `doc/token-fairness-learnings/`).
This plan makes that reflex **part of the fabric**, and adds the decision gate that turns a capability
gap into a *choice* instead of a grind. The feedback loop broadens adaptation beyond "you and me" out
to the community once the marketplaces are in wider use.

**Reference implementations already in the repo (this session):**
- The captured-event template → `doc/token-fairness-learnings/2026-06-13-workflow-fanout-cap-bypass/`
  (incident-report + proposed-solutions). The GEMBA reflex generalises exactly this shape.
- The "create a new handler" pipeline → `doc/handler-build/` (haiku research → sonnet synthesis →
  opus authoring → adversarial review) and the four handlers it produced (incl. `handler-rust-tauri`,
  PR #40). The decision gate's "build the handler" path reuses this.

## Decisions (already made — do not re-ask)

1. **Home:** the reflex lives in **`mission-control`** (reusing its incident→postmortem→action-items→
   iterate machinery — the OPERATE feedback home).
2. **Autonomy:** issue/PR creation is **auto for same-repo SELF_IMPROVEMENT**, **ask-first for
   cross-repo KAIZEN/GEMBA**. (Same-repo *merges* are still governance-gated — never self-merge.)
3. **Scope:** build **both** primitives, **sequenced** — reflex plumbing first (PR-A), then the
   missing-handler gate consumes it (PR-B).
4. **"Instinctive" = honest mechanism:** always-on injected awareness (the KAIZEN canon) + trigger
   points wired into the conveyor (missing-handler, reviewer BLOCK, postmortem) + a one-step reflex
   skill. Not a magic anomaly detector.

## What already exists — REUSE, don't reinvent

- **Capture:** `mission-control:incident` → `POSTMORTEM-*.md` → append-only `.i2p/action-items.jsonl`
  (+ `plugins/mission-control/skills/incident/scripts/overdue-action-items.sh` detector) →
  `mission-control:iterate` (pivot→OPPORTUNITY→DISCOVER ↻).
- **Self-improve governance:** every plugin's `/X:self-improve` (reflect→decide→branch→
  `/foundry:pr-review`→PR); `.foundry/governance.md` (`pr-approval` default); the **never-self-merge**
  guardrail; `plugins/foundry/knowledge/protocols/merge-governance.md`.
- **GEMBA is already canon** — principle #5 "go and see" in
  `plugins/foundry/knowledge/architecture/kaizen-covenant.md` and `knowledge/first-principles.md`.
- **Missing-handler already detected** — `plugins/foundry/agents/builder-lead.md` Phase 4.5 roster
  cross-check — but it **silently degrades** ("route to the nearest registered handler") instead of
  pausing for a decision. This is the seam to upgrade.
- **Decision idiom + deferral:** `plugins/foundry/skills/roadmapper/SKILL.md` GO/DISCUSS/DEFER (§6),
  DEFER/RESTORE + RESUME (§11.6–11.7).
- **Version-thrash antidote:** `plugins/foundry/agents/handler-rust-webapp.md` +
  `plugins/foundry/skills/rust-webapp-rollout/references/00-MANIFEST.md` — a **pinned version matrix**
  + a **FORBIDDEN list**. New handlers must bake this in.
- **Identity discovery:** `git remote -v` (already in `plugins/foundry/skills/pr-review/scripts/gather-diff.sh`)
  + `plugin.json.repository` + `.claude-plugin/marketplace.json.owner`.
- **Canonical-copy + injection:** `scripts/verify-prereqs.sh` (KAIZEN.md is check N) +
  `hooks/inject-kaizen.sh` (atomic per-session dedup) ship a byte-identical canon into all 9 plugins.
- **Durable follow-up:** `.i2p/scheduled-jobs.json` + token-fairness `tf registry/oscron`.
- **Genuinely net-new (small, sharp):** there is **no `gh issue create` anywhere**; no umbrella-org
  identity; the missing-handler path doesn't pause.

## Taxonomy — the routing rule

Every captured learning has a **target = where the fix belongs**:

| Target | When | Action | Autonomy |
|---|---|---|---|
| **SELF_IMPROVEMENT** | fix belongs in **this** marketplace repo | branch→`/foundry:pr-review`→PR (code) **or** file an issue on this repo (tracked gap) | **auto** (merge governance-gated; never self-merge) |
| **GEMBA** (cross-repo) | fix belongs in a **sibling** marketplace under the umbrella org (e.g. token-fairness) | raise an **issue** on that sibling repo (+ optional draft PR carrying the brief, as we did for #2/#3) | **ask first** |
| external / third-party | neither | capture to local ledger only | none |

GEMBA = "go and see": captured at the place the work actually broke.

---

## PRIMITIVE 1 — the GEMBA feedback reflex (in `mission-control`) → **PR-A**

### 1a. Umbrella-org identity — `.i2p/identity.json` (new; `.example` committed)
```json
{ "schema": "identity/1.0",
  "github_org": "whatbirdisthat",
  "marketplace_repo": "whatbirdisthat/idea-to-production",
  "siblings": [ { "name": "token-fairness", "repo": "whatbirdisthat/token-fairness", "provides": ["scheduler"] } ] }
```
Seeded from `git remote -v` + `marketplace.json.owner` when absent. **One field (`github_org`)**
switches the whole marketplace to the new org when it is created. Add
`plugins/mission-control/skills/gemba/scripts/identity.sh` to resolve a target-repo + SELF/GEMBA
verdict from a "where does this belong" hint (this repo, or a named sibling capability).

### 1b. Learning ledger — `.i2p/learnings.jsonl` (new, append-only, schema-versioned)
Mirror `.i2p/action-items.jsonl`. One record/event:
`{schema:"learnings/1.0", id, ts, event:open|filed|closed, origin_plugin, phase, kind:gap|failure|thrash|missing-handler, target:self|gemba|external, target_repo, severity, title, brief_path, issue_url}`.
Add a reducer + an **unfiled/overdue detector** (clone `overdue-action-items.sh`) so open learnings
surface as a re-entry signal into `mission-control:iterate`.

### 1c. The reflex skill — `mission-control:gemba` (new: `plugins/mission-control/skills/gemba/SKILL.md`)
Capture → route → raise:
1. **Capture** into `doc/learnings/<event-slug>/{incident-report,proposed-solutions}.md` — the **exact
   shape** of `doc/token-fairness-learnings/…` (that folder is the canonical template). Append a
   `learnings.jsonl` record (`event:open`).
2. **Route** via `identity.sh`: SELF_IMPROVEMENT → compose the relevant `/X:self-improve` (code fix) or
   auto-file an issue on this repo; GEMBA → draft the issue, **ask**, then file on the sibling repo.
3. **Raise** via `raise-feedback.sh` (1d); record `issue_url` back to the ledger (`event:filed`).

### 1d. The issue-raiser — `raise-feedback.sh` (new; `gh api` REST per the REST-only PAT)
Wrap `gh api repos/<org>/<repo>/issues` (+ optional draft PR carrying the brief). **Dedup** by a
stable title/slug search before filing (so "automatic" never spams). Honour autonomy: same-repo auto;
sibling repo requires `--confirm`. `--dry-run` prints the would-be issue. (The token-fairness `gh api`
calls from this session are the proven shape.)

### 1e. Always-on awareness — extend the KAIZEN canon (the "instinct")
Add a short **GEMBA reflex** clause to `KAIZEN.md` (canonical root) and `kaizen-covenant.md`:
> *When work hits a gap it cannot finish, a failure, or a painful thrash — go and see: capture it, and
> raise it as feedback. Fix in this repo → a SELF_IMPROVEMENT PR (auto, governance-gated). Fix in a
> sibling marketplace → a GEMBA issue on that repo (on consent). The loop, not the lone fix, is how the
> marketplace gets better for everyone.*
Re-sync byte-identical into all 9 plugins via `bash scripts/verify-prereqs.sh --fix`; it injects every
session via `inject-kaizen.sh`. **This is what makes the reflex fire without being asked.**

### 1f. Trigger points (wired instinct)
Doc/skill instructions that invoke `/mission-control:gemba` when: a postmortem action item is
cross-cutting (`incident`); a reviewer returns BLOCK or repeated NEEDS_REVISION (`foundry:pr-review`/
`reviewer`); or the missing-handler gate fires (Primitive 2). Backed by 1e so even un-wired surprises
prompt the reflex.

---

## PRIMITIVE 2 — the missing-capability decision gate (in `foundry` + `ideator`) → **PR-B** (consumes PR-A)

### 2a. Upgrade detection from "degrade" to "pause + decide"
- `plugins/foundry/agents/builder-lead.md` Phase 4.5 roster cross-check: on a missing VALUE_HANDLER,
  **PAUSE** and surface the 3-way gate instead of silently routing to the nearest handler. Also update
  `plugins/foundry/skills/builder/SKILL.md` §8/§14.
- `plugins/ideator/knowledge/ideation/challenge-protocol.md` **stack-fit** axis + the IDEA-brief
  `LANGUAGE/STACK (which FOUNDRY handler)` field: check at **ideation time** too, so the gap is caught
  before a build starts.

### 2b. The 3-way gate (roadmapper GO/DISCUSS/DEFER idiom)
```
MISSING VALUE_HANDLER — stack: <rust+tauri> — no handler in the pool.
 1) BUILD HANDLER FIRST  — block the original build; author handler-<stack> first, then resume.
 2) MVP WITH EXISTING    — route to nearest handler; record DEGRADED_CAPABILITIES; build now.
 3) BOTH                 — build MVP now AND roadmap the new handler via feedback; defer the
                           original build until the handler lands.
```
- **(1) BUILD HANDLER** → author `plugins/foundry/agents/handler-<stack>.md` using the
  research→synthesis→build→review pipeline proven in `doc/handler-build/`, baking in the **pinned
  version matrix + FORBIDDEN list** (2c). Then resume the original build.
- **(2) MVP** → nearest registered handler; emit `DEGRADED_CAPABILITIES` and disclose in `FOUNDRY_PLAN.md`.
- **(3) BOTH** → MVP now **+** `/mission-control:gemba` raises the new-handler feedback
  (SELF_IMPROVEMENT issue on this repo, auto) **+** add a `DEFERRED` roadmap item "Create
  handler-<stack>" **+** mark the original item *awaiting-handler* **+** optionally arm a durable
  follow-up (roadmapper RESTORE, or a `tf` registry job) to resume once the handler lands and the
  marketplace updates.

### 2c. New-handler authoring discipline — `handler-authoring-discipline.md` (new knowledge doc)
The antidote to version/tooling thrash (rust+tauri, typst): a template requiring a **pinned version
matrix**, a **FORBIDDEN list**, the KAIZEN covenant, and the four-wave build pipeline — generalised
from `rust-webapp-rollout/references/00-MANIFEST.md`. (`handler-rust-tauri` already exists from PR #40,
so rust+tauri is the worked example; the typst pain becomes a SELF_IMPROVEMENT issue to harden
`pressroom`'s `scripts/build-pdf.sh` typst path.)

### 2d. Deferral + resumption
Reuse `roadmapper` DEFER/RESTORE (§11.7) + RESUME (§11.6): the original item is `awaiting-handler`,
paired with the `DEFERRED` handler-creation item; when the handler lands the item is RESTORED and
re-planned with the real handler.

---

## Delivery (sequenced, governance-gated, never self-merge)

1. **Stamp** the cycle: `tf plan --class large`; bracket with `tf plan-open`/`plan-close`.
2. **PR-A — the reflex** (mission-control): `.i2p/identity.json(.example)` + `identity.sh`,
   `.i2p/learnings.jsonl` + reducer/detector, `skills/gemba/SKILL.md`, `scripts/raise-feedback.sh`,
   the KAIZEN.md + covenant awareness clause **re-synced into all 9 plugins** (+ a new
   `verify-prereqs.sh` check if any new canonical asset is added), token-fairness event linked as the
   worked example. Branch → `/foundry:pr-review` → PR via `gh api`.
3. **PR-B — the gate** (foundry + ideator): `builder-lead.md` Phase 4.5 upgrade, `builder/SKILL.md`
   §8/§14, ideator stack-fit check, `handler-authoring-discipline.md`, roadmapper deferred-item
   wiring — **consuming PR-A's `/mission-control:gemba`**. Branch → `/foundry:pr-review` → PR.
4. **Dogfood:** authoring PR-A is itself a SELF_IMPROVEMENT — run the new reflex on a seeded test gap
   to file one real issue end-to-end.

## Verification

- **Identity routing**: `identity.sh` returns `self` for this repo and `gemba`+correct sibling repo
  for a token-fairness-class gap; flipping `github_org` re-targets everything (`--dry-run`).
- **Issue-raiser**: `raise-feedback.sh --dry-run` composes a correct body; **dedup** suppresses a
  second identical filing; same-repo files without prompt, sibling repo refuses without `--confirm`;
  one real end-to-end issue filed on this repo as the dogfood.
- **Awareness shipped**: `bash scripts/verify-prereqs.sh` green (KAIZEN canon byte-identical across 9
  plugins); a fresh session shows the GEMBA reflex clause injected.
- **Gate fires + pauses**: a synthetic roadmap item with an unknown stack makes `builder-lead` **stop**
  at the 3-way gate (not silently degrade); option (3) produces an MVP plan **+** a filed issue **+** a
  `DEFERRED` "Create handler-<stack>" item **+** an awaiting-handler mark on the original.
- **Ledger loop**: `.i2p/learnings.jsonl` records open→filed; the unfiled/overdue detector surfaces an
  open learning to `mission-control:iterate`.
- **No silent regressions**: `/foundry:pr-review` PASS on both branches; `mission-control:check` and
  `i2p:check` green.

---

## Open items to confirm at kickoff
- **Umbrella org name**: defaults to `whatbirdisthat`; set `github_org` in `.i2p/identity.json` to the
  new org once it exists (one-line switch; repos re-pointed by `git remote` too).
- **Branding**: `mission-control:gemba` is the reflex command name (aligns with the existing GEMBA
  covenant principle). Rename here if you prefer `feedback`/`kaizen-loop` before PR-A.
