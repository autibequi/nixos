use anyhow::{bail, Result};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::{Path, PathBuf};

use crate::config;

// ── Manifest structs ────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct Manifest {
    pub name: String,
    #[serde(rename = "type", default)]
    pub container_type: Option<String>,
    #[serde(default)]
    pub aliases: Vec<String>,
    #[serde(default)]
    pub image: Option<String>,
    #[serde(default)]
    pub dockerfile: Option<String>,
    #[serde(default)]
    pub start_cmd: Option<String>,
    #[serde(default)]
    pub project: Option<String>,
    #[serde(default)]
    pub source: Option<String>,
    #[serde(default)]
    pub enums: HashMap<String, EnumDef>,
    #[serde(default)]
    pub ports: Vec<u16>,
    #[serde(default)]
    pub commands: HashMap<String, CommandDef>,
}

#[derive(Debug, Deserialize)]
pub struct EnumDef {
    pub values: Vec<String>,
    pub default: String,
    #[serde(default)]
    pub map: HashMap<String, String>,
}

#[derive(Debug, Deserialize)]
pub struct CommandDef {
    pub description: Option<String>,
    #[serde(default)]
    pub args: Vec<ArgDef>,
    pub compose: Option<ComposeDef>,
    pub exec: Option<ExecDef>,
    pub script: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ArgDef {
    pub name: String,
    #[serde(rename = "enum")]
    pub enum_ref: Option<String>,
    #[serde(rename = "type")]
    pub arg_type: Option<String>,
    pub default: Option<serde_yaml::Value>,
}

#[derive(Debug, Deserialize)]
pub struct ComposeDef {
    #[serde(default)]
    pub files: Vec<serde_yaml::Value>,
    pub env_file: Option<String>,
    #[serde(default)]
    pub env: HashMap<String, String>,
    pub action: String,
}

#[derive(Debug, Deserialize)]
pub struct ExecDef {
    pub container: String,
    pub command: String,
}

// ── Loading ─────────────────────────────────────────────────────

impl Manifest {
    pub fn load(path: &Path) -> Result<Self> {
        let contents = std::fs::read_to_string(path)?;
        let manifest: Self = serde_yaml::from_str(&contents)?;
        Ok(manifest)
    }

    pub fn project_name(&self) -> String {
        self.project
            .clone()
            .unwrap_or_else(|| format!("vennon-dk-{}", self.name))
    }

