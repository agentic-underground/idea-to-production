@EARS-001 @EARS-002 @EARS-004 @EARS-006 @EARS-008
Feature: Forge Auto-Sync with Conflict Resolution
  The forge-sync.sh script is the authoritative sync mechanism for ~/.claude.
  It is invoked by the Claude Code Stop hook and is responsible for keeping the
  Forge repository in sync with its git origin, resolving conflicts automatically.

  Background:
    Given the Forge is installed at "~/.claude"
    And the git remote "origin" points to "git.local:~/DotClaude"
    And "cache/forge-sync.log" is writable

  @EARS-001 @EARS-002 @EARS-004 @EARS-006 @EARS-008
  Scenario: Happy path — fast-forward sync on session stop
    Given origin has 2 new commits not present locally
    And the local repository has no uncommitted changes and no unpushed commits
    When the Claude Code session stops
    Then forge-sync.sh is executed
    And git fetches from origin
    And the repository is fast-forwarded to match origin without a merge commit
    And the fast-forwarded state is pushed to origin
    And "cache/forge-sync.log" contains a success entry with a timestamp

  @EARS-001 @EARS-006 @EARS-008
  Scenario: Happy path — local commits pushed when origin is behind
    Given the local repository has 1 unpushed commit
    And origin has no new commits
    When forge-sync.sh runs
    Then git fetches from origin
    And the local commit is pushed to origin
    And "cache/forge-sync.log" contains a success entry

  @EARS-003
  Scenario: Unhappy path — skip sync during in-progress rebase
    Given the file ".git/rebase-merge" exists in the repository
    When forge-sync.sh runs
    Then the sync is skipped entirely
    And "cache/forge-sync.log" contains an entry matching "mid-operation state"
    And the repository contents are unchanged

  @EARS-003
  Scenario: Unhappy path — skip sync during in-progress merge
    Given the file ".git/MERGE_HEAD" exists in the repository
    When forge-sync.sh runs
    Then the sync is skipped entirely
    And "cache/forge-sync.log" contains an entry matching "mid-operation state"

  @EARS-005 @EARS-006 @EARS-008
  Scenario: Unhappy path — conflict resolved by accepting incoming version
    Given origin has modified "settings.json" adding a new permission entry
    And the local repository has also modified "settings.json" with a different permission
    When forge-sync.sh runs
    Then a conflict is detected in "settings.json"
    And the conflict is resolved using origin's version of "settings.json"
    And a merge commit is created recording the auto-resolution
    And the resolved state is pushed to origin
    And "cache/forge-sync.log" contains an entry listing "settings.json" as conflicted

  @EARS-007 @EARS-008
  Scenario: Abuse path — remote unreachable
    Given the git remote "origin" is not reachable (network timeout)
    When forge-sync.sh runs
    Then the script exits with a non-zero status code
    And "cache/forge-sync.log" contains a failure entry
    And the local repository is in a clean state (no partial merge, no rebase in progress)

  @EARS-007 @EARS-008
  Scenario: Abuse path — push rejected (non-fast-forward after successful pull)
    Given forge-sync.sh has successfully merged local and origin commits
    And the push to origin is rejected with "non-fast-forward"
    When forge-sync.sh attempts to push
    Then the script exits with a non-zero status code
    And "cache/forge-sync.log" contains a failure entry mentioning the push rejection
    And the local repository reflects the merged state (pull succeeded, push failed)
