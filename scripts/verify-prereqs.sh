#!/usr/bin/env bash
# verify-prereqs.sh — CI guard for the PREREQUISITES ↔ plugins contract.
#
# Asserts the deterministic invariants that keep the docs, the canonical dependency
# manifests, and the shipped MCP servers from drifting apart. Runnable locally
# (`bash scripts/verify-prereqs.sh`) and in CI (.github/workflows/verify.yml).
#
# Checks (each prints PASS/FAIL; the script exits 1 if any FAILs):
#   A. check.sh is byte-identical across all plugins (the canonical-copy promise).
#   B. every requirements.tsv row is well-formed (4 TAB fields, valid tier, non-empty probe).
#   C. RETIRED — shipped MCP servers ⟺ PREREQUISITES/40-mcp.md. The PREREQUISITES/ folder was
#      archived out of the repo (PR #250). The invariant is now fully covered by check Q, which
#      asserts the same MCP server inventory against the live docs/SLASH_COMMANDS.md appendix.
#   D. RETIRED — no PREREQUISITES/*.md Probe cell fetches remote code. The PREREQUISITES/ folder
#      was archived out of the repo (PR #250); check G covers the same no-download invariant over
#      the canonical requirements.tsv probe cells, which remain.
#   Q. the "## Appendix — MCP servers" table in docs/SLASH_COMMANDS.md matches the SAME real
#      plugins/*/.mcp.json inventory — was a sibling to check C (now the sole MCP-doc parity gate).
#      Asserts three parities so the catalog can't drift when a plugin's .mcp.json changes:
#      (1) server-set (every shipped server is a row, no row names an unshipped server); (2) the
#      "Shipped by" column lists exactly the plugin(s) whose .mcp.json declares that server; and
#      (3) the "ships N MCP servers" count line equals the distinct shipped count (N as a digit or an
#      English number-word). The host-provided chrome-devtools browser MCP is intentionally NOT in the
#      table (driven, not shipped) and is narrated in prose outside it — only `|`-rows are parsed, so
#      that note is correctly ignored. Closes the manifest-changed-but-catalog-doc-not-swept drift
#      class (the two stale "ships a Playwright MCP" leaks the ONE BROWSER cutover left, #246).
#   D′. no-download tsv probes: the SAME no-download rule as check D, extended over the
#      requirements.tsv probe cells (column 2) — a capability probe may render/launch locally
#      but must never `npx -y`/`uvx`/`pip install`/`npm install`/`curl … | sh` a package.
#   N. KAIZEN.md is byte-identical across the canonical root and every plugin copy.
#   O. inject-kaizen.sh is byte-identical across all plugins (the lean SessionStart injector).
#   H. marketplace.json ⟺ plugins/ — every plugins/<name>/ dir has a matching
#      marketplace.json[].name entry and vice-versa (no orphan dir, no orphan entry), and each
#      plugin's plugin.json.version equals its marketplace.json entry version.
#   I. internal doc links resolve — repo-local markdown links in plugins/**/*.md and root *.md that
#      end in a real extension (.md/.sh/.tsv/.json/.svg/.png) point at a file that exists on disk.
#      Conservative: skips http(s)/mailto/anchors, ${CLAUDE_PLUGIN_ROOT}-relative, placeholders,
#      and links inside inline-code spans.
#   J. four-mirror guardrail (P1-21) — the conservative SKILL↔mirror floor. For every
#      plugins/<p>/skills/<s>/ found dynamically: a SKILL.md exists and carries valid frontmatter
#      (a non-empty `name:` and a `description:`); and every plugin that ships ≥1 skill has a
#      README.md that mentions at least one /command (so the skills are reachable from the user-facing
#      mirror). EXEMPTION: requirements.tsv rows are applicable-only (a skill with no external-tool
#      deps legitimately has none), and the README mention is asserted per-PLUGIN, not per-skill, so
#      internal skills (self-improve, etc.) need no individual README line. marketplace.json parity is
#      check H's job — J does not duplicate it.
#   K. MCP servers are version-pinned (P1-10) — for every plugins/*/.mcp.json, every server's launch
#      args must carry an explicit version PIN, never a floating tag. FLAG `@latest`, a bare npx/`-y`
#      package with no `@<version>`, and an unversioned uvx/bunx package. ALLOW an explicit
#      `@<semver>`/`@<pin>`. (Floating tags re-resolve on every launch → non-reproducible installs.)
#   L. hooks smoke-exec (P1-8) — for every plugins/*/hooks/hooks.json, each declared command's script
#      (resolved ${CLAUDE_PLUGIN_ROOT} → the plugin dir) must EXIST, pass `bash -n`, and run to a
#      ZERO exit when fed a minimal synthetic SessionStart event on stdin — in a sandbox
#      (HOME + CLAUDE_PROJECT_DIR = fresh mktemp dirs) so it can't touch real state, under a timeout.
#      A missing / unparsable / non-zero-exiting hook = FAIL: this is what makes a dead
#      inject-kaizen/capture-cost detectable, vs the `2>/dev/null||true` that hides it at runtime.
#   M. LSP capability probes exist AND are no-download (P2-14) — the browser incident's
#      presence-vs-capability lesson, generalised to Language Server Protocol servers. Asserts that
#      (1) at least one CAPABILITY-grade LSP probe exists (one that drives a server over its JSON-RPC
#      stdio wire — fingerprinted by an `initialize` request framed with `Content-Length`, not a
#      `command -v <lsp>` presence row), so the presence≠capability lesson is actually applied; and
#      (2) every such capability probe obeys the no-download invariant (check G's deny set, scoped to
#      the LSP class) — it may launch the server locally but must never fetch-and-run a package.
#   P. roadmap v2 conformance — the roadmap IS the FLEET v2 pipeline (docs/roadmap/), whose grammar is
#      regex-parsed by the engine. Asserts the on-disk artifacts conform (manifest rows: leading `|`,
#      4-digit `order`, `order|epic|state`; each EPIC_NNNN.md: single-line `**Branch**` scrape + any
#      `## Plans` table is `order|plan|state` not the manifest grammar) AND that the vendored
#      references/fleet-pipeline-standard.md declares the pinned schema-version and — when the external
#      FLEET source is present on the box — is byte-identical to it (FAIL LOUD on drift → human re-vendor).
#      A fresh repo with no docs/roadmap/.pipeline.md passes. NOTE: the DoD-content of an emitted PLAN's
#      `.pipeline/verify` (coverage floor / flaky / BDD) is enforced PER EMITTED PROJECT by roadmapper's
#      PLAN "Definition of done" template + FOUNDRY's own DoD audit — NOT asserted here. This marketplace
#      meta-repo has no application test-suite to floor (its own gate is EPIC_0001's deterministic
#      manifest+python checks), so check P guards the GRAMMAR + vendored-standard pin, not gate content.
#      (Check I also skips ``` fenced code blocks, so illustrative links in a vendored grammar's sample
#      tables are not mistaken for real doc links.)
#
# Flag:
#   --fix  guarded canonical re-sync — when the canonical-copy parity checks (A check.sh,
#          N KAIZEN.md, O inject-kaizen.sh) FAIL, re-sync each drifted copy FROM its
#          named canonical source (root KAIZEN.md for N; the most-common copy for
#          A/O). GUARDS: refuses on a dirty git tree, prints
#          the diff before writing, and operates ONLY on the canonical-copy sets these checks track
#          (never a file the user intentionally diverged elsewhere). Without --fix: detect-only.
set -uo pipefail

