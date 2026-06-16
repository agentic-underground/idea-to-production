---
id: 73
title: "EPIC — comfyui-mcp secured generative backend (Phase 1)"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [73] EPIC — comfyui-mcp secured generative backend (Phase 1)

**Brief Description**
Build the secured **comfyui-mcp** server that earns the name: a containerised ComfyUI fronted by an MCP
server that *enforces* (server-side) what `handler-comfyui` today only mitigates client-side. Phase 0 (raw
HTTP over the LAN) shipped with an honest, time-boxed gap — ComfyUI's API would accept an arbitrary node
graph. Phase 1 closes it: workflow-template allowlisting, validated params, a model allowlist, a
path-traversal-safe `/view`, network isolation, and authn. Built by dogfooding the marketplace's own
pipeline (foundry builds test-first, sentinel gates, pressroom documents). This EPIC umbrellas the Phase-1
children [74]–[78]; Phase-2 follow-ons are [79]–[80].

### User Stories
- AS the marketplace owner I WANT a demonstrably-secure ComfyUI backend SO THAT generative figures don't
  depend on an unauthenticated LAN service that can execute arbitrary node graphs.

### EARS Specification
**Ubiquitous**
- The system SHALL expose ComfyUI generation only through an MCP server that enforces template allowlisting,
  input validation, a model allowlist, a path-safe `/view`, network isolation, and authn.

**Unwanted behaviour**
- IF a request names anything other than an allowlisted template/model THEN THE SYSTEM SHALL refuse it
  server-side (not merely rely on the client to fill a fixed template).

### Acceptance Criteria
1. Given the Phase-1 children [74]–[78] complete, When a generation is requested, Then it flows through the
   secured MCP surface with every enforcement in place and the sentinel gate passing.
2. Given the build, When inspected, Then `handler-comfyui` can switch from raw HTTP to `mcp__comfyui__*`
   (the switch itself is pressroom's adoption item [49]).

### Implementation Notes
- Decomposes into [74] server build, [75] enforcement core, [76] boundary hardening, [77] container,
  [78] gate + docs + marketplace registration. Phase 2: [79], [80].
- Resolves the disposition decision recorded in [45] (implement, not archive).
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 1) under roadmap item [47].
