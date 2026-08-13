---
description: Adversarial review of a PR or local diff → a single verdict (PASS / NEEDS_REVISION / BLOCK). Runs ONE composed DELIVER reviewer whose lenses are auto-selected for the diff (or pinned by a project review-profile); composes the SECURE plugin's scan-all when present; writes PR_REVIEW.md.
---

Run an adversarial pull-request review. Follow the [`pr-review` skill](../skills/pr-review/SKILL.md):

1. Gather the review packet for `$ARGUMENTS` (a PR number, a `base..head` range, or — if empty — the
   current branch vs its merge-base with main):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-review/scripts/gather-diff.sh $ARGUMENTS > /tmp/pr-review-packet.md
   ```
2. **Pick the lenses, then run ONE composed reviewer** (skill §2/§2a — *one reviewer looking for
   several things, not several agents each looking for one*). Fingerprint the diff and auto-select the
   ~3 most load-bearing lenses (base triad CORRECTNESS + REGRESSION + DOCUMENT; a diff touching
   auth/API/prompts pulls SECURITY/API-CONTRACT/PROMPT-INJECTION in, displacing the weakest base lens)
   — unless the project's `.deliver/review-profile.md` pins them. Spawn a **single** DELIVER `reviewer`
   with those lenses composed into one hostile-but-fair pass, each finding tagged with its lens. If the
   SECURE plugin is installed, also run `/secure:scan-all` and fold in its verdict as the security lens.
3. HIGH/CRITICAL refutation is **intrinsic** to that one reviewer (it self-refutes each finding);
   confirm each surviving HIGH/CRITICAL carries its proving evidence before it gates. Only a genuinely
   contested HIGH/CRITICAL on a high-stakes diff warrants spawning one independent refuter — the
   exception, never the default.
4. Synthesise one verdict (BLOCK > NEEDS_REVISION > PASS, max-severity rule) and write `PR_REVIEW.md`.
5. Present the verdict, the findings table, and explicitly what was **not** reviewed (lenses
   not-run — no silent narrowing).

This command reports a verdict; what happens after a PASS is decided by the project's merge-governance
mode ([`../knowledge/protocols/merge-governance.md`](../knowledge/protocols/merge-governance.md)) — it
does not merge here. Pass `--post` to also comment the verdict on the PR via `gh pr comment` (needs
`gh`).