fix=0
for arg in "$@"; do
  case "$arg" in
    --fix) fix=1 ;;
    *) printf "unknown argument: %s (supported: --fix)\n" "$arg" >&2; exit 2 ;;
  esac
done

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"

red=$'\033[31m'; green=$'\033[32m'; bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { red=""; green=""; bold=""; dim=""; reset=""; }

fails=0
pass() { printf "  %b✓%b %s\n" "$green" "$reset" "$1"; }
fail() { printf "  %b✗ %s%b\n" "$red" "$1" "$reset"; fails=$((fails+1)); }
section() { printf "\n%b%s%b\n" "$bold" "$1" "$reset"; }

# ── --fix registry (canonical-copy re-sync, used by checks A/N/O) ─────────────
# Each parity check, when it detects drift, registers the canonical source and the drifted copies
# it would re-sync. The actual re-sync happens in the guarded --fix block before the verdict — never
# inline, so detect-only behaviour (the default) is preserved byte-for-byte.
resync_src=()    # parallel arrays: resync_src[i] is the canonical source for…
resync_dst=()    # …resync_dst[i], one drifted copy to overwrite from it.
# canonical_of <file…> : echo the canonical copy of a set — the most-common-by-md5 member (ties
# broken by sort order). This is the "repo-root-blessed" copy: the majority that the lone drifted
# copy diverged from. mawk-safe (no gawk extensions).
canonical_of() {
  md5sum "$@" | awk '
    { c[$1]++; if (!($1 in first)) first[$1]=$2 }   # $1=md5, $2=path; remember first path per md5
    END { best=""; bn=0
          for (h in c) if (c[h]>bn || (c[h]==bn && first[h]<best)) { bn=c[h]; best=first[h] }
          print best }
  '
}
# register_drift <canonical> <file…> : queue every file whose md5 != canonical's md5 for re-sync.
register_drift() {
  local canon="$1"; shift
  local cs ds f
  cs="$(md5sum "$canon" | awk '{print $1}')"
  for f in "$@"; do
    [ "$f" = "$canon" ] && continue
    ds="$(md5sum "$f" | awk '{print $1}')"
    if [ "$ds" != "$cs" ]; then resync_src+=("$canon"); resync_dst+=("$f"); fi
  done
}

# ── A. check.sh byte-identical across all plugins ────────────────────────────
section "A. check.sh canonical-copy parity"
mapfile -t checks < <(find plugins -path '*/skills/check/scripts/check.sh' | sort)
if [ "${#checks[@]}" -lt 2 ]; then
  fail "expected ≥2 check.sh copies, found ${#checks[@]}"
else
  sums="$(md5sum "${checks[@]}" | awk '{print $1}' | sort -u)"
  if [ "$(printf '%s\n' "$sums" | wc -l)" -eq 1 ]; then
    pass "${#checks[@]} copies identical ($sums)"
  else
    fail "check.sh copies diverge across plugins:"; md5sum "${checks[@]}" | sed 's/^/      /'
    register_drift "$(canonical_of "${checks[@]}")" "${checks[@]}"
  fi
fi

# ── B. requirements.tsv rows well-formed ─────────────────────────────────────
section "B. requirements.tsv well-formed"
tsv_ok=1
while IFS= read -r tsv; do
  # awk: every non-comment/non-blank/non-header row must have 4 TAB fields,
  # a valid tier in column 3, and a non-empty probe in column 2.
  errs="$(awk -F'\t' '
    /^#/ || /^[[:space:]]*$/ { next }   # the header row is itself a `# name…` comment, so /^#/ skips it
    {
      if (NF!=4)                                            print "      "FILENAME":"NR": expected 4 TAB fields, got "NF
      else if ($2=="")                                      print "      "FILENAME":"NR": empty probe ("$1")"
      else if ($3!="required" && $3!="recommended" && $3!="optional") print "      "FILENAME":"NR": bad tier \""$3"\" ("$1")"
    }
  ' "$tsv")"
  if [ -n "$errs" ]; then tsv_ok=0; fail "malformed rows in $tsv:"; printf '%s\n' "$errs"; fi
done < <(find plugins -path '*/skills/check/requirements.tsv' | sort)
[ "$tsv_ok" -eq 1 ] && pass "all requirements.tsv rows well-formed (4 fields, valid tier, non-empty probe)"

# ── (retired check C) shipped .mcp.json servers ⟺ PREREQUISITES/40-mcp.md ──────
# The PREREQUISITES/ folder was archived out of the repo (PR #250). The MCP-doc parity
# invariant is now enforced exclusively by check Q (SLASH_COMMANDS.md appendix), which
# passed cleanly on both sides of the archive PR. Nothing to run here.

# ── (retired check D) no Probe cell in PREREQUISITES/*.md fetches remote code ───
# The PREREQUISITES/ folder was archived out of the repo (PR #250). The no-download
# invariant is enforced over the remaining dependency manifests by check G (requirements.tsv
# probe cells), which continues to pass. Nothing to run here.

