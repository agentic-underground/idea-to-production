"""Typed errors for the board core — never raise bare strings (test-policy §7)."""
from __future__ import annotations


class BoardError(Exception):
    """Base class for all board errors."""


class UnknownTransition(BoardError):
    """A transition verb with no canonical Status mapping (EARS-008)."""

    def __init__(self, transition: str) -> None:
        super().__init__(f"unknown transition verb: {transition!r}")
        self.transition = transition


class MalformedBoardData(BoardError):
    """A `gh` JSON payload could not be parsed — fail closed rather than guess (EARS-012)."""


class StatusOptionUnavailable(BoardError):
    """The board has no Status single-select option (or no Status field) for the requested value.

    An honest failure — never the silent stale-cache miss of 0072.013 (EARS-012).
    """


class IssueNotOnBoard(BoardError):
    """The target issue is not an item on the board, so its Status cannot be written (EARS-012)."""
