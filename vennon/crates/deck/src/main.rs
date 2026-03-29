mod exec;
mod os;
mod process;
mod stow;
mod tui;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(
    name = "deck",
    version,
    about = "deck — container dashboard + host utilities"
)]
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

    /// Rebuild and install full stack (`vennon_update` — mesmo que `yaa update` / `vennon update`)
    Update,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Stow { action, reload }) => stow::run(&action, reload),
        Some(Commands::Os { action }) => os::run(&action),
        Some(Commands::Update) => vennon_update::run(),
        None => tui::run(),
    }
}
