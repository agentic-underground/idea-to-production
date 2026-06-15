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
