---
name: value-station-handoff
description: >
  The precise input/exit contract for each value-station, written so a fresh gate-keeping
  agent (reviewer, security-auditor) can pick up an artifact with zero conversation history
  and know exactly what to verify. Use when handing work between stations, when a reviewer
  needs to know what "done" means for a stage, or when defining a new station. Trigger:
  "handoff contract", "what does done mean here", "station contract", "ready for review".
---

# VALUE-STATION-HANDOFF

> Agent-internal — invoked by the DELIVER conveyor, not typed directly.

Every station is a contract. This skill is the authoritative source for **what must arrive**
(input), **what must be true to leave** (exit gate), and **what is produced** (artifact).
Gate-keepers read this and nothing else is assumed.

## Contracts

### VALIDATE  (handler: marketer)
- IN: a candidate idea + its stack-fit argument from the market scan.
- EXIT: ≥3 of 10 target users express willingness to pay, OR a documented kill + re-rank.
- OUT: `docs/marketing/product-brief.md` populated; a validation note.

### SPEC  (handler: roadmapper)
- IN: a validated product-brief and the slice's value sentence.
- EXIT: EARS requirements written; a `.feature` file exists; acceptance criteria are
  concrete and testable (each becomes a STORY assertion).
- OUT: a roadmap entry + `.feature` file.

### DESIGN  (handler: frontend)
- IN: the SPEC and the surfaces touched.
- EXIT: screens carry INTENT markers; accessibility (WCAG 2.1 AA floor) and
  privacy-as-architecture (local-first default) are held or an explicit logged exception
  exists; surfaces classified Capture/Display/Navigate/Instrument.
- OUT: INTENT-marked component(s).

### SLICE  (handler: builder)
- IN: SPEC + DESIGN.
- EXIT: unit + module tests green; one-way dependency direction intact; no panics in
  core/server non-test code; `cargo fmt` + `clippy -D warnings` clean.
- OUT: the implementation diff + its tests.

### HARDEN  (handlers: reviewer, security-auditor)
- IN: the SLICE diff + boundary/system tests.
- EXIT: `reviewer` APPROVE (architecture, correctness, tests, consistency) AND, if api/deps/
  input touched, `security-auditor` APPROVE (input validation, supply chain, no reachable
  panic in request paths, no secrets).
- OUT: an APPROVE verdict (or REQUEST CHANGES with severity-sorted findings).

### SHIP  (handler: founder)
- IN: a HARDEN-approved slice.
- EXIT: STORY tests green; **STORY perf-delta gate passed** vs recorded baseline; deployed;
  new perf baseline recorded.
- OUT: a shipped increment + slice-ledger entry.

### LEARN  (handler: marketer)
- IN: a shipped slice + any usage/market signal + any **ideation-feedback** raised while building
  (an IDEA-package field that proved ambiguous downstream).
- EXIT: signal captured; positioning in `docs/marketing/` still cohesive with reality.
- OUT: the next IDEA candidate (closes the loop). **When the `ideate` / `discover` plugins are
  installed**, also route the ideation-feedback to their self-improve intake (symptom → unclear field →
  preventing question), so the upstream front end sharpens for every future ideation — not just this
  project's brief. See `knowledge/pillars/knowledge-parity.md` ("feedback flows upstream").

## Rule for fresh agents
If you are a gate-keeper and the incoming artifact does not satisfy its station's IN
contract, **reject at intake** — do not attempt the work of the previous station. Name the
missing input and return it.
