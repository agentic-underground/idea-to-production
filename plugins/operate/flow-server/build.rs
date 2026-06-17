//! Build script: bake the short git rev into `FLOW_BUILD_REV` so the running binary
//! can self-report a UNIQUE build identity (crate version + rev) via the `ping` /
//! `--doctor` surfaces. The crate `version` alone is ambiguous because a release tag
//! can be re-cut with different content under the same version (defect [92]); the rev
//! disambiguates which binary is actually running, on every machine.
//!
//! Degrades gracefully: outside a git checkout (e.g. a source tarball) or with no git
//! on PATH, the rev is `unknown` — the build still succeeds.
//!
//! Freshness: we deliberately emit NO `rerun-if-changed` directive. The crate lives at
//! plugins/operate/flow-server/ while `.git` is at the repo root, so a `.git/HEAD`
//! path (resolved relative to this manifest) would point at a non-existent file — and emitting
//! ANY rerun-if directive switches Cargo from its default "re-run when any package file
//! changes" to "re-run ONLY when these paths change", which would freeze the rev. With no
//! directive, Cargo re-runs this script whenever a source file changes — so a dev rebuild after
//! editing code picks up the new rev, and CI release builds (fresh checkout) always bake the
//! correct one. A no-op rebuild may carry the prior rev; that is acceptable best-effort.

use std::process::Command;

fn main() {
    let rev = Command::new("git")
        .args(["rev-parse", "--short=12", "HEAD"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "unknown".to_string());

    println!("cargo:rustc-env=FLOW_BUILD_REV={rev}");
}
