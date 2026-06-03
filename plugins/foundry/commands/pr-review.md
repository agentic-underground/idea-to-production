---
description: Adversarial review of a PR or local diff → a single verdict (PASS / NEEDS_REVISION / BLOCK). Fans out FOUNDRY reviewer roles prompted to refute the change; composes SENTINEL's security-gate when present; writes PR_REVIEW.md.
---

Run an adversarial pull-request review. Follow the [`pr-review` skill](../skills/pr-review/SKILL.md):

1. Gather the review packet for `$ARGUMENTS` (a PR number, a `base..head` range, or — if empty — the
   current branch vs its merge-base with main):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-review/scripts/gather-diff.sh $ARGUMENTS > /tmp/pr-review-packet.md
   ```
2. Fan out the FOUNDRY `reviewer` agent in parallel across the adversarial roles relevant to the
   diff (CORRECTNESS, SECURITY, REGRESSION, ARCHITECTURE, PERFORMANCE, DOCUMENT) — each told to try
   to break the change. If SENTINEL is installed, also run `/security-gate` and fold in its verdict.
3. Adversarially verify each HIGH/CRITICAL finding (a second reviewer tries to refute it).
4. Synthesise one verdict (BLOCK > NEEDS_REVISION > PASS, max-severity rule) and write `PR_REVIEW.md`.
5. Present the verdict, the findings table, and explicitly what was **not** reviewed.

This command reports a verdict; what happens after a PASS is decided by the project's merge-governance
mode ([`../knowledge/protocols/merge-governance.md`](../knowledge/protocols/merge-governance.md)) — it
does not merge here. Pass `--post` to also comment the verdict on the PR via `gh pr comment` (needs
`gh`).
