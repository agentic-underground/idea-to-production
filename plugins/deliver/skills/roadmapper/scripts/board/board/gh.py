"""Thin I/O shell for `board`.

Slice 1 (PLAN 0072.014): order→issue resolution (still via the proven `gh-pipeline.sh` readers) + one
read of children statuses. Slice 2 (PLAN 0072.015): the Status **write** is now NATIVE — `gh project
field-list`/`item-list` reads → `board.core.write` resolution → `gh project item-edit` — no bash. NO
decidable logic lives here (that is `board.core`): every branch below dispatches on a value the pure
core returned.

Injection-safe by construction: every command is an argument LIST (never `shell=True`, never string
interpolation), so untrusted values can't break out — the posture the bash layer established.
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

from .core import write
from .core.errors import BoardError


class BoardUnreachable(BoardError):
    """The board / `gh` could not be reached, or a verb failed (EARS-007) — fail closed."""


def _repo_root() -> Path:
    for anc in Path(__file__).resolve().parents:
        if (anc / "scripts" / "roadmap" / "gh-pipeline.sh").exists():
            return anc
    raise BoardUnreachable("scripts/roadmap/gh-pipeline.sh not found above board/")


def _ghp() -> Path:
    return _repo_root() / "scripts" / "roadmap" / "gh-pipeline.sh"


def _run(args: list[str]) -> str:
    """Run an argument-list command; return stripped stdout; raise BoardUnreachable on any failure.

    Bounded by a timeout so a hung `gh`/`bash` fails closed instead of hanging the CLI.
    """
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=60)
    except FileNotFoundError as e:
        raise BoardUnreachable(f"command not found: {args[0]}") from e
    except subprocess.TimeoutExpired as e:
        raise BoardUnreachable(f"`{' '.join(args[:3])}…` timed out") from e
    if r.returncode != 0:
        raise BoardUnreachable(f"`{' '.join(args[:3])}…` failed (rc={r.returncode}): {r.stderr.strip()}")
    return r.stdout.strip()


def _run_soft(args: list[str], what: str) -> bool:
    """Run a NON-fatal secondary step: warn and return False on any failure, never raise (EARS-013).

    Used for the issue open/closed lockstep AFTER the Status write has already succeeded — the primary
    value is persisted, so a failed close/reopen is a warning, not a command failure (matches the bash
    `set-status` rc contract).
    """
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=60)
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        print(f"board: warning: {what} not applied ({e})", file=sys.stderr)
        return False
    if r.returncode != 0:
        print(f"board: warning: {what} not applied (rc={r.returncode})", file=sys.stderr)
        return False
    return True


def plan_issue(order: str) -> str:
    """Resolve a PLAN order (NNNN.SSS) → issue# via the proven bash verb; fail closed if unresolved."""
    n = _run(["bash", str(_ghp()), "plan-issue", order])
    if not n:
        raise BoardUnreachable(f"PLAN {order} not resolvable on the board")
    return n


def epic_issue(order: str) -> str:
    """Resolve an EPIC order (NNNN) → issue# via the proven bash verb; fail closed if unresolved."""
    n = _run(["bash", str(_ghp()), "epic-issue", order])
    if not n:
        raise BoardUnreachable(f"EPIC {order} not resolvable on the board")
    return n


def _project_ref() -> tuple[str, str, str]:
    """(owner, project_number, project_id) for THIS repo's board, from the pipeline registry.

    `project_id` is the ProjectV2 node id (`PVT_…`) that `gh project item-edit` requires and that does
    NOT appear in the field-list / item-list payloads — a stable config value, not a resolution cache.
    """
    reg = Path.home() / ".claude" / "pipeline-projects.json"
    root = _repo_root()
    try:
        projects = json.loads(reg.read_text())["projects"]
    except (OSError, ValueError, KeyError) as e:
        raise BoardUnreachable(f"pipeline registry unreadable: {reg}") from e
    for p in projects.values():
        repo = p.get("repo")
        if repo and Path(repo).resolve() == root:
            num = p.get("project_number") or p.get("number")
            owner = p.get("project_owner") or p.get("owner")
            pid = p.get("project_id")
            if num and owner and pid:
                return str(owner), str(num), str(pid)
    raise BoardUnreachable(f"no complete pipeline-registry entry (owner/number/project_id) for {root}")


