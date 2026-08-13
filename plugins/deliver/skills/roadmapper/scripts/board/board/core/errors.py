"""Typed errors for the board core — never raise bare strings (test-policy §7)."""
from __future__ import annotations


class BoardError(Exception):
    """Base class for all board errors."""


class UnknownTransition(BoardError):
    """A transition verb with no canonical Status mapping (EARS-008)."""

    def __init__(self, transition: str) -> None:
        super().__init__(f"unknown transition verb: {transition!r}")
        self.transition = transition
