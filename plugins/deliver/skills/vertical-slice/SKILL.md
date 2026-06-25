---
name: vertical-slice
description: >
  Cut and drive ONE thin, end-to-end, independently shippable increment through every
  value-station and gate. Use whenever starting a new piece of work, when a change is
  getting too big to review, or when asked "what's the next slice?". Trigger phrases:
  "next slice", "cut a slice", "this is too big", "ship one increment", "vertical slice".
---

# VERTICAL-SLICE

A vertical slice is the unit of progress in the FOUNDER method: **one thin path that
touches every layer it needs to and nothing it doesn't**, shippable on its own, reviewable
in a single sitting. Horizontal work ("build the whole data layer first") is forbidden —
it defers learning and integration risk.

## 1 · The thinness test
A slice is thin enough when ALL hold:
- It can be described in one sentence as a user-meaningful change.
- Its diff is reviewable in one sitting by the `reviewer` agent.
- It produces at least one new/changed **STORY** test that asserts the user value.
- It can ship to production without depending on an unbuilt future slice.

If any fail, **split it** and do the first part only.

## 2 · Cutting a slice (the procedure)
1. **Name the value** in one sentence (the future STORY title).
2. **Identify the surfaces touched** (frontend taxonomy: Capture/Display/Navigate/Instrument)
   and the crates touched (core/ui/web/mobile/server/api). Minimise both.
3. **Write the SPEC** via `roadmapper`: EARS requirements + a `.feature` file + acceptance
   criteria. The acceptance criteria become STORY assertions.
4. **Write tests first** where practical: unit (core), module, boundary if a seam changes.
5. **Implement** the minimum via `builder`. No speculative abstraction.
6. **Run the contract**: unit → module → boundary → system → STORY, each emitting a perf
   sample; the STORY perf-delta gate must pass against baseline.
7. **HARDEN**: `reviewer` + (if api/deps/input touched) `security-auditor` must APPROVE.
8. **SHIP**: deploy; record the new perf baseline; capture a LEARN note for `marketer`.

## 3 · Driving it through the stations
FOUNDER walks the slice station-by-station, stopping at the first unmet gate with a precise
remediation. You never skip a station; a station with nothing to do is acknowledged and
passed, not omitted.

## 4 · The slice ledger
Each slice leaves a one-line ledger entry (see `references/slice-ledger-template.md`):
`SLICE-NN · <value sentence> · STORY:<name> · perf:<delta vs baseline> · shipped:<date>`.
The ledger is how a fresh agent reconstructs project history with zero conversation context.

## 5 · Worked sequence (this project)
Slice 0 hello-world (done) → 1 deploy-to-Vercel → 2 swap domain → 3 free-tier feature →
4 mobile parity → 5 paid unlock → 6 launch. See `docs/technical/roadmap.md`. Each is thin,
each carries its own STORY, each passes the perf gate before the next begins.
