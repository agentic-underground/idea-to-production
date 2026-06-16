---
id: 78
title: "comfyui-mcp — sentinel gate, pressroom docs, marketplace registration"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "#75, #76, #77"
---

# [78] comfyui-mcp — sentinel gate, pressroom docs, marketplace registration

**Brief Description**
The ship step: **sentinel** runs the security gate on the result (`/security-gate`, `/secret-scan`,
`/dependency-audit`, semgrep) and must pass before ship; **pressroom** documents it; the pinned `.mcp.json`
entry is added to the marketplace and listed in `PREREQUISITES/`. (The `handler-comfyui` curl→MCP switch
itself is pressroom's adoption item [49].)

### User Stories
- AS the marketplace owner I WANT the secured backend gated by sentinel, documented, and registered as a
  pinned MCP server SO THAT it ships to the same standard as every other marketplace surface.

### EARS Specification
**Ubiquitous**
- The system SHALL pass the sentinel security gate, ship documentation, and register a pinned `comfyui`
  `.mcp.json` entry consistent with `PREREQUISITES/40-mcp.md` and `verify-prereqs` checks C/K.

**Event-driven**
- WHEN the security gate returns anything but PASS THE SYSTEM SHALL block the ship.

### Acceptance Criteria
1. Given the built server, When the sentinel gate runs, Then it passes (PII/secrets/deps/semgrep) before ship.
2. Given the marketplace, When inspected, Then a pinned `comfyui` `.mcp.json` entry exists and matches the
   40-mcp.md shipped table (check C), with the launcher version pinned (check K).

### Implementation Notes
- Depends on the enforcement + hardening + container ([75]/[76]/[77]) being in place.
- Add the `comfyui` row to `PREREQUISITES/40-mcp.md` and ship the `.mcp.json` (mirrors the flow-server
  registration discipline).
- Migrated from `comfyui-mcp/ROADMAP.md` (Phase 1 §2 gate + §4) under roadmap item [47].
