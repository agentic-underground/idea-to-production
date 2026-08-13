"""Pure-core tests for `board` Slice 3a (PLAN 0072.017) — native `ensure-epic` create/converge.

100% branch coverage of board/core/create.py is the FLOOR. Each test traces to an EARS requirement via
`# @EARS-NNN`. The converge reducer `ensure_epic_actions` is the star: its branchy heal decision lives
HERE (pure, pinned) rather than in the untested shell — the fable-review fix that keeps the F0 class
(permanent-UNSET) under the coverage floor.
"""
import json

import pytest

from board.core import create as cr
from board.core.errors import MalformedBoardData, MalformedOrder


# ── EARS-018: order normalisation (1–4 digits → 4-pad; else fail closed) ──────────────────────────
def test_norm_epic_order_pads():  # @EARS-018
    assert cr.norm_epic_order("3") == "0003"
    assert cr.norm_epic_order("0068") == "0068"
    assert cr.norm_epic_order("18") == "0018"


@pytest.mark.parametrize("bad", ["3.1", "abc", "12345", "", "0072.1"])
def test_norm_epic_order_rejects(bad):  # @EARS-018
    with pytest.raises(MalformedOrder):
        cr.norm_epic_order(bad)


# ── EARS-015/016: marker + title + body composition (byte-exact vs bash) ──────────────────────────
def test_epic_marker_and_title():  # @EARS-015
    assert cr.epic_marker("0072") == "<!-- pipeline-epic-0072 -->"
    assert cr.epic_title("0068", "GitHub integration") == "EPIC 0068: GitHub integration"


def test_scrub_markers_strips_spoofed_pipeline_comments():  # @EARS-016
    assert cr.scrub_markers("hi <!-- pipeline-epic-0001 --> there") == "hi  there"
    assert cr.scrub_markers("<!-- pipeline-plan-0001.002 -->x") == "x"
    assert cr.scrub_markers("clean text") == "clean text"


def test_compose_body_appends_marker_and_scrubs_desc():  # @EARS-016
    assert cr.compose_body("desc", "<!-- pipeline-epic-0072 -->") == "desc\n\n<!-- pipeline-epic-0072 -->"
    # a desc that tries to smuggle another item's marker is scrubbed before the real marker is appended
    assert cr.compose_body("evil <!-- pipeline-epic-9999 --> d", "<!-- pipeline-epic-0072 -->") \
        == "evil  d\n\n<!-- pipeline-epic-0072 -->"


# ── EARS-015: marker-in-body idempotency search (pure parse of the issues payload) ────────────────
_ISSUES = json.dumps([
    {"number": 337, "body": "EPIC 0072 …\n<!-- pipeline-epic-0072 -->"},
    {"number": 100, "body": "an issue with no marker"},
    {"number": 50, "body": None},   # a body can be null — must not crash
])


def test_issue_number_with_marker_hit():  # @EARS-015
    assert cr.issue_number_with_marker(_ISSUES, "<!-- pipeline-epic-0072 -->") == "337"


def test_issue_number_with_marker_miss_is_none():  # @EARS-015
    assert cr.issue_number_with_marker(_ISSUES, "<!-- pipeline-epic-9999 -->") is None


def test_issue_number_with_marker_malformed_fails_closed():  # @EARS-018
    with pytest.raises(MalformedBoardData):
        cr.issue_number_with_marker("}not json", "<!-- pipeline-epic-0072 -->")


# ── EARS-017: find_item — the non-raising (item_id, status) lookup feeding the reducer ────────────
_ITEMS = json.dumps({"items": [
    {"id": "PVTI_a", "content": {"number": 337}, "status": "In Progress"},
    {"id": "PVTI_b", "content": {"number": 400}, "status": ""},          # on board but UNSET
    {"id": "PVTI_draft", "status": "Backlog"},                            # draft, no content — skipped
]})


def test_find_item_on_board_with_status():  # @EARS-017
    assert cr.find_item(_ITEMS, "337") == ("PVTI_a", "In Progress")


def test_find_item_on_board_unset_status():  # @EARS-017
    assert cr.find_item(_ITEMS, "400") == ("PVTI_b", None)   # "" status ⇒ UNSET (None)


def test_find_item_off_board():  # @EARS-017
    assert cr.find_item(_ITEMS, "999") == (None, None)


def test_find_item_malformed_fails_closed():  # @EARS-018
    with pytest.raises(MalformedBoardData):
        cr.find_item("]nope", "337")


# ── EARS-016: kind → Type + label mapping (best-effort; unknown ⇒ empty, never raises) ────────────
@pytest.mark.parametrize("kind,typ,label", [
    ("bug", "Bug", "bug"),
    ("feature", "Feature", ""),
    ("enhancement", "Feature", "enhancement"),
    ("task", "Task", ""),
    ("zzz", "", ""),   # unknown kind ⇒ empty (the shell warns + skips; verb still succeeds)
])
def test_kind_mapping(kind, typ, label):  # @EARS-016
    assert cr.kind_type(kind) == typ
    assert cr.kind_label(kind) == label


# ── EARS-017: the converge reducer — total over (found_issue, on_board, status_is_set) ────────────
def test_actions_absent_creates_boards_seeds_kinds():  # @EARS-016
    assert cr.ensure_epic_actions(None, False, False) == [cr.CREATE, cr.BOARD_ADD_SEED, cr.SET_KIND]
    # when not found, on_board/status_is_set are irrelevant — still the full create list
    assert cr.ensure_epic_actions(None, True, True) == [cr.CREATE, cr.BOARD_ADD_SEED, cr.SET_KIND]


def test_actions_found_off_board_heals_add_and_seed():  # @EARS-017 (the F0 heal)
    assert cr.ensure_epic_actions("337", False, False) == [cr.BOARD_ADD_SEED, cr.SET_KIND]


def test_actions_found_on_board_unset_heals_seed():  # @EARS-017 (the F0 heal)
    assert cr.ensure_epic_actions("337", True, False) == [cr.SEED, cr.SET_KIND]


def test_actions_found_on_board_set_is_kind_only():  # @EARS-017
    assert cr.ensure_epic_actions("337", True, True) == [cr.SET_KIND]
