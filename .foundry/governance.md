# FOUNDRY — Merge Governance (this project)

**Merge mode:** pr-approval

> Spec: [`plugins/foundry/knowledge/protocols/merge-governance.md`](../plugins/foundry/knowledge/protocols/merge-governance.md).
>
> In `pr-approval` mode FOUNDRY builds the change, the always-on adversarial review
> (`/foundry:pr-review`) gates it, and on **PASS** FOUNDRY **pushes the branch and opens a PR for a
> human to merge** — it never self-merges. This is the right posture for a shared, published
> marketplace repo: a human keeps the final gate and full visibility into each feature branch.
>
> To switch: tell FOUNDRY "give FOUNDRY merge autonomy" (→ `direct-merge`) or "require PR approvals"
> (→ `pr-approval`), or edit the `**Merge mode:**` line above. The adversarial review gate is
> always-on in either mode; the mode only decides who merges after a PASS.
