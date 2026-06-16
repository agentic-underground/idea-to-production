---
id: 60
title: "SENTINEL sbom skill — CycloneDX + SPDX from the dependency graph"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [60] SENTINEL sbom skill — CycloneDX + SPDX from the dependency graph

**Brief Description**
Generate a Software Bill of Materials (CycloneDX and SPDX formats) from the resolved dependency graph.
Increasingly a procurement/compliance requirement; reuses the ecosystem detection from `dependency-audit`.

### User Stories
- AS a vendor responding to a procurement/compliance request I WANT a standards-format SBOM generated from
  my project SO THAT I can supply it without assembling it by hand.

### EARS Specification
**Ubiquitous**
- The system SHALL emit a Software Bill of Materials in both CycloneDX and SPDX formats from the resolved
  dependency graph.

**Event-driven**
- WHEN `/sbom` runs THE SYSTEM SHALL enumerate every resolved dependency (name, version, licence where
  known) and write a valid CycloneDX and a valid SPDX document.

**Unwanted behaviour**
- IF the dependency graph cannot be fully resolved THEN THE SYSTEM SHALL disclose the unresolved portion
  rather than emit an SBOM that silently omits components.

### Acceptance Criteria
1. Given a resolved dependency graph, When `/sbom` runs, Then a schema-valid CycloneDX and a schema-valid
   SPDX file are produced listing every component.
2. Given a partially-resolvable graph, When run, Then the unresolved components are disclosed.

### Implementation Notes
- New skill `plugins/sentinel/skills/sbom/`; reuse `dependency-audit`'s ecosystem detection + resolution.
- Emit CycloneDX (JSON) + SPDX (tag-value or JSON); validate against the schemas.
- Migrated from `plugins/sentinel/ROADMAP.md` (near-term) under roadmap item [47].
