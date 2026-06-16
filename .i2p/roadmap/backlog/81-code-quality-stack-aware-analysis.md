---
id: 81
title: "code-quality v1.1 — stack-aware analysis (framework lenses)"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [81] code-quality v1.1 — stack-aware analysis (framework lenses)

**Brief Description**
Auto-detect the framework (FastAPI, Django, Rails, Spring, etc.) and load a framework-specific lens
alongside the generic ones — e.g. FastAPI router organisation + dependency-injection patterns; Django fat
vs. thin models + signals abuse; Rails concerns, service objects, form objects.

### User Stories
- AS a developer on a framework project I WANT code-quality to apply framework-specific checks SO THAT it
  catches idiom-level issues the generic lenses miss.

### EARS Specification
**Ubiquitous**
- The system SHALL detect the project framework and apply a matching framework lens alongside the generic
  lenses.

**Event-driven**
- WHEN a FastAPI/Django/Rails (etc.) project is analysed THE SYSTEM SHALL apply that framework's specific
  checks (e.g. Django fat-vs-thin models, Rails service objects).

**Unwanted behaviour**
- IF the framework cannot be detected THEN THE SYSTEM SHALL fall back to the generic lenses only (no false
  framework-specific findings).

### Acceptance Criteria
1. Given a FastAPI project, When analysed, Then router-organisation / DI-pattern findings are produced
   alongside the generic ones.
2. Given an unrecognised stack, When analysed, Then only generic lenses run.

### Implementation Notes
- Framework auto-detect; per-framework lens modules (FastAPI/Django/Rails/Spring to start).
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v1.1) under roadmap item [47].