# ── D′. no-download tsv probes (check D, extended over requirements.tsv) ──────
# This is the tsv twin of check D: the same fetch-and-execute rule, applied to the
# requirements.tsv probe cells (column 2). A capability probe may render/launch LOCALLY
# (the publish mmdc row exports a resolver then renders a trivial diagram), but it must
# never DOWNLOAD-AND-RUN a package. Allow-list (mirrors check D + the established tsv idiom):
#   • any probe containing `command -v …`            (pure presence — never fetches), and
#   • `npx --no-install …`                           (refuses to auto-install; fails if absent).
# Deny (the property, not a flag-spelling):
#   • uvx / bunx / pnpm dlx                           (always fetch an uninstalled tool), or
#   • npx -y / --yes …                                (auto-install), or
#   • npx …@<spec>                                    (an explicit remote package spec), or
#   • pip install / npm i|install / curl … | sh       (classic download-and-execute).
# NOTE: only column 2 (the probe) is scanned — install hints in column 4 legitimately say
# `npm i -g …` / `uvx …`. The deny boolean is kept on ONE line on purpose (mawk on Debian/
# GitHub ubuntu-latest rejects a parenthesised expression split across lines). awk stderr is
# captured so a parse/runtime error fails the check loudly (never a vacuous PASS).
section "G. requirements.tsv probes are no-download (check D, extended over tsv probe cells)"
g_err="$(mktemp)"
tsv_offenders="$(
  while IFS= read -r tsv; do
    awk -F'\t' -v file="$tsv" '
      /^#/ || /^[[:space:]]*$/ { next }
      { p=$2
        if (p ~ /command -v/) next
        if (p ~ /npx[ \t]+--no-install/) next
        if (p ~ /(^|[^[:alnum:]_])(uvx|bunx)([ \t]|$)/ || p ~ /pnpm[ \t]+dlx/ || p ~ /npx[ \t]+(-y|--yes)/ || p ~ /npx[ \t]+[^ \t]*@/ || p ~ /pip[ \t]+install/ || p ~ /npm[ \t]+(i|install)([ \t]|$)/ || p ~ /curl[^|]*\|[ \t]*(ba)?sh/) print file" :: "$1" :: "p
      }
    ' "$tsv" 2>>"$g_err"
  done < <(find plugins -path '*/skills/check/requirements.tsv' | sort)
)"
if [ -s "$g_err" ]; then
  fail "awk error while scanning tsv probe cells — the no-download check did not run:"; sed 's/^/      /' "$g_err"; rm -f "$g_err"
elif [ -z "$tsv_offenders" ]; then
  rm -f "$g_err"
  pass "no requirements.tsv probe downloads a package (capability probes render/launch locally)"
else
  rm -f "$g_err"
  fail "requirements.tsv probe cells that fetch-and-execute remote code (use \`command -v\`/\`npx --no-install\`/a local render):"
  printf '%s\n' "$tsv_offenders" | sed 's/^/      /'
fi

# ── N. KAIZEN.md byte-identical (canonical root + every plugin copy) ─────────
# The KAIZEN always-aware banner — a small, universal canon mirrored into every plugin. Canonical-copy
# contract: edits start at the repo-root KAIZEN.md and are mirrored outward.
section "N. KAIZEN.md canonical-copy parity"
mapfile -t kaizens < <(find plugins -path '*/KAIZEN.md' | sort)
if [ ! -f KAIZEN.md ]; then
  fail "canonical root KAIZEN.md is missing"
elif [ "${#kaizens[@]}" -lt 1 ]; then
  fail "expected ≥1 plugin KAIZEN.md copy, found ${#kaizens[@]}"
else
  kaizens=("KAIZEN.md" "${kaizens[@]}")
  sums="$(md5sum "${kaizens[@]}" | awk '{print $1}' | sort -u)"
  if [ "$(printf '%s\n' "$sums" | wc -l)" -eq 1 ]; then
    pass "${#kaizens[@]} copies identical incl. root ($sums)"
  else
    fail "KAIZEN.md copies diverge (root vs plugins):"; md5sum "${kaizens[@]}" | sed 's/^/      /'
    register_drift "KAIZEN.md" "${kaizens[@]}"   # named canonical source = root KAIZEN.md
  fi
fi

# ── O. inject-kaizen.sh byte-identical across all plugins ─────────────────────
# The SessionStart injector for the KAIZEN banner — mirrored byte-identical across all plugins.
section "O. inject-kaizen.sh canonical-copy parity"
mapfile -t kinjectors < <(find plugins -path '*/hooks/inject-kaizen.sh' | sort)
if [ "${#kinjectors[@]}" -lt 2 ]; then
  fail "expected ≥2 inject-kaizen.sh copies, found ${#kinjectors[@]}"
else
  sums="$(md5sum "${kinjectors[@]}" | awk '{print $1}' | sort -u)"
  if [ "$(printf '%s\n' "$sums" | wc -l)" -eq 1 ]; then
    pass "${#kinjectors[@]} copies identical ($sums)"
  else
    fail "inject-kaizen.sh copies diverge across plugins:"; md5sum "${kinjectors[@]}" | sed 's/^/      /'
    register_drift "$(canonical_of "${kinjectors[@]}")" "${kinjectors[@]}"
  fi
fi

# ── H. marketplace.json ⟺ plugins/ (names + versions aligned) ────────────────
# Two assertions, both enumerated dynamically (no hard-coded plugin list):
#   (1) name set parity — every plugins/<name>/ dir has a marketplace.json[].name entry and vice-
#       versa (no orphan dir, no orphan entry); and
#   (2) version alignment — each plugin's plugin.json.version equals its marketplace.json entry
#       version (the four-mirror alignment the maintainer loop keeps bumping).
section "H. marketplace.json ⟺ plugins/ (names + versions aligned)"
mkt=".claude-plugin/marketplace.json"
if ! command -v jq >/dev/null 2>&1; then
  fail "jq not found — required to read $mkt"
elif [ ! -f "$mkt" ]; then
  fail "$mkt is missing"
