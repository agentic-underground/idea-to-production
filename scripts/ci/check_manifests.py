#!/usr/bin/env python3
"""check_manifests.py — deterministic, offline manifest-schema gate.

Validates that the marketplace manifest and every plugin manifest not only PARSE
(the seed gate already proved that) but CONFORM to the Claude Code plugin/marketplace
shape: the required fields are present with the right types, versions are semver, every
declared plugin source resolves to a real plugin.json on disk, and the marketplace entry
agrees with the plugin's own manifest (name + version).

stdlib only (json, re, pathlib, subprocess) — no third-party dependency, no network.
Run from the repo root:  python3 scripts/ci/check_manifests.py
Exits 0 when every manifest conforms; prints every violation and exits 1 otherwise.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

SEMVER = re.compile(r"^\d+\.\d+\.\d+([-+].+)?$")

errors: list[str] = []


def err(manifest: str, msg: str) -> None:
    errors.append(f"{manifest}: {msg}")


def load(path: Path):
    """Parse JSON, recording (not raising) a violation on failure."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        err(str(path), f"does not parse as JSON ({exc})")
        return None


def require(manifest: str, obj: dict, key: str, types) -> bool:
    """Assert obj[key] exists and is of the given type(s). Returns True when valid."""
    if key not in obj:
        err(manifest, f"missing required field '{key}'")
        return False
    if not isinstance(obj[key], types):
        names = types.__name__ if isinstance(types, type) else "/".join(t.__name__ for t in types)
        err(manifest, f"field '{key}' must be {names}, got {type(obj[key]).__name__}")
        return False
    return True


def non_empty_str(manifest: str, obj: dict, key: str) -> None:
    if require(manifest, obj, key, str) and not obj[key].strip():
        err(manifest, f"field '{key}' must be a non-empty string")


def check_plugin_manifest(path: Path) -> dict | None:
    """Validate a plugins/<name>/.claude-plugin/plugin.json. Returns the parsed obj."""
    name = str(path)
    obj = load(path)
    if obj is None:
        return None
    if not isinstance(obj, dict):
        err(name, "top-level value must be a JSON object")
        return None

    non_empty_str(name, obj, "name")
    non_empty_str(name, obj, "description")
    if require(name, obj, "version", str) and not SEMVER.match(obj["version"]):
        err(name, f"version '{obj['version']}' is not semver (MAJOR.MINOR.PATCH)")

    # The plugin name must match its directory: plugins/<dir>/.claude-plugin/plugin.json
    plugin_dir = path.parent.parent.name
    if obj.get("name") not in (None, plugin_dir):
        err(name, f"name '{obj.get('name')}' does not match plugin directory '{plugin_dir}'")
    return obj


def check_marketplace(path: Path, repo: Path) -> None:
    name = str(path)
    obj = load(path)
    if obj is None:
        return
    if not isinstance(obj, dict):
        err(name, "top-level value must be a JSON object")
        return

    non_empty_str(name, obj, "name")
    if "version" in obj and isinstance(obj["version"], str) and not SEMVER.match(obj["version"]):
        err(name, f"version '{obj['version']}' is not semver")
    if not require(name, obj, "plugins", list):
        return
    if not obj["plugins"]:
        err(name, "'plugins' array is empty")
        return

    for i, entry in enumerate(obj["plugins"]):
        tag = f"plugins[{i}]"
        if not isinstance(entry, dict):
            err(name, f"{tag} must be an object")
            continue
        non_empty_str(name, entry, "name")
        if not require(name, entry, "source", str):
            continue
        source = entry["source"]
        # Resolve the declared source to a real plugin manifest on disk.
        src_dir = (repo / source).resolve()
        plugin_json = src_dir / ".claude-plugin" / "plugin.json"
        if not plugin_json.is_file():
            err(name, f"{tag} ('{entry.get('name')}') source '{source}' has no .claude-plugin/plugin.json")
            continue
        sub = load(plugin_json)
        if not isinstance(sub, dict):
            continue
        # The marketplace entry must agree with the plugin's own manifest.
        if entry.get("name") != sub.get("name"):
            err(name, f"{tag} name '{entry.get('name')}' ≠ plugin.json name '{sub.get('name')}'")
        if "version" in entry and entry.get("version") != sub.get("version"):
            err(name, f"{tag} ('{entry.get('name')}') version '{entry.get('version')}' "
                      f"≠ plugin.json version '{sub.get('version')}'")


def tracked_manifests() -> list[Path]:
    out = subprocess.run(
        ["git", "ls-files", "*.claude-plugin/*.json"],
        capture_output=True, text=True, check=True,
    ).stdout
    return [Path(p) for p in out.splitlines() if p.strip()]


def main() -> int:
    repo = Path.cwd()
    manifests = tracked_manifests()
    if not manifests:
        print("check_manifests: no *.claude-plugin/*.json manifests tracked — nothing to validate")
        return 1
    n_plugin = 0
    for path in manifests:
        if path.name == "marketplace.json":
            check_marketplace(path, repo)
        elif path.name == "plugin.json":
            check_plugin_manifest(path)
            n_plugin += 1
        # other .claude-plugin/*.json files are parsed by the seed's json.load loop; no schema here

    if errors:
        print(f"check_manifests: {len(errors)} schema violation(s):", file=sys.stderr)
        for e in errors:
            print(f"  ✗ {e}", file=sys.stderr)
        return 1
    print(f"check_manifests: {len(manifests)} manifest(s) conform "
          f"(1 marketplace + {n_plugin} plugin)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
