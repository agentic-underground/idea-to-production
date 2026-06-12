---
name: state-delivery
description: Lifecycle state skill for upstream synchronization, commit narrative quality, and delivery transaction completion.
---

# State Delivery

## Applies To

- step-7-sync (upstream synchronization)
- step-8-commit-message (commit narrative)
- step-9-commit-push (delivery transaction)

## Purpose

Delivery state governs the quality of the release transaction. A technically correct implementation that is poorly committed, lacks traceability, or breaks on sync is not shipped — it is risk. Delivery state ensures the change is packaged for permanence.

## Exit Criteria for Sync (step-7 complete) — All must be true

- [ ] `git fetch origin` completed
- [ ] Rebase or merge completed (per project convention)
- [ ] Conflicts resolved — both upstream changes and feature changes preserved
- [ ] Full test suite re-run after sync
- [ ] Post-sync tests green (zero new failures)
- [ ] If test files conflicted: resolved tests re-validated against EARS spec

## Exit Criteria for Commit Message (step-8 complete) — All must be true

- [ ] Message follows WHY/WHAT/TESTING/ROADMAP structure
- [ ] `WHAT` section matches actual `git diff --stat` (no invented file changes)
- [ ] EARS IDs explicitly listed
- [ ] Test count and coverage percentage accurate
- [ ] Roadmap item number referenced (`ROADMAP: closes #N`)
- [ ] Message is imperative present tense (not past tense)
- [ ] Reviewer: PASS

## Exit Criteria for Commit/Push (step-9 complete) — All must be true

- [ ] Adversarial review (`/foundry:pr-review`) returned **PASS** for the change
- [ ] Changes staged interactively (`git add -p` — no surprise files committed)
- [ ] Commit created with reviewed message
- [ ] Delivered per **merge governance** ([`../../../knowledge/protocols/merge-governance.md`](../../../knowledge/protocols/merge-governance.md)):
      `pr-approval` → branch pushed + PR opened for the human to merge (item held AWAITING MERGE);
      `direct-merge` → merged to `main` and pushed
- [ ] Commit hash captured
- [ ] Roadmap entry STATUS updated (COMPLETE, or AWAITING MERGE under pr-approval until merged)
- [ ] Plan file completion section populated with commit hash and date
- [ ] If IDEA_COST.jsonl in use: record appended

## Traceability Chain

The delivery state enforces full traceability:
```
Roadmap item → EARS IDs → Gherkin scenarios → Tests → Implementation → Commit message
```
Every link in this chain must be explicit in the commit message. An auditor reading the commit a year from now must be able to trace back to the original requirement.

## Handoff Target

`lifecycle-orchestrator` (global DoD audit) — with delivery evidence, closure updates, and reviewer status.

## KAIZEN Covenant

This skill carries the KAIZEN self-improvement covenant. Traceability failures at delivery state (commit messages missing EARS IDs, roadmap not updated, coverage not reported) indicate a systemic gap in the step-8 or step-9 agent instructions. Flag for the self-improvement covenant ([`kaizen-covenant.md`](../../../knowledge/architecture/kaizen-covenant.md)).
