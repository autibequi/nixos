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

    /// List all available containers
    List,

    /// Any container: vennon <name> [action] [--args]
    #[command(external_subcommand)]
    Container(Vec<String>),
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Init => config::init(),

        Commands::Update => {
            let candidates = [
                config::expand_path("~/nixos/vennon"),
                config::expand_path("~/nixos/host/vennon"),
            ];
            let vennon_dir = candidates
                .iter()
                .find(|p| p.join("justfile").exists())
                .cloned()
                .or_else(|| config::VennonConfig::load().ok().map(|c| c.vennon_path()))
                .ok_or_else(|| anyhow::anyhow!("can't find vennon source dir"))?;
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

        Commands::List => {
            let all = manifest::discover_all()?;
            if all.is_empty() {
                println!("No containers found.");
            } else {
                for (dir, m) in &all {
                    let aliases = if m.aliases.is_empty() {
                        String::new()
                    } else {
                        format!(" ({})", m.aliases.join(", "))
                    };
                    let kind = if containers::is_ide(&m.name) { "ide" } else { "svc" };
                    println!("  [{kind}] {}{aliases}", m.name);
                }
            }
            Ok(())
        }

        Commands::Container(args) => {
            if args.is_empty() {
                bail!("usage: vennon <container> [action] [--args]");
            }

            let config = config::VennonConfig::load()?;
            let name = &args[0];
            let action = args.get(1).map(|s| s.as_str()).unwrap_or_default();
            let rest: Vec<String> = if args.len() > 2 { args[2..].to_vec() } else { vec![] };

            // IDE containers: dispatch through container.rs
            if containers::is_ide(name) {
                let action = if action.is_empty() { "start" } else { action };
                return container::dispatch(name, action, &config);
            }

            // Service containers: find manifest, dispatch through service.rs
            let (dir, m) = manifest::find(name)?;
            let command = if action.is_empty() { "serve" } else { action };
            service::run(&dir, &m, command, &rest, &config)
        }
    }
}
