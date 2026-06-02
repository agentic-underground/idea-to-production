NAME: forge-feature
INSTALLS_SKILL: forge-feature
PREREQUISITES:
- EARS IDs exist in doc/SPECIFICATION.ears.md
- doc/features/ directory exists
- No .feature file references those EARS IDs
QUALITY_GATE:
- Every EARS ID is referenced by at least one scenario tag
- Scenarios cover happy path, unhappy path, and abuse/adversarial path
- Scenarios are written before test code (this step comes first)

---SKILL---
---
name: forge-feature
description: >
  Write Gherkin .feature files for an in-progress Forge feature.
  Auto-installed by phase-sensor when no .feature file exists.
---

# FORGE-FEATURE

You are writing the DEV_SYSTEM **Step 2 — Feature Documentation** for a Forge feature.

## Steps

1. Read the IN PROGRESS feature entry from `ROADMAP.md` and the EARS IDs from
   `doc/SPECIFICATION.ears.md`.

2. Create or update a `.feature` file in `doc/features/`. Name it after the feature
   (e.g. `forge-sync.feature`, `phase-sensor.feature`).

3. Write Gherkin scenarios covering all three paths:

   ```gherkin
   @EARS-NNN @EARS-NNN
   Feature: <Feature Title>
     <one-line description>

     Background:
       Given <shared preconditions>

     @EARS-NNN
     Scenario: Happy path — <normal case>
       Given <preconditions>
       When  <action>
       Then  <expected outcome>

     @EARS-NNN
     Scenario: Unhappy path — <error/edge case>
       ...

     @EARS-NNN
     Scenario: Abuse path — <adversarial/boundary case>
       ...
   ```

4. Rules:
   - Tag every scenario with the EARS IDs it satisfies.
   - Each scenario is independent and complete on its own.
   - Use the Background block for shared Given steps.
   - Write scenarios as the human-readable contract; do not reference implementation.

5. Commit: `docs: add feature scenarios for feature [N] — step 2`

6. The phase sensor will detect the `.feature` file and install `forge-test` for Step 3.
