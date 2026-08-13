"""Thin I/O shell for `board` (PLAN 0072.014) — subprocess to the proven `gh-pipeline.sh` verbs plus
one read of children statuses. NO decidable logic lives here (that is `board.core`).

Injection-safe by construction: every command is an argument LIST (never `shell=True`, never string
interpolation), so untrusted values can't break out — the posture the bash layer established.
"""
from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

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
    """Run an argument-list command; return stripped stdout; raise BoardUnreachable on any failure."""
    try:
        r = subprocess.run(args, capture_output=True, text=True)
    except FileNotFoundError as e:
        raise BoardUnreachable(f"command not found: {args[0]}") from e
    if r.returncode != 0:
        raise BoardUnreachable(f"`{' '.join(args[:3])}…` failed (rc={r.returncode}): {r.stderr.strip()}")
    return r.stdout.strip()


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


def set_status(issue: str, status: str) -> None:
    """Set an issue's board Status (+ the proven close/reopen lockstep) via the bash verb."""
    _run(["bash", str(_ghp()), "set-status", issue, status])


def _project_ref() -> tuple[str, str]:
    """(owner, project_number) for THIS repo's board, from the pipeline registry (match repo→git root)."""
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
            if num and owner:
                return str(owner), str(num)
    raise BoardUnreachable(f"no pipeline-registry entry for {root}")


def board_statuses(epic_order: str) -> tuple[str | None, list[str]]:
    """Return ``(epic_status, [child_status, ...])`` for an EPIC — one board read, no bespoke GraphQL.

    `gh issue view <epic> --json subIssues` gives the child issue#s; `gh project item-list` gives every
    item's Status; we map issue# → Status. Children with no board Status (unset) are omitted.
    """
    if shutil.which("gh") is None:
        raise BoardUnreachable("gh CLI required")
    slug = _run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])
    epic_no = epic_issue(epic_order)
    sub = _run(["gh", "issue", "view", epic_no, "--repo", slug, "--json", "subIssues"])
    nodes = json.loads(sub).get("subIssues", {}).get("nodes", [])
    owner, number = _project_ref()
    items = _run(["gh", "project", "item-list", number, "--owner", owner, "--format", "json", "--limit", "500"])
    status_by_issue: dict[str, str] = {}
    for it in json.loads(items).get("items", []):
        num = (it.get("content") or {}).get("number")
        if num is not None:
            status_by_issue[str(num)] = it.get("status") or ""
    # A CLOSED child is resolved (Done or superseded) — the reliable terminal signal, since its board
    # Status can be stale. An OPEN child contributes its (live) board Status; unset ⇒ omitted.
    children: list[str] = []
    for n in nodes:
        if n.get("state") == "CLOSED":
            children.append("Done")
        else:
            s = status_by_issue.get(str(n["number"]))
            if s:
                children.append(s)
    epic_status = status_by_issue.get(epic_no) or None
    return epic_status, children
