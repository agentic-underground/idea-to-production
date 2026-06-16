---
id: 70
title: "FRONTEND serverless device-swap — local-first continuity, no server"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [70] FRONTEND serverless device-swap — local-first continuity, no server

**Brief Description**
The open problem from `philosophy/privacy-as-architecture.md`: let a customer move between phone and laptop
**without a server**, keeping data private and local-first, without the friction of manual export/import
every time. Explore CRDTs, peer-to-peer transports, and encrypted-blob handoff. Solving this cleanly is a
strategic prize: cloud-grade continuity with local-first privacy.

### User Stories
- AS a privacy-conscious user I WANT to continue my work when I switch from phone to laptop SO THAT I get
  cloud-grade continuity without my data passing through a server.

### EARS Specification
**Ubiquitous**
- The system SHALL support transferring a user's working state between two of their devices without a
  central server, keeping the data local-first and private.

**Event-driven**
- WHEN a user moves to another device THE SYSTEM SHALL hand off the working state (via a peer transport or
  encrypted-blob exchange) without a manual per-move export/import.

**Unwanted behaviour**
- IF a transport is unavailable THEN THE SYSTEM SHALL fall back to an explicit encrypted handoff rather than
  route data through a server.

### Acceptance Criteria
1. Given two devices of one user, When work continues on the second, Then the state transfers without a
   server and without manual export/import.
2. Given the handoff, When inspected, Then data is encrypted in transit and stored local-first.

### Implementation Notes
- Research-grade: evaluate CRDTs, P2P transports, encrypted-blob handoff.
- Strategic ("high value") — the local-first/privacy prize; ground in `philosophy/privacy-as-architecture.md`.
- Migrated from `plugins/foundry/skills/frontend/resources/ROADMAP.md` (§3) under roadmap item [47].