else
  # (1) name-set parity
  dirs="$(ls -d plugins/*/ 2>/dev/null | sed 's#plugins/##; s#/$##' | sort)"
  entries="$(jq -r '.plugins[].name' "$mkt" | sort)"
  orphan_dirs="$(comm -23 <(printf '%s\n' "$dirs") <(printf '%s\n' "$entries"))"
  orphan_entries="$(comm -13 <(printf '%s\n' "$dirs") <(printf '%s\n' "$entries"))"
  h_ok=1
  if [ -n "$orphan_dirs" ]; then
    h_ok=0; fail "plugins/ dir(s) with no marketplace.json entry:"; printf '%s\n' "$orphan_dirs" | sed 's/^/      /'
  fi
  if [ -n "$orphan_entries" ]; then
    h_ok=0; fail "marketplace.json entr(y/ies) with no plugins/ dir:"; printf '%s\n' "$orphan_entries" | sed 's/^/      /'
  fi
  # (2) version alignment — only for names present on BOTH sides (a name orphan is already failed above)
  for name in $(comm -12 <(printf '%s\n' "$dirs") <(printf '%s\n' "$entries")); do
    mver="$(jq -r --arg n "$name" '.plugins[] | select(.name==$n) | .version // "∅"' "$mkt")"
    pj="plugins/$name/.claude-plugin/plugin.json"
    if [ ! -f "$pj" ]; then
      h_ok=0; fail "$name: missing $pj"
    else
      pver="$(jq -r '.version // "∅"' "$pj")"
      if [ "$mver" != "$pver" ]; then
        h_ok=0; fail "$name: version mismatch — marketplace.json=$mver, plugin.json=$pver"
      fi
    fi
  done
  [ "$h_ok" -eq 1 ] && pass "$(printf '%s\n' "$entries" | grep -c .) plugins aligned (names paired, plugin.json.version == marketplace.json version)"
fi

