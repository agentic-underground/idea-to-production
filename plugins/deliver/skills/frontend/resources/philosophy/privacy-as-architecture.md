# Privacy as Architecture (non-negotiable)

The customer's data is **theirs**. It is private. They may share it themselves; the system does not need to see it.

## Defaults
- **Local-first.** Persist to the device (IndexedDB) by default. The app works offline and fast.
- **Cloud-save is opt-in and asked-for, never assumed.** When a design might benefit from "save to our servers", you *ask the developer* whether to offer it, and the end-customer must actively choose it.
- **Import/Export is the lowest-exposure sharing primitive.** For customers truly committed to privacy, a file they move themselves carries far less exposure risk than remote storage. Offer it first.

## Consequences for design
- Sync between devices without a server is an open, valuable problem — see `../ROADMAP.md` (distributed-documents / device-swap). Treat solving it as high-value.
- Feedback signals (see the Feedback Marker element) are local-first and opt-in to share.
- Validation and trust go together: real-time validation is part of earning the customer's trust that their data is safe and correct in their own hands.

State the persistence choice in every screen's INTENT marker (`breadcrumbs`).
