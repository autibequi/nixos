mod compose;
mod config;
mod container;
mod containers;
mod exec;
mod manifest;
mod service;

use anyhow::{bail, Result};
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "vennon", version, about = "vennon — container orchestration")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create ~/.config/vennon/ with config.yaml and container dirs
    Init,

    /// Rebuild and install vennon binary (runs just install)
    Update,

    /// Claude Code container
    Claude {
        /// Action: start (default), build, stop, flush, shell
        #[arg(default_value = "start")]
        action: String,
    },

    /// OpenCode container
    Opencode {
        /// Action: start (default), build, stop, flush, shell
        #[arg(default_value = "start")]
        action: String,
    },

    /// Cursor container
    Cursor {
        /// Action: start (default), build, stop, flush, shell
        #[arg(default_value = "start")]
        action: String,
    },

    /// Service containers (monolito, bo-container, front-student, ...)
    #[command(external_subcommand)]
    Service(Vec<String>),
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Init => config::init(),

        Commands::Update => {
            // Find vennon source: try known paths first, then config
            let candidates = [
                config::expand_path("~/nixos/vennon"),
                config::expand_path("~/nixos/host/vennon"),
            ];
            let vennon_dir = candidates
                .iter()
                .find(|p| p.join("justfile").exists())
                .cloned()
                .or_else(|| config::VennonConfig::load().ok().map(|c| c.vennon_path()))
                .ok_or_else(|| anyhow::anyhow!("can't find vennon source dir (no justfile found)"))?;
            exec::run(
                "just",
                &[
                    "--justfile",
                    &vennon_dir.join("justfile").to_string_lossy(),
                    "--working-directory",
                    &vennon_dir.to_string_lossy(),
                    "install",
                ],
            )
        }

        Commands::Claude { action } => {
            let config = config::VennonConfig::load()?;
            container::dispatch("claude", &action, &config)
        }

        Commands::Opencode { action } => {
            let config = config::VennonConfig::load()?;
            container::dispatch("opencode", &action, &config)
        }

        Commands::Cursor { action } => {
            let config = config::VennonConfig::load()?;
            container::dispatch("cursor", &action, &config)
        }

        Commands::Service(args) => {
            if args.is_empty() {
                bail!("usage: vennon <service> <command> [--args]");
            }

            let config = config::VennonConfig::load()?;
            let svc_name = &args[0];
            let command = args.get(1).map(|s| s.as_str()).unwrap_or("serve");
            let rest: Vec<String> = if args.len() > 2 { args[2..].to_vec() } else { vec![] };

            // Find manifest by name or alias
            let (dir, m) = manifest::find(svc_name)?;

            service::run(&dir, &m, command, &rest, &config)
        }
    }
}
