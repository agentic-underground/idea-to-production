---
name: sessionstart-bg-detach
description: Correct pattern for a SessionStart hook that backgrounds slow work without hanging the harness or check L
metadata:
  type: project
---

A SessionStart hook may pre-warm slow work (network download) in the background, but MUST detach so the harness's `$(...)` capture and check L's `timeout 20` return immediately.

**Why:** command substitution `out=$(bash hook)` waits for ALL fds inherited by background children to close, not just the hook process. A subshell-backgrounded child that inherits the captured stdout fd will block `$(...)` for the child's full duration (verified: a `( sleep 8 & )` with no fd redirect hangs `$(...)` 8s).

**How to apply:** the correct, verified-safe form is
`( "$CMD" >/dev/null 2>&1 & ) >/dev/null 2>&1 || true`
— the INNER `>/dev/null 2>&1` (before `&`) severs the child's stdout/stderr from the captured pipe, so `$(...)`/`timeout` see EOF instantly while the download continues detached. mission-control/hooks/scripts/flow-mcp-onboard.sh (PR #95) does this correctly: foreground returns 0s, the 4.2MB download lands ~15s later. Reuse this pattern; flag any SessionStart bg-spawn that omits the inner redirect. Model hook: concierge/hooks/offer-statusline.sh (same JSON-emit + sentinel shape). Related: [[flow-server-stdio-transport]].
