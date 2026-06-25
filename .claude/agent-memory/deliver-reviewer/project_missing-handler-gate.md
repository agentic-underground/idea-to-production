---
name: missing-handler-gate
description: PR #114 missing-handler pause-and-decide gate (#23-26); handler-build pipeline location + the AC1 "referenced by pipeline" trap
metadata:
  type: project
---

Stream 4 tail of epic #93 shipped the missing-handler **pause-and-decide gate** (cards #23/#24/#25/#26, branch `feat/missing-handler-gate`).

**Why:** old behaviour silently routed a missing VALUE_HANDLER to the nearest one → a DEGRADED build the human never chose. Now Phase 4.5 PAUSEs and surfaces a 3-way gate (BUILD HANDLER FIRST · MVP+DEGRADED_CAPABILITIES · BOTH).

**How to apply / load-bearing facts when reviewing this area:**
- Governing one-copy protocol: `plugins/deliver/knowledge/orchestration/missing-handler-gate.md`; authoring discipline (pinned matrix + FORBIDDEN list + KAIZEN + four-wave pipeline): `handler-authoring-discipline.md` (same dir). Both referenced from `builder-lead.md` Phase 4.5 (~L206) and `builder/SKILL.md` §8 (~L437) + §17 reference table.
- **`docs/internal/handler-build/` DOES exist** (rust-tauri / github-actions / docx / roadmap-decomposition knowledge files) — a subagent claimed it was absent; it is not. Card #24 calls THIS dir "the handler-build pipeline."
- **AC1-of-#25 trap:** "referenced by the handler-build pipeline" is only half-met. The discipline doc is referenced by the gate doc + builder/SKILL.md (the BUILD path) and by `rust-webapp-rollout/references/00-MANIFEST.md` — but NOT by anything under `docs/internal/handler-build/` (the dir the card itself names as the pipeline). The item test masks this by asserting the MANIFEST counts as "the pipeline." Forward-wiring from the real pipeline dir is the gap.
- roadmapper §11.6 RESUME and §11.7 DEFER/RESTORE both genuinely exist (card #26 reuse is faithful). `/mission-control:gemba` exists. `handler-rust-tauri.md` exists. All new-doc relative links resolve; verify-prereqs §I = exit 0.
- Residual LOW: Phase 4.5 section header still says "run these detect-and-degrade checks" (L196) while the body reframes to detect-and-**decide** (L216) — heading/body tension, not an AC contradiction; the handler bullet is unambiguous PAUSE.
