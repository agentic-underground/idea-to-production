# FOUNDRY — Merge Governance (this project)

**Merge mode:** direct-merge

> Spec: [`plugins/foundry/knowledge/protocols/merge-governance.md`](../plugins/foundry/knowledge/protocols/merge-governance.md).
>
> In `direct-merge` mode FOUNDRY builds the change, the always-on adversarial review
> (`/foundry:pr-review`) gates it, and on **PASS** FOUNDRY **pushes the branch, opens a PR, and merges
> it** — completing the full branch → commit → push → PR → merge cycle itself. This is the chosen
> posture for this solo-builder repo: the agent carries each change all the way to `main` once the
> adversarial gate is green. The general workflow is documented in
> [`../CLAUDE.md`](../CLAUDE.md) (GIT WORKFLOW); keep the two in agreement.
>
> To switch: tell FOUNDRY "give FOUNDRY merge autonomy" (→ `direct-merge`) or "require PR approvals"
> (→ `pr-approval`), or edit the `**Merge mode:**` line above. The adversarial review gate is
> always-on in either mode; the mode only decides who merges after a PASS.

## FLEET continuous-delivery engine — governance mapping

When the external **FLEET engine** drains this repo's v2 pipeline (`docs/roadmap/`), the merge mode
above maps onto the engine's registry fields (`~/.claude/pipeline-projects.json`) as follows
(see [`../scripts/register-with-fleet.sh`](../scripts/register-with-fleet.sh)):

| `.foundry/governance.md` | engine registry | engine behaviour on a GREEN plan |
|---|---|---|
| **`direct-merge`** (this repo) | `delivery: pr`, `admin_merge: true` | opens a PR and **`gh pr merge --admin`**'s its own PR — continuous delivery, never pauses |
| `pr-approval` | `delivery: pr`, `admin_merge: false` | opens a PR and marks the EPIC **`delivered`** (fire-and-forget; a human merges) |

For a **v2 EPIC** (one carrying a `## Plans` table — the shape `/roadmapper` emits), landing is governed
by `delivery` + `admin_merge` **only**; the registry's `merge_mode` field applies to the v1 *flat* build
path and is inert for v2 EPICs (it is still written for back-compat). The remote is GitHub (`origin`), so
`delivery` is `pr` (a git.local remote would be `direct`). The repo-declared `.pipeline/verify` gate is
what unlocks merging; keep this mapping and the registry in agreement when the merge mode changes.
