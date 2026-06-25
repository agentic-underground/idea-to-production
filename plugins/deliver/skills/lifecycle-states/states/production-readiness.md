---
name: state-production-readiness
description: Lifecycle state skill for final release confidence assessment, unresolved risk disposition, and Definition Of Done certification.
---

# State Production Readiness

## Applies To

- Final orchestrator pass after step-9
- Iteration closure decision
- DELIVER cycle completion check per item

## Purpose

Production Readiness is the last gate before an item is declared COMPLETE. It is a full audit of all DoD gates — not a rubber stamp. If any gate fails, the item opens a new iteration rather than being declared done with known gaps.

## Exit Criteria — All must be true

### Problem-Solution Traceability
- [ ] Every artifact (plan, EARS, feature, tests, implementation, commit) traces to the IDEATE brief
- [ ] Each EARS requirement has a stable ID and is mapped to passing tests

### Specification Integrity
- [ ] EARS set is complete, unambiguous, and uniquely ID'd
- [ ] Gherkin scenarios cover happy, unhappy, and abuse paths for all EARS IDs

### Test Evidence
- [ ] Tests fail before implementation (RED evidence documented in gap map)
- [ ] Tests pass after implementation (GREEN evidence documented in green run)
- [ ] Full regression suite green
- [ ] Coverage meets threshold (100% line coverage for changed files)

### Implementation Quality
- [ ] Production code satisfies spec intent (confirmed by spec-conformance review at step-6)
- [ ] DESIGN-REVIEWER: PASS

### Integration and Release Readiness
- [ ] Upstream sync validated post-sync
- [ ] Commit message documents WHY/WHAT/TESTING/ROADMAP
- [ ] Roadmap STATUS: COMPLETE with date
- [ ] Plan file: checklist complete with commit hash

### Deploy & Verify Readiness (for items that ship to a runtime)
For any item that deploys to a runtime (web app, API, service) — pure libraries are exempt and
end at DELIVERY. These are the DEPLOY and VERIFY station exit certificates (VALUE_FLOW §4):
- [ ] Gate was green **before** build; build succeeded **before** deploy (no station skipped)
- [ ] Artefact deployed; a live URL/endpoint exists
- [ ] **The verification matrix passes against the DEPLOYED artefact, not localhost** — the fixed
      `request → expected response` checklist run through the real interface in production
- [ ] Preview vs production handled correctly (auth-protected previews tested appropriately; the
      public production alias verified)

> The concrete verification matrix is stack-specific and lives with the owning stack skill
> (e.g. `skills/rust-webapp-rollout/` for Rust/WASM/Vercel). "It works on my machine" is not an
> exit certificate.

### Reviewer Gate Compliance
- [ ] Every generated/materially updated document reviewed
- [ ] All reviewer NEEDS_REVISION findings resolved or explicitly dispositioned
- [ ] Zero unresolved CRITICAL findings

### Handoff Contract Completeness
- [ ] Every stage has a valid, machine-readable handoff payload in the artifact trail

## If Any Gate Fails

1. Identify the owning stage for the failed gate.
2. Open iteration N+1 in the loop state.
3. Route to the owning stage with the specific gate failure as input.
4. Do NOT mark the item COMPLETE until all gates pass.

## Accepted Risk Disposition

If a gate cannot be fully satisfied (external constraint, deferral decision):
1. Document the specific risk and why it cannot be resolved now.
2. Get explicit orchestrator (or user) acknowledgment.
3. Record the accepted risk in the plan file's completion section.
4. Only then may the item be marked COMPLETE with an accepted-risk note.

## Handoff Target

Project closure — next roadmap pull from ROADMAPPER. DELIVER cost record appended.

## KAIZEN Covenant

This skill carries the KAIZEN self-improvement covenant. If the same DoD gate consistently fails across items, the failure is systemic — the gate's owning stage agent or skill needs strengthening. Surface recurring failures in the the self-improvement covenant ([`kaizen-covenant.md`](../../../knowledge/architecture/kaizen-covenant.md)) cycle with proposed fixes to the owning stage agent's KAIZEN Covenant section.
