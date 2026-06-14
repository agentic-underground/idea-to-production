---
description: Run the roadmap flow board — auto-managed daemon that serves the live SVG governance UI on the network and advertises a clickable URL while the roadmap has items.
---

Run the **flow** skill — manual control of the flow-board daemon (the auto-run is handled by the
mission-control SessionStart + ROADMAP-edit hooks).

Route from `$ARGUMENTS` (default: `status`) to the controller
`${CLAUDE_PLUGIN_ROOT}/flow-server/bin/flowctl.sh`:

- `status` — is the board running? print its reachable URL (or `building…` / `stopped`).
- `start` — start it now (if the roadmap has items); binds `0.0.0.0`, advertises the LAN URL.
- `stop` — stop the daemon.
- `url` — print the clickable `http://<LAN-IP>:<port>/?token=…` link.
- `build` — one-time `cargo build` of the flow-server binary (needed once per checkout; `target/` is gitignored).

```bash
bash "${CLAUDE_PLUGIN_ROOT}/flow-server/bin/flowctl.sh" "${ARGUMENTS:-status}"
```

Report the URL to the user. **Security:** the board binds `0.0.0.0` (LAN-reachable) — the bearer token in
`.flow/token` is the only guard and the URL embeds it, so treat the URL as a secret on a shared network. Set
`FLOW_HOST=127.0.0.1` to bind localhost-only.
