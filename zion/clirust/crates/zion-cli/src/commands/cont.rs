use anyhow::{bail, Result};
use zion_sdk::config::ZionConfig;
use zion_sdk::engine::Engine;
use zion_sdk::paths;
use zion_sdk::session::SessionRunner;

/// Continue the last session.
pub fn execute(dir: Option<String>) -> Result<()> {
    let config = ZionConfig::load()?;

    let engine: Engine = match config.engine {
        Some(e) => e,
        None => bail!("engine required: set engine= in ~/.zion to use continue"),
    };

    let mount_path = paths::resolve_dir(dir.as_deref())?;
    let slug = paths::proj_slug(&mount_path);
    let proj_name = paths::proj_name(&slug, None);

    // Resume with special value "1" means --continue in bash (last session)
    SessionRunner::new(engine)
        .mount_path(&mount_path.to_string_lossy())
        .mount_opts("rw")
        .proj_name(&proj_name)
        .resume(Some("1".to_string()))
        .run(&config)?;

    Ok(())
}
