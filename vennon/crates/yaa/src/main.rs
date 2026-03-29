mod config;
mod exec;
mod man;
mod phone;
mod session;
mod tmux;
mod token;
mod usage;

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

    /// Rebuild and install yaa + vennon + bridge (runs just install)
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

    /// Call an agent (interactive session with timer)
    Phone {
        /// Agent name
        agent: String,
        /// Optional message to send
        message: Option<String>,
    },

    /// Run tick cycle (calls ticker agent)
    Tick,

    /// Show API usage for an engine
    Usage {
        /// Engine: claude (default), cursor
        #[arg(default_value = "")]
        engine: String,
        /// Output format: --waybar, --statusline, --refresh, --json, --debug
        #[arg(long)]
        waybar: bool,
        #[arg(long)]
        statusline: bool,
        #[arg(long)]
        refresh: bool,
        #[arg(long)]
        json: bool,
        #[arg(long)]
        debug: bool,
    },

    /// Print OAuth token for an engine
    Token {
        /// Engine: claude (default)
        #[arg(default_value = "")]
        engine: String,
    },

    /// Full documentation
    Man,

    /// Shared tmux session (host ↔ container)
    Tmux {
        /// Action: serve, open, run, capture, status
        #[arg(default_value = "status")]
        action: String,
        /// Command to run (for 'run' action)
        #[arg(trailing_var_arg = true)]
        args: Vec<String>,
    },

    /// Stop and remove container for an engine (cleanup)
    Cleanup {
        /// Engine: claude, cursor, opencode (or "all")
        #[arg(default_value = "all")]
        engine: String,
    },
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
                dir: cli.dir, engine: cli.engine, model: cli.model,
                host: cli.host, danger: cli.danger, mode: session::SessionMode::Shell,
            })
        }

        Some(Commands::Resume { session_id }) => {
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir, engine: cli.engine, model: cli.model,
                host: cli.host, danger: cli.danger, mode: session::SessionMode::Resume(session_id),
            })
        }

        Some(Commands::Continue) => {
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir, engine: cli.engine, model: cli.model,
                host: cli.host, danger: cli.danger, mode: session::SessionMode::Continue,
            })
        }

        Some(Commands::Phone { agent, message }) => {
            let config = config::YaaConfig::load()?;
            phone::call(&agent, message.as_deref(), &config)
        }

        Some(Commands::Tick) => {
            let config = config::YaaConfig::load()?;
            phone::call("hermes", Some("Ciclo automatico. Execute com autonomia total: limpe travados, desbloqueie o que puder, despache vencidos, processe inbox/outbox. Nao pergunte — execute."), &config)
        }

        Some(Commands::Usage { engine, waybar, statusline, refresh, json, debug }) => {
            let config = config::YaaConfig::load()?;
            let e = if engine.is_empty() { None } else { Some(engine.as_str()) };
            let flag = if waybar { Some("--waybar") }
                else if statusline { Some("--statusline") }
                else if refresh { Some("--refresh") }
                else if json { Some("--json") }
                else if debug { Some("--debug") }
                else { None };
            usage::show(e, flag, &config)
        }

        Some(Commands::Token { engine }) => {
            let config = config::YaaConfig::load()?;
            let e = if engine.is_empty() { None } else { Some(engine.as_str()) };
            token::show(e, &config)
        }

        Some(Commands::Man) => man::show(),

        Some(Commands::Tmux { action, args }) => tmux::dispatch(&action, &args),

        Some(Commands::Cleanup { engine }) => {
            let engines: Vec<&str> = if engine == "all" {
                vec!["claude", "cursor", "opencode"]
            } else {
                vec![engine.as_str()]
            };
            for e in &engines {
                let container = format!("vennon-{e}");
                println!("Cleaning up {container}...");
                let _ = exec::run("podman", &["stop", &container]);
                let _ = exec::run("podman", &["rm", "-f", &container]);
            }
            println!("Done.");
            Ok(())
        }

        None => {
            let config = config::YaaConfig::load()?;
            session::launch(&config, session::SessionOpts {
                dir: cli.dir, engine: cli.engine, model: cli.model,
                host: cli.host, danger: cli.danger, mode: session::SessionMode::New,
            })
        }
    }
}
