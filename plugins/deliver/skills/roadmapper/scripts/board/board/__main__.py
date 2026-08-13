"""CLI for `board` — ``python3 -m board <verb>`` (PLAN 0072.014).

Verbs:
  lifecycle <plan-order> <transition>   set a PLAN's status (+ lockstep) then roll its parent EPIC
  rollup    <epic-order>                recompute + apply an EPIC's status from its children

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
    epic_status, children = gh.board_statuses(epic_order)
    target = lc.rollup_status(children, epic_status or "")
    if target is None:
        print(f"EPIC {epic_order}: no rollup change (current={epic_status!r}, children={children})")
        return
    epic_no = gh.epic_issue(epic_order)
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


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="board", description="GitHub Project board integration (lifecycle + rollup)")
    sub = p.add_subparsers(dest="cmd", required=True)
    lp = sub.add_parser("lifecycle", help="transition a PLAN and roll its parent EPIC")
    lp.add_argument("order", help="PLAN order, e.g. 0072.014")
    lp.add_argument("transition", help="start | review | revise | done | deliver | ready")
    rp = sub.add_parser("rollup", help="recompute + apply an EPIC's status from its children")
    rp.add_argument("epic_order", help="EPIC order, e.g. 0072")
    args = p.parse_args(argv)
    try:
        if args.cmd == "lifecycle":
            return _lifecycle(args.order, args.transition)
        return _rollup(args.epic_order)
    except BoardError as e:
        print(f"board: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