    pub fn source_path(&self) -> Option<PathBuf> {
        self.source.as_ref().map(|s| config::expand_path(s))
    }
}

// ── Discovery ───────────────────────────────────────────────────

/// Scan a directory for vennon.yaml manifests.
fn scan_dir(dir: &Path, results: &mut Vec<(PathBuf, Manifest)>, seen: &mut Vec<String>) {
    if !dir.exists() {
        return;
    }
    if let Ok(entries) = std::fs::read_dir(dir) {
        for entry in entries.flatten() {
            let manifest_path = entry.path().join("vennon.yaml");
            if manifest_path.exists() {
                match Manifest::load(&manifest_path) {
                    Ok(m) => {
                        if !seen.contains(&m.name) {
                            seen.push(m.name.clone());
                            results.push((entry.path(), m));
                        }
                    }
                    Err(e) => eprintln!("warning: failed to load {}: {e}", manifest_path.display()),
                }
            }
        }
    }
}

/// Discover all manifests from both:
/// 1. vennon repo: {vennon_path}/containers/ (IDEs)
/// 2. stow/config: ~/.config/vennon/containers/ (services)
pub fn discover_all() -> Result<Vec<(PathBuf, Manifest)>> {
    let mut results = vec![];
    let mut seen = vec![];

    // 1. Repo containers (IDEs + anything in the repo)
    let vennon_path = config::find_vennon_path();
    if let Some(vp) = vennon_path {
        scan_dir(&vp.join("containers"), &mut results, &mut seen);
    }

    // 2. Stow/config containers (services)
    scan_dir(&config::containers_dir(), &mut results, &mut seen);

    Ok(results)
}

/// Find a manifest by name or alias.
pub fn find(name: &str) -> Result<(PathBuf, Manifest)> {
    let all = discover_all()?;
    for (dir, manifest) in all {
        if manifest.name == name || manifest.aliases.contains(&name.to_string()) {
            return Ok((dir, manifest));
        }
    }
    bail!("unknown service: {name}\nAvailable: check containers/ or ~/.config/vennon/containers/")
}

// ── Arg parsing ─────────────────────────────────────────────────

/// Parse raw CLI args against a command definition.
pub fn parse_args(
    raw: &[String],
    cmd: &CommandDef,
    enums: &HashMap<String, EnumDef>,
) -> Result<HashMap<String, String>> {
    let mut result = HashMap::new();

    // Fill defaults
    for arg in &cmd.args {
        if let Some(enum_ref) = &arg.enum_ref {
            if let Some(e) = enums.get(enum_ref) {
                result.insert(arg.name.clone(), e.default.clone());
            }
        } else if let Some(default) = &arg.default {
            let val = match default {
                serde_yaml::Value::Bool(b) => b.to_string(),
                serde_yaml::Value::Number(n) => n.to_string(),
                serde_yaml::Value::String(s) => s.clone(),
                _ => "".into(),
            };
            result.insert(arg.name.clone(), val);
        }
    }

    // Parse --key=value and --flag from raw args
    for raw_arg in raw {
        if let Some(kv) = raw_arg.strip_prefix("--") {
            if let Some((key, value)) = kv.split_once('=') {
                // Validate enum values
                if let Some(arg_def) = cmd.args.iter().find(|a| a.name == key) {
                    if let Some(enum_ref) = &arg_def.enum_ref {
                        if let Some(e) = enums.get(enum_ref) {
                            if !e.values.contains(&value.to_string()) {
                                bail!(
                                    "invalid value '{value}' for --{key}\nValid: {:?}",
                                    e.values
                                );
                            }
                        }
                    }
                }
                result.insert(key.to_string(), value.to_string());
            } else {
                // Boolean flag --debug → true
                result.insert(kv.to_string(), "true".to_string());
            }
        }
    }

    Ok(result)
}

// ── Template rendering ──────────────────────────────────────────

/// Render {{ var }} and {{ var | map }} in a template string.
pub fn render(
    template: &str,
    args: &HashMap<String, String>,
    enums: &HashMap<String, EnumDef>,
    extra: &HashMap<String, String>,
) -> String {
    let mut result = template.to_string();

    // {{ var | map }} — apply enum mapping
    let map_re_pattern = "{{ ";
    // Simple parser: find {{ ... }} blocks
    loop {
        let start = match result.find("{{") {
            Some(i) => i,
            None => break,
        };
        let end = match result[start..].find("}}") {
            Some(i) => start + i + 2,
            None => break,
        };
        let expr = result[start + 2..end - 2].trim();

        let replacement = if expr.contains(" | map") {
            let var_name = expr.replace(" | map", "").trim().to_string();
            let raw_val = args
                .get(&var_name)
                .or_else(|| extra.get(&var_name))
                .cloned()
                .unwrap_or_default();
            // Find the enum that this var references and apply mapping
            let mut mapped = raw_val.clone();
            for (_, enum_def) in enums {
                if let Some(m) = enum_def.map.get(&raw_val) {
                    mapped = m.clone();
                    break;
                }
            }
            // Also check by arg name → enum ref
            if let Some(enum_def) = enums.get(&var_name) {
                if let Some(m) = enum_def.map.get(&raw_val) {
                    mapped = m.clone();
                }
            }
            mapped
        } else {
            args.get(expr)
                .or_else(|| extra.get(expr))
                .cloned()
                .unwrap_or_default()
        };

        result = format!("{}{}{}", &result[..start], replacement, &result[end..]);
    }

    result
}
