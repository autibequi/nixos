mod config;
mod exec;
mod session;

use anyhow::{bail, Result};
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "yaa", version, about = "yaa — session & agent orchestrator")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    /// Engine: claude, opencode, cursor
    #[arg(long, short = 'e')]
    engine: Option<String>,

    /// Model override (e.g. haiku, opus, sonnet)
    #[arg(long, short = 'm')]
    model: Option<String>,

    /// Mount ~/nixos at /workspace/host (rw)
    #[arg(long)]
    host: bool,

    /// Open bash shell instead of IDE
    #[arg(long)]
    shell: bool,

    /// Resume last session
    #[arg(long)]
    resume: bool,

    /// Bypass permissions (claude: --dangerously-skip-permissions + --enable-auto-mode)
    #[arg(long)]
    danger: bool,

    /// Directory to mount at /workspace/target
    #[arg()]
    dir: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    /// Create ~/.yaa.yaml with defaults
    Init,

    // Future: Agents, Tasks, Stow, Os, Cleanup, etc.
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Init) => config::init(),

        None => {
            // Default: launch session
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir,
                engine: cli.engine,
                model: cli.model,
                host: cli.host,
                shell: cli.shell,
                resume: cli.resume,
                danger: cli.danger,
            })
        }
    }
}
