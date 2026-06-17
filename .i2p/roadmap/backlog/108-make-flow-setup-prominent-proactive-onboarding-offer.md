---
id: 108
title: "Make flow-setup prominent — proactive onboarding offer"
status: PENDING
priority: MEDIUM
added: 2026-06-17
depends_on: "#105"
---

# [108] Make flow-setup prominent — proactive onboarding offer

**Brief Description**
`flow-mcp` needs a one-time approval/connection step before the `/flow` surface works. The owner's
directive (epic [93]): *"if this needs user-intervention to set up, the user must be prompted with
instructions."* This item makes `flow-setup` **prominent** via a **SessionStart offer** to set up `flow-mcp`
when it is detected unconnected — surfacing step-by-step instructions — and **reuses the concierge welcome
offer/opt-out pattern** (now folded into i2p via [98]; opt-out markers under `~/.claude/hook-state`).

### User Stories
- AS a new user I WANT to be proactively offered the flow-mcp setup with clear steps SO THAT I am not left
  with a `/flow` surface that silently does nothing because the backend is unconnected.
- AS a returning user who declined I WANT the offer to respect my opt-out SO THAT I am not re-prompted every
  session.

### EARS Specification
**Event-driven**
- WHEN a session starts and `flow-mcp` is detected unconnected AND the user has not opted out THE SYSTEM
  SHALL present a one-time offer to run `flow-setup`, including step-by-step setup instructions.

**Ubiquitous**
- The offer SHALL record decline/opt-out state under `~/.claude/hook-state` (never in the repo), mirroring
  the concierge welcome offer pattern folded into i2p by [98].

**Unwanted behaviour**
- IF `flow-mcp` is already connected, OR the user has previously opted out THEN THE SYSTEM SHALL NOT present
  the offer.
- IF the offer cannot determine connection state THEN THE SYSTEM SHALL degrade to a clean no-op, never
  failing the session.

### Acceptance Criteria
1. Given an unconnected `flow-mcp` and no prior opt-out, When a session starts, Then the user is offered
   `flow-setup` with step-by-step instructions.
2. Given a prior opt-out (marker present under `~/.claude/hook-state`), When a session starts, Then no offer
   is shown.
3. Given a connected `flow-mcp`, When a session starts, Then no offer is shown.
4. The opt-out marker is written under `~/.claude/hook-state`, never committed to the repo.

### Implementation Notes
- Depends on [105] (the flow plugin owns `flow-setup` and ships the SessionStart hook that makes the offer).
- Reuse the concierge welcome offer/opt-out mechanics folded into i2p by [98] — same hook-state marker
  convention, same one-time-offer-then-respect-decline shape; do not invent a parallel mechanism.
- Detect connection state via `flow-mcp`'s `validate_connection` / `ping` verbs; the offer's body is the
  `flow-setup` walkthrough (pre-cache binary → one-time approval → verify).
- Owner directive (verbatim): *"if this needs user-intervention to set up, the user must be prompted with
  instructions."*
