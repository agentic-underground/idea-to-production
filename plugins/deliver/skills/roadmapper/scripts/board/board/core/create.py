"""Pure create/converge decisions for `board` Slice 3a (PLAN 0072.017) — native `ensure-epic`.

No I/O. Turns an EPIC order + desc into the marker/title/body the create needs, parses the issue-search
payload for the idempotency marker, maps a kind to Type+label, and — the heart — decides the ordered
CONVERGE actions the shell executes. Keeping that heal decision here (not in the untested `gh.py`) is
the fable-review fix that puts the F0 class (permanent-UNSET) under the 100% branch floor. Every branch
is pinned by tests/test_create.py; see doc/spec/EARS.md (EARS-015…018).
"""
from __future__ import annotations

import json
import re

from .errors import MalformedBoardData, MalformedOrder

#: Converge action tokens the shell dispatches on (opaque to the core; order is significant).
CREATE = "create"                  # create the issue bare (body = desc + marker)
BOARD_ADD_SEED = "board_add_seed"  # add to the board AND seed Backlog on the item-add-returned id
SEED = "seed"                      # seed Backlog on an already-on-board item whose Status is UNSET
SET_KIND = "set_kind"              # best-effort Type + label (never fails the verb)

_EPIC_ORDER = re.compile(r"^[0-9]{1,4}$")
_MARKER = re.compile(r"<!--\s*pipeline-(?:epic|plan)-[^>]*-->")

_KIND_TYPE = {"bug": "Bug", "feature": "Feature", "enhancement": "Feature", "task": "Task"}
_KIND_LABEL = {"bug": "bug", "enhancement": "enhancement"}


def norm_epic_order(raw: str) -> str:
    """Normalise an EPIC order to 4 digits (``"3"`` → ``"0003"``); reject non-1–4-digit (EARS-018).

    No whitespace tolerance — byte-exact with the bash ``_ghp_norm_order`` (which does not strip).
    """
    s = raw or ""
    if not _EPIC_ORDER.match(s):
        raise MalformedOrder(f"EPIC order must be 1–4 digits (got {raw!r})")
    return s.zfill(4)


def epic_marker(order: str) -> str:
    """The byte-exact EPIC idempotency marker (matches bash ``_ghp_epic_marker``)."""
    return f"<!-- pipeline-epic-{order} -->"


def epic_title(order: str, desc: str) -> str:
    """The EPIC issue title (matches bash ``_ghp_epic_title``)."""
    return f"EPIC {order}: {desc}"


def scrub_markers(text: str) -> str:
    """Strip any pipeline-marker HTML comment from caller text — body is DATA, never a marker source."""
    return _MARKER.sub("", text)


def compose_body(desc: str, marker: str) -> str:
    """The create body: the scrubbed desc, then the real marker (so a spoofed marker can't survive)."""
    return f"{scrub_markers(desc)}\n\n{marker}"


def issue_number_with_marker(issues_json: str, marker: str) -> str | None:
    """Return the number of the first issue whose body carries ``marker``, else ``None`` (EARS-015).

    Pure parse of a JSON array of ``{number, body}`` issue objects; malformed JSON ⇒ fail closed
    (``MalformedBoardData``) rather than be mistaken for "absent" (which would duplicate the EPIC).
    """
    try:
        issues = json.loads(issues_json)
    except (json.JSONDecodeError, TypeError) as e:
        raise MalformedBoardData(f"could not parse issues JSON: {e}") from None
    for issue in issues:
        if marker in (issue.get("body") or ""):
            return str(issue["number"])
    return None


def find_item(items_json: str, issue_no: str) -> tuple[str | None, str | None]:
    """Parse the item-list → ``(item_id, status)`` for an issue#, or ``(None, None)`` if not on the board.

    A non-raising lookup (unlike ``write.select_item_id``) — it supplies the reducer's ``on_board`` /
    ``status_is_set`` inputs (EARS-017) and the item id the SEED heal writes to. Draft items (no
    ``content``) are skipped. Malformed JSON ⇒ fail closed (``MalformedBoardData``).
    """
    try:
        data = json.loads(items_json)
    except (json.JSONDecodeError, TypeError) as e:
        raise MalformedBoardData(f"could not parse items JSON: {e}") from None
    items = data.get("items", []) if isinstance(data, dict) else data
    target = int(issue_no)
    for item in items:
        content = item.get("content") or {}
        if content.get("number") == target:
            return item.get("id"), (item.get("status") or None)
    return None, None


def kind_type(kind: str) -> str:
    """Native GitHub issue Type for a kind, or ``""`` for an unknown kind (best-effort — shell warns)."""
    return _KIND_TYPE.get(kind, "")


def kind_label(kind: str) -> str:
    """Repo label for a kind, or ``""`` when the kind needs none (feature/task) or is unknown."""
    return _KIND_LABEL.get(kind, "")


def ensure_epic_actions(found_issue: str | None, on_board: bool, status_is_set: bool) -> list[str]:
    """The converge reducer (EARS-017) — total over ``(found_issue, on_board, status_is_set)``.

    Absent ⇒ create, board+seed, kind. Present ⇒ HEAL: board+seed if off the board, else seed if on the
    board but Status UNSET (the repair the bash lacked — closes F0), and always (idempotently) re-apply
    the kind. ``on_board``/``status_is_set`` are consulted only when the issue already exists.
    """
    if found_issue is None:
        return [CREATE, BOARD_ADD_SEED, SET_KIND]
    actions: list[str] = []
    if not on_board:
        actions.append(BOARD_ADD_SEED)
    elif not status_is_set:
        actions.append(SEED)
    actions.append(SET_KIND)
    return actions
