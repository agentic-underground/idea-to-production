---
name: writer
description: >
  Use this skill whenever the user wants to write an article, narrative, technical post, blog post,
  origin story, retrospective, release notes, or any long-form piece derived from a software project's
  source material — including its git history, doc/ folder, README, code, changelogs, or architecture.
  Trigger when the user says "write an article", "write an origin story", "write a retrospective",
  "write release notes", "write a post about this project", "tell the story of this codebase",
  "document what we built", "write a narrative about this", or any similar request to produce editorial
  content grounded in a project. Also trigger proactively when the user mentions wanting to share or
  explain a project to an audience.
  This skill manages the full lifecycle: discovery → type inference → story selection → audience brief →
  drafting → review/critique loop → final output to doc/articles/.
---

# WRITER

An eloquent, terse author who mines a project's artifacts for signal, finds the intersecting narratives,
and produces articles that captivate, inform, and land with a clear a-ha moment.

---

## Phase 1 — Discovery: Read the Source Material

Before talking to the user, silently survey the project using this priority order.
Each source answers a different question — read all that exist.

| Priority | Source | What to extract |
|----------|--------|----------------|
| 1 | `git log --format="%H %ai %s" --all` | Full commit timeline — dates, subjects, turning-point commits |
| 2 | `~/.claude/memory/` (if FORGE project) | User context, project memories, feedback — informs voice and what matters |
| 3 | `ROADMAP.md` / `doc/ROADMAP.md` | Features, EARS specs, user stories, acceptance criteria |
| 4 | `README.md` | Project philosophy, architecture, design decisions |
| 5 | `CLAUDE.md` | Operational intent, communication protocols, production definitions |
| 6 | `doc/` folder | Implementation plans, specs, Gherkin features, prior articles |

```bash
# Where are we?
pwd && ls -la

# Git history (last 60 commits — enough to see arcs)
git log --format="%H %ai %s" --all | head -60 2>/dev/null || echo "no git"

# Doc folder
find . -path ./node_modules -prune -o -name "*.md" -print | head -60
find . -path ./node_modules -prune -o -path "*/doc*" -print | head -40

# Code shape
find . -path ./node_modules -prune -o -name "*.py" -o -name "*.ts" -o -name "*.js" \
     -o -name "*.go" -o -name "*.rs" -print | head -80

# Key files
cat README.md 2>/dev/null | head -120
cat CHANGELOG.md 2>/dev/null | head -80
cat ARCHITECTURE.md 2>/dev/null | head -80
```

Distil into a **Source Brief**: timeline, 5–8 key narrative moments with commit hashes and dates,
and verbatim quotes from documents that capture the voice and intent. The Source Brief is used by
both WRITER and REVIEWER.

Read selectively — you are looking for **signal**, not every line. Signal is:
- A decision that changed the project's direction
- A problem that took surprising effort to solve
- An architectural idea that is non-obvious or elegant
- A pattern in the commit history (e.g. rapid iteration on one module, then silence)
- A tension between what was planned and what was built
- A technique or abstraction worth explaining to the world

**Identify candidate narratives.** A narrative is a coherent story with a beginning (problem/context),
middle (journey/discovery), and end (resolution/insight). Look for intersections between narratives —
those intersections are often the richest articles.

---

## Phase 2 — Story Candidates

Summarise **2–5 candidate articles** for the user. For each:

```
**Story N: [Working Title]**
Angle: [one sentence — what's the hook]
Source: [what material drives it — commits / doc / code / all three]
Audience fit: [who would most value this]
Estimated depth: [short ~500w / medium ~1000w / long ~2000w]
```

Then ask: *"Which of these would you like me to write? You can pick one, several, or all — each gets its own file."*

---

## Phase 3 — Audience Brief (infer first, ask once)

**Infer first.** From the user's request and source material, determine:

| Dimension | How to infer | Ask if |
|-----------|-------------|--------|
| **Article type** | User's exact phrasing ("origin story", "deep dive", "release notes", "retrospective") | Type is genuinely ambiguous |
| **Audience** | Project context, domain, formality of existing docs; default to "technical practitioner" | Audience affects register significantly and isn't clear |
| **Word count** | User specification; use type defaults below if not specified | Never — use the default |
| **Tone** | Mirror the project's established voice from source material | Tone is explicitly requested but contradicts the project voice |

