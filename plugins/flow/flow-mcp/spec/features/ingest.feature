# Covers: EARS-FLOW-077 .. EARS-FLOW-087 (startup sequence, config flags, tree vs single-file ingest,
#         graceful degradation, parser tolerance).

Feature: Startup, configuration and roadmap ingest

  # --- config ---

  @EARS-FLOW-079
  Scenario: default data dir and the --mcp no-op
    When the server starts with no flags
    Then the data directory is ".flow"
    And the "--mcp" flag is accepted as a no-op

  @EARS-FLOW-080
  Scenario: a known flag without a value is a configuration error
    When the server starts with args "--roadmap"
    Then startup fails with a missing-value error naming "--roadmap"

  @EARS-FLOW-081
  Scenario: an unknown flag is a configuration error
    When the server starts with args "--nope x"
    Then startup fails with an unknown-flag error

  # --- tree ingest (happy) ---

  @EARS-FLOW-083
  Scenario: a directory source is ingested as a file-per-item tree, folder = status
    Given a roadmap tree with:
      | folder  | id | title  | depends_on |
      | backlog | 16 | Epic   | —          |
      | doing   | 42 | Tree   | #16        |
      | done    | 1  | First  | —          |
    When the server starts with that tree as the roadmap source
    Then item "item-16" has status "do"
    And item "item-42" has status "doing"
    And item "item-1" has status "done"
    And the dependency "item-42" -> "item-16" exists

  @EARS-FLOW-082
  Scenario: with no --roadmap, the .i2p/roadmap tree in the cwd is ingested
    Given a ".i2p/roadmap" tree exists in the working directory with item 5 "Five" in folder "do"
    When the server starts with no roadmap flag
    Then item "item-5" is on the board

  # --- single-file ingest (happy) ---

  @EARS-FLOW-084
  Scenario: a file source is parsed as the legacy ROADMAP.md
    Given a ROADMAP.md file containing:
      """
      ## [1] Flow server
      > STATUS: IN PROGRESS
      > DEPENDS ON: —

      ## [2] Canvas
      > STATUS: PENDING
      > DEPENDS ON: #1
      """
    When the server starts with that file as the roadmap source
    Then item "item-1" has status "doing"
    And item "item-2" has status "do"
    And the dependency "item-2" -> "item-1" exists

  # --- startup ordering ---

  @EARS-FLOW-077 @EARS-FLOW-078
  Scenario: startup is ingest then replay, so a runtime WAIT survives a restart
    Given a roadmap tree with item 1 "Alpha" in folder "do"
    And item "item-1" was set to WAIT in a previous run (a gate_set event is in the log)
    When the server starts with that tree as the roadmap source (ingest then replay)
    Then item "item-1" has gate "wait"

  # --- graceful degradation (unhappy) ---

  @EARS-FLOW-085
  Scenario: no roadmap source starts an empty board with a diagnostic
    When the server starts with no roadmap source available
    Then the board is empty
    And a diagnostic was emitted to stderr
    And the server is healthy

  # --- parser tolerance (abuse) ---

  @EARS-FLOW-086
  Scenario: a cyclic or dangling declared dependency is skipped but the items still load
    Given a ROADMAP.md file declaring item 1 depends on #2 and item 2 depends on #1
    When the server starts with that file as the roadmap source
    Then items "item-1" and "item-2" are on the board
    And at most one of the cyclic edges was kept

  @EARS-FLOW-087
  Scenario: duplicate ids, self-edges, placeholders and garbage are tolerated
    Given a ROADMAP.md file with a duplicate "## [1]" heading, a "DEPENDS ON: #1" self-edge, a "—" placeholder, and garbage lines
    When the server starts with that file as the roadmap source
    Then exactly one item "item-1" exists with the last title and status
    And item "item-1" has no self-edge
