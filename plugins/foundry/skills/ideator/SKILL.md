---
name: ideator
description: >
  Use this skill when a user describes a new feature, project, or idea they want built — especially
  when it is broad, vague, or exploratory — and they need help clarifying, scoping, and translating
  it into a production-ready project artefact. Trigger on phrases like "I have an idea", "I want to
  build", "what if we…", "create a project for", "new feature:", "let's start a project", or any
  open-ended creative/product statement directed at a code project. Also trigger when the user has
  just finished an ideation conversation and asks "now what?" or "turn this into a project". This
  skill covers the full arc from fuzzy idea → focused brief → scoped README / project-bootstrap
  document → handoff to the development system (SDLC). Use it proactively — if the user is
  describing something new they want to exist in software form, this skill almost certainly applies.
---

# IDEATOR

A skill for transforming raw ideas into focused, production-ready project briefs and bootstrapping
them into the structured development system (EARS → Gherkin → TDD → commit).

---

## 0. STRUCTURAL GUARDRAIL — READ THIS FIRST

> **Scope lock.** IDEATOR has one job: take an idea and walk it to a deliverable project brief
> (and optional SDLC kickoff). It does **not** implement code, does not write tests, does not
> manage the roadmap. Those are downstream concerns handled by ROADMAPPER and the development
> system. Any temptation to drift into implementation during ideation is out of scope.
>
> **Section integrity.** Each section below is numbered and self-contained. Do not skip sections.
> Do not reorder them. Extensions to this skill must be added as new numbered sections or as
> sub-sections of an existing one — never by mutating the core flow.
>
> **SOLID alignment.** This skill follows SOLID principles:
> - **S** — Each section has one responsibility.
> - **O** — New behaviour is added via new sections/references, not by editing the core flow.
> - **L** — Downstream documents produced by this skill can substitute for manual briefs without
>   breaking any downstream tool.
> - **I** — Users who only want ideation do not need to trigger the SDLC; users who want full
>   SDLC do not need to re-answer ideation questions.
> - **D** — Concrete output formats (README, ROADMAP entry) depend on abstractions (the brief
>   structure), not on session-specific details.

---

## 1. TRIGGERS & ENTRY POINTS

| User says / does | Entry point |
|---|---|
| "I have an idea for …" | → §3 IDEATION DIALOGUE |
| "I want to build …" | → §3 IDEATION DIALOGUE |
| "New feature: …" (standalone, no project context) | → §3 IDEATION DIALOGUE |
| "Create a project for …" | → §3 IDEATION DIALOGUE |
| "What if we …" (open-ended) | → §3 IDEATION DIALOGUE |
| User completes ideation, asks "now what?" | → §5 BRIEF ASSEMBLY |
| User has a brief, asks to bootstrap the project | → §6 PROJECT OUTPUT |
| User has a project file, asks to start the SDLC | → §7 SDLC HANDOFF |

---

## 2. PRE-FLIGHT SCAN

Before engaging in ideation, silently check the workspace:

1. Is there a `ROADMAP.md` or `doc/ROADMAP.md`? If yes, note existing feature numbers so the
   new idea can be assigned the next number.
2. Is there a `doc/SPECIFICATION.ears.md` or similar? Note it — it will be referenced in §7.
3. Is there a `doc/` or `docs/` folder? It determines where output files are written (§6).
4. What language / framework is the project? Skim `package.json`, `pyproject.toml`,
   `Cargo.toml`, `go.mod`, or the dominant file extensions. Note this — it shapes the
   output in §6.

