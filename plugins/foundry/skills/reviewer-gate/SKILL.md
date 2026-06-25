---
name: reviewer-gate
description: Use when a stage agent generates or updates a document and must pass it through a critical reviewer agent for professional standards and state-of-the-art quality checks.
---

# Reviewer Gate

> Agent-internal — invoked by the FOUNDRY conveyor, not typed directly.

## Purpose

Enforce a mandatory second-pass critical review for every generated document in the Development System. No document advances to the next stage without passing this gate.

## Trigger

Run this gate whenever an agent:
- Creates a new document (plan, EARS spec, feature file, test strategy, commit message)
- Materially updates an existing document
- Produces a completion report or evidence artifact

**Non-triggers** (does not require reviewer gate):
- Mechanical file edits (updating STATUS field in roadmap, adding a date, marking checklist items)
- Running tests (the result is evidence, not a generated document)

## Which Reviewer To Use

| Context | Reviewer |
|---|---|
| Operating in FOUNDRY cycle | `reviewer` with the appropriate role parameter |
| General Development System use | `reviewer` |

Prefer `reviewer` for its specialized checklists (EARS-REVIEWER, BDD-REVIEWER, etc.). Use `reviewer` when outside a FOUNDRY context or when a general quality review is needed.

## Reviewer Prompt Contract

The producing agent must provide:
- Document path (exact file location)
- Stage context and intended audience
- Applicable standards (IDEATE, ROADMAPPER, code-quality, EARS forms, Gherkin)
- Explicit request for critical findings and improved revision

**Do not say** "please review this document" — say "I need a critical review of this [document type] for [stage]. The applicable standards are [list]. Identify severity-ranked findings and provide a revised version."

## Reviewer Output Contract

Reviewer must return:
1. Severity-ranked findings (critical/high/medium/low) — specific, actionable, not vague
2. Suggested revisions with rationale — implementable changes, not suggestions to "improve clarity"
3. Updated version or exact patch instructions — the producing agent can apply without interpretation
4. Residual risks and confidence statement

## Gate Decision Rule

| Verdict | Meaning | Action |
|---|---|---|
| `PASS` | No unresolved critical findings | Stage may advance; emit sentinel |
| `NEEDS_REVISION` | Critical or high findings | Apply revisions; re-review; do NOT advance until resolved |
| `BLOCK` | Unresolvable critical issue | Escalate to orchestrator; pipeline pauses; human review required |

- **Block advance**: any unresolved CRITICAL finding.
- **Warn, do not block**: unresolved HIGH findings — orchestrator decides whether to accept risk.
- **Pass**: zero CRITICAL findings and all mandatory sections of the document complete.

## Revision Limit

If a stage receives `NEEDS_REVISION` 3 times in a row without resolution:
1. Automatically escalate to `BLOCK`.
2. Surface to orchestrator with the revision history.
3. Do NOT continue attempting revision — the issue is systemic, not iterative.

## Operational Excellence Rules

- Avoid rubber-stamp reviews — "looks good" is not a review outcome.
- Challenge unclear assumptions and unverifiable claims.
- Prefer precise edits over broad rewrites.
- Name specific files, line numbers, EARS IDs, and scenario tags in findings.
- Align recommendations to current best practice and project constraints.

## Integration

Use with:
- `${CLAUDE_PLUGIN_ROOT}/skills/development-system-core/SKILL.md` — stage maturity requirements
- `${CLAUDE_PLUGIN_ROOT}/skills/handoff-protocol/SKILL.md` — `reviewer_status` field population
- `${CLAUDE_PLUGIN_ROOT}/agents/lifecycle-orchestrator.md` — orchestrator receives gate results
- `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` — specialized FOUNDRY reviewer (preferred)
- `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` — general-purpose reviewer

## KAIZEN Covenant

This skill carries the KAIZEN self-improvement covenant. If the same types of findings recur across items (missing EARS IDs, incomplete Gherkin coverage, vague commit messages), the issue is upstream in the producing agent's instructions. Flag recurring patterns for the self-improvement covenant ([`kaizen-covenant.md`](../../knowledge/architecture/kaizen-covenant.md)) — fix the template, not the instance.
