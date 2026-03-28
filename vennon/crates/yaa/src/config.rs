use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct YaaConfig {
    #[serde(default)]
    pub session: SessionConfig,
    #[serde(default)]
    pub models: HashMap<String, String>,
    #[serde(default)]
    pub agents: AgentConfig,
    #[serde(default)]
    pub paths: PathsConfig,
    #[serde(default)]
    pub tokens: HashMap<String, String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct SessionConfig {
    #[serde(default = "default_engine")]
    pub engine: String,
    #[serde(default)]
    pub host: bool,
    #[serde(default)]
    pub danger: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AgentConfig {
    #[serde(default = "default_agent_model")]
    pub model: String,
    #[serde(default = "default_steps")]
    pub steps: u32,
}

impl Default for AgentConfig {
    fn default() -> Self {
        Self {
            model: default_agent_model(),
            steps: default_steps(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PathsConfig {
    #[serde(default = "default_vennon")]
    pub vennon: String,
    #[serde(default = "default_obsidian")]
    pub obsidian: String,
    #[serde(default = "default_projects")]
    pub projects: String,
    #[serde(default = "default_host")]
    pub host: String,
}

impl Default for PathsConfig {
    fn default() -> Self {
        Self {
            vennon: default_vennon(),
            obsidian: default_obsidian(),
            projects: default_projects(),
            host: default_host(),
        }
    }
}

fn default_engine() -> String { "claude".into() }
fn default_agent_model() -> String { "haiku".into() }
fn default_steps() -> u32 { 30 }
fn default_vennon() -> String { "~/nixos/vennon".into() }
fn default_obsidian() -> String { "~/.ovault/Work".into() }
fn default_projects() -> String { "~/projects".into() }
fn default_host() -> String { "~/nixos".into() }

// ── Paths ───────────────────────────────────────────────────────

pub fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| "/root".into()))
}

pub fn config_file() -> PathBuf {
    home().join(".yaa.yaml")
}

pub fn expand_path(p: &str) -> PathBuf {
    let home_str = home().to_string_lossy().to_string();
    let expanded = p
        .replace("~/", &format!("{}/", home_str))
        .replace("$HOME", &home_str)
        .replace("${HOME}", &home_str);
    PathBuf::from(expanded)
}

// ── Loading ─────────────────────────────────────────────────────

impl YaaConfig {
    pub fn load() -> Result<Self> {
        let path = config_file();
        if !path.exists() {
            eprintln!("[yaa] no config found, using defaults (run `yaa init`)");
            return Ok(Self::default());
        }
        let contents = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        let config: Self = serde_yaml::from_str(&contents)
            .with_context(|| format!("parsing {}", path.display()))?;
        Ok(config)
    }

    pub fn model_for_engine(&self, engine: &str) -> Option<String> {
        self.models.get(engine).cloned().filter(|s| !s.is_empty())
    }

    pub fn vennon_path(&self) -> PathBuf {
        expand_path(&self.paths.vennon)
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
}

impl Default for YaaConfig {
    fn default() -> Self {
        Self {
            session: SessionConfig::default(),
            models: {
                let mut m = HashMap::new();
                m.insert("claude".into(), "opus".into());
                m.insert("opencode".into(), "opus".into());
                m.insert("cursor".into(), "".into());
                m
            },
            agents: AgentConfig::default(),
            paths: PathsConfig::default(),
            tokens: HashMap::new(),
        }
    }
}

// ── Init ────────────────────────────────────────────────────────

const DEFAULT_CONFIG: &str = r#"session:
  engine: claude
  host: false
  danger: false

models:
  claude: opus
  opencode: opus
  cursor: ""

agents:
  model: haiku
  steps: 30

paths:
  vennon: ~/nixos/vennon
  obsidian: ~/.ovault/Work
  projects: ~/projects
  host: ~/nixos

tokens:
  gh_token: ""
  anthropic_api_key: ""
  npm_token: ""
"#;

pub fn init() -> Result<()> {
    let path = config_file();
    if path.exists() {
        println!("Config already exists: {}", path.display());
    } else {
        std::fs::write(&path, DEFAULT_CONFIG)?;
        println!("Created {}", path.display());
    }
    Ok(())
}
