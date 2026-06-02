# ROADMAP — deferred capability

v1 is the design system itself: philosophy, the INTENT marker protocol, the element registry + `-help`, the elicitation flow, the starter elements, and the adversarial design-critic procedure. The items below are real, valued, and deliberately deferred — read this before promising work in these areas.

## 1. Large datasets & virtualization
Browse grids, tables, and spreadsheet-dense paradigms need windowing/virtualization to stay fast and accessible at thousands of rows. Must preserve keyboard roving, focus management, and reduced layout shift under virtualization. Affects: `browse-grid`, future `data-table`, `inline-text-edit` at scale.

## 2. Large graph-canvases (connected objects on a huge background)
Pan/zoom canvas of connected objects (nodes + edges) on a very large surface. Needs: spatial navigation by keyboard, accessible alternatives to a purely spatial view, level-of-detail rendering, and INTENT markers that survive on canvas nodes. Architecturally leans event-driven + space-based (see `philosophy/architecture-styles.md`).

## 3. Serverless device-swap / distributed-documents (high value)
The open problem from `philosophy/privacy-as-architecture.md`: let a customer move between phone and laptop **without a server**, keeping data private and local-first, without the friction of manual export/import every time. Explore CRDTs, peer-to-peer transports, and encrypted-blob handoff. Solving this cleanly is a strategic prize: cloud-grade continuity with local-first privacy.

## 4. Full automation of adversarial sub-agent spawning
v1 documents *how* to run the design-critic (small, self-contained context) and provides its definition-of-good. Later: automate spawning critic sub-agents on every build, route their findings (and Feedback-Marker signal) into a scored, tracked improvement loop — the second-way HIL optimisation closing on itself.

## 5. Element registry growth
Candidate future elements: data-table (editable, sortable, virtualized), date/time picker, relationship explorer, hierarchical/tree selector, rich-text editor, file uploader, map/geographic picker, levers/sliders, chart family. Each ships as a registry page in the established anatomy and is added to `elements/README.md` so `-help` stays current.
