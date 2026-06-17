#!/usr/bin/env bash
# raise-feedback.sh — the GEMBA ISSUE RAISER: file a feedback issue on the resolved target repo.
#
# WHAT IT DOES (the genuinely net-new primitive — no `gh issue create` existed before)
#   Wraps `gh api repos/<org>/<repo>/issues` (REST only — no `gh issue` porcelain) to file ONE feedback
#   issue on the target repo that identity.sh resolved for the learning, with three guards:
#     • DEDUP   — searches existing OPEN+CLOSED issues for the same stable slug BEFORE filing; an
#                 identical issue suppresses a second filing (idempotent capture).
#     • AUTONOMY — a SELF (same-repo) target files automatically; a GEMBA (sibling) target REFUSES
#                 unless --confirm is given (cross-repo writes always need a human nod).
#     • --dry-run — composes the title/body and prints what WOULD be filed, files nothing.
#
#   The target repo + verdict are resolved by identity.sh from <dir>/.i2p/identity.json, so flipping
#   `github_org` re-points where issues are raised. On success it prints the issue URL on stdout (the
#   gemba skill records it back to the learning ledger via `learnings.sh filed --issue <url>`).
#
# USAGE
#   raise-feedback.sh --dir <dir> --hint "<where-it-belongs hint>" --title "<title>" \
#                     [--body "<md>" | --body-file <path>] [--slug <stable-slug>] \
#                     [--label feedback] [--confirm] [--dry-run]
#   The slug defaults to a deterministic slugification of the title (dedup key).
#
# Needs jq. `gh` is needed to actually file/dedup (not for --dry-run). REST-only; no token handling here
#   (gh provides auth). Exits: 0 filed/dry-run/deduped, 3 refused (sibling without --confirm), 2 usage.
set -uo pipefail

SELFDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDENTITY="${SELFDIR}/identity.sh"

dir="."; hint=""; title=""; body=""; body_file=""; slug=""; label="feedback"
confirm=0; dry_run=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       dir="${2:-.}"; shift 2 ;;
    --hint)      hint="${2:-}"; shift 2 ;;
    --title)     title="${2:-}"; shift 2 ;;
    --body)      body="${2:-}"; shift 2 ;;
    --body-file) body_file="${2:-}"; shift 2 ;;
    --slug)      slug="${2:-}"; shift 2 ;;
    --label)     label="${2:-feedback}"; shift 2 ;;
    --confirm)   confirm=1; shift ;;
    --dry-run)   dry_run=1; shift ;;
    *)           shift ;;
  esac
done
dir="${dir%/}"

have() { command -v "$1" >/dev/null 2>&1; }
have jq || { echo "raise-feedback: jq required" >&2; exit 2; }
[ -n "$title" ] || { echo "raise-feedback: --title is required" >&2; exit 2; }

# slugify — deterministic stable slug from the title (lowercased, non-alnum → '-', squeezed/trimmed).
slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'; }
# Always normalise — an explicit --slug is slugified too, so it can never inject raw text (spaces,
# quotes, colons) into the dedup search query. Default to the title when no --slug was given.
slug="$(slugify "${slug:-$title}")"

# Resolve the target repo + SELF/GEMBA verdict via identity.sh (honours its own --dry-run for seeding).
res="$(bash "$IDENTITY" resolve "$dir" "$hint" ${dry_run:+--dry-run} 2>/dev/null)"
[ -n "$res" ] || { echo "raise-feedback: could not resolve identity for dir=$dir" >&2; exit 2; }
verdict="$(printf '%s' "$res" | jq -r '.verdict // "self"')"
target="$(printf '%s' "$res" | jq -r '.target // ""')"
[ -n "$target" ] || { echo "raise-feedback: identity returned no target" >&2; exit 2; }

# Compose the body. A body-file wins; else the --body string; else a minimal stub with the slug marker.
if [ -n "$body_file" ] && [ -r "$body_file" ]; then
  body="$(cat "$body_file")"
fi
# Always embed a hidden, stable slug marker so dedup has a deterministic anchor even if the title drifts.
marker="<!-- gemba-feedback-slug: ${slug} -->"
composed_body="${body}

${marker}"

# DRY-RUN takes precedence — it composes and prints what WOULD be filed and touches nothing, so it is
# always safe (even for a sibling target; the autonomy refusal below is purely about a REAL filing).
if [ "$dry_run" -eq 1 ]; then
  note=""; [ "$verdict" = "gemba" ] && [ "$confirm" -eq 0 ] && note=" — a real filing here would REFUSE without --confirm (sibling)"
  echo "raise-feedback: (--dry-run) would file on ${target} [verdict=${verdict}]${note}"
  printf 'TITLE: %s\nSLUG:  %s\nLABEL: %s\nREPO:  %s\n--- BODY ---\n%s\n' \
    "$title" "$slug" "$label" "$target" "$composed_body"
  exit 0
fi

# AUTONOMY gate: a sibling (gemba) target refuses to file without --confirm.
if [ "$verdict" = "gemba" ] && [ "$confirm" -eq 0 ]; then
  echo "raise-feedback: REFUSED — target ${target} is a SIBLING (gemba) repo; cross-repo filing needs --confirm." >&2
  echo "Would-be issue on ${target}:" >&2
  echo "  title: ${title}" >&2
  echo "  slug:  ${slug}" >&2
  echo "  label: ${label}" >&2
  echo "--- body ---" >&2
  printf '%s\n' "$composed_body" >&2
  exit 3
fi

# From here we actually touch GitHub — gh is mandatory.
have gh || { echo "raise-feedback: \`gh\` not installed — cannot file/dedup (use --dry-run to compose only)" >&2; exit 2; }

org="${target%%/*}"; repo="${target##*/}"

# DEDUP — search the repo for an issue carrying the same slug marker (REST search, open + closed).
# A hit suppresses the filing (idempotent). The `in:body` qualifier matches the hidden slug marker.
# FAIL CLOSED: the search exit status is captured separately from its (possibly empty) output. A
# NON-ZERO search (transient gh/network/rate-limit failure) must NOT be read as "no duplicate" — that
# would spam duplicates on the auto-file path. On a search error we refuse to file and exit non-zero;
# only a SUCCESSFUL empty result is treated as "no existing issue → safe to file".
existing="$(gh api -X GET search/issues --field q="repo:${target} \"gemba-feedback-slug: ${slug}\" in:body" -q '.items[0].html_url // empty' 2>/dev/null)"
search_rc=$?
if [ "$search_rc" -ne 0 ]; then
  echo "raise-feedback: dedup search failed (gh exit ${search_rc}) — refusing to file to avoid duplicates (retry)." >&2
  exit 1
fi
if [ -n "$existing" ]; then
  echo "raise-feedback: DEDUP — an issue with slug '${slug}' already exists on ${target}: ${existing}"
  printf '%s\n' "$existing"
  exit 0
fi

# FILE — REST POST to repos/<org>/<repo>/issues. labels as a JSON array via jq-built payload.
payload="$(jq -nc --arg t "$title" --arg b "$composed_body" --arg l "$label" \
  '{title:$t, body:$b, labels:($l|split(","))}')"
url="$(printf '%s' "$payload" | gh api -X POST "repos/${org}/${repo}/issues" --input - \
        -q '.html_url // empty' 2>/dev/null || true)"
if [ -z "$url" ]; then
  echo "raise-feedback: gh api POST to repos/${org}/${repo}/issues failed (auth? repo access?)." >&2
  exit 1
fi
echo "raise-feedback: filed on ${target} [verdict=${verdict}]: ${url}"
printf '%s\n' "$url"
exit 0
