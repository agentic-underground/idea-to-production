//! Pure domain core — no IO, no UI, no platform code. Parse-don't-validate;
//! every fallible construction returns a typed `thiserror` enum; the [`Flow`]
//! graph is acyclic by construction.

pub mod annotation;
pub mod error;
pub mod event;
pub mod graph;
pub mod ids;
pub mod model;
pub mod roadmap_view;
pub mod telemetry;

pub use annotation::format_annotation;
pub use error::{FlowError, GraphError, IdError};
pub use event::Event;
pub use graph::{mutate_connection, validate_connection, Mutation};
pub use ids::{ItemId, MAX_ID_LEN};
pub use model::{Edge, Flow, Item, Status, WaitGate};
pub use roadmap_view::render_roadmap;
pub use telemetry::{ancestors, grafana_payload, rollup, CostReport, TelemetryEvent};
