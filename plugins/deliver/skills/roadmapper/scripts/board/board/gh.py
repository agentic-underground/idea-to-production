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
import re
import shutil
import subprocess
import sys
from pathlib import Path

from .core import create, lifecycle, write
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


def _run(args: list[str], stdin: str | None = None) -> str:
    """Run an argument-list command; return stripped stdout; raise BoardUnreachable on any failure.

    Bounded by a timeout so a hung `gh`/`bash` fails closed instead of hanging the CLI. `stdin` feeds the
    process's standard input (e.g. an issue body via `--body-file -`).
    """
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=60, input=stdin)
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


def _repo_slug() -> str:
    """`owner/name` for the current repo."""
    return _run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])


def _issues_with_body_json() -> str:
    """All repo issues (a single flat JSON array of full objects) — the marker-search payload (EARS-015).

    `gh api --paginate` (NO `--slurp`, which can't combine with a downstream parser) concatenates every
    page into one array. FAIL-CLOSED via `_run`: a read error raises rather than yielding "" — so a failed
    read is NEVER mistaken for "marker absent" (which would duplicate the EPIC — EARS-018).
    """
    return _run(["gh", "api", "--paginate", f"repos/{_repo_slug()}/issues?state=all&per_page=100"])


def _write_status_option(owner: str, number: str, pid: str, item_id: str, status: str) -> None:
    """Resolve the Status field/option FRESH and write it to a KNOWN item id (EARS-011).

    Shared by `set_status` (which resolves the item from an issue# first) and the create-path Backlog seed
    (which passes the `item-add`-returned id directly — no re-query, dodging the F0 propagation race).
    """
    field_id, option_id = write.select_status_option(_field_list_json(owner, number), status)
    _run(["gh", "project", "item-edit", "--id", item_id, "--field-id", field_id,
          "--project-id", pid, "--single-select-option-id", option_id])


def set_status(issue: str, status: str) -> None:
    """Set an issue's board Status NATIVELY, then apply the issue open/closed lockstep (EARS-011/012/013).

    Fail-closed order (EARS-007): every resolution/read happens BEFORE the write, so an unreachable board
    or an absent option/off-board issue raises with NO write. Once `gh project item-edit` succeeds the
    Status is persisted; the close/reopen lockstep is a NON-fatal follow-up (`_run_soft`).
    """
    if shutil.which("gh") is None:
        raise BoardUnreachable("gh CLI required")
    owner, number, pid = _project_ref()
    item_id = write.select_item_id(_item_list_json(owner, number), issue)
    slug = _repo_slug()                          # resolved BEFORE the write (behaviour-identical to pre-refactor)
    _write_status_option(owner, number, pid, item_id, status)
    # Issue open/closed lockstep — the pure core decides; the shell only dispatches (EARS-013).
    # A terminal target returns "close" WITHOUT needing the live state, so we read state only otherwise.
    if write.issue_state_action(status, None) == "close":
        _run_soft(["gh", "issue", "close", issue, "--repo", slug], f"close #{issue}")
    else:
        state = _run(["gh", "issue", "view", issue, "--repo", slug, "--json", "state", "-q", ".state"])
        if write.issue_state_action(status, state) == "reopen":
            _run_soft(["gh", "issue", "reopen", issue, "--repo", slug], f"reopen #{issue}")


def ensure_epic(order: str, desc: str, kind: str = "feature") -> str:
    """Create-or-converge an EPIC issue natively, marker-idempotent + converge-correct (EARS-015…018).

    The pure core decides; this shell only executes the ordered action list. Fail-closed: the marker
    search (`_issues_with_body_json`) raises on a read error, so a fresh EPIC is never duplicated. Echoes
    the issue number.

    Known limitation (shared with bash `_ghp_issue_by_marker`): the `gh api issues` list is eventually
    consistent (~3s), so a re-run within that window of a create could duplicate. Real crash→re-run timing
    is well outside it (EARS-015).
    """
    if shutil.which("gh") is None:
        raise BoardUnreachable("gh CLI required")
    order = create.norm_epic_order(order)                      # MalformedOrder on a bad order (EARS-018)
    owner, number, pid = _project_ref()
    slug = _repo_slug()
    marker = create.epic_marker(order)
    found = create.issue_number_with_marker(_issues_with_body_json(), marker)
    item_id, status = create.find_item(_item_list_json(owner, number), found) if found else (None, None)
    actions = create.ensure_epic_actions(found, item_id is not None, status is not None)
    ctx = {
        "owner": owner, "number": number, "pid": pid, "slug": slug, "kind": kind,
        "issue": found, "item_id": item_id, "epic_no": None,
        "create_argv": ["gh", "issue", "create", "--repo", slug,
                        "--title", create.epic_title(order, desc), "--body-file", "-"],
        "body": create.compose_body(desc, marker),
    }
    for action in actions:
        _execute_action(action, ctx)
    return ctx["issue"] or ""


