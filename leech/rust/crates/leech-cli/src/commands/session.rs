//! Session commands — launch, resume, and manage agent sessions inside the container.

use anyhow::Result;
use leech_cli::{
    compose::ComposeCmd, config::LeechConfig, engine::Engine, paths, session::SessionRunner,
};

use super::SessionFlags;

/// `leech` (no args) / `leech new` — new session with resolved engine.
pub fn new(flags: SessionFlags) -> Result<()> {
    let config = LeechConfig::load()?;
    let engine = resolve_engine(flags.engine.as_deref(), &config)?;
    launch(engine, flags, &config)
}

/// `leech continue` — resume last session.
pub fn cont(dir: Option<String>, host: bool) -> Result<()> {
    let config = LeechConfig::load()?;
    let engine = config
        .engine
        .ok_or_else(|| anyhow::anyhow!("engine required in ~/.leech"))?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = if host || config.mount_host {
        format!("{}-host", paths::proj_name(&slug, None))
    } else {
        paths::proj_name(&slug, None)
    };

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&proj)
        .host(host || config.mount_host)
        .resume(Some("1".into()))
        .run(&config)?)
}

/// `leech claude` / `leech cursor` / `leech opencode` — forced engine.
#[allow(dead_code)]
pub fn engine(name: &str, flags: SessionFlags) -> Result<()> {
    let config = LeechConfig::load()?;
    let engine: Engine = name.parse().map_err(|e| anyhow::anyhow!("{e}"))?;
    launch(engine, flags, &config)
}

/// `leech resume` — resume by session ID.
pub fn resume(dir: Option<String>, session_id: Option<String>, host: bool) -> Result<()> {
    let config = LeechConfig::load()?;
    let engine = config
        .engine
        .ok_or_else(|| anyhow::anyhow!("engine required in ~/.leech"))?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = if host || config.mount_host {
        format!("{}-host", paths::proj_name(&slug, None))
    } else {
        paths::proj_name(&slug, None)
    };

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&proj)
        .host(host || config.mount_host)
        .resume(Some(session_id.unwrap_or_else(|| "1".into())))
        .run(&config)?)
}

/// `leech shell` — bash inside container.
pub fn shell(dir: Option<String>, host: bool) -> Result<()> {
    let config = LeechConfig::load()?;
    let host_active = host || config.mount_host;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = if host_active {
        format!("{}-host", paths::proj_name(&slug, None))
    } else {
        paths::proj_name(&slug, None)
    };

    let mut cmd = ComposeCmd::new()
        .project(&proj)
        .env("CLAUDIO_MOUNT", &mount.to_string_lossy())
        .env("CLAUDIO_MOUNT_OPTS", "rw")
        .env("OBSIDIAN_PATH", &paths::obsidian_ensured())
        .env("HOME", &paths::home().to_string_lossy())
        .env("DOCKER_GID", &config.docker_gid.to_string())
        .env("JOURNAL_GID", &config.journal_gid.to_string())
        .env("LEECH_ROOT", &paths::leech_root().to_string_lossy())
        .env("LEECH_NIXOS_DIR", &paths::nixos_dir().to_string_lossy());
    if host_active {
        cmd = cmd.env("CLAUDIO_HOST_OPTS", "rw");
    }

    let host_attached_env = format!("HOST_ATTACHED={}", if host_active { "1" } else { "0" });
    let mount_env = format!("CLAUDIO_MOUNT={}", mount.display());
    let mut args = vec![
        "run",
        "--rm",
        "-it",
        "--entrypoint",
        "/entrypoint.sh",
        "-e", &mount_env, "-e", "BOOTSTRAP_SKIP_CLEAR=1",
        "-e", &host_attached_env,
        "leech", "/bin/bash", "-c",
        ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec bash",
    ];
    if host_active {
        // insert before "leech" to pass HOST_ATTACHED — already in args above
    }
    Ok(cmd.execute(&args)?)
}

/// `leech leech` — ephemeral session with auto-detect.
pub fn leech(flags: SessionFlags, shell_mode: bool) -> Result<()> {
    if shell_mode {
        return shell(flags.dir, flags.host);
    }

    let config = LeechConfig::load()?;
    let raw = flags
        .dir
        .clone()
        .unwrap_or_else(|| paths::home().join("projects").to_string_lossy().to_string());
    let mount = std::path::Path::new(&raw)
        .canonicalize()
        .map_err(|_| anyhow::anyhow!("dir not found: {raw}"))?;

    let is_nixos = paths::nixos_dir()
        .canonicalize()
        .map(|n| mount == n)
        .unwrap_or(false);
    let proj = if is_nixos {
        "leech-projects".into()
    } else {
        paths::proj_name(&paths::proj_slug(&mount), None)
    };

    let extra_volumes = if is_nixos {
        vec!["/var/log/journal:/workspace/logs/host/journal:ro".into()]
    } else {
        vec![]
    };

    let engine = resolve_engine(flags.engine.as_deref(), &config)?;
    let init_md = flags.resolve_init_md(&mount);

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts(flags.mount_opts())
        .proj_name(&proj)
        .model(flags.model)
        .danger(flags.danger)
        .resume(flags.resume)
        .init_md(init_md)
        .extra_volumes(extra_volumes)
        .run(&config)?)
}

// ── Internal ─────────────────────────────────────────────────────

fn resolve_engine(flag: Option<&str>, config: &LeechConfig) -> Result<Engine> {
    let name = flag
        .map(|s| s.to_string())
        .or_else(|| config.engine.map(|e| e.to_string()))
        .ok_or_else(|| {
            anyhow::anyhow!(
                "engine required: use --engine=claude|cursor|opencode or set engine= in ~/.leech"
            )
        })?;
    name.parse().map_err(|e| anyhow::anyhow!("{e}"))
}

fn launch(engine: Engine, flags: SessionFlags, config: &LeechConfig) -> Result<()> {
    if flags.ghost {
        let obsidian = paths::obsidian_path();
        let ghost_dir = obsidian.join("ghost");
        let _ = std::fs::create_dir_all(&ghost_dir);
        let ghost_path = ghost_dir.to_string_lossy().into_owned();
        return Ok(SessionRunner::new(engine)
            .mount_path(&ghost_path)
            .ghost(true)
            .model(flags.model)
            .run(config)?);
    }

    let host_active = flags.host || config.mount_host;
    let mount = paths::resolve_dir(flags.dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = if host_active {
        format!("{}-host", paths::proj_name(&slug, flags.instance.as_deref()))
    } else {
        paths::proj_name(&slug, flags.instance.as_deref())
    };
    let init_md = flags.resolve_init_md(&mount);

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts(flags.mount_opts())
        .proj_name(&proj)
        .host(host_active)
        .model(flags.model)
        .danger(flags.danger)
        .resume(flags.resume)
        .init_md(init_md)
        .analysis_mode(flags.analysis_mode)
        .no_splash(flags.no_splash)
        .run(config)?)
}
