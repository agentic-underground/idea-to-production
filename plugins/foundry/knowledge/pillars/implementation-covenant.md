# PRINCIPLE PHILOSOPHY

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Tests Are the Contract

**Never modify test code during implementation.**

- Tests are the guardrails; the implementation must conform to them.
- If a test is genuinely wrong, stop. Return to Step 3, fix it with documented reasoning,
  re-validate against the EARS spec, then return to implementation.
- Never fix a test to make it pass. Fix the implementation, or correct the spec first.

## 6. Spirit, Not Just Letter

When all tests are green, re-read the EARS spec and the `.feature` file.

Confirm the implementation satisfies the spirit of the requirements, not just the letter
of the tests. A test can pass and the feature can still be wrong.

## 7. Workspace Conventions

- Shell scripts: `set -euo pipefail`; timestamped logging to `cache/*.log`; idempotent; clean exit on error.
- Python: uv-first; no bare `except`; type hints on public signatures; AAA test pattern.
- JavaScript/TypeScript: ESM imports; typed interfaces; descriptive test names.
- Git: never commit without running the full test suite first.

## 8. After Green — Deliver

After all tests pass (Steps 5 + 6), proceed through delivery in order:

- **Step 7**: Sync — `git fetch origin && git rebase origin/main`; re-run tests after rebase.
- **Step 8**: Commit message — per `COMMIT_MESSAGE.md` in this references directory.
- **Step 9**: Commit + push; update ROADMAP.md STATUS → COMPLETE.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, clarifying questions come before implementation rather than after mistakes, and no test is ever modified to make it pass.