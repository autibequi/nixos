use anyhow::{Context, Result};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::{Path, PathBuf};

#[derive(Debug, Deserialize)]
pub struct BusConfig {
    #[serde(default = "default_socket")]
    pub socket: String,
    #[serde(default = "default_log")]
    pub log: String,
    #[serde(default)]
    pub actions: HashMap<String, ActionDef>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ActionDef {
    #[serde(default)]
    pub description: String,
    pub command: String,
    /// If true, capture stdout and return in response. Default: fire-and-forget.
    #[serde(default)]
    pub capture: bool,
    #[serde(default)]
    pub args: Vec<ArgDef>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ArgDef {
    pub name: String,
    #[serde(rename = "type", default = "default_type")]
    pub arg_type: String,
    #[serde(default)]
    pub required: bool,
    #[serde(default)]
    pub default: Option<serde_yaml::Value>,
    #[serde(default)]
    pub validate: Vec<serde_yaml::Value>,
}

fn default_socket() -> String { "~/.vennon/bus.sock".into() }
fn default_log() -> String { "~/.local/share/vennon/logs/bus.log".into() }
fn default_type() -> String { "string".into() }

pub fn expand_path(p: &str) -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let expanded = p
        .replace("~/", &format!("{home}/"))
        .replace("$HOME", &home)
        .replace("${HOME}", &home);
    PathBuf::from(expanded)
}

impl BusConfig {
    pub fn load() -> Result<Self> {
        let candidates = [
            expand_path("~/.config/vennon/bus.yaml"),
            expand_path("~/nixos/stow/.config/vennon/bus.yaml"),
        ];

        for path in &candidates {
            if path.exists() {
                let contents = std::fs::read_to_string(path)
                    .with_context(|| format!("reading {}", path.display()))?;
                let config: Self = serde_yaml::from_str(&contents)
                    .with_context(|| format!("parsing {}", path.display()))?;
                return Ok(config);
            }
        }

        // Fallback: empty config
        Ok(Self {
            socket: default_socket(),
            log: default_log(),
            actions: HashMap::new(),
        })
    }

    pub fn socket_path(&self) -> PathBuf {
        expand_path(&self.socket)
    }

    pub fn log_path(&self) -> PathBuf {
        expand_path(&self.log)
    }
}
