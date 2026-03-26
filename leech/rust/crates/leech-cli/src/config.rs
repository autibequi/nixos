//! `LeechConfig` — unified configuration via Figment.
//!
//! Priority: CLI flag > env var (LEECH_*) > config.yaml > built-in default.
//!
//! Config file: `~/.config/leech/config.yaml`
//! Secrets: raw env vars (GH_TOKEN, ANTHROPIC_API_KEY, etc.)
//! Legacy: `~/.leech` remains for bash `source` compat (tokens only).

use std::collections::HashMap;
use std::path::PathBuf;

use figment::{Figment, providers::{Format, Yaml, Env, Serialized}};
use serde::{Serialize, Deserialize};

use crate::engine::Engine;

// ── Top-level config ────────────────────────────────────────────────────────

/// Unified Leech configuration — all layers merged by Figment.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LeechConfig {
    #[serde(default)]
    pub session: SessionConfig,
    #[serde(default)]
    pub runner: RunnerConfig,
    #[serde(default)]
    pub agents: AgentConfig,
    #[serde(default)]
    pub paths: PathConfig,
    #[serde(default)]
    pub system: SystemConfig,
    #[serde(default, skip_serializing)]
    pub secrets: SecretsConfig,
}

// ── Sub-configs ─────────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SessionConfig {
    pub engine: Option<String>,
    pub model: Option<String>,
    pub model_claude: Option<String>,
    pub model_opencode: Option<String>,
    pub model_cursor: Option<String>,
    #[serde(default)]
    pub host: bool,
    #[serde(default = "default_true")]
    pub rw: bool,
    #[serde(default = "default_true")]
    pub splash: bool,
    #[serde(default)]
    pub danger: bool,
    pub init_md: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RunnerConfig {
    #[serde(default = "default_local")]
    pub env: String,
    #[serde(default)]
    pub debug: bool,
    #[serde(default)]
    pub dev: bool,
    #[serde(default)]
    pub detach: bool,
    #[serde(default = "default_100")]
    pub tail: u32,
    #[serde(default = "default_vertical")]
    pub vertical: String,
    #[serde(default = "default_container")]
    pub container: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AgentConfig {
    #[serde(default = "default_haiku")]
    pub model: String,
    #[serde(default = "default_30")]
    pub steps: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct PathConfig {
    pub obsidian: Option<String>,
    pub monolito: Option<String>,
    pub bo_container: Option<String>,
    pub front_student: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SystemConfig {
    pub docker_gid: Option<u32>,
    #[serde(default = "default_62")]
    pub journal_gid: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct SecretsConfig {
    pub gh_token: Option<String>,
    pub anthropic_api_key: Option<String>,
    pub cursor_api_key: Option<String>,
    pub grafana_url: Option<String>,
    pub grafana_token: Option<String>,
}

// ── Defaults ────────────────────────────────────────────────────────────────

fn default_true() -> bool { true }
fn default_local() -> String { "local".into() }
fn default_haiku() -> String { "haiku".into() }
fn default_100() -> u32 { 100 }
fn default_30() -> u32 { 30 }
fn default_62() -> u32 { 62 }
fn default_vertical() -> String { "carreiras-juridicas".into() }
fn default_container() -> String { "app".into() }

impl Default for LeechConfig {
    fn default() -> Self {
        Self {
            session: SessionConfig::default(),
            runner: RunnerConfig::default(),
            agents: AgentConfig::default(),
            paths: PathConfig::default(),
            system: SystemConfig::default(),
            secrets: SecretsConfig::default(),
        }
    }
}

impl Default for SessionConfig {
    fn default() -> Self {
        Self {
            engine: None,
            model: None,
            model_claude: None,
            model_opencode: None,
            model_cursor: None,
            host: false,
            rw: true,
            splash: true,
            danger: false,
            init_md: None,
        }
    }
}

impl Default for RunnerConfig {
    fn default() -> Self {
        Self {
            env: "local".into(),
            debug: false,
            dev: false,
            detach: false,
            tail: 100,
            vertical: "carreiras-juridicas".into(),
            container: "app".into(),
        }
    }
}

impl Default for AgentConfig {
    fn default() -> Self {
        Self {
            model: "haiku".into(),
            steps: 30,
        }
    }
}

impl Default for SystemConfig {
    fn default() -> Self {
        Self {
            docker_gid: None,
            journal_gid: 62,
        }
    }
}

// ── Loading ─────────────────────────────────────────────────────────────────

impl LeechConfig {
    /// Load config from all sources: defaults → YAML → env vars → secrets.
    pub fn load() -> anyhow::Result<Self> {
        let yaml_path = config_dir().join("config.yaml");

        let mut fig = Figment::new()
            // 1. Built-in defaults
            .merge(Serialized::defaults(LeechConfig::default()))
            // 2. YAML config file (if exists)
            .merge(Yaml::file(&yaml_path))
            // 3. Env vars: LEECH_SESSION_ENGINE, LEECH_RUNNER_ENV, etc.
            .merge(Env::prefixed("LEECH_").split("_"));

        // 4. Secrets from raw env vars (not prefixed — backward compat)
        let secrets = SecretsConfig {
            gh_token: std::env::var("GH_TOKEN").ok(),
            anthropic_api_key: std::env::var("ANTHROPIC_API_KEY").ok(),
            cursor_api_key: std::env::var("CURSOR_API_KEY").ok(),
            grafana_url: std::env::var("GRAFANA_URL").ok(),
            grafana_token: std::env::var("GRAFANA_TOKEN").ok(),
        };
        // 4. Secrets from raw env vars (not prefixed — backward compat)
        let secrets = SecretsConfig {
            gh_token: std::env::var("GH_TOKEN").ok(),
            anthropic_api_key: std::env::var("ANTHROPIC_API_KEY").ok(),
            cursor_api_key: std::env::var("CURSOR_API_KEY").ok(),
            grafana_url: std::env::var("GRAFANA_URL").ok(),
            grafana_token: std::env::var("GRAFANA_TOKEN").ok(),
        };
        if secrets.gh_token.is_some()
            || secrets.anthropic_api_key.is_some()
            || secrets.cursor_api_key.is_some()
            || secrets.grafana_url.is_some()
            || secrets.grafana_token.is_some()
        {
            fig = fig.merge(Serialized::default("secrets", &secrets));
        }

        // 5. Docker GID: env var > socket stat > None (resolved at use site)
        let docker_gid = std::env::var("DOCKER_GID")
            .ok()
            .and_then(|s| s.parse::<u32>().ok())
            .or_else(docker_socket_gid);
        if let Some(gid) = docker_gid {
            fig = fig.merge(Serialized::default("system.docker_gid", &gid));
        }

        // Journal GID from env
        if let Some(gid) = std::env::var("JOURNAL_GID")
            .ok()
            .and_then(|s| s.parse::<u32>().ok())
        {
            fig = fig.merge(Serialized::default("system.journal_gid", &gid));
        }

        fig.extract().map_err(|e| anyhow::anyhow!("config: {e}"))
    }

    // ── Convenience accessors (bridge to old API) ───────────────────────

    /// Parsed engine enum (if set).
    pub fn engine(&self) -> Option<Engine> {
        self.session.engine.as_deref().and_then(|s| s.parse().ok())
    }

    /// Docker GID with auto-detect fallback.
    pub fn docker_gid(&self) -> u32 {
        self.system.docker_gid.unwrap_or_else(|| docker_socket_gid().unwrap_or(999))
    }

    /// Display resolved config for `leech config show`.
    pub fn display(&self) {
        let yaml_path = config_dir().join("config.yaml");
        let exists = if yaml_path.exists() { "" } else { " \x1b[2m(not found)\x1b[0m" };
        println!(
            "\n\x1b[1m\x1b[35m  config\x1b[0m  \x1b[2m{}\x1b[0m{}\n",
            yaml_path.display(),
            exists
        );

        println!("  \x1b[1msession:\x1b[0m");
        show_opt("engine", &self.session.engine);
        show_opt("model", &self.session.model);
        show_bool("host", self.session.host);
        show_bool("rw", self.session.rw);
        show_bool("splash", self.session.splash);
        show_bool("danger", self.session.danger);
        show_opt("init_md", &self.session.init_md);
        println!();

        println!("  \x1b[1mrunner:\x1b[0m");
        println!("    {:<12} {}", "env", self.runner.env);
        show_bool("debug", self.runner.debug);
        show_bool("dev", self.runner.dev);
        show_bool("detach", self.runner.detach);
        println!("    {:<12} {}", "tail", self.runner.tail);
        println!("    {:<12} {}", "vertical", self.runner.vertical);
        println!("    {:<12} {}", "container", self.runner.container);
        println!();

        println!("  \x1b[1magents:\x1b[0m");
        println!("    {:<12} {}", "model", self.agents.model);
        println!("    {:<12} {}", "steps", self.agents.steps);
        println!();

        println!("  \x1b[1mpaths:\x1b[0m");
        show_opt("obsidian", &self.paths.obsidian);
        show_opt("monolito", &self.paths.monolito);
        show_opt("bo_container", &self.paths.bo_container);
        show_opt("front_student", &self.paths.front_student);
        println!();

        println!("  \x1b[1msystem:\x1b[0m");
        println!("    {:<12} {}", "docker_gid", self.docker_gid());
        println!("    {:<12} {}", "journal_gid", self.system.journal_gid);
        println!();

        println!("  \x1b[1msecrets:\x1b[0m");
        show_masked("gh_token", &self.secrets.gh_token);
        show_masked("anthropic", &self.secrets.anthropic_api_key);
        show_masked("cursor", &self.secrets.cursor_api_key);
        show_opt("grafana_url", &self.secrets.grafana_url);
        show_masked("grafana_tok", &self.secrets.grafana_token);
        println!();
    }
}

fn show_opt(key: &str, val: &Option<String>) {
    match val {
        Some(v) => println!("    {key:<12} {v}"),
        None => println!("    {key:<12} \x1b[2m(default)\x1b[0m"),
    }
}

fn show_bool(key: &str, val: bool) {
    println!("    {key:<12} {val}");
}

fn show_masked(key: &str, val: &Option<String>) {
    match val {
        Some(v) if v.len() > 8 => {
            let visible = &v[..4];
            println!("    {key:<12} {visible}…{}", "*".repeat(8));
        }
        Some(_) => println!("    {key:<12} ****"),
        None => println!("    {key:<12} \x1b[2m(not set)\x1b[0m"),
    }
}

// ── Paths ───────────────────────────────────────────────────────────────────

/// Config directory: `~/.config/leech/`
pub fn config_dir() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    PathBuf::from(home).join(".config/leech")
}

fn docker_socket_gid() -> Option<u32> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::MetadataExt;
        std::fs::metadata("/var/run/docker.sock").map(|m| m.gid()).ok()
    }
    #[cfg(not(unix))]
    { None }
}

// ── Template ────────────────────────────────────────────────────────────────

/// Default config template for `leech config init`.
pub const DEFAULT_TEMPLATE: &str = "\
# Leech CLI configuration
# Priority: CLI flag > env var (LEECH_*) > this file > built-in default
# Secrets: use env vars (GH_TOKEN, ANTHROPIC_API_KEY) — not this file

# ── Session defaults ─────────────────────────────
session:
  engine: claude          # claude | cursor | opencode
  # model: sonnet         # haiku | sonnet | opus | full model ID
  host: true              # mount ~/nixos in /workspace/host
  rw: true                # mount read-write
  splash: true            # loading screen
  # init_md: contexto.md  # initial markdown file

# ── Runner / Services defaults ───────────────────
runner:
  env: local              # local | sand | prod
  debug: false            # attach delve debugger
  dev: false              # hot-reload with air
  detach: false           # start and return (no log follow)
  tail: 100               # log lines to follow
  vertical: carreiras-juridicas
  container: app

# ── Agents defaults ──────────────────────────────
agents:
  model: haiku            # default model for ask/run
  steps: 30               # max_turns default

# ── Paths (override auto-detect) ─────────────────
# paths:
#   obsidian: ~/.ovault/Work
#   monolito: ~/projects/estrategia/monolito
#   bo_container: ~/projects/estrategia/bo-container
#   front_student: ~/projects/estrategia/front-student

# ── System ───────────────────────────────────────
# system:
#   docker_gid: 999       # auto-detect from /var/run/docker.sock
#   journal_gid: 62
";

// ── Legacy migration helper ─────────────────────────────────────────────────

/// Parse KEY=value lines from ~/.leech (for migration).
pub fn parse_key_value(content: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        let trimmed = trimmed.strip_prefix("export ").unwrap_or(trimmed);
        if let Some((key, val)) = trimmed.split_once('=') {
            let key = key.trim().to_string();
            let val = val.trim();
            let val = if (val.starts_with('"') && val.ends_with('"'))
                || (val.starts_with('\'') && val.ends_with('\''))
            {
                &val[1..val.len() - 1]
            } else {
                val
            };
            map.insert(key, val.to_string());
        }
    }
    map
}

