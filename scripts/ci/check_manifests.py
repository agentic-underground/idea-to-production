#!/usr/bin/env python3
"""Deterministic, offline schema assertion for the marketplace's plugin manifests.

Part of the `.pipeline/verify` CI gate (Epic 0001). The seed gate only checked that
every `*.claude-plugin/*.json` file *parses*; this adds a shape assertion on top, so a
manifest that parses but is missing the keys the marketplace relies on fails the gate.

Two manifest kinds, two required-key sets:

  * marketplace.json  — the marketplace index. Requires `name` and a non-empty `plugins`
    list; every entry in it requires `name` + `source` (the pointer the marketplace
    resolves a plugin by).
  * plugin.json       — a single plugin's manifest. Requires `name` + `version`.

Usage:
    check_manifests.py <manifest.json> [<manifest.json> ...]

Each path is classified by filename. Exits non-zero on the first manifest that fails,
printing every problem found in that manifest. Pure stdlib, no network, no clock.
"""
import json
import sys
from pathlib import Path


def _check_str(obj, key, where, problems):
    """Require obj[key] to be a non-empty string; record a problem otherwise."""
    if key not in obj:
        problems.append(f"{where}: missing required key '{key}'")
    elif not isinstance(obj[key], str) or not obj[key].strip():
        problems.append(f"{where}: key '{key}' must be a non-empty string")


def check_marketplace(data, path):
    problems = []
    _check_str(data, "name", path, problems)
    plugins = data.get("plugins")
    if not isinstance(plugins, list) or not plugins:
        problems.append(f"{path}: 'plugins' must be a non-empty list")
        return problems
    for i, entry in enumerate(plugins):
        where = f"{path}: plugins[{i}]"
        if not isinstance(entry, dict):
            problems.append(f"{where}: must be an object")
            continue
        _check_str(entry, "name", where, problems)
        _check_str(entry, "source", where, problems)
    return problems


def check_plugin(data, path):
    problems = []
    _check_str(data, "name", path, problems)
    _check_str(data, "version", path, problems)
    return problems


def check_manifest(path):
    """Return a list of problem strings for one manifest file (empty == OK)."""
    try:
        data = json.loads(Path(path).read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{path}: could not read/parse JSON: {exc}"]
    if not isinstance(data, dict):
        return [f"{path}: top-level JSON must be an object"]
    if Path(path).name == "marketplace.json":
        return check_marketplace(data, path)
    return check_plugin(data, path)


def main(argv):
    paths = argv[1:]
    if not paths:
        print("check_manifests.py: no manifest paths given", file=sys.stderr)
        return 2
    failed = False
    for path in paths:
        problems = check_manifest(path)
        if problems:
            failed = True
            for p in problems:
                print(p, file=sys.stderr)
    if failed:
        return 1
    print(f"manifest schema OK ({len(paths)} manifest(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
