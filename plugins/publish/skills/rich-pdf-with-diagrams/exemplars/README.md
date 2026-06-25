# Exemplars

These two `.dot` files are the canonical examples of what good A4-portrait
diagrams look like under this skill's rules.

| File | Pattern | Why it works |
|------|---------|--------------|
| `01-system-stack.dot` | Pattern 6 (Layered architecture) | Four labelled clusters (browser / server / domain / storage) stacked TB. Each cluster has ≤4 boxes. Inter-layer arrows use ortho splines. Colour family per layer. |
| `05-deliver-arch.dot` | Pattern 1 + Pattern 3 (Multi-phase + Wide fan-out wrap) | Central TB flow (Roadmap → Lead Engineer → Phase Pool → Handler Pool → Ledger). Handler pool wraps to two rows of 4+3. Visible balance between left content and right ledger node. |

When in doubt, copy one of these and modify it. Do not design diagrams
from a blank file.