# ── I. internal doc links resolve ────────────────────────────────────────────
# Resolve repo-local markdown links [...](path) across plugins/**/*.md, PREREQUISITES/*.md, and root
# *.md, and report any that point at a missing file. Conservative by design (only clearly-local file
# links — never a false positive on a runtime-resolved or illustrative link). A link is CHECKED only
# when its target, after stripping any "title" and #anchor:
#   • is NOT http(s):// / mailto: / a pure #anchor / ${CLAUDE_PLUGIN_ROOT}-relative (runtime-resolved),
#   • is NOT absolute (/-rooted) and contains no <placeholder> token,
#   • is NOT inside an inline-code span (`…` — those are rendered-output examples, not live refs), and
#   • ends in a real, repo-tracked extension: .md .sh .tsv .json .svg .png.
# It is then resolved against the LINKING FILE's directory (so ../-relative links work) and must exist.
# FUTURE EXTENSION: this pass deliberately does NOT validate /command tokens (e.g. /foundry:check) —
# semantic command-token resolution is noisy and out of scope here; add it as a separate check later.
section "I. internal doc links resolve"
broken_links="$(
  { find plugins \( -name node_modules -o -name target -o -name .venv \) -prune -o -name '*.md' -print; ls ./*.md 2>/dev/null; } | sort -u | while IFS= read -r f; do
    dir="$(dirname "$f")"
    # awk emits one link target per line. It skips ``` fenced code blocks entirely (their links are
    # illustrative examples, not real doc links — e.g. a vendored grammar's sample manifest rows), and
    # blanks inline-code spans so links inside `…` are skipped too. The fence toggle matches only a TRUE
    # fence delimiter — a leading run of ≥3 backticks followed by an optional info string with NO further
    # backticks (`^\s*```+[^`]*$`). A prose line that merely starts with a backtick run but contains more
    # backticks later (an inline span like ```` ```mermaid ````) is NOT a fence and must not toggle, else
    # an unbalanced toggle would silently blind the rest of the file to link-checking.
    awk '
      /^[[:space:]]*```+[^`]*$/ { infence = !infence; next }
      infence { next }
      {
        line=$0
        while (match(line, /`[^`]*`/)) line = substr(line,1,RSTART-1) substr(line,RSTART+RLENGTH)
        s=line
        while (match(s, /\]\([^)]+\)/)) { print substr(s, RSTART+2, RLENGTH-3); s=substr(s, RSTART+RLENGTH) }
      }
    ' "$f" | while IFS= read -r raw; do
      target="${raw%% *}"      # drop a trailing "title"
      target="${target%%#*}"   # drop an #anchor
      [ -z "$target" ] && continue
      case "$target" in
        http://*|https://*|mailto:*|\#*|*CLAUDE_PLUGIN_ROOT*|/*) continue ;;
        *"<"*|*">"*) continue ;;   # illustrative placeholder, not a real path
      esac
      case "$target" in
        *.md|*.sh|*.tsv|*.json|*.svg|*.png) ;;
        *) continue ;;
      esac
      [ -e "$dir/$target" ] || printf '      %s -> %s\n' "$f" "$target"
    done
  done
)"
if [ -z "$broken_links" ]; then
  pass "all repo-local doc links resolve (.md/.sh/.tsv/.json/.svg/.png, ../-relative against the linking file)"
else
  fail "broken internal doc links (target missing on disk):"; printf '%s\n' "$broken_links"
fi

# ── J. four-mirror guardrail (P1-21): the conservative SKILL↔mirror floor ─────
# Every plugins/<p>/skills/<s>/ (found dynamically) must carry a SKILL.md with valid frontmatter
# (a non-empty `name:` and a `description:` key inside the leading `---`…`---` block); and every
# plugin that ships ≥1 skill must have a README.md that mentions at least one /command, so its
# skills are reachable from the user-facing mirror. This is the WEAKEST defensible invariant — it
# does NOT assert every skill name appears in the README (internal skills like self-improve need no
# line) and does NOT require a requirements.tsv row (applicable-only: a depless skill has none).
# marketplace.json parity is check H's job; J is purely SKILL↔README/frontmatter.
section "J. four-mirror guardrail (SKILL.md frontmatter + plugin README ↦ /command)"
j_ok=1
# (1) every skill dir has a SKILL.md with name+description frontmatter
while IFS= read -r sdir; do
  md="$sdir/SKILL.md"
  if [ ! -f "$md" ]; then
    j_ok=0; fail "$sdir: missing SKILL.md"; continue
  fi
  # Pull the leading frontmatter block (between the first two `---` lines) and assert name+description.
  fm_err="$(awk '
    NR==1 && $0=="---" { inb=1; next }
    inb && $0=="---"   { inb=0; done=1; exit }
    inb && /^name:[ \t]*[^ \t]/        { hasname=1 }
    inb && /^description:/             { hasdesc=1 }
    END {
      if (!done)    { print "      "FILE": no closing --- frontmatter block"; exit }
      if (!hasname) print "      "FILE": frontmatter missing a non-empty name:"
      if (!hasdesc) print "      "FILE": frontmatter missing description:"
    }
  ' FILE="$md" "$md")"
  if [ -n "$fm_err" ]; then j_ok=0; fail "$md: invalid SKILL.md frontmatter:"; printf '%s\n' "$fm_err"; fi
done < <(find plugins -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' | sort)
# (2) every plugin that ships ≥1 skill has a README.md mentioning at least one /command
while IFS= read -r pdir; do
  [ -n "$(find "$pdir/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)" ] || continue
  rm="$pdir/README.md"
  if [ ! -f "$rm" ]; then
    j_ok=0; fail "$(basename "$pdir"): ships skills but has no README.md"
  elif ! grep -qE '(^|[^[:alnum:]])/[a-z][a-z0-9:_-]+' "$rm"; then
    j_ok=0; fail "$(basename "$pdir"): README.md mentions no /command (skills unreachable from the user-facing mirror)"
  fi
done < <(find plugins -mindepth 1 -maxdepth 1 -type d | sort)
[ "$j_ok" -eq 1 ] && pass "every skill has SKILL.md (name+description frontmatter); every skill-shipping plugin's README names a /command"

# ── K. MCP servers are version-pinned (P1-10) ────────────────────────────────
# For every plugins/*/.mcp.json server, the launch args must name an explicitly PINNED package, never
# a floating tag that re-resolves on each launch. The package spec is the first arg that is NOT an
# npx/uvx flag (-y/--yes/--no-install/-q/…) and not the runner itself. Deny: a `@latest`/`@next`-style
# floating tag; a bare scoped/unscoped package with NO `@<version>` for an npx/`-y` invocation; an
# unversioned uvx/bunx package. Allow: any explicit `@<pin>` (semver or otherwise). jq enumerates the
# servers; the per-spec verdict is mawk-free (pure shell case), so this is portable on GitHub runners.
section "K. MCP servers version-pinned (no floating tags)"
if ! command -v jq >/dev/null 2>&1; then
  fail "jq not found — required to read plugins/*/.mcp.json"
else
  k_ok=1
  for f in plugins/*/.mcp.json; do
    [ -f "$f" ] || continue
    # Emit one "<server>\t<command>\t<arg1> <arg2> …" line per server.
    while IFS=$'\t' read -r srv cmd args; do
      [ -n "$srv" ] || continue
      # Only EPHEMERAL runners (npx/uvx/bunx/…) re-resolve a package on each launch and so
      # must pin @<version>. A RESIDENT-binary command (a bare executable on PATH) is whatever is
      # installed on the host — there is no package spec to pin, and its args are runtime
      # flags (e.g. `-t stdio`), so exempt it from this check.
      case "$cmd" in
        npx|uvx|bunx|pnpm|dlx) ;;   # ephemeral runner — must pin (fall through)
        *) continue ;;              # resident binary — nothing to pin
      esac
      # The package spec = first non-flag, non-runner token in args.
      spec=""
      for a in $args; do
        case "$a" in
          -y|--yes|--no-install|-q|--quiet|-p|--package|--) continue ;;
          npx|uvx|bunx|pnpm|dlx) continue ;;
          *) spec="$a"; break ;;
        esac
      done
      if [ -z "$spec" ]; then
        k_ok=0; fail "$f [$srv]: could not find a package spec in args ($args)"; continue
      fi
      # Floating tag → fail outright.
      case "$spec" in
        *@latest|*@next|*@canary|*@beta|*@nightly|*@dev)
          k_ok=0; fail "$f [$srv]: floating tag '$spec' — pin an explicit @<version>"; continue ;;
      esac
      # Does the spec carry an @<version> pin? A scoped name @scope/pkg has ONE leading @ and no
      # second @ → unpinned; a pinned spec has a trailing @<pin> (so @scope/pkg@1.2.3 has two @).
      ats="${spec//[!@]/}"          # the @ characters only
      case "$spec" in
        @*) pinned=$([ "${#ats}" -ge 2 ] && echo 1 || echo 0) ;;   # scoped: need a SECOND @
        *)  pinned=$([ "${#ats}" -ge 1 ] && echo 1 || echo 0) ;;   # unscoped: any @ is the pin
      esac
      if [ "$pinned" -ne 1 ]; then
        k_ok=0; fail "$f [$srv]: '$spec' is unpinned — add @<version> ($cmd has no version pin)"
      fi
    done < <(jq -r '.mcpServers | to_entries[] | [.key, (.value.command // ""), ((.value.args // []) | join(" "))] | @tsv' "$f")
  done
  [ "$k_ok" -eq 1 ] && pass "every ephemeral-runner .mcp.json server pins an explicit @<version> (resident-binary servers exempt)"
fi

# ── (retired check) flow-mcp release/artifact parity ─────────────────────────
# The marketplace once shipped a roadmap MCP (flow-mcp): first a SHA-pinned Rust binary (with a
# RELEASE ⟺ Cargo ⟺ SHA256SUMS parity check), then an interpreted Ruby server. The whole flow plugin
# has since been RETIRED (the FLEET continuous-delivery engine supersedes it), so this check and its
# CI job are gone. The language-choice lesson survives in
# plugins/foundry/knowledge/architecture/mcp-language-choice.md.

# ── L. hooks smoke-exec (P1-8) ───────────────────────────────────────────────
# For every plugins/*/hooks/hooks.json, resolve each declared command's script path
# (${CLAUDE_PLUGIN_ROOT} → the plugin dir) and assert: the script EXISTS, passes `bash -n`, and runs
# to a ZERO exit when fed a minimal synthetic SessionStart event on stdin — sandboxed so it cannot
# touch real state: HOME and CLAUDE_PROJECT_DIR are fresh mktemp dirs, and it runs under a timeout
# (when available). A hook that is missing, unparsable, or exits non-zero = FAIL — that is exactly the
# dead inject-kaizen/capture-cost the runtime's `2>/dev/null || true` would otherwise hide. Hooks that
# legitimately emit nothing are fine (output is discarded; only the exit code is asserted).
section "L. hooks smoke-exec (exist · bash -n · zero-exit on a synthetic event)"
if ! command -v jq >/dev/null 2>&1; then
  fail "jq not found — required to read plugins/*/hooks/hooks.json"
else
  l_ok=1
  TIMEOUT=""; command -v timeout >/dev/null 2>&1 && TIMEOUT="timeout 20"
  syn='{"cwd":"/tmp","session_id":"smoke","source":"startup","hook_event_name":"SessionStart"}'
  for hj in plugins/*/hooks/hooks.json; do
    [ -f "$hj" ] || continue
    pdir="$(cd "$(dirname "$(dirname "$hj")")" && pwd)"
    while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      # Resolve the script path: the token after ${CLAUDE_PLUGIN_ROOT}.
      rel="$(printf '%s\n' "$cmd" | sed -n 's#.*${CLAUDE_PLUGIN_ROOT}\(/[^ ]*\).*#\1#p')"
      if [ -z "$rel" ]; then continue; fi   # non-script command (no plugin-root script) — nothing to smoke
      script="$pdir$rel"
      if [ ! -f "$script" ]; then
        l_ok=0; fail "$hj: command references missing script $rel"; continue
      fi
      if ! bash -n "$script" 2>/dev/null; then
        l_ok=0; fail "$script: bash -n syntax error"; continue
      fi
      sb="$(mktemp -d)"; pj="$(mktemp -d)"
      if printf '%s' "$syn" | HOME="$sb" CLAUDE_PROJECT_DIR="$pj" CLAUDE_PLUGIN_ROOT="$pdir" $TIMEOUT bash "$script" >/dev/null 2>&1; then
        :
      else
        rc=$?
        l_ok=0; fail "$script: non-zero exit ($rc) on a synthetic SessionStart event"
      fi
      rm -rf "$sb" "$pj"
    done < <(jq -r '.hooks // {} | to_entries[] | .value[] | .hooks[]? | select(.type=="command") | .command' "$hj")
  done
  [ "$l_ok" -eq 1 ] && pass "every hooks.json command resolves to a script that exists, parses, and exits 0 on a synthetic event"
fi

# ── M. LSP capability probes exist AND are no-download (P2-14) ────────────────
# The browser incident's lesson — presence ≠ capability — generalised to Language Server
# Protocol servers (review L12). A `command -v <lsp>` row proves the binary is on PATH; it does
# NOT prove the server actually SPEAKS LSP. So this check asserts TWO things over the
# requirements.tsv probe cells (column 2):
#   (1) APPLIED — at least one CAPABILITY-grade LSP probe exists somewhere in the marketplace: a
#       probe that drives a language server over its JSON-RPC stdio wire (the capability signature is
#       an LSP `initialize` request framed with `Content-Length` — the protocol itself, not a flag).
#       A marketplace with only `command -v <lsp>` presence rows has re-opened the exact gap P2-14
#       closes, so that is a FAIL.
#   (2) NO-DOWNLOAD — every such capability probe obeys the sacred no-download invariant (the same
#       deny set check G enforces for the whole tsv probe class): a capability probe may LAUNCH the
#       server locally, but must never fetch-and-run a package (uvx/bunx/pnpm dlx, npx -y/--yes,
#       npx …@<spec>, pip install, npm i|install, curl … | sh). This is check G's property, asserted
#       again but SCOPED to the LSP class so a future capability row can't smuggle in a download.
# Detection is on the PROTOCOL fingerprint, so it is independent of which LSP server (pyright /
# typescript-language-server / rust-analyzer) a probe happens to drive. awk stderr is captured so a
# parse/runtime error fails the check loudly (never a vacuous PASS). The deny boolean is kept on ONE
# line on purpose (mawk on Debian/GitHub ubuntu-latest rejects a parenthesised expr split across lines).
section "M. LSP capability probes exist + are no-download (presence ≠ capability)"
m_err="$(mktemp)"
# awk emits one tagged line per capability-grade LSP row: "CAP\t…" for every such row, plus an extra
# "BAD\t…" for any that ALSO violate the no-download deny set. Shell splits the tags afterwards — a
# single stdout stream, so there is no dual-redirect conflict (a genuine awk fault still lands on
# stderr → m_err and fails the check loudly).
m_lines="$(
  while IFS= read -r tsv; do
    awk -F'\t' -v file="$tsv" '
      /^#/ || /^[[:space:]]*$/ { next }
      {
        p=$2
        # Capability signature: an LSP `initialize` request framed on the JSON-RPC stdio wire.
        if (!(p ~ /Content-Length/ && p ~ /initialize/)) next
        print "CAP\t"file" :: "$1
        if (p ~ /command -v/ && p !~ /(^|[^[:alnum:]_])(uvx|bunx)([ \t]|$)/ && p !~ /pnpm[ \t]+dlx/ && p !~ /npx[ \t]+(-y|--yes)/ && p !~ /npx[ \t]+[^ \t]*@/ && p !~ /pip[ \t]+install/ && p !~ /npm[ \t]+(i|install)([ \t]|$)/ && p !~ /curl[^|]*\|[ \t]*(ba)?sh/) next
        print "BAD\t"file" :: "$1" :: "p
      }
    ' "$tsv" 2>>"$m_err"
  done < <(find plugins -path '*/skills/check/requirements.tsv' | sort)
)"
m_caps="$(printf '%s\n' "$m_lines" | sed -n 's/^CAP\t//p')"
m_offenders="$(printf '%s\n' "$m_lines" | sed -n 's/^BAD\t//p')"
if [ -s "$m_err" ]; then
  fail "awk error while scanning for LSP capability probes — check M did not run:"; sed 's/^/      /' "$m_err"
