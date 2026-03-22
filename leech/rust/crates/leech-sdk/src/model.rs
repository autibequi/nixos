//! Model resolution — alias expansion and priority-ordered selection (CLI > per-engine > global).

use crate::config::LeechConfig;
use crate::engine::Engine;

/// Resolve a model alias to its full Claude model ID.
#[must_use]
pub fn resolve_model_id(alias: &str) -> String {
    match alias.to_lowercase().as_str() {
        "haiku" => "claude-haiku-4-5-20251001".to_string(),
        "opus" => "claude-opus-4-6".to_string(),
        "sonnet" => "claude-sonnet-4-6".to_string(),
        "" => String::new(),
        other => other.to_string(), // already a full ID
    }
}

/// Resolve the model for an engine, respecting priority:
/// CLI flag > per-engine config > global config.
#[must_use]
pub fn resolve_model(
    cli_model: Option<&str>,
    engine: Engine,
    config: &LeechConfig,
) -> Option<String> {
    // CLI flag has highest priority
    if let Some(m) = cli_model {
        if !m.is_empty() {
            return Some(resolve_model_id(m));
        }
    }

    // Per-engine config
    let per_engine = match engine {
        Engine::Claude => config.model_claude.as_deref(),
        Engine::OpenCode => config.model_opencode.as_deref(),
        Engine::Cursor => config.model_cursor.as_deref(),
    };
    if let Some(m) = per_engine {
        if !m.is_empty() {
            return Some(resolve_model_id(m));
        }
    }

    // Global config
    config.model.as_deref().and_then(|m| {
        if m.is_empty() {
            None
        } else {
            Some(resolve_model_id(m))
        }
    })
}

/// Format as --model <id> flag string (for claude/cursor CLIs).
#[must_use]
pub fn model_flag(cli_model: Option<&str>, engine: Engine, config: &LeechConfig) -> String {
    resolve_model(cli_model, engine, config).map_or_else(String::new, |id| format!("--model {id}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config_with(model: Option<&str>, model_claude: Option<&str>) -> LeechConfig {
        let mut cfg = LeechConfig::default();
        cfg.model = model.map(|s| s.to_string());
        cfg.model_claude = model_claude.map(|s| s.to_string());
        cfg
    }

    #[test]
    fn alias_expansion() {
        assert_eq!(resolve_model_id("haiku"), "claude-haiku-4-5-20251001");
        assert_eq!(resolve_model_id("opus"), "claude-opus-4-6");
        assert_eq!(resolve_model_id("sonnet"), "claude-sonnet-4-6");
    }

    #[test]
    fn passthrough_full_id() {
        assert_eq!(resolve_model_id("claude-sonnet-4-6"), "claude-sonnet-4-6");
        assert_eq!(resolve_model_id("custom-model-v1"), "custom-model-v1");
    }

    #[test]
    fn empty_alias() {
        assert_eq!(resolve_model_id(""), "");
    }

    #[test]
    fn case_insensitive() {
        assert_eq!(resolve_model_id("HAIKU"), "claude-haiku-4-5-20251001");
        assert_eq!(resolve_model_id("Sonnet"), "claude-sonnet-4-6");
    }

    #[test]
    fn priority_cli_over_config() {
        let cfg = config_with(Some("haiku"), Some("opus"));
        // CLI flag wins
        let r = resolve_model(Some("sonnet"), Engine::Claude, &cfg);
        assert_eq!(r.unwrap(), "claude-sonnet-4-6");
    }

    #[test]
    fn priority_per_engine_over_global() {
        let cfg = config_with(Some("haiku"), Some("opus"));
        // No CLI flag → per-engine wins over global
        let r = resolve_model(None, Engine::Claude, &cfg);
        assert_eq!(r.unwrap(), "claude-opus-4-6");
    }

    #[test]
    fn priority_global_fallback() {
        let cfg = config_with(Some("haiku"), None);
        // No CLI, no per-engine → global
        let r = resolve_model(None, Engine::Claude, &cfg);
        assert_eq!(r.unwrap(), "claude-haiku-4-5-20251001");
    }

    #[test]
    fn no_model_configured() {
        let cfg = LeechConfig::default();
        let r = resolve_model(None, Engine::Claude, &cfg);
        assert!(r.is_none());
    }

    #[test]
    fn model_flag_format() {
        let cfg = config_with(Some("sonnet"), None);
        assert_eq!(model_flag(None, Engine::Claude, &cfg), "--model claude-sonnet-4-6");
    }

    #[test]
    fn model_flag_empty() {
        let cfg = LeechConfig::default();
        assert_eq!(model_flag(None, Engine::Claude, &cfg), "");
    }
}
