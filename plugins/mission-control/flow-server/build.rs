//! Build script: bake the short git rev into `FLOW_BUILD_REV` so the running binary
//! can self-report a UNIQUE build identity (crate version + rev) via the `ping` /
//! `--doctor` surfaces. The crate `version` alone is ambiguous because a release tag
//! can be re-cut with different content under the same version (defect [92]); the rev
//! disambiguates which binary is actually running, on every machine.
//!
//! Degrades gracefully: outside a git checkout (e.g. a source tarball) or with no git
//! on PATH, the rev is `unknown` — the build still succeeds. We also re-run when HEAD
//! moves so a rebuild after a commit picks up the new rev.

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

    // Rebuild when HEAD or the ref it points at changes, so the baked rev stays honest.
    println!("cargo:rerun-if-changed=.git/HEAD");
    println!("cargo:rerun-if-changed=.git/refs/heads");
    // And always re-run if these env hints change (CI may inject them).
    println!("cargo:rerun-if-env-changed=FLOW_BUILD_REV");
}
