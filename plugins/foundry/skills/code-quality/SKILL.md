---
name: code-quality
description: >
  Deep code quality analysis across Clean Code, SOLID, DRY, Clean/Hexagonal
  Architecture, TDD, BDD, DDD, 12-Factor App, and Pragmatic Programming
  principles. Use proactively whenever the user asks about code quality,
  technical debt, refactoring, architecture review, code review, maintainability,
  test coverage, coverage gaps, coverage loops, or says things like "is this
  clean?", "how good is this code?", "review my architecture", "find smells",
  "improve my tests", or "chase coverage". Also triggers the /coverage-loop
  slash command, which finds behaviour not yet pinned by a test and adds the
  missing coordinates (100% coverage is the floor that results, not the target).
---

# Code Quality Skill

A comprehensive code quality analyser and behaviour-pinning orchestrator.
Covers the full spectrum from micro-cleanliness to macro-architecture,
anchored in the principle that **100% coverage is the floor, not the goal** —
a unit test is a *coordinate* that pins the working solution in logical space;
the real target is **coverage density** (happy / unhappy / abuse paths per
behaviour are table-stakes), and full coverage falls out of pinning every
behaviour. See [`${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md`](../../knowledge/testing/test-policy.md).

---

## Activation Modes

This skill has two primary modes. Identify which one the user wants:

| Mode | Trigger | What happens |
|---|---|---|
| **Analysis** | "review my code", "find smells", "is this SOLID?" | Full quality analysis across all dimensions → report |
| **Coverage Loop** | `/coverage-loop`, "chase coverage", "fill gaps" | Automated loop: find unpinned behaviour → add the missing coordinate(s) → repeat (coverage rises as a consequence) |

---

## Mode 1: Code Quality Analysis

### Step 0 — Locate the codebase

Before analysing, orient yourself:

```
1. Read CLAUDE.md or README.md to understand the project
2. Find the primary language(s) and framework(s)
3. Locate: src/, tests/, docs/, any architecture diagrams
4. Check for existing coverage reports (coverage.xml, htmlcov/, .coverage)
5. Note the test runner (pytest, jest, rspec, go test, etc.)
```

### Step 1 — Coverage Baseline (Always First)

Before applying any quality lens, establish the coverage baseline.

> **THE FOUNDRY MANDATE: 100% coverage is the floor, not a goal. It is the definition of done.**
> A feature is not complete. A bug is not fixed. A refactor is not finished.
> Code is not shipped — until every behaviour is *pinned* by a test (a coordinate
> locating the correct implementation). An uncovered line is an *unpinned*
> behaviour: a known unknown that may be wrong and cannot be detected by the suite.
> Ship known unknowns and you are not shipping software — you are shipping optimism.
> Coverage is what results from pinning every behaviour; the variable you actually
> work is **coverage density** — happy, unhappy, and abuse paths per behaviour are
> table-stakes, not extras.

The only legitimate path to less-than-100% is **explicit exclusion** via
`# pragma: no cover` (Python), `/* istanbul ignore next */` (JS), or the
equivalent for your stack. Exclusions require a comment explaining WHY the
code cannot or should not be tested (e.g. `# pragma: no cover — legacy
HTTP handler retained for backward compatibility; Flask blueprint covers this
functionality`). Unexplained exclusions are treated the same as missing coverage.

```bash
# Find coverage report — check common locations
find . -name "coverage.xml" -o -name ".coverage" -o -name "lcov.info" \
       -o -name "coverage-summary.json" 2>/dev/null | head -5
```

If no coverage report exists, **stop and demand one**:

> ❌ No coverage report found. No quality analysis can proceed without one.
> Run your test suite with coverage enabled first.
> See ${CLAUDE_PLUGIN_ROOT}/knowledge/testing/coverage-commands.md for the exact command for your stack.
> Do not continue until coverage.xml (or equivalent) exists.

