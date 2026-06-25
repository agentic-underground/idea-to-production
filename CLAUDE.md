# CLAUDE.md — idea-to-production marketplace

Agent entry point for the **idea-to-production** Claude Code plugin marketplace. Humans
start at [README.md](./README.md); agents working *on the marketplace itself* start here.

- **What this repo is** — a marketplace of eight composable plugins (the **i2p** front
  door — which also greets whoever opens a repo — plus seven specialists) that carry software
  from IDEA to PRODUCTION. The roadmap lives on GitHub (project board); the in-repo `flow`
  plugin that once owned DELIVER has been retired — its `roadmapper` folded into the
  **`deliver`** plugin (formerly `foundry`), which now spans **DELIVER → BUILD → ASSURE**
  (plan → build test-first → certify). The pillars and plugin tour:
  [README.md](./README.md). The
  philosophical spine: [`plugins/deliver/knowledge/first-principles.md`](plugins/deliver/knowledge/first-principles.md).
  The operation: [`plugins/deliver/VALUE_FLOW.md`](plugins/deliver/VALUE_FLOW.md).
- **Glossary** — every concept, plugin, agent, skill, command:
  [`plugins/deliver/knowledge/glossary.md`](plugins/deliver/knowledge/glossary.md).
- **Self-contained plugins** — each plugin is installed standalone, so live surfaces
  resolve paths through `${CLAUDE_PLUGIN_ROOT}` only; never against `~/.claude` or a
  sibling plugin. The canonical-copy promise (a file shipped byte-identical into every
  plugin and CI-verified) is how shared assets stay in sync — see
  `scripts/verify-prereqs.sh`.

## GIT WORKFLOW — branch → commit → push → PR → merge

**Every change to this repo follows the full cycle — never commit straight to `main`.** Even a
one-line fix gets its own branch and PR. The steps, in order:

1. **Branch** off up-to-date `main` (`feat/…`, `fix/…`, `chore/…`, `docs/…`).
2. **Commit** in focused, single-purpose batches — one concern per PR (small batches are KAIZEN; a
   mixed PR is `muda`). Emoji-prefixed messages matching the existing history (`📝 docs(...)`,
   `✨ feat(...)`, `🔧 chore(...)`), ending with the `Co-Authored-By` trailer.
3. **Push** the branch to `origin`.
4. **PR** via `gh pr create` — a clear title + body. The always-on adversarial review
   (`/deliver:pr-review`) is the quality gate.
5. **Merge** after the gate is green. **Merge mode is `direct-merge`** (see below): the agent merges
   its own PR after a PASS.

## MERGE GOVERNANCE

**Merge mode: `direct-merge`**

In `direct-merge` mode DELIVER builds the change, the always-on adversarial review
(`/deliver:pr-review`) gates it, and on **PASS** DELIVER **pushes the branch, opens a PR, and merges
it** — completing the full branch → commit → push → PR → merge cycle itself. This is the chosen
posture for this solo-builder repo: the agent carries each change all the way to `main` once the
adversarial gate is green.

To switch: tell DELIVER "require PR approvals" (→ `pr-approval`) or "give DELIVER merge autonomy"
(→ `direct-merge`), or edit the **Merge mode** line above.

### FLEET continuous-delivery engine — governance mapping

When the external **FLEET engine** drains this repo's v2 pipeline (`docs/roadmap/`), the merge mode
maps onto the engine's registry fields (`~/.claude/pipeline-projects.json`) as follows
(see [`scripts/register-with-fleet.sh`](scripts/register-with-fleet.sh)):

| Merge mode | engine registry | engine behaviour on a GREEN plan |
|---|---|---|
| **`direct-merge`** (this repo) | `delivery: pr`, `admin_merge: true` | opens a PR and **`gh pr merge --admin`**'s its own PR — continuous delivery, never pauses |
| `pr-approval` | `delivery: pr`, `admin_merge: false` | opens a PR and marks the EPIC **`delivered`** (fire-and-forget; a human merges) |

For a **v2 EPIC** (one carrying a `## Plans` table — the shape `/roadmapper` emits), landing is governed
by `delivery` + `admin_merge` **only**; the registry's `merge_mode` field applies to the v1 *flat* build
path and is inert for v2 EPICs. The remote is GitHub (`origin`), so `delivery` is `pr`. The
repo-declared `.pipeline/verify` gate is what unlocks merging.

## TOKEN SAFETY — provided by the token-fairness plugin

The token-aware scheduler that protects a solo builder's usage meter from a paid lockout **no longer
ships in this marketplace.** It has been ported to a tested Rust binary (`tf`) and split into the
standalone **token-fairness** marketplace. Install it to enable the always-on guard:

```
/plugin marketplace add ~/Code/token-fairness     # or the published URL
/plugin install scheduler@token-fairness
```

Once enabled, `scheduler@token-fairness` injects its TOKEN SAFETY protocol into **every** session
globally — classify each plan, stamp its cost + p95 convergence, bracket `plan-open`/`plan-close` so the
actual feeds the estimator, and gate every fan-out wave against the live rate-limit window — and runs
the guard hooks (live-ceiling spawn gate, snapshot bridge, session-token writer, durable-job re-arm),
all driven by the `tf` binary. Until token-fairness is installed, this repo ships **no** token guard.

## KAIZEN

The standing operating awareness of the marketplace — the lean canon (muda · mura · muri, the seven
wastes + rediscovery, and *halve the distance to perfection*). It is **not** duplicated here: the
canonical source is [`KAIZEN.md`](./KAIZEN.md), mirrored byte-for-byte into every plugin and **injected
into the agent's context once per session** by each plugin's SessionStart hook
(`plugins/*/hooks/inject-kaizen.sh`) — so it is ALWAYS_ON wherever any plugin is active (a plugin user's
own project too, which is why it lives in `KAIZEN.md` and not only here). Depth:
[`plugins/deliver/knowledge/pillars/waste-elimination.md`](plugins/deliver/knowledge/pillars/waste-elimination.md)
and [`plugins/deliver/knowledge/architecture/kaizen-covenant.md`](plugins/deliver/knowledge/architecture/kaizen-covenant.md).
How a document reaches an agent's context is explained in
[`docs/guide/context-building-pipeline.md`](docs/guide/context-building-pipeline.md).