elif [ -z "$m_caps" ]; then
  fail "no capability-grade LSP probe found — every LSP row is presence-only (command -v); presence ≠ capability (P2-14)."
elif [ -n "$m_offenders" ]; then
  fail "LSP capability probe(s) violate the no-download invariant (launch the server locally; never fetch a package):"
  printf '%s\n' "$m_offenders" | sed 's/^/      /'
else
  pass "$(printf '%s\n' "$m_caps" | grep -c .) capability-grade LSP probe(s) present, all no-download (JSON-RPC initialize over stdio, never an install)"
fi
rm -f "$m_err"

# ── P. roadmap v2 conformance (FLEET pipeline grammar + vendored-standard pin) ─
# The roadmap IS the FLEET v2 pipeline (docs/roadmap/). Its grammar is load-bearing — the engine
# parses it with regex/awk, so a wrong shape silently skips or mis-reads the project. This check
# asserts the on-disk artifacts conform AND that the vendored standard has not drifted from FLEET.
#
#   (1) .pipeline.md manifest rows (manifest/local_file mode ONLY — board-mode repos retire the manifest
#       and hold state on a GitHub Project, so its ABSENCE is valid): leading `|`, first 3 columns
#       `order | epic | state`, order = 4 digits.
#   (2) each EPIC_NNNN.md (validated whenever EPIC docs exist, in BOTH modes): a single-physical-line
#       `**Branch**` whose scrape (pipeline/NNNN-slug) is non-empty; and any `## Plans` table uses
#       `order|plan|state`. (This is the live-roadmap grammar floor that survives manifest retirement.)
#   (3) the vendored references/fleet-pipeline-standard.md carries the pinned schema-version, and — when
#       the external FLEET source is present on this box — is byte-identical to it (FAIL LOUD on drift →
#       forces a human re-vendor + pin bump). RE-VENDOR OWNER: foundry maintainer, on any FLEET schema bump.
#
# NOTE: gate CONTENT (coverage floor / flaky / BDD) is NOT asserted here. The DoD floors of an emitted
# PLAN's .pipeline/verify are roadmapper's PLAN "Definition of done" template + FOUNDRY's per-build DoD
# audit, enforced per emitted project. This marketplace meta-repo has no application test-suite to floor
# (its gate is EPIC_0001's deterministic manifest+python checks). Check P guards GRAMMAR + vendor-pin.
EXPECTED_SCHEMA_VERSION="017"   # the FLEET v2 plan schema (doc 017) the vendored copy validated against
section "P. roadmap v2 conformance"
vendored_std="plugins/foundry/skills/roadmapper/references/fleet-pipeline-standard.md"
manifest="docs/roadmap/.pipeline.md"
p_fail=0

