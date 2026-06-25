# Project README Template

> **Instructions for IDEATE**: Replace all `{{FIELD}}` tokens with values from the populated
> brief (§4). The KAIZEN Replication Fragment in §9 must be copied verbatim from the covenant block in
> `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/kaizen-covenant.md` — do not paraphrase.

---

# {{TITLE}}

> *{{TAGLINE — one punchy sentence capturing the essence of the project}}*

**Date:** {{DATE}}
**Roadmap Entry:** #{{ROADMAP-ENTRY}}
**Stack:** {{LANGUAGE/STACK}}

---

## 1. Problem Statement

{{PROBLEM — 1–3 sentences. What pain or gap does this address? Who feels it?}}

---

## 2. Actors & Roles

{{ACTORS — list each role and their primary interaction with the system}}

| Role | Description |
|---|---|
| {{Actor 1}} | {{What they do}} |
| {{Actor 2}} | {{What they do}} |

---

## 3. Scope

### In Scope (v1)

{{IN-SCOPE — bullet list. Each item is a discrete, deliverable capability.}}

- {{capability 1}}
- {{capability 2}}
- {{capability 3}}

### Out of Scope (v1)

{{OUT-OF-SCOPE — bullet list. Be explicit. "Not yet" items prevent scope creep.}}

- {{exclusion 1}}
- {{exclusion 2}}

---

## 4. Constraints & Non-Functionals

{{CONSTRAINTS — performance, platform, compliance, integration, budget, etc.}}

| Constraint | Detail |
|---|---|
| {{Constraint 1}} | {{Specifics}} |
| {{Constraint 2}} | {{Specifics}} |

---

## 5. Success Metrics

{{SUCCESS-METRIC — how do we know this is working? Prefer measurable outcomes.}}

- {{metric 1}}
- {{metric 2}}

---

## 6. Architecture Sketch

*High-level only. 3–5 bullets. Do not over-specify here — that belongs in the EARS spec.*

- {{component or layer 1 and its role}}
- {{component or layer 2 and its role}}
- {{data flow or integration point}}
- {{key technical decision or constraint}}

---

## 7. Roadmap Entry

*Ready to paste into `ROADMAP.md` or `doc/ROADMAP.md`.*

```markdown
### #{{ROADMAP-ENTRY}} — {{TITLE}}

STATUS: BACKLOG
ADDED: {{DATE}}
SLUG: {{SLUG}}

**Problem:** {{PROBLEM — 1 sentence}}
**Actors:** {{ACTORS — comma-separated}}
**In Scope:** {{IN-SCOPE — comma-separated summary}}
**Out of Scope:** {{OUT-OF-SCOPE — comma-separated summary}}
**Constraints:** {{CONSTRAINTS — comma-separated summary}}
**Success Metric:** {{SUCCESS-METRIC — 1 sentence}}
```

---

## 8. SDLC Next Steps

When ready to implement, work through the development system in order:

- [ ] **Step 0** — Write the implementation plan to `doc/{{SLUG}}_PLAN.md`
- [ ] **Step 1** — Add EARS statements to `doc/SPECIFICATION.ears.md`
- [ ] **Step 2** — Write Gherkin scenarios in `features/{{SLUG}}.feature`
- [ ] **Step 3** — Write failing tests (unit, integration, e2e as appropriate)
- [ ] **Step 4** — Run tests; confirm new tests fail, existing tests pass
- [ ] **Step 5** — Implement the minimum production code to pass the tests
- [ ] **Step 6** — Run tests to green; confirm no regressions
- [ ] **Step 7** — Sync with upstream (`git fetch` + rebase/merge)
- [ ] **Step 8** — Write the structured commit message
- [ ] **Step 9** — Commit, push, update roadmap entry to COMPLETE

> **Trigger ROADMAPPER** to automate this checklist: say "pull feature #{{ROADMAP-ENTRY}}"
> or "implement {{TITLE}}".

---

## 9. KAIZEN Replication Fragment

<!-- INSERT the KAIZEN REPLICATION FRAGMENT block from knowledge/architecture/kaizen-covenant.md VERBATIM BELOW THIS LINE -->
