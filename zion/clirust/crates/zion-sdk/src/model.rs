use crate::config::ZionConfig;
use crate::engine::Engine;

/// Resolve a model alias to its full Claude model ID.
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
pub fn resolve_model(
    cli_model: Option<&str>,
    engine: Engine,
    config: &ZionConfig,
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
pub fn model_flag(cli_model: Option<&str>, engine: Engine, config: &ZionConfig) -> String {
    resolve_model(cli_model, engine, config)
        .map(|id| format!("--model {id}"))
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_model_id() {
        assert_eq!(resolve_model_id("haiku"), "claude-haiku-4-5-20251001");
        assert_eq!(resolve_model_id("opus"), "claude-opus-4-6");
        assert_eq!(resolve_model_id("sonnet"), "claude-sonnet-4-6");
        assert_eq!(resolve_model_id("claude-sonnet-4-6"), "claude-sonnet-4-6");
        assert_eq!(resolve_model_id(""), "");
    }
}
