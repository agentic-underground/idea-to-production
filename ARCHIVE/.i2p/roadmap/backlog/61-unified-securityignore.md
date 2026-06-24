---
id: 61
title: "SENTINEL unified .securityignore — one exclusion file, per-lens sections"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [61] SENTINEL unified .securityignore — one exclusion file, per-lens sections

**Brief Description**
One exclusion file consumed by all lenses (superseding the per-skill `.piiignore` / `.secretignore`), with
per-lens sections. Keeps exclusions in one auditable place.

### User Stories
- AS a security owner I WANT one `.securityignore` for every lens SO THAT exclusions are auditable in a
  single file rather than scattered per-skill.

### EARS Specification
**Ubiquitous**
- The system SHALL read a single `.securityignore` (with per-lens sections) as the exclusion source for
  every SENTINEL lens.

**Event-driven**
- WHEN a lens runs THE SYSTEM SHALL apply that lens's section of `.securityignore` plus any shared/global
  section.

**State-driven**
- WHILE a legacy `.piiignore`/`.secretignore` exists THE SYSTEM SHALL honour it for backward compatibility
  and surface a deprecation note pointing at `.securityignore`.

### Acceptance Criteria
1. Given a `.securityignore` with a secrets section, When the secret-scan runs, Then those patterns are
   excluded and no other lens's exclusions leak into it.
2. Given a legacy `.secretignore`, When the secret-scan runs, Then it is still honoured with a deprecation
   note.

### Implementation Notes
- Define the `.securityignore` format (per-lens sections + a shared section).
- Update each lens (pii-audit, secret-scan, dependency-audit) to read it; keep legacy fallbacks.
- Migrated from `plugins/sentinel/ROADMAP.md` (near-term) under roadmap item [47].
