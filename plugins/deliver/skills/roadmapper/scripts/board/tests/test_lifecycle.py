"""Pure-core tests for `board` Slice 1 (PLAN 0072.014) — lifecycle + EPIC rollup.

100% branch coverage of board/core/lifecycle.py is the FLOOR (the variable is density: happy /
unhappy / abuse). Each test traces to an EARS requirement via `# @EARS-NNN`.
"""
import subprocess
from pathlib import Path

import pytest

from board.core import lifecycle as lc
from board.core.errors import UnknownTransition

# ── EARS-001: transition → status mapping is total over the supported verbs ──────────────────────
@pytest.mark.parametrize("verb,status", [
    ("start", "In Progress"),
    ("review", "Review"),
    ("revise", "Revise"),
    ("done", "Done"),
    ("deliver", "Delivered"),
    ("ready", "To Do"),
])
def test_status_for_known_transitions(verb, status):  # @EARS-001
    assert lc.status_for(verb) == status


def test_status_for_unknown_transition_rejects():  # @EARS-008
    with pytest.raises(UnknownTransition):
        lc.status_for("frobnicate")


# ── EARS-010: the canonical list equals the bash _GHP_STATUS_OPTIONS (cross-language drift guard) ─
def _find_gh_pipeline() -> Path:
    """Locate the repo-root bash `gh-pipeline.sh` by walking up (robust to restructuring)."""
    for anc in Path(__file__).resolve().parents:
        cand = anc / "scripts" / "roadmap" / "gh-pipeline.sh"
        if cand.exists():
            return cand
    raise FileNotFoundError("scripts/roadmap/gh-pipeline.sh not found above the test file")


def test_canonical_list_matches_bash():  # @EARS-010
    ghp = _find_gh_pipeline()
    out = subprocess.run(
        ["bash", "-c", f'source "{ghp}" >/dev/null 2>&1; IFS="|"; echo "${{_GHP_STATUS_OPTIONS[*]}}"'],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    assert "|".join(lc.CANONICAL) == out


def test_is_terminal():  # @EARS-005
    assert lc.is_terminal("Done") and lc.is_terminal("Delivered")
    assert not lc.is_terminal("In Progress")
    assert not lc.is_terminal("Backlog")


def test_epic_of():
    assert lc.epic_of("0072.014") == "0072"
    assert lc.epic_of("0001.001") == "0001"


# ── EARS-005/006/009: rollup_status — one pinned coordinate per branch ───────────────────────────
def test_rollup_all_terminal_mixed_is_done():  # @EARS-005
    assert lc.rollup_status(["Done", "Delivered", "Done"], "In Progress") == "Done"


def test_rollup_all_delivered_is_delivered():  # @EARS-005
    assert lc.rollup_status(["Delivered", "Delivered"], "In Progress") == "Delivered"


def test_rollup_any_active_is_in_progress():  # @EARS-006
    assert lc.rollup_status(["In Progress", "Backlog"], "Backlog") == "In Progress"
    assert lc.rollup_status(["Review", "Done"], "Backlog") == "In Progress"
    assert lc.rollup_status(["Revise", "To Do"], "Backlog") == "In Progress"


def test_rollup_all_not_started_is_no_change():  # @EARS-006
    assert lc.rollup_status(["Backlog", "Backlog"], "Backlog") is None
    assert lc.rollup_status(["To Do", "To Do"], "Backlog") is None
    assert lc.rollup_status(["Backlog", "To Do"], "Backlog") is None


def test_rollup_empty_children_is_no_change():  # @EARS-009
    assert lc.rollup_status([], "In Progress") is None


def test_rollup_off_lifecycle_children_ignored():  # @EARS-009
    # a PARKED (or non-canonical) child is set aside — it neither forces nor blocks the parent
    assert lc.rollup_status(["Done", "Done", "PARKED"], "In Progress") == "Done"
    assert lc.rollup_status(["In Progress", "Frozen"], "Backlog") == "In Progress"
    # nothing on-lifecycle remains → no change
    assert lc.rollup_status(["PARKED", "PARKED"], "In Progress") is None


def test_rollup_parked_epic_never_unparked():  # @EARS-009 (the CRITICAL guard)
    assert lc.rollup_status(["In Progress", "Done"], "PARKED") is None
    assert lc.rollup_status(["Done", "Done"], "PARKED") is None


def test_rollup_unknown_current_status_no_change():  # @EARS-009
    assert lc.rollup_status(["In Progress"], "Frozen") is None


def test_rollup_terminal_epic_never_regresses():  # @EARS-009
    assert lc.rollup_status(["Done", "Done"], "Done") is None
    assert lc.rollup_status(["Delivered", "Delivered"], "Delivered") is None
    # a Done EPIC that would compute Delivered is still left alone (never auto-change a terminal EPIC)
    assert lc.rollup_status(["Delivered", "Delivered"], "Done") is None


def test_rollup_idempotent_target_equals_current():  # @EARS-004
    # already In Progress and children keep it In Progress → no needless write
    assert lc.rollup_status(["In Progress", "Backlog"], "In Progress") is None


# ── EARS-014: child_rollup_status — a CLOSED child's contribution distinguishes Delivered from Done ─
def test_child_rollup_closed_trusts_terminal_board_status():  # @EARS-014
    # the bug this fixes: a Delivered-closed child must contribute "Delivered", NOT be flattened to Done
    assert lc.child_rollup_status("CLOSED", "Delivered") == "Delivered"
    assert lc.child_rollup_status("CLOSED", "Done") == "Done"


def test_child_rollup_closed_non_terminal_board_falls_back_to_done():  # @EARS-014
    # a closed issue whose board Status is stale/non-terminal/unset is still at least Done
    assert lc.child_rollup_status("CLOSED", "In Progress") == "Done"
    assert lc.child_rollup_status("CLOSED", None) == "Done"
    assert lc.child_rollup_status("CLOSED", "") == "Done"


def test_child_rollup_open_contributes_live_board_status_or_omitted():  # @EARS-014
    assert lc.child_rollup_status("OPEN", "In Progress") == "In Progress"
    assert lc.child_rollup_status("OPEN", "Backlog") == "Backlog"
    assert lc.child_rollup_status("OPEN", None) is None   # unset ⇒ omitted from the rollup
    assert lc.child_rollup_status("OPEN", "") is None


def test_rollup_all_delivered_children_via_child_resolution():  # @EARS-005 (end-to-end of the fix)
    # feed rollup what child_rollup_status now yields for two Delivered-closed children → Delivered
    kids = [lc.child_rollup_status("CLOSED", "Delivered"), lc.child_rollup_status("CLOSED", "Delivered")]
    assert lc.rollup_status(kids, "In Progress") == "Delivered"
