---
id: 18
title: "Learning ledger — `.i2p/learnings.jsonl` + reducer + overdue detector"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "— (atomic; PR-A)"
---

# [18] Learning ledger — `.i2p/learnings.jsonl` + reducer + overdue detector

**Brief Description**
An append-only, schema-versioned `.i2p/learnings.jsonl` (mirroring `.i2p/action-items.jsonl`): one record per
event (`open|filed|closed`) carrying origin/phase/kind/target/severity/title/brief_path/issue_url. Plus a
reducer and an unfiled/overdue detector (cloning `overdue-action-items.sh`) so open learnings surface as a
re-entry signal into `mission-control:iterate`.

### EARS Specification
**Event-driven**
- WHEN a learning is captured/filed/closed THE SYSTEM SHALL append a schema-versioned record to `.i2p/learnings.jsonl`.
- WHEN learnings remain unfiled/open past a threshold THE SYSTEM SHALL surface them to `mission-control:iterate`.

### Acceptance Criteria
1. Given a capture and a later filing, the ledger records `open` then `filed` for the same id.
2. Given an open-but-unfiled learning, the detector surfaces it.

### Implementation Notes
- Mirror `plugins/mission-control/skills/incident/scripts/{action-items,overdue-action-items}.sh`. Plan §1b.

### Development Plan Reference
`doc/GEMBA_LEARNING_LEDGER_PLAN.md`
