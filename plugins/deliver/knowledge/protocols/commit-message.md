# COMMIT_MESSAGE — Commit Message Standard

> **Single source of truth** for all DELIVER commit message rules.
> Every agent, skill, and instruction that previously defined commit message format now points here.

---

## 1. Purpose & Scope

This file governs how commit messages are written across all DELIVER-driven projects.
It is read by:

- `agents/ds-step-8-commit-message.md` — the agent that produces the commit message
- `skills/roadmapper/SKILL.md` — step 8 of the development system
- `skills/ideate/references/dev-system.md` — step 8 reference for ideate-driven projects
- `CLAUDE.md` — config-repo commit hygiene (author only)

Any file that previously contained an inline commit message template instead carries a
single pointer to this file. Update this file to change the standard everywhere at once.

---

## 2. The DELIVER Commit Format

Every project commit MUST follow this structure:

```
[emoji] type(scope): short imperative summary (≤72 chars total)

WHY:
One to three sentences on the motivation. What problem does this solve?
Reference the roadmap item number.

WHAT:
- 📐 EARS-042, EARS-043: [brief description of requirements implemented]
- 🥒 features/[slug].feature: [N] Gherkin scenarios (happy/unhappy/abuse)
- 🧪 tests/[path]: [N] tests covering [area]
- ⚙️  src/[path]: [description of implementation]
- 🔗 [other wiring/routing if applicable]

TESTING:
All [N] tests pass. Coverage: [N]%. No regressions.

ROADMAP: closes #[N]
```

### Worked Example

```
✨ feat(auth): add JWT session management

WHY:
The SPA had no authenticated state — any browser on the LAN could access
roster data. Implements roadmap item #7 (Authenticated Multi-User Operation).

WHAT:
- 📐 EARS-AUTH-001, EARS-AUTH-004, EARS-AUTH-008: auth session requirements
- 🥒 features/auth.feature: 5 Gherkin scenarios (happy/unhappy/abuse)
- 🧪 tests/test_auth.py: 12 tests covering login flow, token expiry, and role enforcement
- ⚙️  src/auth/session.py: JWT session creation and validation
- 🔗 src/blueprints/auth.py: /api/auth/login, /callback, /logout endpoints

TESTING:
All 779 tests pass. Coverage: 94%. No regressions.

ROADMAP: closes #7
```

### GitHub issue linkage (allowlisted origins only)

When the work item's git `origin` owner is on the **org allowlist** (default `agentic-underground/*`
— see [`merge-governance.md`](merge-governance.md)), the value system raises a GitHub issue per
completed item, and the commit carries that issue number as a footer trailer:

```
GITHUB_ISSUE: #142
```

This is a Conventional Commits footer (§11.8 — `word-token: value`) sitting alongside `ROADMAP:`.
It traces the commit to its tracking issue; the **PR body** (not the commit) carries the
`Closes #<issue>` reference that closes the issue on merge (see `merge-governance.md`). Omit the
trailer entirely on non-allowlisted origins — there is no issue, so there is nothing to reference.

> **Two number spaces — do not let the roadmap number close a GitHub issue.** `GITHUB_ISSUE: #N`
> and the PR's `Closes #N` use the **GitHub issue** number; the `ROADMAP:` footer's `#N` is the
> **roadmap item** number — a *different* space. GitHub treats `closes #N` in a merged commit as a
> closing keyword on *its* issue numbering, so on an allowlisted github origin a literal
> `ROADMAP: closes #7` would wrongly close GitHub issue #7. **On allowlisted github origins, write
> the roadmap footer in a non-closing form** — `ROADMAP: item #N` (or `Refs roadmap #N`) — so the
> *only* thing that closes an issue is the PR body's `Closes #<issue>`. On non-github / non-allowlisted
> origins the existing `ROADMAP: closes #N` form is unchanged.

---

## 3. Summary Line — Conventional Commits Integration

The first line of every DELIVER commit MUST combine:

```
[emoji] type(scope): short imperative summary
```

- **emoji** — visual shorthand (see §4); comes first
- **type** — Conventional Commits type noun (see §11); required
- **scope** — optional noun in parentheses describing the area of change
- **description** — imperative present tense, no period, ≤72 chars total for the whole line
- **`!`** — append before `:` to signal a breaking change: `feat(api)!: remove v1 endpoints`

Examples:
```
✨ feat(auth): add JWT session management
🐛 fix(scheduler): correct BYE round exclusion for away-only jobs
♻️ refactor(store): extract live-store write-through to module
📝 docs(roadmap): add sport profiles entry
🧪 test(data-panel): add abuse-path coverage for duplicate jersey numbers
🔒 fix(auth)!: enforce HTTPS-only session cookies
```

