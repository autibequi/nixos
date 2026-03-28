use anyhow::Result;
use serde::Serialize;
use std::collections::BTreeMap;
use std::path::Path;

// ── Compose YAML structs ────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct ComposeFile {
    pub services: BTreeMap<String, Service>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub volumes: Option<BTreeMap<String, serde_yaml::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub networks: Option<BTreeMap<String, Network>>,
}

#[derive(Debug, Serialize)]
pub struct Service {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub image: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub container_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub build: Option<BuildConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mem_limit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub memswap_limit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub network_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stdin_open: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tty: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub working_dir: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entrypoint: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub command: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub restart: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ports: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub volumes: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub environment: Option<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tmpfs: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cap_drop: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extra_hosts: Option<Vec<String>>,
}

#[derive(Debug, Serialize)]
pub struct BuildConfig {
    pub context: String,
    pub dockerfile: String,
}

#[derive(Debug, Serialize)]
pub struct Network {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub external: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
}

// ── Write compose to disk ───────────────────────────────────────

pub fn write_compose(compose: &ComposeFile, output: &Path) -> Result<()> {
    let yaml = serde_yaml::to_string(compose)?;
    if let Some(parent) = output.parent() {
        std::fs::create_dir_all(parent)?;
    }
    // Only write if content changed — avoids podman-compose recreation from timestamp
    if output.exists() {
        if let Ok(existing) = std::fs::read_to_string(output) {
            if existing == yaml {
                return Ok(());
            }
        }
    }
    std::fs::write(output, yaml)?;
    Ok(())
}
