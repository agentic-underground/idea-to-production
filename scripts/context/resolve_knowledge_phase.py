#!/usr/bin/env python3
"""resolve_knowledge_phase.py — EPIC 0067 / PLAN 0067.003 — the knowledge-module phase resolver.

Gives every `plugins/*/knowledge/**/*.md` module a resolvable lifecycle phase so the context pointer
(PLAN 0067.002) and the leanness gate (PLAN 0067.004) can name / verify the right knowledge per phase.
Implements the model in docs/guide/context-population.md §3.4:

  1. OWN TAG (authoritative) — a knowledge module MAY carry `metadata.phase: [...]` in frontmatter.
  2. INHERITED (default)     — else its phase is the UNION of `metadata.phase` of the SKILLS that
                               reference it (intra-plugin; a plugin is self-contained). Determinacy:
                                 • a `cross-cut` referring skill makes the doc `cross-cut`;
                                 • doc→doc references do NOT propagate (only skills/agents are scanned).
  3. ORPHAN (flagged)        — untagged AND no phased referrer → resolves to no phase; flagged so it is
                               tagged deliberately, never treated as silently global.

REALITY OF THIS MARKETPLACE: agents and commands do NOT carry `metadata.phase` (only skills do — the
R5 routing gate). So inheritance is skill-driven; a doc reachable ONLY via agents/docs has no phased
referrer and is flagged (`ambiguous`) for a deliberate own-tag — same remedy as a bare orphan.

Deterministic + offline. No third-party deps (frontmatter parsed with a regex, house style of
verify-routing.sh's `phase:` match). `--self-test` proves the logic against scripts/context/fixtures/.
"""
import argparse
import glob
import os
import re
import sys

PHASES = {"DISCOVER", "IDEATE", "DELIVER", "DESIGN", "BUILD", "ASSURE", "SECURE", "PUBLISH", "OPERATE"}
CROSS_CUT = "cross-cut"
ALLOWED = PHASES | {CROSS_CUT}


def _here():
    return os.path.dirname(os.path.abspath(__file__))


def repo_root():
    # scripts/context/ -> repo root two levels up.
    return os.path.abspath(os.path.join(_here(), "..", ".."))


def _frontmatter(text):
    """Return the YAML frontmatter block (between the leading '---' fences), or '' if none."""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            return text[3:end]
    return ""


def parse_phase_list(block):
    """Extract a `phase: [A, B]` list from a frontmatter block → set of tokens (house-style regex)."""
    m = re.search(r"^\s*phase:\s*\[([^\]]*)\]", block, re.M)
    if not m:
        return set()
    toks = {t.strip().strip("\"'") for t in m.group(1).split(",") if t.strip()}
    return {t for t in toks if t in ALLOWED}


def _read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return ""


def collect(root):
    """Return (skills, agents, knowledge) for a marketplace tree rooted at `root`.

    skills/agents: list of dicts {plugin, path, text, phases}. knowledge: list of {plugin, path, rel}.
    """
    def plugin_of(p):
        # .../plugins/<PLUGIN>/...  -> <PLUGIN>
        parts = os.path.relpath(p, root).split(os.sep)
        return parts[1] if len(parts) > 1 and parts[0] == "plugins" else None

    skills = []
    for sp in glob.glob(os.path.join(root, "plugins", "*", "skills", "*", "SKILL.md")):
        txt = _read(sp)
        skills.append({"plugin": plugin_of(sp), "path": sp, "text": txt,
                       "phases": parse_phase_list(_frontmatter(txt))})
    agents = []
    for ap in glob.glob(os.path.join(root, "plugins", "*", "agents", "*.md")):
        agents.append({"plugin": plugin_of(ap), "path": ap, "text": _read(ap)})
    knowledge = []
    for kp in glob.glob(os.path.join(root, "plugins", "*", "knowledge", "**", "*.md"), recursive=True):
        plugin = plugin_of(kp)
        if plugin is None:
            continue
        # A knowledge-dir README.md is a directory index, not a loadable phase-scoped module — skip it.
        if os.path.basename(kp).lower() == "readme.md":
            continue
        rel = os.path.relpath(kp, os.path.join(root, "plugins", plugin, "knowledge"))
        knowledge.append({"plugin": plugin, "path": kp, "rel": rel.replace(os.sep, "/")})
    return skills, agents, knowledge


