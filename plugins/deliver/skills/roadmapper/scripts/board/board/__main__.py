"""CLI for `board` — ``python3 -m board <verb>`` (PLAN 0072.014).

Verbs:
  lifecycle  <plan-order> <transition>  set a PLAN's status (+ lockstep) then roll its parent EPIC
  rollup     <epic-order>               recompute + apply an EPIC's status from its children
  set-status <issue#> <Status>          set an issue's Status natively (+ lockstep), NO rollup — the
                                        raw/manual escape hatch (e.g. EPIC promote); the order-addressed
                                        `lifecycle` verb is what always rolls the parent.
  ensure-epic <order> <desc> [kind]     create-or-converge an EPIC issue (marker-idempotent, heals board
                                        membership + Backlog seed on re-run); echoes the issue number.

Fails closed (non-zero, no partial write) on an unreachable board, an unresolvable/malformed order, or
an unknown transition verb.
"""
from __future__ import annotations

import argparse
import sys

from . import gh
from .core import lifecycle as lc
from .core.errors import BoardError


def _apply_rollup(epic_order: str) -> None:
    epic_no, epic_status, children = gh.board_statuses(epic_order)
    target = lc.rollup_status(children, epic_status or "")
    if target is None:
        print(f"EPIC {epic_order}: no rollup change (current={epic_status!r}, children={children})")
        return
    gh.set_status(epic_no, target)
    print(f"EPIC {epic_order} (#{epic_no}) rolled → {target}")


def _lifecycle(order: str, transition: str) -> int:
    status = lc.status_for(transition)          # UnknownTransition on a bad verb (EARS-008)
    issue = gh.plan_issue(order)                 # order→issue, fail closed (rejects an issue# via grammar)
    gh.set_status(issue, status)
    print(f"PLAN {order} (#{issue}) → {status}")
    _apply_rollup(lc.epic_of(order))
    return 0


def _rollup(epic_order: str) -> int:
    _apply_rollup(epic_order)
    return 0


def _set_status(issue: str, status: str) -> int:
    gh.set_status(issue, status)                 # native write + lockstep; fail closed on any resolution miss
    print(f"#{issue} → {status}")
    return 0


def _ensure_epic(order: str, desc: str, kind: str) -> int:
    issue = gh.ensure_epic(order, desc, kind)    # create-or-converge, marker-idempotent (EARS-015…018)
    print(issue)                                  # echo the issue# (callers capture it, like the bash verb)
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="board", description="GitHub Project board integration (lifecycle + rollup)")
    sub = p.add_subparsers(dest="cmd", required=True)
    lp = sub.add_parser("lifecycle", help="transition a PLAN and roll its parent EPIC")
    lp.add_argument("order", help="PLAN order, e.g. 0072.014")
    lp.add_argument("transition", help="start | review | revise | done | deliver | ready")
    rp = sub.add_parser("rollup", help="recompute + apply an EPIC's status from its children")
    rp.add_argument("epic_order", help="EPIC order, e.g. 0072")
    sp = sub.add_parser("set-status", help="set an issue's Status natively (+ lockstep), no rollup")
    sp.add_argument("issue", help="GitHub issue number, e.g. 378")
    sp.add_argument("status", help="canonical Status, e.g. 'In Progress'")
    ep = sub.add_parser("ensure-epic", help="create-or-converge an EPIC issue (marker-idempotent)")
    ep.add_argument("order", help="EPIC order, e.g. 0072")
    ep.add_argument("desc", help="short description")
    ep.add_argument("kind", nargs="?", default="feature", help="bug | feature | enhancement | task")
    args = p.parse_args(argv)
    try:
        if args.cmd == "lifecycle":
            return _lifecycle(args.order, args.transition)
        if args.cmd == "set-status":
            return _set_status(args.issue, args.status)
        if args.cmd == "ensure-epic":
            return _ensure_epic(args.order, args.desc, args.kind)
        return _rollup(args.epic_order)
    except BoardError as e:
        print(f"board: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
