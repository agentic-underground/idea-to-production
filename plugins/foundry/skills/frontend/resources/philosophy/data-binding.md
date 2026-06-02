# Data Binding — one-way, triggered, validated

## One-way binding
Data flows **down** (host → element renders from `value`); **intents flow up** (element emits `add`/`remove`/`commit`/`select`; host applies and re-renders). Elements never mutate their inputs. This keeps a single source of truth and makes the system predictable for both customers and future agents.

## Render-triggers
Elements subscribe to named triggers (e.g. `tags.changed`, `value.changed`, `collection.changed`) and re-render on them. Markers record which triggers an element responds to (`render-trigger`).

## Real-time validation (table-stakes)
Validate as the customer acts, in real time. Show errors in text adjacent to the field, keep focus, never destroy in-progress input. Validation is part of **earning trust** — see `privacy-as-architecture.md`.

## Persistence
Binding is independent of where data lives: the same one-way contract works over IndexedDB (local-first default) or HTTP to a server. The persistence choice is a separate, explicit decision recorded in the marker.