# (3a) vendored standard exists + carries the pinned schema-version token
if [ ! -f "$vendored_std" ]; then
  fail "vendored FLEET standard missing: $vendored_std"; p_fail=1
elif ! grep -qE "schema .${EXPECTED_SCHEMA_VERSION}|v2 \(${EXPECTED_SCHEMA_VERSION}\)" "$vendored_std"; then
  fail "vendored FLEET standard does not declare the pinned schema-version ${EXPECTED_SCHEMA_VERSION} (re-vendor + bump EXPECTED_SCHEMA_VERSION)"; p_fail=1
fi
# (3b) opportunistic drift compare against the live external FLEET source(s) on this box (CI: absent →
# skipped). A box may carry MORE THAN ONE copy at different schema versions (e.g. a v2 monorepo checkout
# + a stale v1-only plugin cache). Only a copy that ALSO declares the pinned schema-version counts as a
# drift ORACLE — a stale v1 copy must never be treated as the truth. FAIL only if ≥1 same-version oracle
# exists and the vendored copy matches NONE of them.
drift_note=""
if [ -f "$vendored_std" ]; then
  vmd5="$(md5sum < "$vendored_std")"; oracle_found=0; oracle_match=0
  for c in \
    "$HOME/.local/share/fleet/pipeline-marketplace/pipeline/skills/roadmap-to-pipeline/references/fleet-pipeline-standard.md" \
    "$HOME"/.claude/plugins/cache/fleet-pipeline/pipeline/*/skills/roadmap-to-pipeline/references/fleet-pipeline-standard.md; do
    [ -f "$c" ] || continue
    grep -qE "schema .${EXPECTED_SCHEMA_VERSION}|v2 \(${EXPECTED_SCHEMA_VERSION}\)" "$c" || continue   # same-version copies only are oracles
    oracle_found=1
    [ "$(md5sum < "$c")" = "$vmd5" ] && oracle_match=1
  done
  if [ "$oracle_found" -eq 1 ] && [ "$oracle_match" -eq 0 ]; then
    fail "vendored FLEET standard has DRIFTED from every same-version (${EXPECTED_SCHEMA_VERSION}) live source on this box — re-vendor (cp) and bump the schema-version pin if the grammar changed"; p_fail=1
  fi
  [ "$oracle_match" -eq 1 ] && drift_note=" (drift-checked vs live FLEET)"
fi

# (1)+(2) on-disk artifact grammar. The manifest is OPTIONAL — board-mode repos retire it (state lives
# on the GitHub Project), so its absence is valid; but the EPIC/PLAN docs remain and ARE still validated.
epics_present=0; ls docs/roadmap/EPIC_*.md >/dev/null 2>&1 && epics_present=1
# (1) manifest pipeline rows — manifest/local_file mode only (skip header + separator rows)
if [ -f "$manifest" ]; then
  while IFS= read -r row; do
    case "$row" in
      '| order '*|'| ---'*|'|---'*) continue ;;   # header / separator
      '|'*) ;;                                      # a data row
      *) continue ;;                               # not a table row
    esac
    ord="$(printf '%s' "$row" | awk -F'|' '{gsub(/[` ]/,"",$2); print $2}')"
    if ! printf '%s' "$ord" | grep -qE '^[0-9]{4}$'; then
      fail "manifest row order not 4 digits: $row"; p_fail=1
    fi
  done < "$manifest"
fi
# (2) per-EPIC docs — validated whenever ANY EPIC doc exists (covers BOTH manifest and board mode); this
# is the live-roadmap grammar floor that survives manifest retirement.
if [ "$epics_present" -eq 1 ]; then
  while IFS= read -r epic; do
    [ -f "$epic" ] || continue
    # single-physical-line **Branch** scrape
    br="$(grep -E '\*\*Branch\*\*' "$epic" | grep -oE 'pipeline/[0-9]{4}-[A-Za-z0-9._-]+' | head -1)"
    if [ -z "$br" ]; then
      fail "$epic: **Branch** scrape empty (must be one physical line: \`pipeline/NNNN-slug\`)"; p_fail=1
    fi
    # any ## Plans table must use the 3-col plan grammar, not the manifest's epic grammar
    if grep -qE '^\| order \| epic \|' "$epic"; then
      fail "$epic: a '## Plans' table uses the manifest grammar (order|epic|state) — it must be order|plan|state"; p_fail=1
    fi
  done < <(ls docs/roadmap/EPIC_*.md 2>/dev/null)
fi
# pass messaging by mode
if [ "$p_fail" -eq 0 ]; then
  if [ -f "$manifest" ]; then
    pass "roadmap v2 artifacts conform (manifest 4-digit order, EPIC **Branch** scrape, ## Plans grammar) + vendored standard pinned @${EXPECTED_SCHEMA_VERSION}${drift_note}"
  elif [ "$epics_present" -eq 1 ]; then
    pass "board-mode roadmap: EPIC docs conform (**Branch** scrape, ## Plans grammar); no .pipeline.md (board authoritative) + vendored standard pinned @${EXPECTED_SCHEMA_VERSION}${drift_note}"
  else
    pass "no docs/roadmap roadmap yet (no v2 roadmap to conform); vendored standard pinned @${EXPECTED_SCHEMA_VERSION}${drift_note}"
  fi
fi

# ── Q. shipped .mcp.json servers ⟺ SLASH_COMMANDS.md "Appendix — MCP servers" ─
# Check C's sibling, over the user-facing slash-command catalog. The "## Appendix — MCP servers" table
# in docs/SLASH_COMMANDS.md is hand-maintained and had no binding to the real shipped inventory, so it
# silently drifted when a plugin's .mcp.json changed (the ONE BROWSER cutover left two stale "ships a
# Playwright MCP" claims behind — #246). This asserts three parities against plugins/*/.mcp.json:
# server-set, the "Shipped by" plugin list per server, and the "ships N MCP servers" count line. The
# host-provided chrome-devtools MCP is driven-not-shipped, lives in prose OUTSIDE the table, and is
# correctly ignored (only `|`-rows are parsed). python3 (already required by check C) does the parse.
section "Q. shipped MCP servers ⟺ SLASH_COMMANDS.md appendix"
if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 not found — required to read plugins/*/.mcp.json"
else
  q_out="$(python3 - <<'PYEOF'
import json, glob, re, sys

# Real shipped inventory: server -> set(plugin dir names) from every plugins/*/.mcp.json
shipped = {}
for f in sorted(glob.glob("plugins/*/.mcp.json")):
    plugin = f.split("/")[1]
    try:
        data = json.load(open(f))
    except Exception as e:
        print(f".mcp.json unreadable: {f}: {e}"); sys.exit(1)
    for srv in (data.get("mcpServers") or {}):
        shipped.setdefault(srv, set()).add(plugin)

