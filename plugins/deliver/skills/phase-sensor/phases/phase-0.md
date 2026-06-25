NAME: deliver-plan
INSTALLS_SKILL: deliver-plan
PREREQUISITES:
- ROADMAP.md has at least one feature with STATUS: IN PROGRESS
- No plan file exists at the path in "Development Plan Reference"
QUALITY_GATE:
- Plan file exists and is non-empty
- Plan contains an implementation checklist with Steps 0-9
- Plan contains a Resumption section

---SKILL---
---
name: deliver-plan
description: >
  Write the DEV_SYSTEM Step 0 (Plan) document for an in-progress DELIVER feature.
  Auto-installed by phase-sensor when the plan file is absent.
---

# DELIVER-PLAN

You are writing the DEV_SYSTEM **Step 0 — Write the Plan** document for a DELIVER
feature. This is the single source of truth for the entire implementation.

## Steps

1. Read the IN PROGRESS feature entry from `ROADMAP.md`:
   - Title, entry number, EARS statements, user stories, acceptance criteria,
     implementation notes, and the "Development Plan Reference" path.

2. Write the plan file at the path specified in "Development Plan Reference".
   Structure it exactly as:

   ```
   # [FEATURE TITLE] — Implementation Plan
   > Feature: [N] Title
   > Date: YYYY-MM-DD
   > Status: IN PROGRESS

   ## Summary of EARS Specification
   | ID | Form | Requirement |

   ## Gherkin Scenarios Summary
   | Scenario | Path | EARS IDs |

   ## Files Created / Modified
   | File | Action | Rationale |

   ## Test Strategy
   Runner, file locations, approach, naming conventions.

   ## Known Risks
   Bullet list of risks and mitigations.

   ## Implementation Checklist
   - [ ] STEP 0 — Write this plan
   - [ ] STEP 1 — EARS specification
   - [ ] STEP 2 — Feature documentation (.feature files)
   - [ ] STEP 3 — Test code
   - [ ] STEP 4 — Run tests (confirm red)
   - [ ] STEP 5 — Implementation
   - [ ] STEP 6 — Run tests (drive to green)
   - [ ] STEP 7 — Sync with upstream
   - [ ] STEP 8 — Write commit message
   - [ ] STEP 9 — Commit and push

   ## Resumption
   Instructions explicit enough for a cold-start agent to continue mid-implementation.
   ```

3. Commit: `docs: write plan for feature [N] — step 0`

4. The phase sensor will detect the plan file on the next ROADMAP.md edit and install
   `deliver-ears` to guide Step 1.
