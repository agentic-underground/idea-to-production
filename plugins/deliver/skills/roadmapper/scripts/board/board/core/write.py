"""Pure resolution for the native Status write — `board` Slice 2 (PLAN 0072.015).

No I/O. These functions turn the RAW JSON of `gh project field-list` / `gh project item-list` into the
ids the native write needs (`gh project item-edit --field-id … --single-select-option-id … --id …`),
and decide the issue open/closed lockstep. Every branch is pinned by a test in tests/test_write.py; see
doc/spec/EARS.md (EARS-011/012/013).

Resolving fresh from a live payload each call is deliberate: it designs out the stale-cache bug class
of 0072.013 — a board option added later is simply present in the next read, and a genuinely absent
option fails closed HONESTLY (StatusOptionUnavailable) instead of silently.
"""
from __future__ import annotations

import json
from typing import Any

from .errors import IssueNotOnBoard, MalformedBoardData, StatusOptionUnavailable
from .lifecycle import is_terminal

_STATUS_FIELD = "Status"


def _loads(raw: str) -> Any:
    """Parse a `gh` JSON payload; fail closed (MalformedBoardData) rather than guess (EARS-012)."""
    try:
        return json.loads(raw)
    except (json.JSONDecodeError, TypeError) as e:
        raise MalformedBoardData(f"could not parse board JSON: {e}") from None


def select_status_option(fields_json: str, status: str) -> tuple[str, str]:
    """Resolve ``(status_field_id, option_id)`` for a Status NAME from a fresh `field-list` (EARS-011).

    Fails closed (StatusOptionUnavailable) if the board has no Status field, or no option with that name
    — never the silent stale-cache miss of 0072.013 (EARS-012).
    """
    data = _loads(fields_json)
    fields = data.get("fields", []) if isinstance(data, dict) else data
    for field in fields:
        if field.get("name") == _STATUS_FIELD:
            for opt in field.get("options", []):
                if opt.get("name") == status:
                    return field["id"], opt["id"]
            raise StatusOptionUnavailable(
                f"no Status option {status!r} on the board (fresh field-list); add it via the web UI"
            )
    raise StatusOptionUnavailable("board has no Status single-select field")


def select_item_id(items_json: str, issue_no: str) -> str:
    """Resolve an issue# → its board item node id (``PVTI_…``) from a fresh `item-list` (EARS-011).

    Fails closed (IssueNotOnBoard) if the issue is not an item on the board. Draft items (no `content`)
    are skipped.
    """
    data = _loads(items_json)
    items = data.get("items", []) if isinstance(data, dict) else data
    target = int(issue_no)
    for item in items:
        content = item.get("content") or {}
        if content.get("number") == target:
            return item["id"]
    raise IssueNotOnBoard(f"issue #{issue_no} is not an item on the board")


def issue_state_action(target_status: str, issue_state: str | None) -> str | None:
    """The open/closed lockstep decision (EARS-002/003/013) — pure, total over the inputs.

    Terminal target ⇒ ``"close"`` (the current `issue_state` is NOT consulted, so the shell need not read
    it on this branch). Non-terminal target ⇒ ``"reopen"`` iff the issue is ``"CLOSED"``, else ``None``.
    """
    if is_terminal(target_status):
        return "close"
    if issue_state == "CLOSED":
        return "reopen"
    return None