def _field_list_json(owner: str, number: str) -> str:
    """Raw `gh project field-list` JSON — resolved FRESH every write (the anti-stale-cache, EARS-011)."""
    return _run(["gh", "project", "field-list", number, "--owner", owner, "--format", "json", "--limit", "50"])


def _item_list_json(owner: str, number: str) -> str:
    """Raw `gh project item-list` JSON — the single fetch shape shared by the write + rollup reads."""
    return _run(["gh", "project", "item-list", number, "--owner", owner, "--format", "json", "--limit", "500"])


def set_status(issue: str, status: str) -> None:
    """Set an issue's board Status NATIVELY, then apply the issue open/closed lockstep (EARS-011/012/013).

    Fail-closed order (EARS-007): every resolution/read happens BEFORE the write, so an unreachable board
    or an absent option/off-board issue raises with NO write. Once `gh project item-edit` succeeds the
    Status is persisted; the close/reopen lockstep is a NON-fatal follow-up (`_run_soft`).
    """
    if shutil.which("gh") is None:
        raise BoardUnreachable("gh CLI required")
    owner, number, pid = _project_ref()
    field_id, option_id = write.select_status_option(_field_list_json(owner, number), status)
    item_id = write.select_item_id(_item_list_json(owner, number), issue)
    slug = _run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])
    # THE WRITE (native porcelain, argument-list): everything above must have succeeded first.
    _run(["gh", "project", "item-edit", "--id", item_id, "--field-id", field_id,
          "--project-id", pid, "--single-select-option-id", option_id])
    # Issue open/closed lockstep — the pure core decides; the shell only dispatches (EARS-013).
    # A terminal target returns "close" WITHOUT needing the live state, so we read state only otherwise.
    if write.issue_state_action(status, None) == "close":
        _run_soft(["gh", "issue", "close", issue, "--repo", slug], f"close #{issue}")
    else:
        state = _run(["gh", "issue", "view", issue, "--repo", slug, "--json", "state", "-q", ".state"])
        if write.issue_state_action(status, state) == "reopen":
            _run_soft(["gh", "issue", "reopen", issue, "--repo", slug], f"reopen #{issue}")


def board_statuses(epic_order: str) -> tuple[str, str | None, list[str]]:
    """Return ``(epic_issue#, epic_status, [child_status, ...])`` for an EPIC — one board read.

    `gh issue view <epic> --json subIssues` gives the children; `gh project item-list` gives every item's
    Status; we map issue# → Status. A CLOSED child is resolved (the reliable terminal signal, since its
    board Status can be stale); an OPEN child contributes its live board Status (unset ⇒ omitted). The
    resolved EPIC issue# is returned so callers need not re-resolve it.

    (Within a `lifecycle` run this item-list read follows `set_status`'s own — an accepted small redundancy;
    both use the shared `_item_list_json` shape. Not threaded through, to keep the write API a clean setter.)
    """
    if shutil.which("gh") is None:
        raise BoardUnreachable("gh CLI required")
    slug = _run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])
    epic_no = epic_issue(epic_order)
    sub = _run(["gh", "issue", "view", epic_no, "--repo", slug, "--json", "subIssues"])
    nodes = json.loads(sub).get("subIssues", {}).get("nodes", [])
    owner, number, _ = _project_ref()
    items = _item_list_json(owner, number)
    status_by_issue: dict[str, str] = {}
    for it in json.loads(items).get("items", []):
        num = (it.get("content") or {}).get("number")
        if num is not None:
            status_by_issue[str(num)] = it.get("status") or ""
    children: list[str] = []
    for n in nodes:
        num = n.get("number")
        if num is None:
            continue
        if n.get("state") == "CLOSED":
            children.append("Done")
        elif status_by_issue.get(str(num)):
            children.append(status_by_issue[str(num)])
    epic_status = status_by_issue.get(epic_no) or None
    return epic_no, epic_status, children
