---
id: 77
title: "comfyui-mcp — container: ComfyUI + server, model bind-mount, private net"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "#74"
---

# [77] comfyui-mcp — container: ComfyUI + server, model bind-mount, private net

**Brief Description**
The `container/` build: ComfyUI + the MCP server, bind-mounting `DIFFUSION_MODELS` (the i9's 1T_990 drive),
putting ComfyUI on a private network, and publishing **only** the MCP port.

### User Stories
- AS an operator I WANT a container that runs ComfyUI + the MCP server with the model drive bind-mounted and
  only the MCP port exposed SO THAT the backend is reproducible and the raw ComfyUI API is never reachable.

### EARS Specification
**Ubiquitous**
- The system SHALL build a container running ComfyUI + the MCP server, with `DIFFUSION_MODELS` bind-mounted
  and ComfyUI on a private network.

**Event-driven**
- WHEN the container is brought up THE SYSTEM SHALL publish only the MCP port and keep ComfyUI unpublished.

**Unwanted behaviour**
- IF the compose/run config would publish the ComfyUI port THEN THE SYSTEM SHALL be considered misconfigured
  (only the MCP port may be published).

### Acceptance Criteria
1. Given the container, When up, Then ComfyUI sees the bind-mounted models and only the MCP port is published.
2. Given a port scan of the host, When run, Then the ComfyUI API port is not reachable.

### Implementation Notes
- `comfyui-mcp/container/` builds both services; private network; bind-mount the model drive.
- Realises the network-isolation half of [76].
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 1 §3) under roadmap item [47].
