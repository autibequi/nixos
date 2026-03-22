//! Session commands — launch, resume, and manage agent sessions inside the container.

use anyhow::Result;
use zion_sdk::{
    compose::ComposeCmd, config::ZionConfig, engine::Engine, paths, session::SessionRunner,
};

use super::SessionFlags;

/// `zion` (no args) / `zion new` — new session with resolved engine.
pub fn new(flags: SessionFlags) -> Result<()> {
    let config = ZionConfig::load()?;
    let engine = resolve_engine(flags.engine.as_deref(), &config)?;
    launch(engine, flags, &config)
}

/// `zion continue` — resume last session.
pub fn cont(dir: Option<String>) -> Result<()> {
    let config = ZionConfig::load()?;
    let engine = config
        .engine
        .ok_or_else(|| anyhow::anyhow!("engine required in ~/.zion"))?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&paths::proj_name(&slug, None))
        .resume(Some("1".into()))
        .run(&config)?)
}

/// `zion claude` / `zion cursor` / `zion opencode` — forced engine.
#[allow(dead_code)]
pub fn engine(name: &str, flags: SessionFlags) -> Result<()> {
    let config = ZionConfig::load()?;
    let engine: Engine = name.parse().map_err(|e| anyhow::anyhow!("{e}"))?;
    launch(engine, flags, &config)
}

/// `zion resume` — resume by session ID.
pub fn resume(dir: Option<String>, session_id: Option<String>) -> Result<()> {
    let config = ZionConfig::load()?;
    let engine = config
        .engine
        .ok_or_else(|| anyhow::anyhow!("engine required in ~/.zion"))?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&paths::proj_name(&slug, None))
        .resume(Some(session_id.unwrap_or_else(|| "1".into())))
        .run(&config)?)
}

/// `zion shell` — bash inside container.
pub fn shell(dir: Option<String>) -> Result<()> {
    let config = ZionConfig::load()?;
    let mount = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount);

    Ok(ComposeCmd::new()
        .project(&paths::proj_name(&slug, None))
        .env("CLAUDIO_MOUNT", &mount.to_string_lossy())
        .env("CLAUDIO_MOUNT_OPTS", "rw")
        .env("OBSIDIAN_PATH", &paths::obsidian_ensured())
        .env("HOME", &paths::home().to_string_lossy())
        .env("DOCKER_GID", &config.docker_gid.to_string())
        .env("JOURNAL_GID", &config.journal_gid.to_string())
        .env("ZION_ROOT", &paths::zion_root().to_string_lossy())
        .env("ZION_NIXOS_DIR", &paths::nixos_dir().to_string_lossy())
        .execute(&[
            "run",
            "--rm",
            "-it",
            "--entrypoint",
            "/entrypoint.sh",
            "-e",
            &format!("CLAUDIO_MOUNT={}", mount.display()),
            "-e",
            "BOOTSTRAP_SKIP_CLEAR=1",
            "leech",
            "/bin/bash",
            "-c",
            ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec bash",
        ])?)
}

/// `zion leech` — ephemeral session with auto-detect.
pub fn leech(flags: SessionFlags, shell_mode: bool) -> Result<()> {
    if shell_mode {
        return shell(flags.dir);
    }

    let config = ZionConfig::load()?;
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
        "zion-projects".into()
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

/// `zion host` — nixos mount session.
pub fn lab(
    engine: Option<String>,
    model: Option<String>,
    resume: Option<String>,
    danger: bool,
) -> Result<()> {
    let config = ZionConfig::load()?;
    let mount = paths::nixos_dir()
        .canonicalize()
        .map_err(|_| anyhow::anyhow!("nixos dir not found"))?;

    let engine: Engine = engine
        .or_else(|| config.engine.map(|e| e.to_string()))
        .unwrap_or_else(|| "claude".into())
        .parse()
        .map_err(|e| anyhow::anyhow!("{e}"))?;

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts("rw")
        .proj_name("zion-projects")
        .model(model)
        .danger(danger)
        .resume(resume)
        .extra_volumes(vec![
            "/var/log/journal:/workspace/logs/host/journal:ro".into(),
        ])
        .run(&config)?)
}

// ── Internal ─────────────────────────────────────────────────────

fn resolve_engine(flag: Option<&str>, config: &ZionConfig) -> Result<Engine> {
    let name = flag
        .map(|s| s.to_string())
        .or_else(|| config.engine.map(|e| e.to_string()))
        .ok_or_else(|| {
            anyhow::anyhow!(
                "engine required: use --engine=claude|cursor|opencode or set engine= in ~/.zion"
            )
        })?;
    name.parse().map_err(|e| anyhow::anyhow!("{e}"))
}

fn launch(engine: Engine, flags: SessionFlags, config: &ZionConfig) -> Result<()> {
    let mount = paths::resolve_dir(flags.dir.as_deref())?;
    let slug = paths::proj_slug(&mount);
    let proj = paths::proj_name(&slug, flags.instance.as_deref());
    let init_md = flags.resolve_init_md(&mount);

    Ok(SessionRunner::new(engine)
        .mount_path(&mount.to_string_lossy())
        .mount_opts(flags.mount_opts())
        .proj_name(&proj)
        .model(flags.model)
        .danger(flags.danger)
        .resume(flags.resume)
        .init_md(init_md)
        .analysis_mode(flags.analysis_mode)
        .no_splash(flags.no_splash)
        .run(config)?)
}
