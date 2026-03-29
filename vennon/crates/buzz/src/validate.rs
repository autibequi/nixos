use anyhow::Result;
use std::collections::HashMap;
use std::path::PathBuf;

use crate::config::{expand_path, ActionDef};

/// Validate all args for an action. Returns Ok(resolved_args) or Err with reason.
pub fn validate_args(
    action: &ActionDef,
    raw: &HashMap<String, serde_json::Value>,
) -> Result<HashMap<String, String>, String> {
    let mut resolved = HashMap::new();

    for arg_def in &action.args {
        let val = match raw.get(&arg_def.name) {
            Some(v) => json_to_string(v),
            None => {
                if let Some(default) = &arg_def.default {
                    yaml_to_string(default)
                } else if arg_def.required {
                    return Err(format!("arg obrigatório ausente: {}", arg_def.name));
                } else {
                    continue;
                }
            }
        };

        // Run validators
        for validator in &arg_def.validate {
            validate_rule(validator, &val, &arg_def.name)?;
        }

        resolved.insert(arg_def.name.clone(), val);
    }

    Ok(resolved)
}

fn validate_rule(
    rule: &serde_yaml::Value,
    value: &str,
    arg_name: &str,
) -> Result<(), String> {
    match rule {
        serde_yaml::Value::Mapping(m) => {
            for (key, param) in m {
                let key_str = key.as_str().unwrap_or("");
                match key_str {
                    "path_under" => validate_path_under(value, param, arg_name)?,
                    "path_exists" => {
                        if param.as_bool().unwrap_or(false) {
                            validate_path_exists(value, arg_name)?;
                        }
                    }
                    "starts_with" => {
                        let prefix = param.as_str().unwrap_or("");
                        if !value.starts_with(prefix) {
                            return Err(format!(
                                "{arg_name}: deve começar com '{prefix}'"
                            ));
                        }
                    }
                    "enum" => {
                        if let Some(seq) = param.as_sequence() {
                            let allowed: Vec<&str> = seq.iter()
                                .filter_map(|v| v.as_str())
                                .collect();
                            if !allowed.contains(&value) {
                                return Err(format!(
                                    "{arg_name}: valor '{value}' não permitido. Válidos: {allowed:?}"
                                ));
                            }
                        }
                    }
                    "max_length" => {
                        if let Some(max) = param.as_u64() {
                            if value.len() as u64 > max {
                                return Err(format!(
                                    "{arg_name}: máximo {max} chars, recebeu {}",
                                    value.len()
                                ));
                            }
                        }
                    }
                    "matches" => {
                        // Simple regex check (no regex crate — just basic patterns)
                        let pattern = param.as_str().unwrap_or("");
                        if !simple_match(pattern, value) {
                            return Err(format!(
                                "{arg_name}: não casa com padrão '{pattern}'"
                            ));
                        }
                    }
                    "range" => {
                        if let Some(seq) = param.as_sequence() {
                            if seq.len() == 2 {
                                let min = seq[0].as_i64().unwrap_or(i64::MIN);
                                let max = seq[1].as_i64().unwrap_or(i64::MAX);
                                let n: i64 = value.parse().map_err(|_| {
                                    format!("{arg_name}: não é número")
                                })?;
                                if n < min || n > max {
                                    return Err(format!(
                                        "{arg_name}: valor {n} fora do range [{min}, {max}]"
                                    ));
                                }
                            }
                        }
                    }
                    _ => {} // Unknown validator: ignore
                }
            }
        }
        _ => {} // Non-mapping rule: ignore
    }
    Ok(())
}

fn validate_path_under(
    value: &str,
    allowed_dirs: &serde_yaml::Value,
    arg_name: &str,
) -> Result<(), String> {
    let dirs = match allowed_dirs.as_sequence() {
        Some(seq) => seq.iter()
            .filter_map(|v| v.as_str())
            .map(|s| expand_path(s))
            .collect::<Vec<PathBuf>>(),
        None => return Ok(()),
    };

    // Expand and canonicalize the input path
    let expanded = expand_path(value);
    // Use the expanded path directly (don't canonicalize — file may not exist yet)
    // But normalize away .. and . components
    let normalized = normalize_path(&expanded);

    for dir in &dirs {
        let norm_dir = normalize_path(dir);
        if normalized.starts_with(&norm_dir) {
            return Ok(());
        }
    }

    Err(format!(
        "{arg_name}: path '{}' não está dentro dos diretórios permitidos: {:?}",
        value,
        dirs.iter().map(|d| d.display().to_string()).collect::<Vec<_>>()
    ))
}

fn validate_path_exists(value: &str, arg_name: &str) -> Result<(), String> {
    let expanded = expand_path(value);
    if expanded.exists() {
        Ok(())
    } else {
        Err(format!("{arg_name}: path não existe: {}", expanded.display()))
    }
}

/// Normalize a path: resolve `.` and `..` without filesystem access.
fn normalize_path(path: &PathBuf) -> PathBuf {
    let mut components = Vec::new();
    for comp in path.components() {
        match comp {
            std::path::Component::ParentDir => { components.pop(); }
            std::path::Component::CurDir => {}
            c => components.push(c),
        }
    }
    components.iter().collect()
}

/// Very basic pattern matching (no regex crate).
/// Supports: ^...$, [a-zA-Z0-9_-]+, literal match.
fn simple_match(pattern: &str, value: &str) -> bool {
    match pattern {
        "^[a-zA-Z0-9_-]+$" => {
            !value.is_empty() && value.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '-')
        }
        "^[a-zA-Z0-9_.-]+$" => {
            !value.is_empty() && value.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '.' || c == '-')
        }
        "^[a-zA-Z0-9_./-]+$" => {
            !value.is_empty() && value.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '.' || c == '-' || c == '/')
        }
        // Fallback: literal contains
        other => value.contains(other),
    }
}

fn json_to_string(v: &serde_json::Value) -> String {
    match v {
        serde_json::Value::String(s) => s.clone(),
        serde_json::Value::Number(n) => n.to_string(),
        serde_json::Value::Bool(b) => b.to_string(),
        _ => v.to_string(),
    }
}

fn yaml_to_string(v: &serde_yaml::Value) -> String {
    match v {
        serde_yaml::Value::String(s) => s.clone(),
        serde_yaml::Value::Number(n) => {
            if let Some(i) = n.as_i64() { i.to_string() }
            else if let Some(f) = n.as_f64() { f.to_string() }
            else { n.to_string() }
        }
        serde_yaml::Value::Bool(b) => b.to_string(),
        _ => String::new(),
    }
}