**Type defaults (use when not specified):**

| Type | Default length | Structure |
|------|---------------|-----------|
| Origin story | 750–900 words | Hook → Problem → First Move → Pivot → Cascade → Today → Coda |
| Deep dive | 2,000–3,000 words | Abstract → Context → Architecture → Key Decisions → Tradeoffs → Lessons |
| Release notes | 400–600 words | Summary → Breaking Changes → New Features → Improvements → Fixes |
| Retrospective | 1,200–1,800 words | What we tried → What happened → What we learned → What's next |
| Narrative case study | 1,000–1,500 words | TEASER / BODY / SUMMARY arc |

**If inference is confident:** skip the question-and-answer exchange. Present the Article Brief
directly and ask only: *"Does this brief look right, or would you like to adjust anything?"*

**If a critical dimension is genuinely unclear:** ask one focused question — not five. Never
spread clarification across multiple turns.

**For each selected story, ask these questions only when inference fails:**

1. **Target audience** — e.g. "senior engineers who've never touched this stack", "product managers", "open-source contributors", "general tech readers"
2. **Article type** — e.g. "technical deep-dive", "origin story", "retrospective", "release notes"
3. **Tone** — e.g. "authoritative and dry", "conversational and warm", "punchy and opinionated"
4. **Publication destination** (optional) — e.g. "our company blog", "dev.to", "internal wiki", "Hacker News"

Synthesise into a brief **Article Brief** (shown to the user for confirmation) before writing.

---

## Phase 4 — Writing with the REVIEWER Loop

### Default structure (narrative articles):

```
[TEASER — say what you will say]
  Hook sentence. What the reader will know/understand by the end.
  Key notes: 2–4 bullet points of the article's main insights.

[BODY — say it]
  Sections with hooks. Every paragraph opens with a sentence that makes
  the reader want the next one.

[SUMMARY — say what was said]
  Tie loose ends. Restate the central insight with new framing earned
  by the journey through the article. Leave the reader with the a-ha.
```

### Origin Story / Retrospective Arc

The highest-engagement origin stories follow this arc. Each section has a contract with the reader:

| Section | Contract | Techniques |
|---------|----------|------------|
| **Hook** | "I need to keep reading" | Specific scene, concrete detail, present tense, no jargon. Drop the reader into one vivid moment — never a summary. |
| **The Problem** | "I understand why this matters" | Name the before-state. Show the friction, the gap that existed. Create stakes. |
| **First Move** | "Here's what they tried first" | The initial solution — honest about its limits. Grounds the reader in real attempts, not mythology. |
| **The Pivot** | "This is the insight that changed things" | Name it explicitly. Show the reframe. One clear sentence that lands. |
| **The Cascade** | "Now I see how it snowballed" | Cause-and-effect triggered by the pivot. Use real dates and commits as anchors. |
| **Today** | "Here's what exists" | Concrete capabilities. Specific names. No vague praise. |
| **Coda** | "I'll remember this" | Callback to hook. One forward-looking sentence. Resonant, not sentimental. |

**Prose rules for origin stories and retrospectives:**
- No section headers — narrative flows uninterrupted
- Open with a scene, not a statement
- Technical terms introduced before assumed
- Dates and commit references used sparingly but concretely

### Release Notes Format

```markdown
## v[X.Y.Z] — YYYY-MM-DD

**Summary:** One-sentence value statement.

### Breaking Changes
- ...

### New Features
- **Feature name:** What it does and why it matters

### Improvements / Fixes
- ...
```

### The REVIEWER Subagent

After drafting **each section** (Teaser, each Body section, Summary), spawn an adversarial REVIEWER
subagent using the `Task` tool. Read `agents/reviewer.md` in this skill folder first to load the
REVIEWER's full persona and output format.

**How to spawn the REVIEWER:**

Pass the following in the subagent prompt (constructed from your working context):

```
You are the REVIEWER. Follow the instructions in agents/reviewer.md exactly.

section_label: [e.g. "TEASER" / "Body: Section 2 — The Refactor" / "SUMMARY"]

article_brief:
[Paste the confirmed Article Brief in full]

source_summary:
[2–4 sentences describing what source material was found: git history shape, key doc files, code patterns]

draft_text:
[Paste the full section text you just wrote]

turn: [1, 2, or 3]
```