def resolve(root):
    """Resolve every knowledge module → dict path→{phases:set, source:str, rel, plugin, referrers:[..]}."""
    skills, agents, knowledge = collect(root)
    out = {}
    for k in knowledge:
        ref_token = "knowledge/" + k["rel"]           # e.g. knowledge/architecture/solid.md
        own = parse_phase_list(_frontmatter(_read(k["path"])))
        if own:
            out[k["path"]] = {"phases": own, "source": "own", "rel": k["rel"],
                              "plugin": k["plugin"], "referrers": []}
            continue
        # Intra-plugin referrers only (self-contained plugins resolve knowledge via ${CLAUDE_PLUGIN_ROOT}).
        ref_skills = [s for s in skills if s["plugin"] == k["plugin"] and ref_token in s["text"]]
        ref_agents = [a for a in agents if a["plugin"] == k["plugin"] and ref_token in a["text"]]
        referrers = [os.path.basename(os.path.dirname(s["path"])) for s in ref_skills]
        if ref_skills:
            if any(CROSS_CUT in s["phases"] for s in ref_skills):
                phases, source = {CROSS_CUT}, "inherited"
            else:
                phases = set().union(*[s["phases"] for s in ref_skills])
                source = "inherited" if phases else "ambiguous"
            out[k["path"]] = {"phases": phases, "source": source if phases else "ambiguous",
                              "rel": k["rel"], "plugin": k["plugin"], "referrers": referrers}
        elif ref_agents:
            # Referenced, but only by unphased agents → no phase derivable → flag for a deliberate own-tag.
            out[k["path"]] = {"phases": set(), "source": "ambiguous", "rel": k["rel"],
                              "plugin": k["plugin"], "referrers": ["(agent-only)"]}
        else:
            out[k["path"]] = {"phases": set(), "source": "orphan", "rel": k["rel"],
                              "plugin": k["plugin"], "referrers": []}
    return out


def is_flagged(rec):
    return not rec["phases"]  # orphan or ambiguous → empty phase set


def fmt_phases(rec):
    return ",".join(sorted(rec["phases"])) if rec["phases"] else "ORPHAN(" + rec["source"] + ")"


def cmd_list(root, phase=None, orphans_only=False):
    res = resolve(root)
    rows = []
    for rec in res.values():
        if orphans_only and not is_flagged(rec):
            continue
        if phase is not None:
            if not (phase in rec["phases"] or CROSS_CUT in rec["phases"]):
                continue
        rows.append((rec["plugin"], rec["rel"], fmt_phases(rec), rec["source"]))
    for plugin, rel, phases, source in sorted(rows):
        print(f"{phases:24} {source:10} {plugin}/knowledge/{rel}")
    return res, rows