// ── Tests ───────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_values() {
        let cfg = LeechConfig::default();
        assert_eq!(cfg.runner.env, "local");
        assert_eq!(cfg.runner.tail, 100);
        assert_eq!(cfg.agents.model, "haiku");
        assert_eq!(cfg.agents.steps, 30);
        assert!(cfg.session.rw);
        assert!(cfg.session.splash);
        assert!(!cfg.session.host);
        assert!(!cfg.session.danger);
        assert!(cfg.session.engine.is_none());
    }

    #[test]
    fn parse_key_value_basic() {
        let map = parse_key_value("engine=claude\nmodel=sonnet\n");
        assert_eq!(map.get("engine").unwrap(), "claude");
        assert_eq!(map.get("model").unwrap(), "sonnet");
    }

    #[test]
    fn parse_key_value_quotes_and_export() {
        let map = parse_key_value(r#"
# comment
GH_TOKEN='abc123'
export ANTHROPIC_API_KEY="sk-ant-xxx"
DANGER=true
"#);
        assert_eq!(map.get("GH_TOKEN").unwrap(), "abc123");
        assert_eq!(map.get("ANTHROPIC_API_KEY").unwrap(), "sk-ant-xxx");
        assert_eq!(map.get("DANGER").unwrap(), "true");
    }

    #[test]
    fn parse_key_value_empty() {
        let map = parse_key_value("# only comments\n\n  \n");
        assert!(map.is_empty());
    }

    #[test]
    fn parse_key_value_equals_in_value() {
        let map = parse_key_value("url=https://example.com?a=1&b=2\n");
        assert_eq!(map.get("url").unwrap(), "https://example.com?a=1&b=2");
    }

    #[test]
    fn figment_yaml_override() {
        // Simulate: defaults + inline YAML
        let yaml_content = "runner:\n  env: sand\n  tail: 50\n";
        let cfg: LeechConfig = Figment::new()
            .merge(Serialized::defaults(LeechConfig::default()))
            .merge(Yaml::string(yaml_content))
            .extract()
            .unwrap();
        assert_eq!(cfg.runner.env, "sand");
        assert_eq!(cfg.runner.tail, 50);
        // Untouched defaults
        assert!(!cfg.runner.debug);
        assert_eq!(cfg.runner.container, "app");
        assert_eq!(cfg.agents.model, "haiku");
    }

    #[test]
    fn figment_env_override() {
        // LEECH_RUNNER_ENV=prod should override runner.env
        std::env::set_var("LEECH_RUNNER_ENV", "prod");
        let cfg: LeechConfig = Figment::new()
            .merge(Serialized::defaults(LeechConfig::default()))
            .merge(Env::prefixed("LEECH_").split("_"))
            .extract()
            .unwrap();
        assert_eq!(cfg.runner.env, "prod");
        std::env::remove_var("LEECH_RUNNER_ENV");
    }

    #[test]
    fn figment_session_engine() {
        let yaml = "session:\n  engine: cursor\n  model: opus\n";
        let cfg: LeechConfig = Figment::new()
            .merge(Serialized::defaults(LeechConfig::default()))
            .merge(Yaml::string(yaml))
            .extract()
            .unwrap();
        assert_eq!(cfg.session.engine.as_deref(), Some("cursor"));
        assert_eq!(cfg.session.model.as_deref(), Some("opus"));
        assert_eq!(cfg.engine(), Some(Engine::Cursor));
    }
}
