use anyhow::{Context, Result};
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

fn default_engine() -> String {
    "claude".into()
}
fn default_agent_model() -> String {
    "haiku".into()
}
fn default_steps() -> u32 {
    30
}
fn default_vennon() -> String {
    "~/nixos/vennon".into()
}
fn default_obsidian() -> String {
    "~/.ovault/Work".into()
}
fn default_projects() -> String {
    "~/projects".into()
}
fn default_host() -> String {
    "~/nixos".into()
}

// ── Paths ───────────────────────────────────────────────────────

pub fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| "/root".into()))
}

pub fn config_file() -> PathBuf {
    home().join(".yaa.yaml")
}

/// Segredos opcionais (stow → `~/yaa.yaml`). Vazio = fallback (env, `~/.claude`, OAuth).
pub fn secrets_file() -> PathBuf {
    home().join("yaa.yaml")
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

#[derive(Debug, Deserialize, Default)]
struct SecretsYaml {
    #[serde(default)]
    tokens: HashMap<String, String>,
}

impl YaaConfig {
    pub fn load() -> Result<Self> {
        let path = config_file();
        let mut config = if !path.exists() {
            eprintln!("[yaa] no config found, using defaults (run `yaa init`)");
            Self::default()
        } else {
            let contents = std::fs::read_to_string(&path)
                .with_context(|| format!("reading {}", path.display()))?;
            serde_yaml::from_str(&contents)
                .with_context(|| format!("parsing {}", path.display()))?
        };

        let secrets_path = secrets_file();
        if secrets_path.exists() {
            let raw = std::fs::read_to_string(&secrets_path)
                .with_context(|| format!("reading {}", secrets_path.display()))?;
            let parsed: SecretsYaml = serde_yaml::from_str(&raw)
                .with_context(|| format!("parsing {}", secrets_path.display()))?;
            merge_tokens(&mut config.tokens, parsed.tokens);
        }

        Ok(config)
    }

    /// Valor de token não vazio; senão `None` (use o fallback padrão do script/env).
    pub fn token(&self, key: &str) -> Option<&str> {
        self.tokens
            .get(key)
            .map(|s| s.trim())
            .filter(|s| !s.is_empty())
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

/// Non-empty values from `extra` sobrescrevem `base`.
fn merge_tokens(base: &mut HashMap<String, String>, extra: HashMap<String, String>) {
    for (k, v) in extra {
        let t = v.trim();
        if !t.is_empty() {
            base.insert(k, t.to_string());
        }
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

const DEFAULT_CONFIG: &str = r#"# Preferência: tokens sensíveis em ~/yaa.yaml (yaa init).
session:
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
"#;

/// Template para `~/yaa.yaml` — chmod 600. Campos vazios = mesmo comportamento de antes (OAuth, ~/.claude, env).
const DEFAULT_SECRETS: &str = r#"# Segredos do yaa — manter chmod 600. Vazio = fallback automático (scripts/env).
# Chaves usadas hoje: claude_web_session → CLAUDE_AI_SESSION_KEY; claude_org_id → CLAUDE_AI_ORG_ID.
tokens:
  claude_web_session: ""
  claude_org_id: ""
  github: ""
  jira: ""
"#;

pub fn init() -> Result<()> {
    let path = config_file();
    if path.exists() {
        println!("Config already exists: {}", path.display());
    } else {
        std::fs::write(&path, DEFAULT_CONFIG)?;
        println!("Created {}", path.display());
    }

    let sec = secrets_file();
    if sec.exists() {
        println!("Secrets already exists: {}", sec.display());
    } else {
        write_secrets_file(&sec)?;
        println!("Created {} (chmod 600)", sec.display());
    }

    Ok(())
}

fn write_secrets_file(path: &std::path::Path) -> Result<()> {
    use std::io::Write;
    let mut opts = std::fs::OpenOptions::new();
    opts.create(true).write(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        opts.mode(0o600);
    }
    let mut f = opts.open(path).with_context(|| format!("creating {}", path.display()))?;
    f.write_all(DEFAULT_SECRETS.as_bytes())?;
    Ok(())
}