Parse coverage and compute:
- **Overall %** and line count
- **Files below 100%** — list every one, every uncovered line number
- **Files at 0%** — flag as CRITICAL: no tests exist for this code at all

Coverage gates — hard rules, not suggestions:

| Coverage | Gate | Action required |
|---|---|---|
| 100% | ✅ **SHIP** | Code is done. No action. |
| 99% | 🔴 **BLOCK** | Find the uncovered line. Write the test. |
| < 99% | 🔴 **BLOCK** | Do not review quality until coverage is 100%. |
| Any file at 0% | ⛔ **REJECT** | Return the diff. Write tests first. |

**There is no "near enough". There is no "we'll get to it". 99% is a bug.**

When you find coverage below 100%, your job is not to note it and move on.
Your job is to identify every uncovered line, explain why it is not hit,
and either (a) write the missing test or (b) justify an explicit `# pragma: no cover`
exclusion. Present both options to the user. Do not proceed to Step 2 until
coverage is at 100% or all gaps have explicit, documented exclusions.

### Step 1b — Scoped auto-format on a trivial-style gate failure (P1-19)

When a review/quality gate would fail **only** for mechanical formatting (whitespace, import order,
quote style) on files the change already touches, do **not** halt the gate and do **not** reformat the
whole repo. Run the scoped auto-format self-heal:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/code-quality/scripts/autoformat-changed.sh --base <merge-base|HEAD> .
```

It formats **only** the files in `git diff --name-only <base>`, **asserts** the post-format change set is
a SUBSET of the touched files (ABORTS without committing if formatting would spill outside the change
set), lands the fix as a **separate** `style: auto-format changed files` commit, and exits **10** to
signal the gate to re-run. Exit **0** = nothing to do; **2** = spill refused (gate stays red — investigate
the formatter config, never widen the blast radius); **3** = no formatter configured (pass `--formatter`).
Never reformats untouched files — a repo-wide reformat is the exact unsafe blast radius this prevents.
This is a safe-auto heal: scoped, asserted-subset, separate-commit, re-run — see the script header for the
full SAFETY CONTRACT.

### Step 2 — Quality Analysis

Run all lenses in parallel. Read the reference file for each applicable lens.
Reference files are in `references/` — load only what is relevant.

**Lens Index:**

| Lens | Reference File | Load When |
|---|---|---|
| Clean Code | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/clean-code.md | Always |
| SOLID | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/solid.md | OOP languages |
| DRY / YAGNI | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/dry-yagni.md | Always |
| Clean Architecture | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/clean-architecture.md | Any layered system |
| Hexagonal / Ports & Adapters | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/hexagonal.md | Service-oriented, testable boundaries needed |
| Domain-Driven Design | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/ddd.md | Complex domain, domain language present |
| TDD / BDD | ${CLAUDE_PLUGIN_ROOT}/knowledge/specs/bdd-gherkin.md | Test strategy review |
| 12-Factor App | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/twelve-factor.md | Deployed services, containers |
| Pragmatic Programming | ${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/pragmatic.md | Always (meta-quality) |

For each lens, produce findings in this format:

```
### [LENS NAME]
**Status:** ✅ Good / 🟡 Minor issues / 🟠 Significant issues / 🔴 Critical

**Findings:**
- [File:line] Specific issue. Why it matters. Suggested fix.

**Coverage impact:** [How coverage level affects the risk of addressing this]
```

### Step 3 — Synthesise and Prioritise

After all lenses:

1. **Triage by coverage × severity** — high-severity findings in uncovered
   code are most dangerous to fix. Flag them explicitly.
2. **Produce a prioritised action list** — ordered by: (a) coverage risk,
   (b) architectural impact, (c) implementation effort.
3. **Self-improvement prompt** (always include at the end):

```
💡 SKILL IMPROVEMENT SUGGESTIONS
─────────────────────────────────
Based on this analysis, here are ways to make this skill work better for
your project:

