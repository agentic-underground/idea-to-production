//! Server configuration: the data directory and roadmap source. Parsed from CLI
//! args in `main.rs`. The web-UI binding flags (`--host`, `--port`, `--static`)
//! and the `--token` file flag were removed with the HTTP server in roadmap #39
//! — stdio has no auth transport, so no token file is loaded.

use std::path::PathBuf;

/// Runtime configuration for the flow server.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Config {
    /// Directory holding the flow state (JSONL + markdown).
    pub data_dir: PathBuf,
    /// Optional roadmap source to ingest on startup so the board is not blank.
    /// A directory is read as the `.i2p/roadmap/` file-per-item tree (folder =
    /// status); a file is the legacy single `ROADMAP.md`. `None` (the default)
    /// makes `main` fall back to the conventional `.i2p/roadmap/` tree if present,
    /// else an empty store.
    pub roadmap_path: Option<PathBuf>,
    /// Accepted for back-compat (roadmap #39 made stdio the only transport, so
    /// the flag is a harmless no-op). Default `false`; set by the `--mcp` flag.
    pub mcp: bool,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            data_dir: PathBuf::from(".flow"),
            roadmap_path: None,
            mcp: false,
        }
    }
}

impl Config {
    /// Parse `--data`, `--roadmap`, and `--mcp` from an argument iterator
    /// (excluding argv[0]). Unknown flags are an error so a typo never silently
    /// runs the default.
    pub fn from_args<I: IntoIterator<Item = String>>(args: I) -> Result<Self, ConfigError> {
        let mut cfg = Config::default();
        let mut it = args.into_iter();
        while let Some(flag) = it.next() {
            match flag.as_str() {
                "--data" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.data_dir = PathBuf::from(v);
                }
                "--roadmap" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.roadmap_path = Some(PathBuf::from(v));
                }
                "--mcp" => {
                    cfg.mcp = true;
                }
                other => {
                    return Err(ConfigError::UnknownFlag {
                        flag: other.to_string(),
                    })
                }
            }
        }
        Ok(cfg)
    }
}

/// Errors parsing the CLI configuration.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum ConfigError {
    /// A known flag was given without its value.
    #[error("flag {flag} requires a value")]
    MissingValue { flag: String },
    /// A flag's value failed to parse.
    #[error("flag {flag} got invalid value {value:?}")]
    BadValue { flag: String, value: String },
    /// An unrecognised flag was passed.
    #[error("unknown flag {flag}")]
    UnknownFlag { flag: String },
}

#[cfg(test)]
mod tests {
    use super::*;

    fn argv(s: &[&str]) -> Vec<String> {
        s.iter().map(|x| x.to_string()).collect()
    }

    #[test]
    fn default_paths() {
        let cfg = Config::default();
        assert_eq!(cfg.data_dir, PathBuf::from(".flow"));
        assert_eq!(cfg.roadmap_path, None);
        assert!(!cfg.mcp);
    }

    #[test]
    fn parses_all_flags() {
        let cfg = Config::from_args(argv(&[
            "--data",
            "/srv/d",
            "--roadmap",
            "/repo/ROADMAP.md",
            "--mcp",
        ]))
        .unwrap();
        assert_eq!(cfg.data_dir, PathBuf::from("/srv/d"));
        assert_eq!(cfg.roadmap_path, Some(PathBuf::from("/repo/ROADMAP.md")));
        assert!(cfg.mcp);
    }

    #[test]
    fn empty_args_is_default() {
        assert_eq!(Config::from_args(argv(&[])).unwrap(), Config::default());
    }

    #[test]
    fn roadmap_flag_absent_is_none() {
        // Without `--roadmap`, the server starts with no roadmap to ingest.
        let cfg = Config::from_args(argv(&[])).unwrap();
        assert_eq!(cfg.roadmap_path, None);
    }

    #[test]
    fn roadmap_flag_present_sets_path() {
        let cfg = Config::from_args(argv(&["--roadmap", "/repo/ROADMAP.md"])).unwrap();
        assert_eq!(cfg.roadmap_path, Some(PathBuf::from("/repo/ROADMAP.md")));
    }

    #[test]
    fn roadmap_flag_missing_value_errors() {
        assert_eq!(
            Config::from_args(argv(&["--roadmap"])),
            Err(ConfigError::MissingValue {
                flag: "--roadmap".into()
            })
        );
    }

    #[test]
    fn missing_value_errors_for_every_flag() {
        // Each value-taking flag reports MissingValue when its value is absent.
        for flag in ["--data", "--roadmap"] {
            assert_eq!(
                Config::from_args(argv(&[flag])),
                Err(ConfigError::MissingValue { flag: flag.into() }),
                "flag {flag} should require a value"
            );
        }
    }

    #[test]
    fn unknown_flag_errors() {
        assert_eq!(
            Config::from_args(argv(&["--nope"])),
            Err(ConfigError::UnknownFlag {
                flag: "--nope".into()
            })
        );
    }

    // The web-UI binding flags and the token-file flag were removed in roadmap
    // #39 (stdio has no auth transport); passing one is now an unknown-flag error
    // rather than a recognised option.
    #[test]
    fn removed_web_flags_are_unknown() {
        for flag in ["--host", "--port", "--static", "--token"] {
            assert_eq!(
                Config::from_args(argv(&[flag, "x"])),
                Err(ConfigError::UnknownFlag { flag: flag.into() }),
                "removed flag {flag} should be rejected"
            );
        }
    }

    // --mcp flag tests
    #[test]
    fn mcp_flag_absent_is_false() {
        let cfg = Config::from_args(argv(&[])).unwrap();
        assert!(!cfg.mcp, "--mcp absent must default to false");
    }

    #[test]
    fn mcp_flag_present_is_true() {
        let cfg = Config::from_args(argv(&["--mcp"])).unwrap();
        assert!(cfg.mcp, "--mcp present must set mcp to true");
    }
}
