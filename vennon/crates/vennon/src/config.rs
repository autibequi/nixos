use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

use crate::exec;

// ── Config structs ──────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct VennonConfig {
    pub paths: PathsConfig,
    #[serde(default)]
    pub settings: SettingsConfig,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PathsConfig {
    #[serde(rename = "self")]
    pub self_path: String,
    pub obsidian: String,
    pub projects: String,
    pub host: String,
    pub vennon: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SettingsConfig {
    #[serde(default = "default_memory_limit")]
    pub memory_limit: String,
    #[serde(default = "default_journal_gid")]
    pub journal_gid: u32,
}

fn default_memory_limit() -> String {
    "12g".into()
}
fn default_journal_gid() -> u32 {
    62
}

impl Default for SettingsConfig {
    fn default() -> Self {
        Self {
            memory_limit: default_memory_limit(),
            journal_gid: default_journal_gid(),
        }
    }
}

// ── Paths ───────────────────────────────────────────────────────

pub fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| "/root".into()))
}

pub fn config_dir() -> PathBuf {
    home().join(".config/vennon")
}

pub fn config_file() -> PathBuf {
    config_dir().join("config.yaml")
}

pub fn containers_dir() -> PathBuf {
    config_dir().join("containers")
}

/// Find the vennon source directory (repo with containers/ and justfile).
/// Tries: config, then known paths.
pub fn find_vennon_path() -> Option<PathBuf> {
    // Try config first
    if let Ok(cfg) = VennonConfig::load() {
        let p = cfg.vennon_path();
        if p.join("containers").exists() {
            return Some(p);
        }
    }
    // Fallback to known paths
    let candidates = [
        expand_path("~/nixos/vennon"),
        expand_path("~/nixos/host/vennon"),
    ];
    candidates.into_iter().find(|p| p.join("containers").exists())
}

/// Expand ~ and $HOME in a path string.
pub fn expand_path(p: &str) -> PathBuf {
    let home_str = home().to_string_lossy().to_string();
    let expanded = p
        .replace("~/", &format!("{}/", home_str))
        .replace("$HOME", &home_str)
        .replace("${HOME}", &home_str);
    PathBuf::from(expanded)
}

// ── Config loading ──────────────────────────────────────────────

impl VennonConfig {
    pub fn load() -> Result<Self> {
        let path = config_file();
        if !path.exists() {
            bail!(
                "Config not found: {}\nRun `vennon init` first.",
                path.display()
            );
        }
        let contents = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        let config: Self =
            serde_yaml::from_str(&contents).with_context(|| "parsing config.yaml")?;
        Ok(config)
    }

    pub fn self_path(&self) -> PathBuf {
        expand_path(&self.paths.self_path)
    }
    pub fn obsidian_path(&self) -> PathBuf {
        expand_path(&self.paths.obsidian)
    }
    pub fn projects_path(&self) -> PathBuf {
        expand_path(&self.paths.projects)
    }
    pub fn host_path(&self) -> PathBuf {
        expand_path(&self.paths.host)
    }
    pub fn vennon_path(&self) -> PathBuf {
        expand_path(&self.paths.vennon)
    }
}

// ── Dynamic env detection ───────────────────────────────────────

/// Git author/committer from the running user's git config.
pub fn git_env() -> Vec<(String, String)> {
    let name = exec::capture("git", &["config", "user.name"]).unwrap_or_default();
    let email = exec::capture("git", &["config", "user.email"]).unwrap_or_default();
    vec![
        ("GIT_AUTHOR_NAME".into(), name.clone()),
        ("GIT_AUTHOR_EMAIL".into(), email.clone()),
        ("GIT_COMMITTER_NAME".into(), name),
        ("GIT_COMMITTER_EMAIL".into(), email),
    ]
}

/// UID/GID of the running user.
pub fn user_ids() -> (u32, u32) {
    let uid = unsafe { libc::getuid() };
    let gid = unsafe { libc::getgid() };
    (uid, gid)
}

// ── Init ────────────────────────────────────────────────────────

const DEFAULT_CONFIG: &str = r#"paths:
  self: ~/nixos/vennon/self
  obsidian: ~/.ovault/Work
  projects: ~/projects
  host: ~/nixos
  vennon: ~/nixos/vennon

settings:
  memory_limit: 12g
  journal_gid: 62
"#;

pub fn init() -> Result<()> {
    let cfg_dir = config_dir();
    let cfg_file = config_file();
    let containers = containers_dir();

    // Config file
    if cfg_file.exists() {
        println!("Config already exists: {}", cfg_file.display());
    } else {
        std::fs::create_dir_all(&cfg_dir)?;
        std::fs::write(&cfg_file, DEFAULT_CONFIG)?;
        println!("Created {}", cfg_file.display());
    }

    // Container dirs
    for name in &["claude", "monolito", "bo-container", "front-student"] {
        let dir = containers.join(name);
        if !dir.exists() {
            std::fs::create_dir_all(&dir)?;
            println!("Created {}", dir.display());
        }
    }

    println!("\nvennon init complete.");
    Ok(())
}
