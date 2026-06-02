NAME: forge-ears
INSTALLS_SKILL: forge-ears
PREREQUISITES:
- Plan file exists and is non-empty
- doc/SPECIFICATION.ears.md exists
- No EARS IDs (### EARS-NNN) present for this feature
QUALITY_GATE:
- All user stories from the feature entry have corresponding EARS IDs
- Every EARS statement uses SHALL/SHOULD/MAY and covers exactly one behaviour
- No "and" within a single EARS statement (split into two if needed)
- Every EARS ID is unique within the specification

---SKILL---
---
name: forge-ears
description: >
  Write EARS specifications for an in-progress Forge feature.
  Auto-installed by phase-sensor when EARS IDs are absent from SPECIFICATION.ears.md.
---

# FORGE-EARS

You are writing the DEV_SYSTEM **Step 1 — EARS Specification** for a Forge feature.

## Steps

1. Read the IN PROGRESS feature entry from `ROADMAP.md`: user stories, acceptance
   criteria, and the existing EARS statements in the entry itself.

2. Read `doc/SPECIFICATION.ears.md`. Note the highest existing EARS-NNN number so
   you can assign the next sequential IDs.

3. For each user story and acceptance criterion, write one or more EARS statements
   using the correct form:

   | Form | Keyword | Template |
   |------|---------|----------|
   | Ubiquitous | (none) | The system SHALL `<response>`. |
   | Event-driven | WHEN | WHEN `<trigger>` THE SYSTEM SHALL `<response>`. |
   | Unwanted behaviour | IF | IF `<condition>` THEN THE SYSTEM SHALL `<safeguard>`. |
   | State-driven | WHILE | WHILE `<state>` THE SYSTEM SHALL `<behaviour>`. |
   | Optional feature | WHERE | WHERE `<feature>` THE SYSTEM SHALL `<behaviour>`. |

4. Write each statement as a `### EARS-NNN` section in `doc/SPECIFICATION.ears.md`.

5. Rules:
   - One behaviour per statement. Split on "and".
   - Use SHALL (mandatory), SHOULD (recommended), MAY (optional) deliberately.
   - Every ID must be unique across the entire file.

6. Commit: `docs: add EARS specification for feature [N] — step 1`

7. The phase sensor will detect the new EARS IDs and install `forge-feature` for Step 2.
