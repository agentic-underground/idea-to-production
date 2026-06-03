@EARS-009 @EARS-010 @EARS-011 @EARS-012 @EARS-013
Feature: DEV_SYSTEM Phase Sensor
  The phase sensor detects the current DEV_SYSTEM step for an in-progress Forge
  feature by examining existing artifacts, evaluates prerequisites for the next step,
  and installs the appropriate skills and agents when those prerequisites are met.

  Background:
    Given the Forge is installed at "~/.claude"
    And "ROADMAP.md" exists at the repository root
    And "cache/phase-sensor.log" is writable

  @EARS-009 @EARS-010 @EARS-011
  Scenario: Happy path — feature at Phase 0, plan file missing → install forge-plan skill
    Given feature [1] has "STATUS: IN PROGRESS" in ROADMAP.md
    And no plan file exists at "doc/FORGE_AUTO_SYNC_PLAN.md"
    And no EARS IDs exist in "doc/SPECIFICATION.ears.md" for feature [1]
    When the phase sensor runs
    Then it identifies the current phase as Phase 0 (Write the Plan)
    And it installs or updates "skills/forge-plan/SKILL.md" in the repository
    And it commits the installed skill with message "skill: install forge-plan for phase 0"

  @EARS-009 @EARS-010 @EARS-011
  Scenario: Happy path — plan exists, EARS missing → install forge-ears skill
    Given feature [1] has "STATUS: IN PROGRESS" in ROADMAP.md
    And "doc/FORGE_AUTO_SYNC_PLAN.md" exists and is non-empty
    And no EARS IDs exist in "doc/SPECIFICATION.ears.md" for feature [1]
    When the phase sensor runs
    Then it identifies the current phase as Phase 1 (EARS Specification)
    And it installs or updates "skills/forge-ears/SKILL.md"
    And it commits the installed skill with message "skill: install forge-ears for phase 1"

  @EARS-009 @EARS-010 @EARS-011
  Scenario: Happy path — EARS complete, .feature missing → install forge-feature skill
    Given feature [1] has "STATUS: IN PROGRESS" in ROADMAP.md
    And all user stories for feature [1] are covered by EARS IDs in the specification
    And no ".feature" file exists referencing those EARS IDs
    When the phase sensor runs
    Then it identifies the current phase as Phase 2 (Feature Documentation)
    And it installs or updates "skills/forge-feature/SKILL.md"

  @EARS-009 @EARS-010 @EARS-011
  Scenario: Happy path — .feature exists, no tests → install forge-test skill
    Given a ".feature" file exists for feature [1] with scenarios covering happy, unhappy, and abuse paths
    And no test file exists in "tests/" referencing those scenarios
    When the phase sensor runs
    Then it identifies the current phase as Phase 3 (Test Code)
    And it installs or updates "skills/forge-test/SKILL.md"

  @EARS-009 @EARS-010 @EARS-011
  Scenario: Happy path — tests exist, no implementation → install forge-implement skill
    Given test files exist in "tests/" for feature [1]
    And the implementation file "forge-sync.sh" does not exist
    When the phase sensor runs
    Then it identifies the current phase as Phase 5 (Implementation)
    And it installs or updates "skills/forge-implement/SKILL.md"

  @EARS-012
  Scenario: Phase transition logging
    Given the phase sensor runs and detects a transition from Phase 1 to Phase 2
    Then "cache/phase-sensor.log" contains an entry with:
      | field           | value                          |
      | timestamp       | current date-time              |
      | feature         | [1] Forge Auto-Sync            |
      | current_phase   | 1                              |
      | next_phase      | 2                              |
      | prerequisites   | comma-separated list of checks |
      | artifacts       | list of installed files        |

  @EARS-013
  Scenario: Unhappy path — unsatisfied prerequisite, user prompted
    Given a prerequisite for Phase 2 is "all EARS IDs assigned"
    And EARS-005 has no ID assigned in the specification
    When the phase sensor runs
    Then it does not install any new skills or agents
    And it outputs: "Unsatisfied prerequisite: EARS-005 has no unique identifier assigned"
    And it exits with a non-zero status code
    And the repository is unchanged

  @EARS-013
  Scenario: Abuse path — ROADMAP.md has no IN PROGRESS features
    Given all features in ROADMAP.md have status PENDING or COMPLETE
    When the phase sensor runs
    Then it outputs: "No features currently IN PROGRESS — nothing to evaluate"
    And it exits with status 0
    And the repository is unchanged
