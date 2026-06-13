//! Server configuration: host (default LAN-reachable), port, token path, and
//! the static-asset directory. Parsed from CLI args in `main.rs`.

use std::net::{IpAddr, Ipv4Addr};
use std::path::PathBuf;

/// Runtime configuration for the flow server.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Config {
    /// Bind host. Default `0.0.0.0` (LAN-reachable, per the spec).
    pub host: IpAddr,
    /// Bind port.
    pub port: u16,
    /// Path to the shared bearer-token file (created on first run).
    pub token_path: PathBuf,
    /// Directory holding the static frontend assets.
    pub static_dir: PathBuf,
    /// Directory holding the flow state (JSONL + markdown).
    pub data_dir: PathBuf,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            host: IpAddr::V4(Ipv4Addr::UNSPECIFIED),
            port: 7421,
            token_path: PathBuf::from(".flow/token"),
            static_dir: PathBuf::from("static"),
            data_dir: PathBuf::from(".flow"),
        }
    }
}

impl Config {
    /// Parse `--host`, `--port`, `--token`, `--static`, `--data` from an
    /// argument iterator (excluding argv[0]). Unknown flags are an error so a
    /// typo never silently runs the default.
    pub fn from_args<I: IntoIterator<Item = String>>(args: I) -> Result<Self, ConfigError> {
        let mut cfg = Config::default();
        let mut it = args.into_iter();
        while let Some(flag) = it.next() {
            match flag.as_str() {
                "--host" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.host = v.parse().map_err(|_| ConfigError::BadValue {
                        flag: "--host".into(),
                        value: v,
                    })?;
                }
                "--port" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.port = v.parse().map_err(|_| ConfigError::BadValue {
                        flag: "--port".into(),
                        value: v,
                    })?;
                }
                "--token" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.token_path = PathBuf::from(v);
                }
                "--static" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.static_dir = PathBuf::from(v);
                }
                "--data" => {
                    let v = it.next().ok_or(ConfigError::MissingValue { flag })?;
                    cfg.data_dir = PathBuf::from(v);
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
    fn default_is_lan_reachable() {
        let cfg = Config::default();
        assert_eq!(cfg.host, IpAddr::V4(Ipv4Addr::UNSPECIFIED));
        assert_eq!(cfg.port, 7421);
        assert_eq!(cfg.token_path, PathBuf::from(".flow/token"));
    }

    #[test]
    fn parses_all_flags() {
        let cfg = Config::from_args(argv(&[
            "--host",
            "127.0.0.1",
            "--port",
            "9000",
            "--token",
            "/tmp/t",
            "--static",
            "/srv/s",
            "--data",
            "/srv/d",
        ]))
        .unwrap();
        assert_eq!(cfg.host, IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1)));
        assert_eq!(cfg.port, 9000);
        assert_eq!(cfg.token_path, PathBuf::from("/tmp/t"));
        assert_eq!(cfg.static_dir, PathBuf::from("/srv/s"));
        assert_eq!(cfg.data_dir, PathBuf::from("/srv/d"));
    }

    #[test]
    fn empty_args_is_default() {
        assert_eq!(Config::from_args(argv(&[])).unwrap(), Config::default());
    }

    #[test]
    fn missing_value_errors() {
        assert_eq!(
            Config::from_args(argv(&["--port"])),
            Err(ConfigError::MissingValue {
                flag: "--port".into()
            })
        );
    }

    #[test]
    fn missing_value_errors_for_every_flag() {
        // Each value-taking flag reports MissingValue when its value is absent.
        for flag in ["--host", "--port", "--token", "--static", "--data"] {
            assert_eq!(
                Config::from_args(argv(&[flag])),
                Err(ConfigError::MissingValue { flag: flag.into() }),
                "flag {flag} should require a value"
            );
        }
    }

    #[test]
    fn bad_value_errors() {
        assert_eq!(
            Config::from_args(argv(&["--port", "notnum"])),
            Err(ConfigError::BadValue {
                flag: "--port".into(),
                value: "notnum".into()
            })
        );
        assert_eq!(
            Config::from_args(argv(&["--host", "notip"])),
            Err(ConfigError::BadValue {
                flag: "--host".into(),
                value: "notip".into()
            })
        );
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
}
