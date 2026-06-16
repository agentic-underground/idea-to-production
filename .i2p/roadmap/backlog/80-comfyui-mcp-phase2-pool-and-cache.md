---
id: 80
title: "comfyui-mcp Phase 2 — worker pool + result cache"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "#73"
---

# [80] comfyui-mcp Phase 2 — worker pool + result cache

**Brief Description**
Multiple backends (a pool of ComfyUI workers) behind one MCP endpoint, and a cache keyed by
`(template_id, params, checkpoint)` so identical figures are free.

### User Stories
- AS an operator under load I WANT several ComfyUI workers behind one MCP endpoint SO THAT generation scales,
  and AS a frequent caller I WANT identical requests cached SO THAT repeat figures are instant and free.

### EARS Specification
**Ubiquitous**
- The system SHALL distribute generation across a pool of ComfyUI workers behind one MCP endpoint and cache
  results by `(template_id, params, checkpoint)`.

**Event-driven**
- WHEN a request matches a cached `(template_id, params, checkpoint)` key THE SYSTEM SHALL return the cached
  result without re-generating.

### Acceptance Criteria
1. Given multiple workers, When several requests arrive, Then they are distributed across the pool.
2. Given an identical prior request, When repeated, Then the cached result is returned (no re-generation).

### Implementation Notes
- Pool behind the one MCP endpoint; cache keyed by `(template_id, params, checkpoint)`.
- Builds on the Phase-1 server ([73]/[74]).
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 2) under roadmap item [47].