---

## 4. Emoji Convention

Use consistently. Pick the emoji that best describes the primary change type.

| Symbol | CC type(s) | Meaning |
|--------|-----------|---------|
| ✨ | feat | New feature |
| 🐛 | fix | Bug fix |
| ♻️ | refactor | Refactor |
| 📐 | — | Specification / EARS (WHAT line only) |
| 🥒 | — | Gherkin / .feature file (WHAT line only) |
| 🧪 | test | Test code |
| ⚙️  | ci, build | Implementation / CI / automation |
| 🔗 | build | Routing / wiring / build |
| 📝 | docs | Documentation |
| 🚀 | perf | Performance |
| 🔒 | — | Security fix |
| 🧹 | chore, style | Cleanup / chore / style |

> `📐` and `🥒` are used only in the WHAT bullet lines to label artefact types.
> They are not valid summary-line emoji — use the feat/fix/docs/test etc. emoji there.

---

## 5. Quality Rules

Before handing off to the reviewer, verify all of the following:

- The diff summary in WHAT matches the actual changed files from `git diff --stat` — no invented or missing files.
- No vague language: "various improvements", "misc changes", "updates" are blocked.
- EARS IDs are explicitly listed (e.g. `EARS-042, EARS-043`), not described generically.
- Test count and coverage percentage are accurate — run the suite and read the output.
- Roadmap item number is present in the `ROADMAP: closes #N` footer.
- Summary line is imperative present tense ("add", "fix", "remove") not past tense ("added", "fixed").
- Summary line includes a Conventional Commits type prefix.
- Total summary line length ≤ 72 characters.

---

## 6. Exit Criteria (step-8 complete)

All seven must be true before handing off to step-9:

- [ ] Message follows WHY/WHAT/TESTING/ROADMAP structure
- [ ] `WHAT` section matches actual `git diff --stat` (no invented file changes)
- [ ] EARS IDs explicitly listed
- [ ] Test count and coverage percentage accurate
- [ ] Roadmap item number referenced (`ROADMAP: closes #N`)
- [ ] Summary line is imperative present tense with CC type prefix
- [ ] Reviewer: PASS

---

## 7. Traceability Chain

The commit message is the final link in the traceability chain. Every upstream artefact must
be traceable from the commit:

```
Roadmap item → EARS IDs → Gherkin scenarios → Tests → Implementation → Commit message
```

An auditor reading the commit a year from now must be able to trace back to the original requirement using only the commit message and the git history.

---

## 8. Reviewer Gate

Before submitting the commit message to step-9, send it to `reviewer`
(or `reviewer` with role `SMU-REVIEWER` for vocabulary consistency checks).
Apply all critical findings before handoff. A reviewer PASS is required for exit criteria
(§6) to be satisfied.

---

## 9. Sentinel Emission

On completion and reviewer PASS, emit:

```
SENTINEL::COMMIT_MSG_READY::ROADMAP-{N}::PASS::{summary_line}
```

Payload: the first line of the approved commit message (≤72 chars).

---

## 10. Config-repo Commit Type Prefixes (marketplace-source maintainers only — NOT for plugin users)

> **Scope note:** This section applies **only** when committing to the **marketplace source
> repository** itself (the repo that ships these plugins). Projects that merely *use* the DELIVER
> plugin do not need it — use ordinary Conventional Commits. Retained for marketplace maintainers.

When committing changes to the marketplace source repo itself, use these type prefixes instead of
CC types — they describe the artefact class being changed:

| Prefix | When to use |
|--------|-------------|
| `skill` | Adding or modifying a skill under `skills/` |
| `agent` | Adding or modifying an agent under `agents/` |
| `hook` | Adding or modifying a git hook |
| `settings` | Changing `settings.json` or `settings.local.json` |
| `utility` | Adding or modifying utility scripts (`.py`, `.sh`) |
| `docs` | Changing `CLAUDE.md`, `README.md`, or reference documents |

Format: `git commit -m "docs(commit-standard): consolidate commit message guidelines"`

Do not batch unrelated changes into a single commit.

---

## 11. Conventional Commits v1.0.0 — Full Specification

> Source: <https://www.conventionalcommits.org/en/v1.0.0/>
> License: Creative Commons Attribution 3.0 Unported (CC BY 3.0)

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Formal Specification

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT,
RECOMMENDED, MAY, and OPTIONAL in this document are to be interpreted as described in RFC 2119.