doc = "docs/SLASH_COMMANDS.md"
try:
    lines = open(doc).read().splitlines()
except Exception as e:
    print(f"{doc} unreadable: {e}"); sys.exit(1)

WORDS = {"zero":0,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,
         "seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12}
in_appendix = False
table = {}          # server -> set(plugins) as documented
count_decl = None
for ln in lines:
    if ln.startswith("## "):
        if "Appendix" in ln and "MCP servers" in ln:
            in_appendix = True; continue
        elif in_appendix:
            break       # left the appendix section
    if not in_appendix:
        continue
    if count_decl is None:   # FIRST "ships N MCP servers" wins — a later mention can't mask a wrong headline
        m = re.search(r"ships\s+([A-Za-z]+|\d+)\s+MCP servers", ln)
        if m:
            tok = m.group(1).lower()
            count_decl = int(tok) if tok.isdigit() else WORDS.get(tok)
    if ln.lstrip().startswith("|"):
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        if not cells:
            continue
        if "Server" in cells[0] or set("".join(cells).replace(" ", "")) <= set(":-"):
            continue    # header row / separator row
        sm = re.search(r"`([^`]+)`", cells[0])
        if not sm:
            continue
        server = sm.group(1)
        plugins = set()
        if len(cells) > 1:
            for p in cells[1].split(","):
                p = p.strip().strip("`").strip()
                if p:
                    plugins.add(p)
        table[server] = plugins

errs = []
sj, st = set(shipped), set(table)
for s in sorted(sj - st):
    errs.append(f"`{s}` is shipped (in {', '.join(sorted(shipped[s]))}/.mcp.json) but ABSENT from the appendix table")
for s in sorted(st - sj):
    errs.append(f"appendix lists `{s}` but NO plugins/*/.mcp.json ships it")
for s in sorted(sj & st):
    if shipped[s] != table[s]:
        errs.append(f"`{s}` shipped-by mismatch — .mcp.json={{{', '.join(sorted(shipped[s]))}}}, appendix={{{', '.join(sorted(table[s])) or '∅'}}}")
n = len(shipped)
if count_decl is None:
    errs.append(f'no "ships <N> MCP servers" count line found in the appendix (expected N={n})')
elif count_decl != n:
    errs.append(f"count line says {count_decl} but {n} server(s) are shipped")

if errs:
    print("\n".join(errs)); sys.exit(1)
print(f"{n} shipped server(s) match the appendix (names + shipped-by + count): " + ", ".join(sorted(shipped)))
PYEOF
)"
  if [ $? -eq 0 ]; then
    pass "$q_out"
  else
    fail "SLASH_COMMANDS.md MCP appendix drifted from the shipped .mcp.json inventory:"
    printf '%s\n' "$q_out" | sed 's/^/      /'
  fi
fi

# ── --fix: guarded canonical re-sync ─────────────────────────────────────────
# Only acts when --fix was passed. Re-syncs the drifted canonical copies registered by checks A/E/F/N/O
# from their named canonical source. GUARDS (all mandatory): refuse on a dirty git tree; print the
# diff of every change first; touch ONLY the registered canonical-copy set (never an unrelated or
# intentionally-diverged file). Without --fix the registry is computed but never applied.
if [ "$fix" -eq 1 ]; then
  section "--fix. guarded canonical re-sync"
  if [ "${#resync_dst[@]}" -eq 0 ]; then
    pass "nothing to re-sync; all parity checks pass"
  elif ! git diff --quiet || ! git diff --cached --quiet; then
    fail "refusing to --fix: git tree is dirty. Commit/stash your changes first, then re-run --fix."
  else
    printf "  %bwould re-sync %d drifted copy(ies) from their canonical source:%b\n" "$dim" "${#resync_dst[@]}" "$reset"
    for i in "${!resync_dst[@]}"; do
      printf "    %s  ⟸  %s\n" "${resync_dst[$i]}" "${resync_src[$i]}"
      diff -u "${resync_dst[$i]}" "${resync_src[$i]}" | sed 's/^/      /' || true
    done
    for i in "${!resync_dst[@]}"; do
      cp "${resync_src[$i]}" "${resync_dst[$i]}"
    done
    pass "re-synced ${#resync_dst[@]} copy(ies); re-run without --fix to confirm parity restored"
  fi
fi

# ── verdict ──────────────────────────────────────────────────────────────────
printf "\n"
if [ "$fails" -eq 0 ]; then
  printf "%b✓ PREREQUISITES contract verified — all checks passed.%b\n" "$green" "$reset"
  exit 0
else
  printf "%b✗ %d check(s) failed.%b\n" "$red" "$fails" "$reset"
  exit 1
fi
