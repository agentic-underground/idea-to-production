"""Pure lifecycle + rollup decisions for `board` Slice 1 (PLAN 0072.014).

No I/O. Every branch is pinned by a test in tests/test_lifecycle.py; see doc/spec/EARS.md. The
canonical Status list is kept byte-identical to the bash `_GHP_STATUS_OPTIONS` (EARS-010, asserted
across languages in the test suite).
"""
from __future__ import annotations

from .errors import UnknownTransition

#: The canonical board Status lifecycle — MUST equal bash `_GHP_STATUS_OPTIONS` (EARS-010).
CANONICAL: list[str] = ["Backlog", "To Do", "In Progress", "Review", "Revise", "Done", "Delivered"]

_TERMINAL = frozenset({"Done", "Delivered"})   # a terminal Status closes the issue
_NOT_STARTED = frozenset({"Backlog", "To Do"})  # "ready but not started" — the human §11.4a gesture

_TRANSITIONS = {
    "start": "In Progress",
    "review": "Review",
    "revise": "Revise",
    "done": "Done",
    "deliver": "Delivered",
    "ready": "To Do",
}


def status_for(transition: str) -> str:
    """Map a transition verb to its canonical Status; reject an unknown verb (EARS-001/008)."""
    try:
        return _TRANSITIONS[transition]
    except KeyError:
        raise UnknownTransition(transition) from None


def is_terminal(status: str) -> bool:
    """True iff `status` is a terminal (issue-closing) state (EARS-005)."""
    return status in _TERMINAL


def epic_of(plan_order: str) -> str:
    """The parent EPIC order (``NNNN``) of a PLAN order (``NNNN.SSS``)."""
    return plan_order.split(".", 1)[0]


def rollup_status(children: list[str], current_epic: str) -> str | None:
    """Compute an EPIC's target Status from its children's statuses, or ``None`` for "no change".

    The corrected decision table (EARS-005/006/009); guards come first so a parked or completed EPIC
    is never disturbed:

    1. current is off-lifecycle (PARKED / non-canonical) or already terminal -> None
    2. off-lifecycle children (PARKED / non-canonical) are IGNORED — a parked plan is set aside and
       must not force or block the parent; if nothing on-lifecycle remains -> None
    3. all considered children terminal -> Delivered iff every one Delivered, else Done
    4. none started (all Backlog/To Do) -> None
    5. otherwise (>=1 active child) -> In Progress
    6. computed target equals current -> None (idempotent)
    """
    if current_epic not in CANONICAL or is_terminal(current_epic):
        return None
    considered = [c for c in children if c in CANONICAL]
    if not considered:
        return None
    if all(is_terminal(c) for c in considered):
        target = "Delivered" if all(c == "Delivered" for c in considered) else "Done"
    elif all(c in _NOT_STARTED for c in considered):
        return None
    else:
        target = "In Progress"
    return target if target != current_epic else None
