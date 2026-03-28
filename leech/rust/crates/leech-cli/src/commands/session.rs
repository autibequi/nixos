//! Session commands — launch, resume, and manage agent sessions inside the container.

use anyhow::Result;
use leech_cli::{
    compose::ComposeCmd, config::LeechConfig, engine::Engine, paths, session::SessionRunner,
};
use std::os::unix::process::CommandExt;
use std::process::Command;

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
        .engine()
        .ok_or_else(|| anyhow::anyhow!("engine required — set session.engine in config.yaml"))?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = if host || config.session.host {
        format!("{}-host", paths::proj_name(&slug, None))
    } else {
        paths::proj_name(&slug, None)
    };

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&proj)
        .host(host || config.session.host)
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
        .engine()
        .ok_or_else(|| anyhow::anyhow!("engine required — set session.engine in config.yaml"))?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = if host || config.session.host {
        format!("{}-host", paths::proj_name(&slug, None))
    } else {
        paths::proj_name(&slug, None)
    };

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&proj)
        .host(host || config.session.host)
        .resume(Some(session_id.unwrap_or_else(|| "1".into())))
        .run(&config)?)
}

/// `leech shell` — bash inside container.
pub fn shell(dir: Option<String>, host: bool) -> Result<()> {
    let config = LeechConfig::load()?;
    let host_active = host || config.session.host;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let home = paths::home().to_string_lossy().into_owned();
    let leech_root = paths::leech_root().to_string_lossy().into_owned();
    let obsidian_path = paths::obsidian_ensured();

    let mount_env = format!("CLAUDIO_MOUNT={}", mount.display());
    let host_attached_env = format!("HOST_ATTACHED={}", if host_active { "1" } else { "0" });

    // Use podman run directly (podman-compose doesn't support -i -t flags)
    let mut cmd = Command::new("podman");
    cmd.args(["run", "--rm", "-i", "-t"]);

    // Volumes
    cmd.args(["-v", &format!("{}:/workspace/mnt:rw", mount.display())]);
    cmd.args(["-v", &format!("{obsidian_path}:/workspace/obsidian:rw")]);
    cmd.args(["-v", &format!("{leech_root}:/workspace/self:ro")]);
    cmd.args(["-v", &format!("{home}/.claude:/home/claude/.claude:rw")]);
    cmd.args(["-v", &format!("{home}/.leech:/home/claude/.leech:rw")]);
    cmd.args(["-v", "podman.sock:/run/user/1000/podman/podman.sock"]);

    if host_active {
        cmd.args(["-v", &format!("{home}/nixos:/workspace/host:rw")]);
    }

    // Environment
    cmd.args(["-e", &mount_env]);
    cmd.args(["-e", &host_attached_env]);
    cmd.args(["-e", "BOOTSTRAP_SKIP_CLEAR=1"]);
    cmd.args(["-e", &format!("DOCKER_GID={}", config.docker_gid())]);
    cmd.args(["-e", &format!("JOURNAL_GID={}", config.system.journal_gid)]);
    cmd.args(["-e", &format!("HOME={home}")]);
    cmd.args(["-e", &format!("LEECH_ROOT={leech_root}")]);
    cmd.args(["-e", &format!("LEECH_NIXOS_DIR={}", paths::nixos_dir().to_string_lossy())]);
    cmd.args(["-e", &format!("XDG_DATA_HOME={}", paths::xdg_data_home())]);
    cmd.args(["-e", &format!("XDG_RUNTIME_DIR={}", paths::xdg_runtime_dir())]);

    // Entrypoint and command
    cmd.args(["--entrypoint", "/entrypoint.sh"]);
    cmd.args(["leech", "/bin/bash", "-c"]);
    cmd.arg(". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec bash");

    let err = cmd.exec();
    Err(anyhow::anyhow!("podman run failed: {err}"))
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
        .or_else(|| config.engine().map(|e| e.to_string()))
        .ok_or_else(|| {
            anyhow::anyhow!(
                "engine required: use --engine=claude|cursor|opencode or set session.engine in config.yaml"
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

    let host_active = flags.host || config.session.host;
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
