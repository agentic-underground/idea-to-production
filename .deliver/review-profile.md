# Review profile — idea-to-production

Read by `/deliver:pr-review` §2a (via `resolve-review-profile.sh`) to decide the **one composed
reviewer's** lenses. This never changes the reviewer *count* (always one — PLAN 0073.001); it only
declares *which* lenses that reviewer carries.

Mode: auto

<!--
Why `auto` for this repo: the marketplace's work is overwhelmingly bash scripts + markdown/knowledge
docs + agent/skill prompt files. Auto-select gives the base triad — CORRECTNESS + REGRESSION +
DOCUMENT — on a typical script/doc slice (the operator's "1 agent, 3 things"), and correctly pulls
PROMPT-INJECTION in when a diff edits agent/skill prompt files, or SECURITY when it touches the board
token / external-API path. That adaptivity is wanted here; pinning would under-cover the prompt-file
edits this repo makes often.

To lock the gate to a fixed set instead (e.g. a repo whose work never varies):
    Mode: fixed
    Lenses: CORRECTNESS, REGRESSION, DOCUMENT
Or for a small/uniform repo, one undifferentiated pass:
    Mode: holistic
Canonical lens names live in pr-review SKILL §2a.
-->
