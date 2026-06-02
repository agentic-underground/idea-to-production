# Architecture Styles (Richards & Ford) — applied to front-end composition

*Fundamentals of Software Architecture* (Richards & Ford, 2020) catalogues nine architecture styles. FRONT-END borrows them as a vocabulary for composing UIs from building blocks — and for recording, in markers, *which* compositional stance a screen takes so later agents extend it coherently.

## The nine styles (one-line each)
1. **Layered (n-tier)** — concerns stacked (presentation/logic/data). Maps to: render layer ← intent layer ← state/persistence layer (our one-way binding is layered).
2. **Pipeline (pipes & filters)** — data flows through transforms. Maps to: input → validate → format → render pipelines.
3. **Microkernel (plug-in)** — a small core plus plug-ins. Maps to: an element registry where each UI element is a plug-in around a small binding core. **This is FRONT-END's own shape.**
4. **Service-based** — a few coarse services. Maps to: grouping screens around a handful of domain services (catalogue, library, composition).
5. **Event-driven** — components react to events. Maps to: render-triggers and emitted intents; the natural fit for one-way binding.
6. **Space-based** — replicated state for scale/resilience. Maps to: local-first replicas and the distributed-documents / device-swap problem (see ROADMAP).
7. **Orchestration-driven SOA** — central orchestrator. (Rarely the right front-end stance; note when used.)
8. **Microservices** — many small independently-deployable services. Maps to: independently-shippable element/feature bundles.
9. **Monolith (modular)** — one deployable, well-modularised. Often the honest default for a vanilla-JS app — modular internally, single artifact externally.

## How to use this
- Name the dominant style in a screen's marker when it's architecturally meaningful (e.g. `microkernel` for the element system, `event-driven` for binding, `space-based` for sync work).
- Composable building blocks → **elements** (plug-ins) over a small **binding core** (microkernel), reacting to **events** (render-triggers): that trio is the system's spine.
- When choosing between options, an ADR (see the engineering:architecture discipline) records the trade-off so the decision is legible later.
