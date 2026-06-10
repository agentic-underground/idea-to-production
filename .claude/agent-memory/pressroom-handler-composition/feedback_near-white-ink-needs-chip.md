---
name: near-white-ink-needs-chip
description: In hand-SVG on transparent ground, near-white text fill (e.g. #e6e9f0) must sit on a surface chip or it vanishes on white grounds
metadata:
  type: feedback
---

Near-white neutral ink (the dark-mode canon `text` tone, e.g. `#e6e9f0`) placed
**directly on the transparent root ground** passes the dark-ground gate but nearly
disappears on the white ground — the classic dual-ground miss for titles/prose.

**Why:** transparent ground means white-on-white when rsvg renders onto `#ffffff`.
The accents (`#7aa2f7`, `#9ece6a`, `#e0af68`, `#b8bed0` dim) already clear both grounds;
only the bright neutral `text` tone fails.

**How to apply:** for any `#e6e9f0`-class text on transparent ground, either (a) seat it
on a `surface`/`surface-raised` chip (`#1e1e2e`/`#2a2a3c`) with a thin `stroke`, or
(b) demote it to the `dim` tone (`#b8bed0`) which clears both. Titles want weight, so
prefer the chip. Ink that already sits on a chip/box is safe — only audit text drawn
straight onto the root. Pairs with the dual-ground gate in the dark-mode canon.