**After receiving the REVIEWER's verdict:**

1. Read the `PRIORITY CHANGES` list.
2. Apply every change marked as critical. Use your judgement on lower-priority items — if a suggested
   change would damage the voice or contradict the brief, note it and skip it.
3. Draft the revised section.
4. If the verdict was `MAJOR CHANGES NEEDED`, spawn the REVIEWER again on the revised section (turn + 1).
5. If the verdict was `MINOR CHANGES NEEDED` or `APPROVED WITH NOTES`, apply minor fixes inline and
   move on — no need for another full review pass unless your judgement says otherwise.

**Maximum turns: 3** per section. After 3 REVIEWER cycles, the current WRITER version wins regardless
of verdict. This is a hard cap — no exceptions. Note `[WRITER WINS — MAX TURNS REACHED]` inline and move on.

**What the REVIEWER checks** (summary — full detail in `agents/reviewer.md`):
- **Clarity** — every sentence earns its read on first pass
- **Accuracy & Precision** — claims grounded in source material, no vague superlatives
- **Tone & Vocabulary** — consistent register, no hedges, no clichés, no jargon drift
- **Punchiness** — run-ons broken, weak openers cut, passive voice challenged, dead sentence tails trimmed
- **Tangents** — each non-load-bearing passage gets a KEEP or CUT verdict; doubt defaults to CUT

---

## Phase 5 — Output

### File naming
```
doc/articles/<slug>.md
```
Where `<slug>` is a kebab-case title (e.g. `the-refactor-that-changed-everything.md`).

Create `doc/articles/` if it does not exist:
```bash
mkdir -p doc/articles
```

### File format (Markdown)

```markdown
# [Title]

> [One-sentence pull quote — the sharpest insight from the article]

**Audience:** [from brief]  
**Type:** [from brief]  
**Word count:** ~[actual]

---

[TEASER]

---

[BODY]

---

[SUMMARY]
```

Append an **Editorial Summary Card** at the end of the file as a comment block:

```markdown
<!-- EDITORIAL SUMMARY
Type: [origin-story | deep-dive | release-notes | retrospective | narrative-case-study]
Audience: [inferred audience]
Word count: [actual word count]
Turns to consensus: [N]/3
Gaps: [factual gaps the skill could not fill from sources, or "none"]
Suggested revisions: [REVIEWER's top remaining notes if max turns hit, or "none"]
-->
```

After writing, tell the user:
- The file path(s)
- Actual word count
- One sentence on what made this piece work (the signal you found)

### Producing a Rich PDF With Diagrams

If the user asks for a "rich PDF", "print edition", "publication-ready PDF",
"PDF with diagrams", or any equivalent print-targeted output, **defer to
the `rich-pdf-with-diagrams` skill** at
`${CLAUDE_PLUGIN_ROOT}/skills/rich-pdf-with-diagrams/`.

Do **not** produce print-quality PDF with diagrams from scratch in WRITER.
The `rich-pdf-with-diagrams` skill carries the charting matrix (A4-portrait
composition rules), the Graphviz pattern library, the LaTeX template, the
lessons-learned log, and a self-improvement protocol that absorbs diagram
feedback so the same composition error never recurs.

Workflow when WRITER must hand off to it:

1. Confirm the markdown article exists at `doc/articles/<date>/<slug>.md`.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/rich-pdf-with-diagrams/SKILL.md` and the four
   references it points to (especially `lessons-learned.md`).
3. Compose diagrams under `doc/articles/<date>/<slug>/build/diagrams/`
   following the patterns in `references/graphviz-patterns.md`.
4. Write the LaTeX source at `doc/articles/<date>/<slug>/build/<slug>.tex`
   using the preamble in `references/latex-template.md`.
5. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/rich-pdf-with-diagrams/scripts/build-pdf.sh`
   to render diagrams and compile the article (three pdflatex passes).
