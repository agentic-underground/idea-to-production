---
name: founder-method
description: >
  The FOUNDER method — how a software production house turns an idea into a product one
  vertical slice at a time through value-stations and value-handlers, governed by a
  five-level performance-instrumented test contract. Use when planning the production line,
  defining stages and their owners, onboarding a new value-handler agent, or explaining
  WHAT is being built and HOW. Trigger phrases: "founder method", "value stations",
  "who owns this stage", "production line", "how does our process work".
---

# THE FOUNDER METHOD

A method for running an application-layer production house. It exists to make every change
**rigorously disciplined**: each increment passes through a fixed line of stations, each
station has a defined value, an owning handler, and an exit gate, and nothing merges that
has not satisfied the test contract.

## 1 · Core vocabulary
- **foundry** — the BUILD_SYSTEM; the machine FOUNDER orchestrates.
- **FOUNDER** — the COO agent that staffs and sequences the line (subtype `FOUNDER_COO`).
- **value-station** — a stage every increment passes through. Has: input contract,
  handler, exit gate, output artifact.
- **value-handler** — the agent that owns a station.
- **vertical slice** — one thin, end-to-end, independently shippable increment.
- **test contract** — the five levels + perf instrumentation + STORY perf-delta gate that
  every slice must satisfy.

## 2 · The line (canonical)
| Station | Value (what it adds) | Handler | Exit gate |
|---|---|---|---|
| IDEA | a candidate worth pursuing | founder | thesis stated; stack-fit argued |
| VALIDATE | evidence a buyer exists | marketer | ≥3/10 target users say "I'd pay" |
| SPEC | unambiguous, agent-readable intent | roadmapper | EARS + `.feature` + acceptance criteria |
| DESIGN | surfaces a human can use | frontend | INTENT-marked screens; a11y + privacy held |
| SLICE | working code + tests | builder | unit+module green; one-way deps intact |
| HARDEN | correctness + safety | reviewer, security-auditor | both APPROVE; boundary/system green |
| SHIP | product in users' hands | founder | STORY green; perf-delta gate passed; deployed |
| LEARN | the next IDEA | marketer | signal captured; positioning still cohesive |

LEARN feeds IDEA. The loop is the product.

## 3 · The test contract (non-negotiable)
Five levels, each **performance-instrumented**:
- **unit** — one function/type; sample: time.
- **module** — one crate's public surface; sample: time.
- **boundary** — a seam/serialised contract between crates; sample: time + payload size.
- **system** — assembled app on one platform, end-to-end; sample: time + (wasm) bundle delta.
- **STORY** — a user-meaningful journey asserted as behaviour; sample: time, **gated** against
  a recorded baseline by a configured perf-delta budget. A STORY whose performance regresses
  past budget **does not merge**. The gate runs WITH the STORY tests.

FOUNDER verifies this contract on every invocation and **halts** (`CONTRACT UNMET`) if any
level, instrument, or the STORY gate is missing.

## 4 · Discovery protocol (FOUNDER runs this first)
1. `foundry -help` (project `./.claude`, or the user's global config if present): learn the stage list and,
   per stage, *what to put in for a rich and viable result out*.
2. `frontend -help`: learn the surface taxonomy (Capture/Display/Navigate/Instrument), the
   INTENT marker protocol, and the two non-negotiables (a11y floor, privacy-as-architecture).
3. Verify the test contract (§3). Halt if unmet.
4. Emit the topology READOUT (see `references/readout-template.md`).

## 5 · Staffing rule
Every station MUST have a handler. An unstaffed station is a defect FOUNDER reports; it
nominates an existing agent or recommends authoring one via `skill-creator`. No station
without a handler; no gate without a check; no merge without the contract.

See `references/station-contracts.md` for the precise per-station input/exit definitions
(this is the same material the `value-station-handoff` skill serves to gate-keepers).
