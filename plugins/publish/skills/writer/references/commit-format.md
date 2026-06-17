# Commit Format — article commits (PUBLISH-local)

A self-contained commit convention for article and documentation deliverables, so PUBLISH
never depends on any other plugin being installed. (If you are working inside a repository that
has its own commit convention, prefer that one; this is the fallback.)

Format: an emoji-prefixed Conventional-Commits subject, a `WHY`, a `WHAT`, and an optional
roadmap reference. The `TESTING` line is omitted — articles have no test suite.

## New article

```
📝 docs(articles): add "<article title>"

WHY:
[One sentence: what prompted the article and what it captures.]

WHAT:
- 📝 doc/articles/<slug>.md: [type] for [audience] (~[word count] words)

ROADMAP: [closes #N | n/a]
```

## Edited / revised article

```
📝 docs(articles): revise "<article title>"

WHY:
[One sentence: what changed and why — e.g. "address REVIEWER feedback".]

WHAT:
- 📝 doc/articles/<slug>.md: [brief description of what changed]

ROADMAP: [closes #N | n/a]
```

## Multiple articles in one session

```
📝 docs(articles): add [N] articles — <comma-separated titles>

WHY:
[One sentence: what prompted the batch.]

WHAT:
- 📝 doc/articles/<slug-1>.md: [type] (~[word count] words)
- 📝 doc/articles/<slug-2>.md: [type] (~[word count] words)

ROADMAP: [closes #N | n/a]
```

## Rules

- Stage **only** files under `doc/articles/` (or your docs output dir) — never batch article
  commits with code changes.
- If the output directory was just created, include it in the same commit as the first article.
- If the push fails, report the error — do not retry silently.
- Subject ≤ ~72 chars; `WHY`/`WHAT` wrapped at ~100.
