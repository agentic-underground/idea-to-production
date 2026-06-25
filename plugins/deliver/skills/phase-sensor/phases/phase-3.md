NAME: deliver-test
INSTALLS_SKILL: deliver-test
PREREQUISITES:
- .feature file(s) exist in doc/features/
- No test file exists in tests/ for this feature
QUALITY_GATE:
- Tests cover happy, unhappy, and abuse paths from the .feature file
- Each test references the EARS ID(s) it satisfies in a comment
- Tests are validated against the spec before running (no implementation yet)
- Tests are red (failing) when run because the feature is not yet implemented

---SKILL---
---
name: deliver-test
description: >
  Write bats tests for an in-progress DELIVER feature.
  Auto-installed by phase-sensor when .feature files exist but no tests do.
---

# DELIVER-TEST

You are writing the DEV_SYSTEM **Step 3 — Test Code** for a DELIVER feature.

## Steps

1. Read `doc/features/<feature>.feature` for the Gherkin scenarios.
2. Read `doc/SPECIFICATION.ears.md` for the EARS IDs.
3. Read the plan file for test strategy (runner, file locations, naming).

4. Write `tests/test-<feature-name>.bats` using bats-core:

   ```bash
   #!/usr/bin/env bats
   # Tests for <script-name>
   # EARS: NNN, NNN, NNN
   # Runner: bats-core — bats tests/test-<name>.bats

   load helpers/git-fixture   # or a project-specific fixture as appropriate

   SCRIPT="$BATS_TEST_DIRNAME/../<path-to-script>"

   setup()    { fixture_setup;    export HOME="$LOCAL_REPO"; }
   teardown() { fixture_teardown; }

   # --- EARS-NNN ---
   @test "happy: <scenario name>" {
       # Arrange
       # Act
       run bash "$SCRIPT"
       # Assert
       [ "$status" -eq 0 ]
       ...
   }

   @test "unhappy: <scenario name>" { ... }
   @test "abuse: <scenario name>"   { ... }
   ```

5. Validate every test against the spec before running:
   - Does each assertion match the EARS statement it references?
   - Is the scenario path (happy/unhappy/abuse) correct?
   Fix mismatches now, before running.

6. Commit: `tests: add bats tests for feature [N] — step 3`

7. Run tests to confirm they are RED (feature not yet implemented):
   `bats tests/test-<name>.bats`
   If any test passes unexpectedly, investigate before proceeding.

8. The phase sensor will detect the test file and install `deliver-implement` for Step 5.
