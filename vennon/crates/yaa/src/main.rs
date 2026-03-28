mod config;
mod exec;
mod session;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "yaa", version, about = "yaa — session & agent orchestrator")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    /// Engine: claude, opencode, cursor
    #[arg(long, short = 'e', global = true)]
    engine: Option<String>,

    /// Model override (e.g. haiku, opus, sonnet)
    #[arg(long, short = 'm', global = true)]
    model: Option<String>,

    /// Mount ~/nixos at /workspace/host (rw)
    #[arg(long, global = true)]
    host: bool,

    /// Bypass permissions (claude: --dangerously-skip-permissions)
    #[arg(long, global = true)]
    danger: bool,

    /// Directory to mount at /workspace/target
    #[arg(global = true)]
    dir: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    /// Create ~/.yaa.yaml with defaults
    Init,

    /// Rebuild and install yaa + vennon (runs just install)
    Update,

    /// Open interactive shell (zsh) inside the container
    Shell,

    /// Resume a specific session by ID
    Resume {
        /// Session ID to resume
        session_id: Option<String>,
    },

    /// Continue last session
    Continue,

    // Future: Agents, Tasks, Stow, Os, Cleanup, etc.
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Init) => config::init(),

        Some(Commands::Update) => {
            let config = config::YaaConfig::load()?;
            let vennon_dir = config.vennon_path();
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

        Some(Commands::Shell) => {
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir,
                engine: cli.engine,
                model: cli.model,
                host: cli.host,
                danger: cli.danger,
                mode: session::SessionMode::Shell,
            })
        }

        Some(Commands::Resume { session_id }) => {
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir,
                engine: cli.engine,
                model: cli.model,
                host: cli.host,
                danger: cli.danger,
                mode: session::SessionMode::Resume(session_id),
            })
        }

        Some(Commands::Continue) => {
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir,
                engine: cli.engine,
                model: cli.model,
                host: cli.host,
                danger: cli.danger,
                mode: session::SessionMode::Continue,
            })
        }

        None => {
            // Default: new session
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir,
                engine: cli.engine,
                model: cli.model,
                host: cli.host,
                danger: cli.danger,
                mode: session::SessionMode::New,
            })
        }
    }
}
