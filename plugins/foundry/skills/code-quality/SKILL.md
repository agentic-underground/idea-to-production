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
  slash command for automated coverage-gap remediation.
---

# Code Quality Skill

A comprehensive code quality analyser and coverage-chasing orchestrator.
Covers the full spectrum from micro-cleanliness to macro-architecture,
anchored in the principle that **100% coverage is the floor, not the goal**.

---

## Activation Modes

This skill has two primary modes. Identify which one the user wants:

| Mode | Trigger | What happens |
|---|---|---|
| **Analysis** | "review my code", "find smells", "is this SOLID?" | Full quality analysis across all dimensions → report |
| **Coverage Loop** | `/coverage-loop`, "chase coverage", "fill gaps" | Automated loop: find gaps → write tests → repeat |

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

> **THE FORGE MANDATE: 100% coverage is not a goal. It is the definition of done.**
> A feature is not complete. A bug is not fixed. A refactor is not finished.
> Code is not shipped — until every line is covered by a test.
> Any uncovered line is a known unknown: behaviour that may be wrong and cannot
> be detected by the test suite. Ship known unknowns and you are not shipping
> software — you are shipping optimism.

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

> **Goal:** Systematically find the file with the worst coverage, attempt to
> increase it by writing tests, and loop until done or the user stops.

See `${CLAUDE_PLUGIN_ROOT}/agents/coverage-loop-agent.md` for the full loop agent definition.

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

To start the loop, load `${CLAUDE_PLUGIN_ROOT}/agents/coverage-loop-agent.md` and delegate to it.

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

- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/clean-code.md` — Uncle Bob's Clean Code principles
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/solid.md` — SOLID with OOP examples
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/dry-yagni.md` — DRY, YAGNI, KISS
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/clean-architecture.md` — Layers, dependency rule, boundaries
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/hexagonal.md` — Ports & Adapters pattern
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/ddd.md` — DDD tactical and strategic patterns
- `${CLAUDE_PLUGIN_ROOT}/knowledge/specs/bdd-gherkin.md` — TDD/BDD disciplines and red-green-refactor
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/twelve-factor.md` — 12-Factor App checklist
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/pragmatic.md` — Pragmatic Programmer principles
- `${CLAUDE_PLUGIN_ROOT}/knowledge/testing/coverage-commands.md` — How to run coverage for each stack
- `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/untestable-patterns.md` — Known untestable patterns and fixes
