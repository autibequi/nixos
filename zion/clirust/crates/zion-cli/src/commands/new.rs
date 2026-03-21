use anyhow::{bail, Result};
use zion_sdk::config::ZionConfig;
use zion_sdk::engine::Engine;
use zion_sdk::paths;
use zion_sdk::session::SessionRunner;

#[allow(clippy::too_many_arguments)]
pub fn execute(
    dir: Option<String>,
    engine: Option<String>,
    model: Option<String>,
    instance: Option<String>,
    _rw: bool,
    ro: bool,
    danger: bool,
    resume: Option<String>,
    init_md: Option<String>,
    analysis_mode: bool,
) -> Result<()> {
    let config = ZionConfig::load()?;

    // Resolve engine: CLI flag > config
    let engine_str = engine.or_else(|| config.engine.map(|e| e.to_string()));

    let engine: Engine = match engine_str {
        Some(ref s) => s.parse().map_err(|e| anyhow::anyhow!("{e}"))?,
        None => {
            bail!("engine required: use --engine=claude|cursor|opencode or set engine= in ~/.zion")
        }
    };

    let mount_opts = if ro { "ro" } else { "rw" };

    let mount_path = paths::resolve_dir(dir.as_deref())?;

    // Resolve init_md: check if file exists in mount dir
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
        .analysis_mode(analysis_mode)
        .instance(instance)
        .run(&config)?;

    Ok(())
}
