"""Pure-core tests for `board` Slice 2 (PLAN 0072.015) — the native Status-write selectors.

100% branch coverage of board/core/write.py is the FLOOR (the variable is density: happy / unhappy /
abuse). Each test traces to an EARS requirement via `# @EARS-NNN`. Fixtures mirror the live shapes of
`gh project field-list --format json` and `gh project item-list --format json` (probed 2026-08-13).
"""
import json

import pytest

from board.core import write as w
from board.core.errors import IssueNotOnBoard, MalformedBoardData, StatusOptionUnavailable

# ── fixtures: faithful to the live `gh` JSON shapes ──────────────────────────────────────────────
FIELDS = json.dumps({
    "fields": [
        {"id": "PVTF_title", "name": "Title", "type": "ProjectV2Field"},
        {"id": "PVTSSF_status", "name": "Status", "type": "ProjectV2SingleSelectField", "options": [
            {"id": "619419be", "name": "Backlog"},
            {"id": "46376e36", "name": "To Do"},
            {"id": "04617ecc", "name": "In Progress"},
            {"id": "707695c2", "name": "Review"},
            {"id": "b5834fe6", "name": "Done"},
        ]},
    ],
    "totalCount": 2,
})
FIELDS_NO_STATUS = json.dumps({"fields": [{"id": "x", "name": "Title", "type": "ProjectV2Field"}], "totalCount": 1})

ITEMS = json.dumps({
    "items": [
        {"id": "PVTI_a", "content": {"number": 378, "title": "PLAN 0072.015"}, "status": "Backlog"},
        {"id": "PVTI_b", "content": {"number": 337, "title": "EPIC 0072"}, "status": "In Progress"},
        {"id": "PVTI_draft", "status": "Backlog"},  # a draft item has no `content` — must be skipped
    ],
    "totalCount": 3,
})


# ── EARS-011: select_status_option resolves (field_id, option_id) from a fresh field-list ─────────
def test_select_status_option_happy():  # @EARS-011
    assert w.select_status_option(FIELDS, "Done") == ("PVTSSF_status", "b5834fe6")
    assert w.select_status_option(FIELDS, "Backlog") == ("PVTSSF_status", "619419be")


def test_select_status_option_absent_option_fails_closed():  # @EARS-012
    # `Delivered` is a real canonical status but absent from THIS board — must refuse, not guess.
    with pytest.raises(StatusOptionUnavailable):
        w.select_status_option(FIELDS, "Delivered")


def test_select_status_option_absent_status_field_fails_closed():  # @EARS-012
    with pytest.raises(StatusOptionUnavailable):
        w.select_status_option(FIELDS_NO_STATUS, "Done")


def test_select_status_option_malformed_json_fails_closed():  # @EARS-012
    with pytest.raises(MalformedBoardData):
        w.select_status_option("not json {", "Done")


# ── EARS-011: select_item_id resolves an issue# → board item node id ──────────────────────────────
def test_select_item_id_happy():  # @EARS-011
    assert w.select_item_id(ITEMS, "378") == "PVTI_a"
    assert w.select_item_id(ITEMS, "337") == "PVTI_b"


def test_select_item_id_off_board_fails_closed():  # @EARS-012
    with pytest.raises(IssueNotOnBoard):
        w.select_item_id(ITEMS, "999")


def test_select_item_id_malformed_json_fails_closed():  # @EARS-012
    with pytest.raises(MalformedBoardData):
        w.select_item_id("]not json", "378")


# ── EARS-013: issue_state_action — total decision over (target_status, issue_state) ───────────────
def test_issue_state_action_terminal_closes_without_reading_state():  # @EARS-002 / @EARS-013
    # a terminal target closes regardless of (and without needing) the current issue state
    assert w.issue_state_action("Done", None) == "close"
    assert w.issue_state_action("Delivered", "OPEN") == "close"


def test_issue_state_action_out_of_terminal_while_closed_reopens():  # @EARS-003 / @EARS-013
    assert w.issue_state_action("In Progress", "CLOSED") == "reopen"


def test_issue_state_action_non_terminal_open_is_noop():  # @EARS-013
    assert w.issue_state_action("In Progress", "OPEN") is None
    assert w.issue_state_action("Review", None) is None