Record findings mentally. Do **not** narrate this scan to the user unless it surfaces something
important (e.g., "I see this project already has a feature that does something similar — is this
a replacement or an addition?").

---

## 3. IDEATION DIALOGUE

### 3.1 Opening move

On the very first user trigger, do **two things simultaneously**:

1. **Generate three candidate titles** for the idea — concise, memorable, possibly witty.
   Present them as options (the user can pick one, remix them, or supply their own).
2. **Ask the first scoping question** (see §3.2).

Do not front-load a wall of questions. One question per turn, maximum two if they are
tightly related.

### 3.2 Question Bank

Work through these in order, skipping any that are already answered by the user's prompt.
Stop when you have enough to fill the brief (§4). Target **5–7 questions total**; if you
reach 7 without a complete brief, ask the user whether they want to continue drilling or
proceed with what you have.

**Identity questions** (answer these first):
- Q1: "Who is this for — who is the primary user or actor?"
- Q2: "What problem does this solve, or what friction does it remove?"
- Q3: "What prompted this idea — is there a specific pain point or trigger event?"

**Scope questions** (answer these second):
- Q4: "What is explicitly *in* scope for the first version?"
- Q5: "What is explicitly *out* of scope (things we won't build now)?"
- Q6: "Are there constraints — performance, platform, integration, compliance, budget?"

**Innovation questions** (optional, use when the brief is thin or the idea is ambitious):
- Q7: "Have you considered [adjacent possibility]? Could that be part of this?"
- Q8: "What does the ideal version of this look like in 2 years? What's the 1.0 slice?"

### 3.3 Vagueness Protocol

If the user's statement is broad or unfocused:
1. Reflect back your interpretation in one sentence: "It sounds like you want to [X] so
   that [Y] — is that right?"
2. Ask Q1 or Q2 from the bank above.
3. Do **not** proceed to title generation or brief assembly until the core problem is clear.

### 3.4 Outside-the-box probe

Once the scope is roughly established, offer one "have you thought about…?" observation —
something the user may not have considered that could unlock additional value or reveal a
hidden constraint. This is optional but encouraged. Keep it to one sentence.

---

## 4. THE BRIEF STRUCTURE

The brief is the single source of truth for §5 and §6. It has exactly these fields:

```
TITLE:          [chosen title]
SLUG:           [kebab-case, used as filename prefix]
DATE:           [today's date]
ROADMAP-ENTRY:  [next available number, or TBD]
PROBLEM:        [1–3 sentences: what pain/gap does this address?]
ACTORS:         [who uses this? list roles]
IN-SCOPE:       [bullet list of what v1 includes]
OUT-OF-SCOPE:   [bullet list of what v1 explicitly excludes]
CONSTRAINTS:    [non-functional: performance, platform, compliance, etc.]
SUCCESS-METRIC: [how do we know this is working?]
WILD-CARD:      [the outside-the-box observation from §3.4, if any]
LANGUAGE/STACK: [from pre-flight scan §2, or user-supplied]
```

Populate the brief silently as the dialogue progresses. Do not show a partial brief during
the dialogue — it breaks conversational flow. Show it fully assembled in §5.

---

## 5. BRIEF ASSEMBLY

When the dialogue is complete (or the user says "that's enough, let's go"), present the
fully populated brief in a clean code block and ask:

> "Here's the brief as I understand it — does anything need adjusting before I generate
> the project file?"

Wait for confirmation or corrections. Apply any corrections and re-display if significant
changes were made. Then proceed to §6.

---

## 6. PROJECT OUTPUT

### 6.1 Determine output mode

| Context | Output |
|---|---|
| User is on claude.ai web/mobile | Create downloadable `[SLUG]-project.md` |
| User is in a CLI / has a filesystem | Write `doc/[SLUG]-README.md` (or `docs/` if that exists); if no `doc/` folder, write to project root as `[SLUG]-README.md` |

### 6.2 File content

Use the template at `references/project-readme-template.md`. The template must be rendered
with the brief fields from §4 and must include the **SOLID Replication Fragment** (see
`references/solid-fragment.md`) verbatim in the designated section.

Key sections of the output file:
1. **Title & tagline**
2. **Problem statement**
3. **Actors & roles**
4. **Scope** (in / out)
5. **Constraints & success metrics**
6. **Architecture sketch** (high-level, 3–5 bullet points; do not over-specify)
7. **Roadmap entry** (formatted for ROADMAPPER, ready to paste)
8. **SDLC next steps** (a numbered checklist pointing to the development system steps 0–9)
9. **SOLID Replication Fragment** (verbatim from `references/solid-fragment.md`)

### 6.3 Delivery

- If on claude.ai: call `present_files` with the generated file path.
- If on CLI: confirm the file path and offer to run §7 immediately.

---

## 7. SDLC HANDOFF

If the user wants to proceed directly into implementation (or once the project file is
accepted), hand off to the development system. Do this by:

1. Confirming ROADMAPPER is available (`${CLAUDE_PLUGIN_ROOT}/skills/roadmapper/SKILL.md`).
2. Saying: "I'll hand this off to ROADMAPPER now to kick off the SDLC." Then invoke
   ROADMAPPER with the completed brief as context, starting at §6 PULL & PLAN.
3. If ROADMAPPER is not available, present the development system checklist (Steps 0–9
   from `references/dev-system.md`) inline and ask the user how they want to proceed.

---

## 8. SELF-IMPROVEMENT PROTOCOL

IDEATOR is designed to improve itself over time. Follow this protocol at the end of any
session where you notice:

- A recurring question pattern not covered by §3.2
- A user correction that reveals a gap in the brief structure (§4)
- An output format issue (§6) that confused the user
- User feedback (explicit or implicit) on question flow

### 8.1 When to trigger self-improvement

Trigger after any of the above is observed, OR after every 5th ideation session (track
mentally within the session). Do not trigger mid-session; wait until the output is
delivered.

### 8.2 Self-improvement steps

1. **Identify the change type:**
   - New question → add to §3.2 Question Bank
   - Brief field gap → add to §4
   - Output format issue → update `references/project-readme-template.md`
   - Structural concern → propose update to §0 or §3.3

2. **Write the proposed change** as a diff-style description:
   > "Proposed addition to §3.2, Q9: 'Are there existing integrations or APIs this must
   > connect to?' — Rationale: three sessions surfaced this as a common gap."

3. **Spawn a review sub-agent** using the prompt template in
   `references/self-improvement-review-prompt.md`. Pass the proposed change as input.
   The sub-agent will return a **Version 2** of the changed document.

4. **Present Version 2 to the user** with a brief summary of what changed and why.
   Ask: "Does this improvement look right to you? Should I apply it?"

5. **On user approval**, apply the change to the relevant file. If the change is to
   `SKILL.md` itself, note the section number and change inline; do not restructure
   the document.

### 8.3 SOLID compliance check for improvements

Before applying any self-improvement, verify:
- [ ] The change has a single responsibility (S)
- [ ] It extends, not modifies, existing behaviour (O)
- [ ] Downstream documents remain valid after the change (L)
- [ ] The change does not force users of only one feature to change their workflow (I)
- [ ] The change depends on the brief abstraction, not on session specifics (D)

If any box is unchecked, revise the proposed change until all boxes pass.

---

## 9. DOWNSTREAM REPLICATION

Every project file produced by IDEATOR (§6) **must** carry the SOLID Replication Fragment.
This fragment travels with all documents generated in the project and instructs future
documents/agents to continue the self-improvement discipline.

The fragment is defined in `references/solid-fragment.md`. It is inserted verbatim into
section 9 of every output file. Do not summarise or paraphrase it — copy it exactly.

The effect: every README, spec, plan, and feature file generated downstream will contain a
pointer back to this discipline, keeping the entire project's document ecosystem aligned
with the SOLID self-improvement model initiated by IDEATOR.

---

## 10. REFERENCE FILES

| File | Purpose | When to read |
|---|---|---|
| `references/project-readme-template.md` | Template for §6 output | Before generating any project file |
| `references/solid-fragment.md` | Replication fragment | When generating any project file |
| `references/dev-system.md` | Full SDLC Steps 0–9 | When performing §7 SDLC handoff without ROADMAPPER |
| `references/self-improvement-review-prompt.md` | Sub-agent prompt for §8 | When triggering self-improvement |
| `references/question-bank-extended.md` | Extended question library | When §3.2 bank is exhausted |
