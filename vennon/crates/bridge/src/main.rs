mod exec;
mod os;
mod stow;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "bridge", version, about = "bridge — TUI dashboard + host utilities")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Deploy dotfiles via GNU stow
    Stow {
        /// Action: restow (default), delete, status
        #[arg(default_value = "restow")]
        action: String,
        /// Reload hyprland + waybar after deploy
        #[arg(long, short = 'r')]
        reload: bool,
    },

    /// NixOS operations via nh
    Os {
        /// Action: switch, test, boot, build
        action: String,
    },

    /// Rebuild and install all binaries (vennon + yaa + bridge)
    Update,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Stow { action, reload }) => stow::run(&action, reload),

        Some(Commands::Os { action }) => os::run(&action),

        Some(Commands::Update) => exec::run("yaa", &["update"]),

        None => {
            // TODO: TUI dashboard (migrar de leech-tui)
            println!("bridge — TUI dashboard (coming soon)");
            println!();
            println!("Available commands:");
            println!("  bridge stow [restow|delete|status]");
            println!("  bridge os [switch|test|boot]");
            println!("  bridge update");
            Ok(())
        }
    }
}
