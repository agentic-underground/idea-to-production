# Subject Matter Understanding (SMU) Reference

> For DELIVER §5 (LEAD ENGINEER). Template for the SMU document created at
> cycle start and carried by every agent throughout the pipeline.

---

## Purpose

The Subject Matter Understanding document is the **philosophical and domain
foundation** for all activity in a DELIVER cycle. It answers:

- What is this product and who is it for?
- What problem does it solve, and why does that matter?
- What are the core concepts, terms, and mental models of this domain?
- What constraints and values must every agent hold when making decisions?

Every agent — PHASE_POOL, VALUE_HANDLER, REVIEWER, and DAILY INSPECTOR —
receives the SMU as part of its instantiation context. It is the shared
understanding that prevents agents from making locally-rational but
globally-incoherent decisions.

---

## File Location

`doc/SUBJECT_MATTER_UNDERSTANDING.md` in the project.

Created by LEAD ENGINEER during §5 if absent.
Updated whenever the domain understanding evolves (open for extension, never
rewrite existing content — add new sections).

---

## Template

```markdown
# Subject Matter Understanding — [Project Name]

> *This document is the philosophical and domain foundation for all DELIVER
> agents operating on [Project Name]. Read it before taking any action.*

---

## 1. What This Product Is

[1–3 sentences: what the product does, at the highest level of abstraction.]

---

## 2. Who It Is For

| Actor | Role | Core need |
|---|---|---|
| [Primary user] | [Role description] | [What they need from the product] |
| [Secondary user] | [Role description] | [What they need] |
| [External system] | [Integration partner] | [What it expects] |

---

## 3. The Problem It Solves

[2–4 sentences: the specific friction, gap, or pain this product removes.
Be concrete. Avoid marketing language.]

---

## 4. Core Domain Concepts

[Define the essential terms of this domain. Every agent must use these terms
consistently. If a concept has a precise meaning in this domain that differs
from everyday usage, define it explicitly.]

| Term | Definition |
|---|---|
| [Term] | [Precise definition as used in this domain] |
| [Term] | [Precise definition] |

---

## 5. Design Values

[What does this product optimise for? List 3–5 non-negotiable values that
every design decision must honour. These are tie-breakers when trade-offs arise.]

1. **[Value]** — [One sentence: why this matters for this product]
2. **[Value]** — [One sentence]
3. **[Value]** — [One sentence]

---

## 6. Constraints Every Agent Must Honour

[Hard constraints that no agent may violate, regardless of other pressures.]

- **[Constraint]**: [Description]
- **[Constraint]**: [Description]
- **[Constraint]**: [Description]

---

## 7. What Success Looks Like

[How will we know this product is working? Prefer observable, measurable
outcomes. Not metrics — outcomes.]

- [Outcome 1]
- [Outcome 2]
- [Outcome 3]

---

## 8. What Failure Looks Like

[Anti-patterns, failure modes, and outcomes to actively avoid.]

- [Failure mode 1]
- [Failure mode 2]

---

## 9. Revision History

| Date | Change | Reason |
|---|---|---|
| [ISO date] | Initial creation | DELIVER cycle start |
```

---

## SMU Reviewer Checklist (for SMU-REVIEWER)

When reviewing the SMU at the EARS → FEATURE transition:

- [ ] All domain terms used in EARS statements are defined in §4
- [ ] The actors in §2 match the actors referenced in EARS statements
- [ ] The constraints in §6 are not contradicted by any EARS statement
- [ ] The design values in §5 are concrete enough to serve as tie-breakers
- [ ] No agent reading only this document would be confused about what the product does

If any item fails, return `NEEDS_REVISION` with specific gaps identified.

---

## Carrying the SMU

When spawning any agent, prepend the SMU content to the agent's context.
The sentinel format for confirming the SMU has been loaded:

```
SMU::LOADED::[project-slug]::[doc/SUBJECT_MATTER_UNDERSTANDING.md]::[version-N]
```

The SMU version increments with each approved addition. Never decrement.
