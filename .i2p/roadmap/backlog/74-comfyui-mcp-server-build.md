---
id: 74
title: "comfyui-mcp — foundry builds server/ test-first (5 MCP tools)"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "#73"
---

# [74] comfyui-mcp — foundry builds server/ test-first (5 MCP tools)

**Brief Description**
FOUNDRY consumes `comfyui-mcp/EARS.md` and builds `server/` test-first to the 100% line+branch coverage
floor: the five MCP tools (`list_models`, `set_model`, `list_templates`, `submit_prompt`, `get_result`),
the allowlist loaders, the param validators, and the `/view` proxy. This is the buildable core the
enforcement ([75]) and hardening ([76]) layers refine.

### User Stories
- AS a builder I WANT the comfyui-mcp server built test-first to the coverage floor SO THAT its security
  enforcement is pinned by tests, not asserted in prose.

### EARS Specification
**Ubiquitous**
- The system SHALL implement the five MCP tools (`list_models`, `set_model`, `list_templates`,
  `submit_prompt`, `get_result`) with the allowlist loaders, param validators, and `/view` proxy.

**Event-driven**
- WHEN `submit_prompt` is called THE SYSTEM SHALL accept a `template_id` (not a node graph), validate params,
  submit to ComfyUI, and return a handle pollable via `get_result`.

### Acceptance Criteria
1. Given `EARS.md`, When `server/` is built, Then the five tools exist with the allowlist loaders + param
   validators + `/view` proxy, at the 100% line+branch coverage floor.
2. Given the test suite, When run, Then it passes and pins each tool's happy + refusal paths.

### Implementation Notes
- Test-first per the FOUNDRY DEV_SYSTEM; source EARS in `comfyui-mcp/EARS.md`.
- The enforcement specifics (allowlist semantics, validation bounds) are detailed in [75]/[76].
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 1 §1) under roadmap item [47].
