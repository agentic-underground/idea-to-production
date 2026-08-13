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


# ══════════════════════════════════════════════════════════════════════════════════════════════════
# Slice 4 (PLAN 0072.018) — ensure-plan + next-plan
# ══════════════════════════════════════════════════════════════════════════════════════════════════

# ── EARS-022: plan-order + issue-number normalisation ─────────────────────────────────────────────
def test_norm_plan_order_pads_and_keeps():  # @EARS-022
    assert cr.norm_plan_order("68.1") == "0068.001"
    assert cr.norm_plan_order("0068.002") == "0068.002"


@pytest.mark.parametrize("bad", ["0068", "0068.", "abc", "12345.1", "0068.1234", "0068.1.2", ""])
def test_norm_plan_order_rejects(bad):  # @EARS-022
    with pytest.raises(MalformedOrder):
        cr.norm_plan_order(bad)


def test_norm_issue_number_canonicalises():  # @EARS-022
    assert cr.norm_issue_number("337") == "337"
    assert cr.norm_issue_number("0337") == "337"   # zero-pad canonicalised (no re-link loop)
    assert cr.norm_issue_number("7") == "7"


@pytest.mark.parametrize("bad", ["abc", "", "3.1", "-5", "12a"])
def test_norm_issue_number_rejects(bad):  # @EARS-022
    with pytest.raises(MalformedOrder):
        cr.norm_issue_number(bad)


# ── EARS-019: plan marker + title (byte-exact vs bash) ────────────────────────────────────────────
def test_plan_marker_and_title():  # @EARS-019
    assert cr.plan_marker("0072.018") == "<!-- pipeline-plan-0072.018 -->"
    assert cr.plan_title("0068.002", "A1") == "PLAN 0068.002: A1"


# ── EARS-021: epic order from title + next_plan_order (SUBSTRING; the collision-avoidance fix) ─────
def test_epic_order_from_title():  # @EARS-021
    assert cr.epic_order_from_title("EPIC 0072: Board Information-Surface") == "0072"
    assert cr.epic_order_from_title("some wrapped title (PLAN 0072.002)") == "0072"  # mid-title 4-digit run
    assert cr.epic_order_from_title("no digits at all here") is None


def test_next_plan_order_empty_is_001():  # @EARS-021
    assert cr.next_plan_order("0072", []) == "0072.001"
    assert cr.next_plan_order("0072", ["EPIC 0072: parent", "a random note"]) == "0072.001"  # non-PLAN ignored


def test_next_plan_order_single_and_multi():  # @EARS-021
    assert cr.next_plan_order("0072", ["PLAN 0072.001: x"]) == "0072.002"
    assert cr.next_plan_order("0072", ["PLAN 0072.001: x", "PLAN 0072.002: y"]) == "0072.003"


def test_next_plan_order_gap_is_max_plus_one():  # @EARS-021
    assert cr.next_plan_order("0072", ["PLAN 0072.001: x", "PLAN 0072.003: y"]) == "0072.004"


def test_next_plan_order_substring_token_mid_title():  # @EARS-021 (the fullmatch trap)
    assert cr.next_plan_order("0072", ["chore: wrap up (PLAN 0072.014) done"]) == "0072.015"


# ── EARS-020: parent_number + link_decision (do-not-steal) + the reducer ──────────────────────────
def test_parent_number_linked_null_malformed():  # @EARS-020
    assert cr.parent_number('{"parent": {"number": 337}}') == "337"
    assert cr.parent_number('{"parent": null}') is None
    with pytest.raises(MalformedBoardData):
        cr.parent_number("}nope")


def test_link_decision_link_ok_skip():  # @EARS-020 (never steal a different-EPIC child)
    assert cr.link_decision(None, "337") == "link"       # unlinked → heal
    assert cr.link_decision("337", "337") == "ok"         # already correct
    assert cr.link_decision("0337", "337") == "ok"        # canonicalised, no needless re-link
    assert cr.link_decision("400", "337") == "skip"       # owned by a DIFFERENT EPIC → warn, don't repoint


def test_plan_actions_absent_creates():  # @EARS-019
    assert cr.ensure_plan_actions(None, False, False, False) == [cr.CREATE, cr.BOARD_ADD_SEED, cr.SET_KIND]
    # found None ⇒ the other inputs are irrelevant
    assert cr.ensure_plan_actions(None, True, True, True) == [cr.CREATE, cr.BOARD_ADD_SEED, cr.SET_KIND]


def test_plan_actions_found_needs_link_variants():  # @EARS-020
    assert cr.ensure_plan_actions("391", False, False, True) == [cr.LINK_PARENT, cr.BOARD_ADD_SEED, cr.SET_KIND]
    assert cr.ensure_plan_actions("391", True, False, True) == [cr.LINK_PARENT, cr.SEED, cr.SET_KIND]
    assert cr.ensure_plan_actions("391", True, True, True) == [cr.LINK_PARENT, cr.SET_KIND]


def test_plan_actions_found_no_link_variants():  # @EARS-020
    assert cr.ensure_plan_actions("391", True, True, False) == [cr.SET_KIND]
    assert cr.ensure_plan_actions("391", False, False, False) == [cr.BOARD_ADD_SEED, cr.SET_KIND]
    assert cr.ensure_plan_actions("391", True, False, False) == [cr.SEED, cr.SET_KIND]
