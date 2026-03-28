mod compose;
mod config;
mod container;
mod containers;
mod exec;

use anyhow::Result;
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

    /// Claude container
    Claude {
        /// Action: start (default), build, stop, flush, shell
        #[arg(default_value = "start")]
        action: String,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Init => config::init(),

        Commands::Update => {
            let config = config::VennonConfig::load()?;
            let vennon_dir = config.vennon_path();
            println!("Rebuilding vennon from {}...", vennon_dir.display());
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
    }
}
