# code-quality Skill — Deployment & Usage Guide

> **LEGACY GUIDE.** This describes deploying `code_quality` as a *standalone* skill. It is now
> a station inside the FOUNDRY plugin — to install, enable the plugin; the standalone
> `mkdir`/`cp` steps below no longer apply. Retained for reference. See
> `../../docs/DEPRECATED.md`.

Complete step-by-step installation, usage, and development guide.
Self-contained. Deployment-ready.

---

## What This Skill Does

The `code-quality` skill gives Claude Code two capabilities:

**1. Code Quality Analysis** — Deep, multi-lens review across:
Clean Code · SOLID · DRY/YAGNI/KISS · Clean Architecture · Hexagonal Architecture ·
Domain-Driven Design · TDD/BDD · 12-Factor App · Pragmatic Programming

**2. Coverage Loop** (`/coverage-loop`) — Automated behaviour-pinning loop that:
- Finds the behaviour least pinned by tests (most unpinned lines)
- Adds the coordinate(s) that pin it
- Reports when a behaviour cannot be pinned without a structural change (and why)
- Offers a refactoring plan for structural gaps
- Loops until every behaviour is pinned (100% coverage is the floor that results) or the user stops
- Writes a disaster-recovery log to `IN_PROGRESS.md`

---

## Prerequisites

- Claude Code installed (`npm install -g @anthropic-ai/claude-code`)
- A git repository with `.claude/` already initialised (`claude init` or exists)
- Your project already has a test runner and can produce a coverage report

---

## Installation

### Option A: Project-level (recommended for team use)

Install in your repository so every team member benefits.
The skill will be version-controlled with your project.

```bash
# Navigate to your project root
cd ~/your-project

# Create the skills directory if it doesn't exist
mkdir -p .claude/skills
mkdir -p .claude/agents

# Copy the skill into your project
cp -r /path/to/code-quality .claude/skills/code-quality

# Copy the agent definition (it lives in the top-level agents/ directory, not under the skill)
cp .claude/agents/coverage-loop-agent.md .claude/agents/

# Verify structure
find .claude/skills/code-quality -type f | sort
```

Expected structure:
```
.claude/
├── agents/
│   └── coverage-loop-agent.md    ← lives here, not under the skill
└── skills/
    └── code-quality/
        ├── SKILL.md
        └── references/
            ├── clean-code.md
            ├── clean-architecture.md
            ├── coverage-commands.md
            ├── ddd.md
            ├── hexagonal.md
            ├── pragmatic.md
            ├── solid.md
            ├── tdd-bdd.md
            ├── twelve-factor.md (if present)
            └── untestable-patterns.md
```

Commit to version control:
```bash
git add .claude/
git commit -m "feat: add code-quality skill and coverage-loop-agent"
```

---

### Option B: Personal (available in all your projects)

**Obsolete — no longer applies.** The standalone manual-copy install (into a personal config
directory) has been superseded: `code-quality` ships **inside the foundry plugin**. To use it
everywhere, install/enable the **foundry** plugin from the marketplace — there is nothing to copy by
hand. (Retained here only to record that this path is gone.)

---

## First-Run Verification

Open Claude Code in your project:

```bash
cd ~/your-project
claude
```

Verify the skill is loaded:

```
> /skills
```

You should see `code-quality` in the list.

Verify the agent is available:

```
> /agents
```

You should see `coverage-loop-agent` in the Library tab.

---

## Usage

### Code Quality Analysis

**Automatic trigger** (Claude detects the intent):
```
> Review my architecture for SOLID violations
> Is this code clean?
> Find code smells in the payments module
> How maintainable is this codebase?
```

**Direct invocation:**
```
> /code-quality
> /code-quality src/orders/
> /code-quality --focus=SOLID,DDD
```

**What you get:**
1. Coverage baseline (risk rating for all findings)
2. Findings per quality lens (only relevant lenses)
3. Prioritised action list
4. Self-improvement suggestions specific to your project

---

### Coverage Loop

**Start the loop:**
```
> /coverage-loop
```

**Or naturally:**
```
> Pin every behaviour the tests are missing
> Fill the coverage gaps
> Run the coverage loop
```

**What happens:**
1. The `coverage-loop-agent` activates
2. It finds your coverage report (or asks you which command to run)
3. It picks the file with the worst coverage
4. It writes tests, runs them, checks if coverage improved
5. It reports each round and asks: keep going or stop?

**Control the loop:**
```
> keep going          ← run without asking after each file
> stop here           ← finish after the current file
> stop after this one ← same as above
> one more            ← do one more file then stop
```

