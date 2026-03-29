use anyhow::{bail, Result};
use std::collections::HashMap;
use std::path::Path;

use crate::config::{self, VennonConfig};
use crate::exec;
use crate::manifest::{self, Manifest};

/// Execute a service command from its vennon.yaml manifest.
pub fn run(
    service_dir: &Path,
    manifest: &Manifest,
    command: &str,
    raw_args: &[String],
    _config: &VennonConfig,
) -> Result<()> {
    let cmd_def = manifest.commands.get(command).ok_or_else(|| {
        let available: Vec<&String> = manifest.commands.keys().collect();
        anyhow::anyhow!(
            "unknown command: {command}\nAvailable for {}: {:?}",
            manifest.name,
            available
        )
    })?;

    // Parse args against command definition + enums
    let args = manifest::parse_args(raw_args, cmd_def, &manifest.enums)?;

    // Build extra context vars
    let mut extra = HashMap::new();
    let home = config::home().to_string_lossy().to_string();
    extra.insert("home".into(), home);
    if let Some(src) = manifest.source_path() {
        extra.insert("source".into(), src.to_string_lossy().to_string());
    }
    // Environment variables
    if let Ok(token) = std::env::var("NPM_TOKEN") {
        extra.insert("NPM_TOKEN".into(), token);
    }

    // Dispatch based on command type
    if let Some(compose) = &cmd_def.compose {
        run_compose(service_dir, manifest, compose, &args, &extra)
    } else if let Some(exec_def) = &cmd_def.exec {
        run_exec(manifest, exec_def, &args, &extra)
    } else if let Some(script) = &cmd_def.script {
        run_script(script, &args, &extra, &manifest.enums)
    } else {
        bail!("command '{command}' has no compose, exec, or script defined")
    }
}

/// Execute a compose-based command.
fn run_compose(
    service_dir: &Path,
    manifest: &Manifest,
    compose: &manifest::ComposeDef,
    args: &HashMap<String, String>,
    extra: &HashMap<String, String>,
) -> Result<()> {
    let project = manifest.project_name();

    // Build compose file list
    let mut compose_args: Vec<String> = vec![];
    for file_ref in &compose.files {
        match file_ref {
            serde_yaml::Value::String(f) => {
                let path = service_dir.join(f);
                compose_args.push("-f".into());
                compose_args.push(path.to_string_lossy().to_string());
            }
            serde_yaml::Value::Mapping(m) => {
                // Conditional: { if: <arg>, file: <path> }
                if let (Some(cond), Some(file)) = (
                    m.get(serde_yaml::Value::String("if".into())),
                    m.get(serde_yaml::Value::String("file".into())),
                ) {
                    let cond_name = cond.as_str().unwrap_or("");
                    let enabled = args.get(cond_name).map(|v| v == "true").unwrap_or(false);
                    if enabled {
                        if let Some(f) = file.as_str() {
                            let path = service_dir.join(f);
                            compose_args.push("-f".into());
                            compose_args.push(path.to_string_lossy().to_string());
                        }
                    }
                }
            }
            _ => {}
        }
    }

    compose_args.push("-p".into());
    compose_args.push(project);

    // Env file
    if let Some(env_file_tpl) = &compose.env_file {
        let rendered = manifest::render(env_file_tpl, args, &manifest.enums, extra);
        let env_path = service_dir.join(&rendered);
        if env_path.exists() {
            compose_args.push("--env-file".into());
            compose_args.push(env_path.to_string_lossy().to_string());
        }
    }

    // Action (split by whitespace)
    let action = manifest::render(&compose.action, args, &manifest.enums, extra);
    for part in action.split_whitespace() {
        compose_args.push(part.into());
    }

    // Environment variables for compose
    let mut env_vars: Vec<(String, String)> = vec![];

    // VENNON_SERVICE_DIR — where Dockerfiles and env/ live
    env_vars.push((
        "VENNON_SERVICE_DIR".into(),
        service_dir.to_string_lossy().to_string(),
    ));

    if let Some(src) = manifest.source_path() {
        // Export source dir as SERVICE_DIR (e.g., MONOLITO_DIR)
        let var_name = format!("{}_DIR", manifest.name.to_uppercase().replace('-', "_"));
        env_vars.push((var_name, src.to_string_lossy().to_string()));
    }
    for (k, v_tpl) in &compose.env {
        let v = manifest::render(v_tpl, args, &manifest.enums, extra);
        env_vars.push((k.clone(), v));
    }

    // Also inject HOME (needed by compose files referencing ${HOME})
    env_vars.push(("HOME".into(), config::home().to_string_lossy().to_string()));

    // Run podman-compose with env vars (inherit parent env + overlay ours)
    let args_refs: Vec<&str> = compose_args.iter().map(|s| s.as_str()).collect();
    let mut cmd = std::process::Command::new("podman-compose");
    cmd.args(&args_refs);
    // Inherit all parent env vars first, then overlay ours
    for (k, v) in &env_vars {
        cmd.env(k, v);
    }
    cmd.stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit());

    let status = cmd.status()?;
    if !status.success() {
        bail!("podman-compose exited with {}", status);
    }
    Ok(())
}

/// Execute a command inside a running container.
fn run_exec(
    manifest: &Manifest,
    exec_def: &manifest::ExecDef,
    args: &HashMap<String, String>,
    extra: &HashMap<String, String>,
) -> Result<()> {
    let container_name = manifest::render(&exec_def.container, args, &manifest.enums, extra);
    let command = manifest::render(&exec_def.command, args, &manifest.enums, extra);

    let project = manifest.project_name();
    // Find container by project + service name
    let full_name = format!("{}-{}", project, container_name);
    let cid = exec::capture(
        "podman",
        &["ps", "-q", "--filter", &format!("name={full_name}")],
    )?;

    if cid.is_empty() {
        bail!(
            "Container {full_name} not running. Start it first with `vennon {} serve`",
            manifest.name
        );
    }

    let cid = cid.lines().next().unwrap_or(&cid).trim();
    exec::exec_replace("podman", &["exec", "-it", cid, "/bin/bash", "-c", &command]);
}

/// Execute a shell script.
fn run_script(
    script: &str,
    args: &HashMap<String, String>,
    extra: &HashMap<String, String>,
    enums: &HashMap<String, manifest::EnumDef>,
) -> Result<()> {
    let rendered = manifest::render(script, args, enums, extra);
    exec::run("bash", &["-c", &rendered])
}
