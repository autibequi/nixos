use anyhow::Result;
use zion_sdk::config::ZionConfig;
use zion_sdk::engine::Engine;
use zion_sdk::paths;
use zion_sdk::session::SessionRunner;

/// Execute a session with a forced engine (claude/cursor/opencode subcommands).
#[allow(clippy::too_many_arguments)]
pub fn execute(
    engine_name: &str,
    dir: Option<String>,
    model: Option<String>,
    instance: Option<String>,
    _rw: bool,
    ro: bool,
    danger: bool,
    resume: Option<String>,
    init_md: Option<String>,
) -> Result<()> {
    let config = ZionConfig::load()?;
    let engine: Engine = engine_name.parse().map_err(|e| anyhow::anyhow!("{e}"))?;

    let mount_opts = if ro { "ro" } else { "rw" };
    let mount_path = paths::resolve_dir(dir.as_deref())?;

    let resolved_init_md = init_md.and_then(|f| {
        let full = mount_path.join(&f);
        full.exists().then_some(f)
    });

    let slug = paths::proj_slug(&mount_path);
    let proj_name = paths::proj_name(&slug, instance.as_deref());

    SessionRunner::new(engine)
        .mount_path(&mount_path.to_string_lossy())
        .mount_opts(mount_opts)
        .proj_name(&proj_name)
        .model(model)
        .danger(danger)
        .resume(resume)
        .init_md(resolved_init_md)
        .instance(instance)
        .run(&config)?;

    Ok(())
}
