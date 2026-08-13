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
LINK_PARENT = "link_parent"        # heal a MISSING sub-issue→EPIC link (Slice 4; non-fatal)

_EPIC_ORDER = re.compile(r"^[0-9]{1,4}$")
_PLAN_ORDER = re.compile(r"^([0-9]{1,4})\.([0-9]{1,3})$")
_ISSUE_NO = re.compile(r"^[0-9]+$")
_FOUR = re.compile(r"[0-9]{4}")                 # first 4-digit run in an EPIC title (SUBSTRING, bash parity)
_PLAN_SSS = re.compile(r"PLAN [0-9]{4}\.([0-9]{3})")  # SUBSTRING match of a child PLAN order's SSS
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


# ── Slice 4 (PLAN 0072.018): ensure-plan + next-plan ──────────────────────────────────────────────
def norm_plan_order(raw: str) -> str:
    """Normalise a PLAN order to ``NNNN.SSS`` (``"68.1"`` → ``"0068.001"``); reject other (EARS-022).

    Byte-exact with the bash ``_ghp_norm_plan_order`` (regex ``^[0-9]{1,4}\\.[0-9]{1,3}$`` → ``%04d.%03d``).
    """
    m = _PLAN_ORDER.match(raw or "")
    if not m:
        raise MalformedOrder(f"PLAN order must be NNNN.SSS (got {raw!r})")
    return f"{int(m.group(1)):04d}.{int(m.group(2)):03d}"


def norm_issue_number(raw: str) -> str:
    """Canonicalise a GitHub issue number (``"0337"`` → ``"337"``); reject non-numeric (EARS-022).

    Canonical form makes the parent-link comparison stable (``"0337"`` ≡ ``"337"``) so a correctly-linked
    PLAN never triggers a needless re-link loop.
    """
    s = raw or ""
    if not _ISSUE_NO.match(s):
        raise MalformedOrder(f"issue number must be digits (got {raw!r})")
    return str(int(s))


def plan_marker(order: str) -> str:
    """The byte-exact PLAN idempotency marker (matches bash ``_ghp_plan_marker``)."""
    return f"<!-- pipeline-plan-{order} -->"


def plan_title(order: str, desc: str) -> str:
    """The PLAN issue title (matches bash ``_ghp_plan_title``)."""
    return f"PLAN {order}: {desc}"


def epic_order_from_title(title: str) -> str | None:
    """The EPIC's 4-digit order — the first 4-digit run anywhere in the title, or ``None`` (EARS-021)."""
    m = _FOUR.search(title or "")
    return m.group(0) if m else None


def next_plan_order(epic_order: str, subissue_titles: list[str]) -> str:
    """The next free ``NNNN.SSS`` under an EPIC = max child ``SSS`` + 1, or ``.001`` if none (EARS-021).

    ``SSS`` is matched as a SUBSTRING of each child title (``PLAN NNNN.SSS`` may appear mid-title), matching
    the bash ``cmd_next_plan`` grep — a full-match port would miss populated EPICs and mint colliding orders.
    """
    hi = 0
    for title in subissue_titles:
        for sss in _PLAN_SSS.findall(title):
            hi = max(hi, int(sss))
    return f"{epic_order}.{hi + 1:03d}"


def parent_number(parent_json: str) -> str | None:
    """Parse ``gh issue view --json parent`` → the parent issue# (canonical str), or ``None`` if unlinked."""
    try:
        data = json.loads(parent_json)
    except (json.JSONDecodeError, TypeError) as e:
        raise MalformedBoardData(f"could not parse parent JSON: {e}") from None
    parent = data.get("parent") or {}
    num = parent.get("number")
    return norm_issue_number(str(num)) if num is not None else None


def link_decision(parent_no: str | None, epic_no: str) -> str:
    """Decide the sub-issue link action (EARS-020): ``link`` (unlinked → heal), ``ok`` (already this EPIC),
    or ``skip`` (owned by a DIFFERENT EPIC — the caller warns and MUST NOT repoint/steal it)."""
    if parent_no is None:
        return "link"
    return "ok" if norm_issue_number(parent_no) == norm_issue_number(epic_no) else "skip"


def ensure_plan_actions(found_issue: str | None, on_board: bool, status_is_set: bool, needs_link: bool) -> list[str]:
    """The PLAN converge reducer (EARS-019/020) — total over the four inputs; extends the EPIC reducer with
    a ``LINK_PARENT`` heal. ``found_issue is None`` ⇒ the other inputs are ignored (a fresh create)."""
    if found_issue is None:
        return [CREATE, BOARD_ADD_SEED, SET_KIND]
    actions: list[str] = []
    if needs_link:
        actions.append(LINK_PARENT)
    if not on_board:
        actions.append(BOARD_ADD_SEED)
    elif not status_is_set:
        actions.append(SEED)
    actions.append(SET_KIND)
    return actions
