//! Config command — show, edit, init, path.

use anyhow::{bail, Result};
use leech_cli::config::{self, LeechConfig};

/// Config subcommand action
pub enum ConfigAction {
    Show,
    Edit,
    Init,
    Path,
}

pub fn run(action: Option<ConfigAction>) -> Result<()> {
    match action {
        None | Some(ConfigAction::Show) => show(),
        Some(ConfigAction::Edit) => edit(),
        Some(ConfigAction::Init) => init(),
        Some(ConfigAction::Path) => path(),
    }
}

/// `leech config` / `leech config show` — display resolved config.
fn show() -> Result<()> {
    let cfg = LeechConfig::load()?;
    cfg.display();
    Ok(())
}

/// `leech config edit` — open config.yaml in $EDITOR.
fn edit() -> Result<()> {
    let path = config::config_dir().join("config.yaml");
    if !path.exists() {
        bail!(
            "Config not found: {}\nRun `leech config init` first.",
            path.display()
        );
    }
    let editor = std::env::var("EDITOR").unwrap_or_else(|_| "vi".into());
    std::process::Command::new(&editor)
        .arg(&path)
        .status()
        .map_err(|e| anyhow::anyhow!("Failed to open {editor}: {e}"))?;
    Ok(())
}

/// `leech config init` — generate default config.yaml.
fn init() -> Result<()> {
    let dir = config::config_dir();
    let path = dir.join("config.yaml");
    if path.exists() {
        bail!("Config already exists: {}", path.display());
    }
    std::fs::create_dir_all(&dir)?;
    std::fs::write(&path, config::DEFAULT_TEMPLATE)?;
    println!("Created: {}", path.display());
    Ok(())
}

/// `leech config path` — print config file paths.
fn path() -> Result<()> {
    let yaml = config::config_dir().join("config.yaml");
    let dotfile = std::env::var("HOME")
        .unwrap_or_else(|_| "/root".into());
    println!("  config.yaml:  {}", yaml.display());
    println!("  ~/.leech:     {}/.leech", dotfile);
    Ok(())
}
