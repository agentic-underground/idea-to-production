#!/usr/bin/env bash
# publish-wiki.sh — publish PRESSROOM's per-item docs (doc/articles/) to the origin's .wiki.git.
#
# Read-only against the USER's repo (it only reads doc/articles/); all writes land in a scratch wiki
# clone under the system temp dir. Idempotent: re-running re-syncs pages. Degrades gracefully — a clean
# no-op with a named reason when the origin is not GitHub, when git/gh is unavailable, when the wiki has
# never been enabled, or when there is no PRESSROOM output to publish. Never fabricates content.
#
# Exit 0 = published OR a legible, intentional no-op. Exit 1 = a real failure (push refused, etc.).
set -uo pipefail

DIR="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="${2:-$PWD}"; shift 2 ;;
    *) shift ;;
  esac
done

note() { printf '%s\n' "$*" >&2; }

command -v git >/dev/null 2>&1 || { note "no-op: git unavailable (cannot clone .wiki.git)"; exit 0; }

# --- GitHub origin only ---
url="$(git -C "$DIR" remote get-url origin 2>/dev/null || true)"
slug=""
case "$url" in
  git@github.com:*)        slug="${url#git@github.com:}"; slug="${slug%.git}" ;;
  https://github.com/*)    slug="${url#https://github.com/}"; slug="${slug%.git}" ;;
  ssh://git@github.com/*)  slug="${url#ssh://git@github.com/}"; slug="${slug%.git}" ;;
esac
[ -n "$slug" ] || { note "no-op: origin is not a github.com remote (wiki target is GitHub-specific)"; exit 0; }

# --- there must be something #12 produced to publish ---
SRC="$DIR/doc/articles"
if [ ! -d "$SRC" ] || [ -z "$(find "$SRC" -type f -name '*.md' 2>/dev/null | head -1)" ]; then
  note "no-op: no PRESSROOM output to publish (doc/articles/ empty) — run /publish per completed item first"
  exit 0
fi

# --- prefer gh for auth; else fall back to the ambient credential helper ---
wiki_url="https://github.com/${slug}.wiki.git"
if command -v gh >/dev/null 2>&1; then
  tok="$(gh auth token 2>/dev/null || true)"
  [ -n "$tok" ] && wiki_url="https://x-access-token:${tok}@github.com/${slug}.wiki.git"
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/mc-wiki.XXXXXX")" || { note "no-op: cannot create scratch dir"; exit 0; }
trap 'rm -rf "$work"' EXIT

if ! git clone --depth 1 "$wiki_url" "$work/wiki" >/dev/null 2>&1; then
  # A brand-new wiki may be empty (clone refused). Try to init-and-push the first page.
  if ! git -C "$DIR" ls-remote "$wiki_url" >/dev/null 2>&1; then
    note "no-op: the wiki for ${slug} is not enabled (initialise it once on GitHub: repo → Wiki → Create the first page), then re-run"
    exit 0
  fi
  mkdir -p "$work/wiki"; ( cd "$work/wiki" && git init -q && git remote add origin "$wiki_url" )
fi

dst="$work/wiki"

# --- map each per-item doc to a wiki page; rewrite + copy embedded illustrations ---
sidebar="$work/_Sidebar.md"; : > "$sidebar"
index="$work/Home.md"
{
  printf '# Documentation\n\n'
  printf 'Per-item documentation, published from `doc/articles/` by MISSION-CONTROL `/wiki-publisher`.\n\n'
} > "$index"

pages=0
while IFS= read -r md; do
  rel="${md#"$SRC"/}"
  # Page title = first H1, else the slug.
  title="$(grep -m1 '^# ' "$md" 2>/dev/null | sed 's/^# *//')"
  [ -n "$title" ] || title="$(basename "${rel%.md}")"
  page="$(printf '%s' "$title" | tr -c 'A-Za-z0-9._ -' '-' | tr ' ' '-' )"
  cp "$md" "$dst/${page}.md"

  # Copy embedded illustrations referenced by the doc, rewriting the link to a wiki-relative path.
  srcdir="$(dirname "$md")"
  while IFS= read -r asset; do
    [ -n "$asset" ] || continue
    case "$asset" in http*|/*|*'<'*) continue ;; esac
    if [ -f "$srcdir/$asset" ]; then
      base="$(basename "$asset")"
      cp "$srcdir/$asset" "$dst/$base" 2>/dev/null || true
      # rewrite ](path) → ](base) inside the copied page (best-effort, exact path)
      python3 - "$dst/${page}.md" "$asset" "$base" 2>/dev/null <<'PY' || true
import sys,io
p,old,new=sys.argv[1],sys.argv[2],sys.argv[3]
s=io.open(p,encoding='utf-8').read().replace('](%s)'%old,'](%s)'%new)
io.open(p,'w',encoding='utf-8').write(s)
PY
    fi
  done < <(grep -oE '!\[[^]]*\]\([^)]+\)' "$md" 2>/dev/null | sed -E 's/.*\(([^)]+)\).*/\1/')

  printf -- '- [[%s]]\n' "$page" >> "$sidebar"
  printf -- '- [[%s]]\n' "$page" >> "$index"
  pages=$((pages+1))
done < <(find "$SRC" -type f -name '*.md' | sort)

cp "$sidebar" "$dst/_Sidebar.md"
cp "$index"   "$dst/Home.md"

# --- commit & push to the wiki's default branch ---
( cd "$dst"
  git add -A >/dev/null 2>&1
  git -c user.name='mission-control' -c user.email='mission-control@local' \
    commit -q -m "docs(wiki): publish ${pages} item page(s) from doc/articles/" >/dev/null 2>&1 || true
  branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo master)"
  if ! git push origin "HEAD:${branch}" >/dev/null 2>&1; then
    note "FAILED: push to ${slug}.wiki.git refused (auth missing, or wiki not enabled) — nothing published"
    exit 1
  fi
) || exit 1

note "published ${pages} page(s) to https://github.com/${slug}/wiki"
exit 0
