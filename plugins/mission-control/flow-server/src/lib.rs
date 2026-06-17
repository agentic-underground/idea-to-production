//! Flow server library: the pure domain core plus the thin IO adapters (store,
//! auth, api, mcp). The binary (`main.rs`) wires them together and runs the
//! stdio MCP loop.

pub mod api;
pub mod auth;
pub mod config;
pub mod domain;
pub mod history;
pub mod mcp;
pub mod store;

// Dispatch-/store-level contract tests run in-crate (a single instrumented test
// binary) so coverage is measured against one library copy rather than being
// fragmented across separate integration-test binaries.
#[cfg(test)]
mod mcp_contract_intest;
#[cfg(test)]
mod mcp_dispatch_intest;
#[cfg(test)]
mod mcp_surface_intest;
#[cfg(test)]
mod store_contract_intest;
#[cfg(test)]
mod story_gate_persist_intest;