**When a gap can't be filled:**
The agent will explain exactly why (e.g., "the database is instantiated
directly inside the function — no test can substitute a mock without
modifying production code") and offer a refactoring plan.

Approve the plan:
```
> yes, proceed with that refactor
```

The plan is written to `IN_PROGRESS.md` before any code is touched.
If anything goes wrong, `IN_PROGRESS.md` is your recovery document.

---

## IN_PROGRESS.md

The coverage loop automatically maintains `IN_PROGRESS.md` at your project root.
This file serves as:

1. **Disaster recovery** — if the session crashes mid-refactor, open the file
   and continue from where it stopped
2. **Audit trail** — documents what was changed and why
3. **Handoff document** — another developer (or agent) can resume from it

To resume after a crash:
```
> Read IN_PROGRESS.md and continue the coverage loop from where it stopped
```

---

## Coverage Report Setup

If you haven't set up coverage reporting yet, run the command for your stack:

| Stack | Command |
|---|---|
| Python | `pip install pytest-cov && pytest --cov=src --cov-report=xml tests/` |
| JavaScript (Jest) | `npx jest --coverage --coverageReporters=cobertura` |
| JavaScript (Vitest) | `npx vitest run --coverage` |
| Go | `go test ./... -coverprofile=coverage.out` |
| Ruby | `gem install simplecov-cobertura` then configure (see references/coverage-commands.md) |
| Java | Add JaCoCo to pom.xml (see references/coverage-commands.md) |

The agent will ask you for this command on first run and remember it.

---

## Development: Customising the Skill

### Adding a project-specific lens

Create a new reference file and add it to the Lens Index in `SKILL.md`:

```bash
cat > .claude/skills/code-quality/references/my-project-conventions.md << 'EOF'
# My Project — Conventions & Patterns

## API Design
- All endpoints return {data: ..., error: ..., meta: ...}
- ...

## Domain Language
- "booking" = a confirmed reservation (not "reservation" or "appointment")
- ...
EOF
```

Then add to `SKILL.md` in the Lens Index:
```markdown
| My Project Conventions | references/my-project-conventions.md | Always |
```

### Adjusting the coverage loop behaviour

Edit `.claude/agents/coverage-loop-agent.md`:
- Change the skip list (e.g., exclude `migrations/` or `scripts/`)
- Adjust the loop control prompt wording
- Change which patterns trigger an immediate refactor offer

### Adding stack-specific coverage parsing

The agent currently handles Cobertura XML format. For other formats,
add parsing instructions to the agent's `## Phase 0 — Initialise` section.

---

## Roadmap — Planned Improvements

Planned improvements are tracked on the GitHub project board.

---

## Self-Improving Skill: How to Act on Suggestions

At the end of every run, the skill emits suggestions like:

```
💡 SKILL IMPROVEMENT SUGGESTIONS
• Your project uses FastAPI — adding a FastAPI-specific lens would improve analysis
• You have 7 repository methods without ports — a port-extraction template would speed up refactoring
Have you thought about... adding a quality-gate pre-commit hook?
To implement: update .claude/skills/code-quality/references/fastapi-lens.md
```

**To act on a suggestion:**

1. Create or edit the referenced file:
   ```bash
   $EDITOR .claude/skills/code-quality/references/fastapi-lens.md
   ```

2. Add the new lens to `SKILL.md`'s Lens Index

3. Commit:
   ```bash
   git add .claude/skills/code-quality/
   git commit -m "skill(code-quality): add FastAPI-specific lens"
   ```

4. Next run will use the improved skill automatically.

The skill is designed to grow with your project. The suggestions are generated
from what was actually found — they are not generic advice.

---

## Troubleshooting

**Skill not triggering automatically**
```
> /skills
```
If `code-quality` shows as `off` or `name-only`, re-enable it:
```
> /skills → select code-quality → press Space to toggle → Enter to save
```

**Coverage loop can't find coverage report**
Run your test suite with coverage first, then start the loop:
```bash
pytest --cov=src --cov-report=xml tests/
claude
> /coverage-loop
```

**Agent memory is wrong (remembers the wrong test command)**
```
> Clear your memory for this project and ask me for the test command again
```

**Loop runs too aggressively (making changes you don't want)**
Add `maxTurns: 10` to `${CLAUDE_PLUGIN_ROOT}/agents/coverage-loop-agent.md` frontmatter
to limit how many steps it takes per invocation.

**Skill takes too long (too many lenses)**
Use targeted invocation:
```
> /code-quality --focus=SOLID
> Review only the DDD aspects of src/domain/
```

---

## File Reference

```
.claude/
├── agents/
│   └── coverage-loop-agent.md    ← The loop agent (copy here for Claude Code to find it)
└── skills/
    └── code-quality/
        ├── SKILL.md               ← Main skill (entry point)
        ├── agents/
        │   └── coverage-loop-agent.md   ← Source copy
        └── references/
            ├── clean-code.md
            ├── clean-architecture.md    ← Includes Hexagonal summary
            ├── hexagonal.md             ← Detailed Hexagonal guide
            ├── solid.md
            ├── ddd.md
            ├── tdd-bdd.md
            ├── pragmatic.md
            ├── coverage-commands.md     ← Stack-specific coverage commands
            └── untestable-patterns.md   ← 10 untestable patterns + fixes
```

---

*code-quality skill v1.0*
*Compatible with: Claude Code (May 2026+)*
*Official docs: https://code.claude.com/docs/en/skills*