1. Commits MUST be prefixed with a type, which is a noun, `feat`, `fix`, etc., followed
   by the OPTIONAL scope, OPTIONAL `!`, and REQUIRED terminal colon and space.

2. The type `feat` MUST be used when a commit adds a new feature to your application or library.

3. The type `fix` MUST be used when a commit represents a bug fix for your application.

4. A scope MAY be provided after a type. A scope MUST consist of a noun describing a
   section of the codebase surrounded by parentheses, e.g., `fix(parser):`.

5. A description MUST immediately follow the colon and space after the type/scope prefix.
   The description is a short summary of the code changes, e.g.,
   `fix: array parsing issue when multiple spaces were contained in string`.

6. A longer commit body MAY be provided after the short description, providing additional
   contextual information about the code changes. The body MUST begin one blank line after
   the description.

7. A commit body is free-form and MAY consist of any number of newline-separated paragraphs.

8. One or more footers MAY be provided one blank line after the body. Each footer MUST
   consist of a word token, followed by either a `:<space>` or `<space>#` separator,
   followed by a string value (this is inspired by the git trailer convention).

9. A footer's token MUST use `-` in place of whitespace characters, e.g., `Acked-by`
   (this helps differentiate the footer section from a multi-paragraph body).
   An exception is made for `BREAKING CHANGE`, which MAY also be used as a token.

10. A footer's value MAY contain spaces and newlines, and parsing MUST terminate when the
    next git trailer token/separator pair is observed.

11. Breaking changes MUST be indicated in the footer portion of a commit, by including the
    text `BREAKING CHANGE:`, followed by a description, e.g.,
    `BREAKING CHANGE: environment variables now take precedence over config files`.

12. Breaking changes MAY be indicated by appending a `!` after the type/scope, prior to
    the `:`. When `!` is used, `BREAKING CHANGE:` MAY be omitted from the footer section,
    and the commit description SHALL be used to describe the breaking change.

13. Types other than `feat` and `fix` MAY be used in your commit messages, e.g.,
    `docs: correct spelling of CHANGELOG`.

14. The units of information that make up Conventional Commits MUST NOT be treated as case
    sensitive by implementors, with the exception of `BREAKING CHANGE` which MUST be uppercase.

15. `BREAKING-CHANGE` MUST be synonymous with `BREAKING CHANGE`, when used as a token in a footer.

---

### Type Reference

| Type | SemVer | When to use |
|------|--------|-------------|
| `feat` | MINOR | A new feature |
| `fix` | PATCH | A bug fix |
| `build` | — | Changes that affect the build system or external dependencies |
| `chore` | — | Other changes that don't modify src or test files |
| `ci` | — | Changes to CI configuration files and scripts |
| `docs` | — | Documentation only changes |
| `style` | — | Changes that do not affect the meaning of the code (white-space, formatting, etc.) |
| `refactor` | — | A code change that neither fixes a bug nor adds a feature |
| `perf` | PATCH | A code change that improves performance |
| `test` | — | Adding missing tests or correcting existing tests |
| `revert` | — | Reverts a previous commit |

A `BREAKING CHANGE` in any type triggers a MAJOR version bump.

---

### Examples

**1. Commit with description and breaking change footer:**
```
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```

**2. Commit with `!` to draw attention to breaking change:**
```
feat!: send an email to the customer when a product is shipped
```

**3. Commit with scope and `!` to draw attention to breaking change:**
```
feat(api)!: send an email to the customer when a product is shipped
```

**4. Commit with both `!` and BREAKING CHANGE footer:**
```
chore!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

**5. Commit with no body:**
```
docs: correct spelling of CHANGELOG
```

**6. Commit with scope:**
```
feat(lang): add Polish language
```

**7. Commit with multi-paragraph body and multiple footers:**
```
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```

---

## 12. Why Use Conventional Commits

- **Automatically generate CHANGELOGs** — tooling can parse type and scope to build a changelog.
- **Automatically determine semantic version bumps** — `fix` → PATCH, `feat` → MINOR, `BREAKING CHANGE` → MAJOR.
- **Communicate the nature of changes** to teammates, the public, and other stakeholders.
- **Trigger build and publish processes** — CI pipelines can key off commit type.
- **Make it easier for people to contribute** — a structured commit history is navigable and auditable.
- **Trace requirements** — the DELIVER WHY/WHAT/TESTING/ROADMAP body extends CC's body/footer model with EARS and test traceability.

---
