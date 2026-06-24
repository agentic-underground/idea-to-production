---
id: 76
title: "comfyui-mcp — boundary hardening: path-safe /view, net isolation, authn"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "#74"
---

# [76] comfyui-mcp — boundary hardening: path-safe /view, net isolation, authn

**Brief Description**
The trust-boundary hardening: a **path-traversal-safe `/view`** (filename/subfolder canonicalised and
confined to the output dir), **network isolation** (ComfyUI on a private container network, never exposed;
only the MCP port published), and **authn** (a token on the MCP endpoint; `.mcp.json` approval-gating is the
second layer).

### User Stories
- AS a security owner I WANT the result proxy confined to the output dir, ComfyUI unexposed, and the MCP
  endpoint authenticated SO THAT neither arbitrary files nor the raw ComfyUI API are reachable.

### EARS Specification
**Ubiquitous**
- The system SHALL serve `/view` only for canonicalised paths inside the output dir, expose only the
  authenticated MCP port, and keep ComfyUI on a private network.

**Unwanted behaviour**
- IF a `/view` request contains a path-traversal sequence THEN THE SYSTEM SHALL refuse it; IF a request
  reaches the MCP port without a valid token THEN THE SYSTEM SHALL reject it.

### Acceptance Criteria
1. Given `/view?filename=../../etc/passwd`, When requested, Then it is refused (confined to the output dir).
2. Given a request without a valid token, When it hits the MCP endpoint, Then it is rejected; given a valid
   token, Then it is served.

### Implementation Notes
- Canonicalise + confine the `/view` filename/subfolder; token-gate the MCP endpoint.
- Network isolation is realised together with the container ([77]).
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 1 §2, security model) under roadmap item [47].