def _execute_action(action: str, ctx: dict) -> None:
    """Execute one converge action against a mutable context — shared by `ensure_epic`/`ensure_plan` so the
    item-add+seed / kind / link steps live in ONE place (no drift). `CREATE` sets `ctx["issue"]`."""
    if action == create.CREATE:
        ctx["issue"] = _parse_issue_number(_run(ctx["create_argv"], stdin=ctx["body"]))
    elif action == create.LINK_PARENT:
        # heal a MISSING sub-issue link — NON-fatal (warn), so a permission failure never aborts the
        # board/seed heal that follows (EARS-020, matching bash `_ghp_link_subissue` warn contract).
        _run_soft(["gh", "issue", "edit", ctx["issue"], "--repo", ctx["slug"], "--parent", ctx["epic_no"]],
                  f"link #{ctx['issue']} → parent #{ctx['epic_no']}")
    elif action == create.BOARD_ADD_SEED:
        url = f"https://github.com/{ctx['slug']}/issues/{ctx['issue']}"
        added = _run(["gh", "project", "item-add", ctx["number"], "--owner", ctx["owner"],
                      "--url", url, "--format", "json"])
        new_item = json.loads(added).get("id")
        if new_item:
            _write_status_option(ctx["owner"], ctx["number"], ctx["pid"], new_item, "Backlog")
    elif action == create.SEED:
        if ctx["item_id"]:
            _write_status_option(ctx["owner"], ctx["number"], ctx["pid"], ctx["item_id"], "Backlog")
    elif action == create.SET_KIND:
        _apply_kind(ctx["slug"], ctx["issue"], ctx["kind"])


def ensure_plan(epic_no: str, order: str, desc: str, kind: str = "feature") -> str:
    """Create-or-converge a PLAN sub-issue under an EPIC, marker-idempotent + converge-correct (EARS-019…022).

    Same shape as `ensure_epic` plus the parent-link dimension: `gh issue create --parent` at create (NOT
    atomic — a half-failed link is recovered by the next converge), and a MISSING link is healed via
    `gh issue edit --parent`. A PLAN already owned by a DIFFERENT EPIC is left alone (warn, never stolen).
    """
    if shutil.which("gh") is None:
        raise BoardUnreachable("gh CLI required")
    epic_no = create.norm_issue_number(epic_no)                # EARS-022 (canonical, so the ==check is stable)
    order = create.norm_plan_order(order)
    owner, number, pid = _project_ref()
    slug = _repo_slug()
    marker = create.plan_marker(order)
    found = create.issue_number_with_marker(_issues_with_body_json(), marker)
    item_id, status = create.find_item(_item_list_json(owner, number), found) if found else (None, None)
    parent = create.parent_number(_run(["gh", "issue", "view", found, "--repo", slug, "--json", "parent"])) if found else None
    dec = create.link_decision(parent, epic_no)
    if dec == "skip":
        print(f"board: warning: #{found} is a sub-issue of a DIFFERENT EPIC (#{parent}) — not repointing to #{epic_no}",
              file=sys.stderr)
    actions = create.ensure_plan_actions(found, item_id is not None, status is not None, dec == "link")
    ctx = {
        "owner": owner, "number": number, "pid": pid, "slug": slug, "kind": kind,
        "issue": found, "item_id": item_id, "epic_no": epic_no,
        "create_argv": ["gh", "issue", "create", "--repo", slug, "--title", create.plan_title(order, desc),
                        "--body-file", "-", "--parent", epic_no],
        "body": create.compose_body(desc, marker),
    }
    for action in actions:
        _execute_action(action, ctx)
    return ctx["issue"] or ""


def next_plan(epic_no: str) -> str:
    """The next free PLAN order (``NNNN.SSS``) under an EPIC — from its title + child titles (EARS-021)."""
    epic_no = create.norm_issue_number(epic_no)
    slug = _repo_slug()
    data = json.loads(_run(["gh", "issue", "view", epic_no, "--repo", slug, "--json", "title,subIssues"]))
    epic_order = create.epic_order_from_title(data.get("title") or "")
    if not epic_order:
        raise BoardUnreachable(f"could not derive an EPIC order from #{epic_no}'s title (EARS-022)")
    titles = [n.get("title") or "" for n in (data.get("subIssues") or {}).get("nodes", [])]
    return create.next_plan_order(epic_order, titles)


def _apply_kind(slug: str, issue: str, kind: str) -> None:
    """Best-effort Type + label (EARS-016) — a non-org repo / missing label warns, never fails the verb."""
    typ, label = create.kind_type(kind), create.kind_label(kind)
    if typ:
        _run_soft(["gh", "issue", "edit", issue, "--repo", slug, "--type", typ], f"#{issue} Type={typ}")
    if label:
        _run_soft(["gh", "issue", "edit", issue, "--repo", slug, "--add-label", label], f"#{issue} label={label}")
    if not typ:
        print(f"board: warning: unknown kind {kind!r} — Type/label not applied", file=sys.stderr)


def _parse_issue_number(create_out: str) -> str:
    """Extract the issue number from `gh issue create` output (the created issue URL)."""
    m = re.search(r"/issues/(\d+)", create_out)
    if not m:
        raise BoardUnreachable(f"could not parse created issue number from: {create_out!r}")
    return m.group(1)


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
        # the pure core decides a child's contribution — a CLOSED child trusts a terminal board Status
        # (so Delivered is not flattened to Done), else falls back to Done; an OPEN child's status, or omit
        cs = lifecycle.child_rollup_status(n.get("state") or "", status_by_issue.get(str(num)))
        if cs:
            children.append(cs)
    epic_status = status_by_issue.get(epic_no) or None
    return epic_no, epic_status, children