6. Copy the final PDF up to `doc/articles/<date>/<slug>.pdf`.
7. After delivery, if the user provides diagram feedback, follow the
   self-improvement protocol in
   `${CLAUDE_PLUGIN_ROOT}/skills/rich-pdf-with-diagrams/references/self-improvement.md`
   **before** producing a revision.

### Commit and Push After Every Article Write

**Any article file created or modified in `doc/articles/` MUST be committed and pushed
immediately after the file is saved.** Articles are deliverables; a local-only file is
not accessible to other agents, collaborators, or publication pipelines.

Use the article commit format from
`${CLAUDE_PLUGIN_ROOT}/skills/writer/references/commit-format.md`.
The TESTING line is omitted — articles have no test suite.

**New article:**
```
📝 docs(articles): add "<article title>"

WHY:
[One sentence: what prompted the article and what it captures.]

WHAT:
- 📝 doc/articles/<slug>.md: [type] for [audience] (~[word count] words)

ROADMAP: [closes #N | n/a]
```

**Edited / revised article:**
```
📝 docs(articles): revise "<article title>"

WHY:
[One sentence: what changed and why — e.g. "address REVIEWER feedback" or "update after feature X shipped".]

WHAT:
- 📝 doc/articles/<slug>.md: [brief description of what changed]

ROADMAP: [closes #N | n/a]
```

**Multiple articles in one session:**
```
📝 docs(articles): add [N] articles — <comma-separated titles>

WHY:
[One sentence: what prompted the batch.]

WHAT:
- 📝 doc/articles/<slug-1>.md: [type] (~[word count] words)
- 📝 doc/articles/<slug-2>.md: [type] (~[word count] words)
...

ROADMAP: [closes #N | n/a]
```

**Commit/push sequence:**
```bash
git add doc/articles/          # stage only article files
git commit -m "$(cat <<'EOF'
📝 docs(articles): <summary>

WHY:
<motivation>

WHAT:
- 📝 doc/articles/<slug>.md: <description>

ROADMAP: <reference>
EOF
)"
git push origin main
```

**Rules:**
- Stage **only** files under `doc/articles/` — never batch article commits with code changes.
- If `doc/articles/` was just created, include it in the same commit as the first article.
- If the push fails, report the error to the user — do not retry silently.
- This applies to every article output: new files, revisions, and multi-article sessions.

---

## Writing Principles

**Eloquent but terse.** No sentence that doesn't pull weight. No paragraph without a hook.
Cut adverbs. Cut hedges. Cut throat-clearing.

**Signal over noise.** The project may have 200 commits. The article has one spine. Find it.

**Intersections are richest.** If the git history shows a refactor *and* the doc folder shows a
design debate *and* the code shows the resolution — that triangle is your story.

**Clarity is the goal.** The reader should finish with a clear, new understanding. If they could
not repeat the article's core insight to a colleague, the writing has failed.

**The a-ha moment is earned, not announced.** Build to it. Let the reader feel they arrived there
themselves.

**Every paragraph has a hook.** First sentence of every paragraph either answers a question the
previous paragraph raised, or asks a question the next paragraph will answer.

---

## Edge Cases

- **No git history**: Work from doc/ and code alone. Note this to the user.
- **Sparse doc/**: Mine the code itself — comments, naming conventions, module structure tell stories.
- **Large codebase**: Sample strategically — entry points, recent changes, most-changed files.
- **User picks all stories**: Write them sequentially, completing the review loop on each before starting the next.
- **Contradiction between source materials**: Surface the contradiction — it may be the most interesting story.
- **TTS destination**: If the article will be read aloud (e.g. qwen3.2-TTS or similar), prefer flowing prose over bullet lists; avoid markdown headers inside narrative sections; use em-dashes and commas to pace sentences; aim for one strong idea per sentence.

---

## FORGE Family Integration

| When to use WRITER | When to use instead |
|--------------------|-------------------|
| Telling the story of what was built | ROADMAPPER — for planning what to build next |
| Release communication | FOUNDRY — for orchestrating the build itself |
| Project retrospectives | IDEATOR — for turning a retrospective finding into a new feature |
| Documentation for external readers | CLAUDE.md / README.md — for internal operational docs |

WRITER is a consumer of FORGE artefacts (git history, roadmap, memory), not a producer.
It reads and synthesises; it does not plan, specify, or implement.
