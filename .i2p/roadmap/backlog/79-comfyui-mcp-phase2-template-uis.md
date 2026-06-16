---
id: 79
title: "comfyui-mcp Phase 2 — per-template parameter UIs / presets"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "#73"
---

# [79] comfyui-mcp Phase 2 — per-template parameter UIs / presets

**Brief Description**
Per-template parameter UIs / presets for common figure kinds (hero, diagram-accent, texture), so a caller
picks a preset instead of tuning raw params.

### User Stories
- AS an illustrator I WANT presets for common figure kinds SO THAT I get a good result without learning each
  template's parameter space.

### EARS Specification
**Ubiquitous**
- The system SHALL offer per-template presets/parameter UIs for common figure kinds over the allowlisted
  templates.

**Event-driven**
- WHEN a preset is selected THE SYSTEM SHALL apply its validated parameter set to the template's allowlisted
  schema.

### Acceptance Criteria
1. Given a "hero" preset, When selected, Then its parameters are applied within the template's validation
   bounds and a figure is produced.

### Implementation Notes
- Builds on the Phase-1 allowlist/validation core ([75]); presets are validated parameter sets, not new
  node graphs.
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 2) under roadmap item [47].
