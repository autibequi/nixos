//! `ZionConfig` — loads and parses `~/.zion` (KEY=value, bash-sourceable format).

use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

use crate::engine::Engine;
use crate::error::{Result, ZionError};

/// Parsed ~/.zion config (KEY=value format, sourceable by bash).
#[derive(Debug, Clone, Default)]
pub struct ZionConfig {
    pub engine: Option<Engine>,
    pub model: Option<String>,
    pub model_claude: Option<String>,
    pub model_opencode: Option<String>,
    pub model_cursor: Option<String>,
    pub danger: bool,
    pub gh_token: Option<String>,
    pub anthropic_api_key: Option<String>,
    pub cursor_api_key: Option<String>,
    pub grafana_url: Option<String>,
    pub grafana_token: Option<String>,
    pub obsidian_path: Option<String>,
    pub docker_gid: u32,
    pub journal_gid: u32,
    raw: HashMap<String, String>,
}

impl ZionConfig {
    /// Load config from ~/.zion (or $ZION_CONFIG).
    pub fn load() -> Result<Self> {
        let path = config_path();
        let mut cfg = ZionConfig::default();

        if path.exists() {
            let content = fs::read_to_string(&path)
                .map_err(|e| ZionError::Config(format!("reading {}: {e}", path.display())))?;
            cfg.raw = parse_key_value(&content);

            cfg.engine = cfg.raw.get("engine").and_then(|s| s.parse().ok());
            cfg.model = cfg.raw.get("model").cloned();
            cfg.model_claude = cfg.raw.get("model_claude").cloned();
            cfg.model_opencode = cfg.raw.get("model_opencode").cloned();
            cfg.model_cursor = cfg.raw.get("model_cursor").cloned();
            cfg.danger = cfg
                .raw
                .get("DANGER")
                .or_else(|| cfg.raw.get("danger"))
                .is_some_and(|v| v != "0" && v != "false");
            cfg.gh_token = cfg.raw.get("GH_TOKEN").cloned();
            cfg.anthropic_api_key = cfg.raw.get("ANTHROPIC_API_KEY").cloned();
            cfg.cursor_api_key = cfg.raw.get("CURSOR_API_KEY").cloned();
            cfg.grafana_url = cfg.raw.get("GRAFANA_URL").cloned();
            cfg.grafana_token = cfg.raw.get("GRAFANA_TOKEN").cloned();
            cfg.obsidian_path = cfg
                .raw
                .get("OBSIDIAN_PATH")
                .map(|s| crate::paths::expand_home(s));
        }

        // Docker GID
        cfg.docker_gid = std::env::var("DOCKER_GID")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or_else(|| docker_socket_gid().unwrap_or(999));

        // Journal GID
        cfg.journal_gid = std::env::var("JOURNAL_GID")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(62);

        Ok(cfg)
    }

    #[must_use]
    pub fn get(&self, key: &str) -> Option<&str> {
        self.raw.get(key).map(String::as_str)
    }
}

fn config_path() -> PathBuf {
    std::env::var("ZION_CONFIG").map_or_else(|_| dirs_home().join(".zion"), PathBuf::from)
}

fn dirs_home() -> PathBuf {
    std::env::var("HOME").map_or_else(|_| PathBuf::from("/root"), PathBuf::from)
}

fn docker_socket_gid() -> Option<u32> {
    use std::os::unix::fs::MetadataExt;
    fs::metadata("/var/run/docker.sock").map(|m| m.gid()).ok()
}

/// Parse KEY=value lines (ignoring comments and empty lines).
/// Handles quoted values: KEY="value" or KEY='value'.
fn parse_key_value(content: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        // Skip export prefix
        let trimmed = trimmed.strip_prefix("export ").unwrap_or(trimmed);
        if let Some((key, val)) = trimmed.split_once('=') {
            let key = key.trim().to_string();
            let val = val.trim();
            // Strip surrounding quotes
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_basic() {
        let map = parse_key_value("engine=claude\nmodel=sonnet\n");
        assert_eq!(map.get("engine").unwrap(), "claude");
        assert_eq!(map.get("model").unwrap(), "sonnet");
    }

    #[test]
    fn parse_quotes_and_export() {
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
    fn parse_empty_and_comments() {
        let map = parse_key_value("# only comments\n\n  \n");
        assert!(map.is_empty());
    }

    #[test]
    fn parse_value_with_equals() {
        // KEY=value=with=equals should capture everything after first =
        let map = parse_key_value("url=https://example.com?a=1&b=2\n");
        assert_eq!(map.get("url").unwrap(), "https://example.com?a=1&b=2");
    }

    #[test]
    fn parse_spaces_around_key() {
        let map = parse_key_value("  engine = claude  \n");
        assert_eq!(map.get("engine").unwrap(), "claude");
    }

    #[test]
    fn parse_danger_false_not_set() {
        let map = parse_key_value("danger=false\n");
        // The config loader checks this — verify raw value is preserved
        assert_eq!(map.get("danger").unwrap(), "false");
    }

    #[test]
    fn parse_overrides_last_wins() {
        let map = parse_key_value("engine=claude\nengine=cursor\n");
        assert_eq!(map.get("engine").unwrap(), "cursor");
    }
}
