use anyhow::{bail, Result};

use crate::config::{self, YaaConfig};
use crate::exec;

pub struct SessionOpts {
    pub dir: Option<String>,
    pub engine: Option<String>,
    pub model: Option<String>,
    pub host: bool,
    pub shell: bool,
    pub resume: bool,
    pub danger: bool,
}

/// Launch a session: resolve engine/model, call vennon, attach.
pub fn launch(config: &YaaConfig, opts: SessionOpts) -> Result<()> {
    // Resolve engine: CLI flag > config
    let engine = opts
        .engine
        .as_deref()
        .unwrap_or(&config.session.engine);

    match engine {
        "claude" | "opencode" | "cursor" => {}
        _ => bail!("unknown engine: {engine}\nValid: claude, opencode, cursor"),
    }

    // Resolve model: CLI flag > config models.<engine>
    let model = opts
        .model
        .clone()
        .or_else(|| config.model_for_engine(engine));

    // Resolve host: CLI flag OR config
    let host = opts.host || config.session.host;

    // Resolve danger: CLI flag OR config
    let danger = opts.danger || config.session.danger;

    // Resolve directory
    let dir = match &opts.dir {
        Some(d) => {
            let p = if d == "." {
                std::env::current_dir()?
            } else {
                config::expand_path(d)
            };
            p.canonicalize().unwrap_or(p)
        }
        None => config.projects_path(),
    };

    if !dir.exists() {
        bail!("directory not found: {}", dir.display());
    }

    // Action
    let action = if opts.shell { "shell" } else { "start" };

    // Log
    println!("Engine: {engine}");
    if let Some(ref m) = model {
        println!("Model: {m}");
    }
    println!("Target: {}", dir.display());
    if host {
        println!("Host: {} → /workspace/host", config.host_path().display());
    }
    println!();

    // Pass config to vennon via env vars
    // Vennon's IDE compose reads these to configure volumes and exec command
    let dir_str = dir.to_string_lossy().to_string();
    let host_path = config.host_path().to_string_lossy().to_string();
    let obsidian = config.obsidian_path().to_string_lossy().to_string();
    let vennon_self = config.vennon_path().join("self").to_string_lossy().to_string();

    std::env::set_var("YAA_TARGET_DIR", &dir_str);
    std::env::set_var("YAA_HOST_DIR", &host_path);
    std::env::set_var("YAA_HOST_ENABLED", if host { "1" } else { "0" });
    std::env::set_var("YAA_OBSIDIAN_DIR", &obsidian);
    std::env::set_var("YAA_SELF_DIR", &vennon_self);
    if let Some(ref m) = model {
        std::env::set_var("YAA_MODEL", m);
    }
    std::env::set_var("YAA_DANGER", if danger { "1" } else { "0" });

    // Call vennon <engine> <action>
    exec::exec_replace("vennon", &[engine, action]);
}