# ── self-test ────────────────────────────────────────────────────────────────────────────────────
def self_test():
    fx = os.path.join(_here(), "fixtures", "knowledge-phase")
    if not os.path.isdir(fx):
        print(f"self-test: missing fixtures at {fx}", file=sys.stderr)
        return 1
    res = resolve(fx)
    by_rel = {rec["rel"]: rec for rec in res.values()}
    failures = []

    def check(cond, label):
        print(("  ✓ " if cond else "  ✗ ") + label)
        if not cond:
            failures.append(label)

    def phases_of(rel):
        return by_rel.get(rel, {"phases": set()})["phases"]

    def source_of(rel):
        return by_rel.get(rel, {"source": "MISSING"})["source"]

    print("resolve_knowledge_phase.py --self-test (PLAN 0067.003)")
    # AC-1: doc referenced only by a BUILD skill resolves to BUILD (not global).
    check(phases_of("build-only.md") == {"BUILD"}, "AC-1: build-only.md inherits {BUILD}")
    check(source_of("build-only.md") == "inherited", "AC-1: source is 'inherited'")
    # Own tag is authoritative over inheritance.
    check(phases_of("own-tagged.md") == {"OPERATE"}, "own-tag: own-tagged.md is {OPERATE} (own tag wins over a BUILD referrer)")
    check(source_of("own-tagged.md") == "own", "own-tag: source is 'own'")
    # cross-cut referrer makes the doc cross-cut.
    check(phases_of("shared.md") == {CROSS_CUT}, "cross-cut: shared.md is {cross-cut}")
    # multi-phase loop doc.
    check(phases_of("loop-doc.md") == {"ASSURE", "SECURE"}, "loop: loop-doc.md is {ASSURE,SECURE}")
    # AC-2: --phase PUBLISH lists only in-phase (+ cross-cut), never DISCOVER/IDEATE.
    pub = {rec["rel"] for rec in res.values() if "PUBLISH" in rec["phases"] or CROSS_CUT in rec["phases"]}
    check("pub-doc.md" in pub, "AC-2: PUBLISH view includes pub-doc.md")
    check("shared.md" in pub, "AC-2: PUBLISH view includes the cross-cut doc")
    check("disc-doc.md" not in pub and "build-only.md" not in pub, "AC-2: PUBLISH view excludes DISCOVER/BUILD docs")
    # ASSURE and SECURE both see the loop doc; DISCOVER does not.
    assure = {rec["rel"] for rec in res.values() if "ASSURE" in rec["phases"] or CROSS_CUT in rec["phases"]}
    check("loop-doc.md" in assure, "loop: ASSURE view includes loop-doc.md")
    # AC-3: a bare orphan and a doc→doc-only reference both flag (doc→doc must NOT propagate phase).
    check(source_of("orphan.md") == "orphan", "AC-3: orphan.md flagged as 'orphan'")
    check(is_flagged(by_rel["doc-to-doc.md"]), "AC-3: doc-to-doc.md flagged (doc→doc ref does not propagate)")
    check(source_of("agent-only.md") == "ambiguous", "AC-3: agent-only.md flagged 'ambiguous' (agents are unphased)")

    if failures:
        print(f"✗ self-test: {len(failures)} row(s) failed", file=sys.stderr)
        return 1
    print("✓ self-test passed")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Resolve knowledge-module lifecycle phases (EPIC 0067).")
    ap.add_argument("--root", default=repo_root(), help="marketplace tree root (default: repo root)")
    ap.add_argument("--phase", help="list only modules loadable in this phase (+ cross-cut)")
    ap.add_argument("--orphans", action="store_true", help="list only flagged (orphan/ambiguous) modules")
    ap.add_argument("--check", action="store_true", help="exit 1 if any module is flagged (orphan/ambiguous)")
    ap.add_argument("--self-test", action="store_true", help="run the fixture self-test and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()
    if args.check:
        res = resolve(args.root)
        flagged = [rec for rec in res.values() if is_flagged(rec)]
        for rec in sorted(flagged, key=lambda r: (r["plugin"], r["rel"])):
            print(f"FLAGGED({rec['source']}) {rec['plugin']}/knowledge/{rec['rel']}", file=sys.stderr)
        if flagged:
            print(f"✗ {len(flagged)} knowledge module(s) resolve to NO phase — tag them "
                  f"(metadata.phase) or add a phased referrer", file=sys.stderr)
            return 1
        print("✓ every knowledge module resolves to a phase")
        return 0
    cmd_list(args.root, phase=args.phase, orphans_only=args.orphans)
    return 0


if __name__ == "__main__":
    sys.exit(main())
