---
id: 45
title: "comfyui-mcp disposition — implement or archive the stub"
status: PENDING
priority: LOW
added: 2026-06-15
depends_on: "—"
---

# [45] comfyui-mcp disposition — implement or archive the stub

**Brief Description**
Decide the fate of `./comfyui-mcp`, currently a stub (design doc + Dockerfile + 5 workflow templates, no
server code, not wired in; `handler-comfyui` still uses raw HTTP). Either implement the secured MCP
(allowlisted templates, no raw node graphs) or archive the stub to `docs/historical/archive/` and drop the
root folder.

### User Stories
- AS the owner I WANT a clear decision on comfyui-mcp SO THAT the root isn't cluttered by an unfinished stub.

### EARS Specification
**Ubiquitous**
- The repo SHALL NOT carry an unimplemented MCP stub at the root without a decision recorded.

**Optional feature**
- WHERE the secured ComfyUI MCP is implemented THE SYSTEM SHALL expose only allowlisted workflow templates
  (no arbitrary node graphs) and `handler-comfyui` SHALL switch from raw HTTP to the MCP verbs.

### Acceptance Criteria
1. Either: the secured MCP is implemented + wired into `handler-comfyui`; OR `comfyui-mcp/` is archived to
   `docs/historical/archive/` and removed from the root.
2. The decision and rationale are recorded.

### Implementation Notes
- Stub has zero blast radius today (not referenced/wired).
- If implementing: allowlisted templates, image-queue + result-poll verbs (`list_models`, `set_model`,
  `list_templates`, `submit_prompt`, `get_result`).