• [Specific suggestion based on what was found, e.g., "Your project uses
  FastAPI — adding a FastAPI-specific lens (dependency injection patterns,
  router organisation) would improve analysis accuracy"]
• [e.g., "You have 3 uncovered integration points — a dedicated 'integration
  boundary' lens would catch these automatically"]
• [e.g., "Your domain language is rich — a project-specific DDD glossary in
  references/project-domain.md would sharpen DDD findings"]

Have you thought about...
• Running this skill as a pre-commit hook via a Claude Code hook?
• Adding a quality-gate subagent that blocks PRs below a threshold?
• Creating a project-specific lens for [observed domain pattern]?
```

---

## Mode 2: Coverage Loop (`/coverage-loop`)

> **Purpose:** Systematically find the behaviour least pinned by tests (the file
> with the most unpinned lines), add the missing coordinate(s) that locate its
> correct implementation, and loop until every behaviour is pinned or the user
> stops. Rising coverage is the *consequence* of pinning behaviour, not the aim;
> the aim is density — every behaviour exercised on happy, unhappy, and abuse paths.

See [`${CLAUDE_PLUGIN_ROOT}/agents/coverage-loop-agent.md`](../../agents/coverage-loop-agent.md) for the full loop agent definition.

### Quick summary of the loop:

```
LOOP:
  1. Parse coverage.xml (or equivalent)
  2. Find file with lowest coverage % (most uncovered lines)
  3. Analyse the gap: what is uncovered? Why?
  4. Attempt to write tests that cover the gap ("include" strategy)
  5. Run tests with coverage
  6. If coverage increased → record progress → ask to continue or stop
  7. If coverage cannot increase:
     a. Explain precisely WHY (untestable code, missing seam, design issue)
     b. If a fix is known → present plan → get affirmative → write to IN_PROGRESS.md → begin
     c. If no fix known → document as known gap → continue loop
  8. At end of loop: emit self-improvement suggestions
  9. Ask: "Loop until done?" or "Stop here?"
```

To start the loop, load [`${CLAUDE_PLUGIN_ROOT}/agents/coverage-loop-agent.md`](../../agents/coverage-loop-agent.md) and delegate to it.

---

## Self-Improving Skill Protocol

This skill emits improvement suggestions at the end of every run.
The format is always:

```
💡 SKILL IMPROVEMENT SUGGESTIONS
[Context-specific suggestion 1]
[Context-specific suggestion 2]
Have you thought about... [emergent theme from this session]
To implement suggestion N, update: ${CLAUDE_PLUGIN_ROOT}/skills/code-quality/[file]
```

**This is not boilerplate.** Each suggestion must be specific to what was
found in this session. Generic suggestions are not permitted.

---

## Reference Files

Load these as needed — do not load all at once:

- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/clean-code.md`](../../knowledge/architecture/clean-code.md) — Uncle Bob's Clean Code principles
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/solid.md`](../../knowledge/architecture/solid.md) — SOLID with OOP examples
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/dry-yagni.md`](../../knowledge/architecture/dry-yagni.md) — DRY, YAGNI, KISS
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/clean-architecture.md`](../../knowledge/architecture/clean-architecture.md) — Layers, dependency rule, boundaries
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/hexagonal.md`](../../knowledge/architecture/hexagonal.md) — Ports & Adapters pattern
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/ddd.md`](../../knowledge/architecture/ddd.md) — DDD tactical and strategic patterns
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/specs/bdd-gherkin.md`](../../knowledge/specs/bdd-gherkin.md) — TDD/BDD disciplines and red-green-refactor
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/twelve-factor.md`](../../knowledge/architecture/twelve-factor.md) — 12-Factor App checklist
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/pragmatic.md`](../../knowledge/architecture/pragmatic.md) — Pragmatic Programmer principles
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/testing/coverage-commands.md`](../../knowledge/testing/coverage-commands.md) — How to run coverage for each stack
- [`${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/untestable-patterns.md`](../../knowledge/architecture/untestable-patterns.md) — Known untestable patterns and fixes
