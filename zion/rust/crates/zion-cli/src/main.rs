//! Zion CLI — command-line interface for the Zion agent orchestration system.

use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod exec;

use commands::SessionFlags;

#[derive(Parser)]
#[command(name = "zion", version, about = "ZION - agent orchestration system")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    // Global flags (used when no subcommand = implicit `new`)
    #[command(flatten)]
    flags: SessionFlags,

    #[arg(long)]
    haiku: bool,
    #[arg(long)]
    opus: bool,
    #[arg(long)]
    sonnet: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// New session in container
    #[command(alias = "open", alias = "code")]
    New {
        #[command(flatten)]
        flags: SessionFlags,
    },
    /// Continue last session
    #[command(alias = "cont")]
    Continue { dir: Option<String> },
    /// Session with Claude engine (default: new session)
    Claude {
        #[command(subcommand)]
        action: Option<ClaudeAction>,

        #[command(flatten)]
        flags: SessionFlags,
    },
    /// Session with Cursor engine
    Cursor {
        #[command(flatten)]
        flags: SessionFlags,
    },
    /// Session with OpenCode engine
    #[command(alias = "oc")]
    Opencode {
        #[command(flatten)]
        flags: SessionFlags,
    },
    /// Resume a session by ID
    Resume {
        dir: Option<String>,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
    },
    /// Bash shell inside container
    #[command(alias = "sh")]
    Shell { dir: Option<String> },
    /// Ephemeral session (auto-detect nixos)
    #[command(alias = "l")]
    Leech {
        #[command(flatten)]
        flags: SessionFlags,
        #[arg(long, short = 's')]
        shell: bool,
    },
    /// Lab session (nixos mount)
    Lab {
        #[arg(long)]
        engine: Option<String>,
        #[arg(long)]
        model: Option<String>,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
        #[arg(long)]
        danger: bool,
    },

    /// Build Docker image
    Build {
        #[arg(long)]
        danger: bool,
    },
    /// Stop compose containers
    Down,
    /// Stop all + kill strays
    Shutdown,
    /// Remove stopped containers
    #[command(alias = "gc", alias = "prune")]
    Clean {
        #[arg(long, short = 'f')]
        force: bool,
    },

    /// Deploy dotfiles via GNU stow
    Stow {
        #[arg(default_value = "restow")]
        action: String,
        #[arg(long, short = 'r')]
        reload: bool,
    },
    /// NixOS operations (switch/test/boot/build)
    Os {
        #[command(subcommand)]
        action: OsAction,
    },
    /// Build and install zion CLIs
    #[command(alias = "install")]
    Update,
    /// Create ~/.zion config
    Init {
        #[arg(long)]
        force: bool,
    },
    /// Set default engine
    Set { engine: String },

    /// Execute a Claude Code hook
    #[command(alias = "hook")]
    Hooks {
        hook: Option<String>,
        #[arg(long, short = 'l')]
        list: bool,
        #[arg(trailing_var_arg = true)]
        env_overrides: Vec<String>,
    },
    /// Chrome Relay (CDP)
    Relay {
        #[arg(default_value = "start")]
        action: String,
    },
    /// Read or add to inbox
    #[command(alias = "ib")]
    Inbox { message: Option<String> },
    /// List outbox files
    #[command(alias = "ob")]
    Outbox,
    /// Full documentation
    Man,
    /// Show banner
    #[command(alias = "h")]
    Banner,
    /// Claude usage stats (alias for `claude usage`)
    Usage {
        #[arg(long)]
        waybar: bool,
        #[arg(long)]
        json: bool,
        #[arg(long)]
        no_cache: bool,
        #[arg(long)]
        refresh: bool,
    },
    /// Print Claude OAuth token (alias for `claude token`)
    Token,

    /// Interactive status dashboard
    #[command(alias = "st")]
    Status {
        #[arg(long, short = 't', default_value = "5")]
        tick: u64,
    },

    // ── Auto (timer systemd) ────────────────────────────────────
    /// Execute agents e tasks vencidos (timer systemd 10min)
    Auto {
        #[arg(long, short = 'n')]
        dry_run: bool,
        #[arg(long, short = 's')]
        steps: Option<u32>,
    },

    // ── Run (agent or task) ─────────────────────────────────────
    /// Roda um agente ou task imediatamente
    #[command(alias = "r")]
    Run {
        name: String,
        #[arg(long, short = 's')]
        steps: Option<u32>,
    },

    // ── Agents ──────────────────────────────────────────────────
    #[command(alias = "ag", alias = "a")]
    Agents {
        #[command(subcommand)]
        action: Option<AgentsAction>,
    },

    // ── Tasks ───────────────────────────────────────────────────
    #[command(alias = "tk")]
    Tasks {
        #[command(subcommand)]
        action: Option<TasksAction>,
    },

    // ── Git ─────────────────────────────────────────────────────
    #[command(alias = "g")]
    Git {
        #[command(subcommand)]
        action: GitAction,
    },
}

#[derive(Subcommand)]
enum ClaudeAction {
    /// Claude usage stats
    Usage {
        #[arg(long)]
        waybar: bool,
        #[arg(long)]
        no_cache: bool,
        #[arg(long)]
        refresh: bool,
    },
    /// Print Claude OAuth token
    Token,
}

#[derive(Subcommand)]
enum OsAction {
    #[command(alias = "sw")]
    Switch,
    #[command(alias = "t")]
    Test,
    #[command(alias = "b")]
    Boot,
    Build,
}

#[derive(Subcommand)]
enum AgentsAction {
    /// Lista todos os agentes e status
    #[command(alias = "ls")]
    List,
    /// Conversa interativa com um agente
    #[command(alias = "p", alias = "call")]
    Phone {
        name: Option<String>,
    },
    /// Mostra _schedule, _running e execucoes recentes
    Log,
}

#[derive(Subcommand)]
enum TasksAction {
    /// Ultimas execucoes de tasks
    Log,
}

#[derive(Subcommand)]
enum GitAction {
    #[command(alias = "ap")]
    Append { branch: String },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        // Session
        Some(Commands::New { flags }) => commands::session::new(flags),
        Some(Commands::Continue { dir }) => commands::session::cont(dir),
        Some(Commands::Claude { action, flags }) => match action {
            Some(ClaudeAction::Usage {
                waybar,
                no_cache,
                refresh,
            }) => commands::tools::usage(waybar, no_cache || refresh),
            Some(ClaudeAction::Token) => commands::tools::token(),
            None => commands::session::engine("claude", flags),
        },
        Some(Commands::Cursor { flags }) => commands::session::engine("cursor", flags),
        Some(Commands::Opencode { flags }) => commands::session::engine("opencode", flags),
        Some(Commands::Resume { dir, resume }) => commands::session::resume(dir, resume),
        Some(Commands::Shell { dir }) => commands::session::shell(dir),
        Some(Commands::Leech { flags, shell }) => commands::session::leech(flags, shell),
        Some(Commands::Lab {
            engine,
            model,
            resume,
            danger,
        }) => commands::session::lab(engine, model, resume, danger),

        // Docker
        Some(Commands::Build { danger }) => commands::docker::build(danger),
        Some(Commands::Down) => commands::docker::down(),
        Some(Commands::Shutdown) => commands::docker::shutdown(),
        Some(Commands::Clean { force }) => commands::docker::clean(force),

        // Host
        Some(Commands::Stow { action, reload }) => commands::host::stow(&action, reload),
        Some(Commands::Os { action }) => commands::host::os(match action {
            OsAction::Switch => "switch",
            OsAction::Test => "test",
            OsAction::Boot => "boot",
            OsAction::Build => "build",
        }),
        Some(Commands::Update) => commands::host::update(),
        Some(Commands::Init { force }) => commands::host::init(force),
        Some(Commands::Set { engine }) => commands::host::set_engine(&engine),

        // Tools
        Some(Commands::Hooks {
            hook,
            list,
            env_overrides,
        }) => commands::tools::hooks(hook, list, env_overrides),
        Some(Commands::Relay { action }) => commands::tools::relay(&action),
        Some(Commands::Inbox { message }) => commands::tools::inbox(message),
        Some(Commands::Outbox) => commands::tools::outbox(),
        Some(Commands::Man) => commands::tools::man(),
        Some(Commands::Banner) => commands::tools::help_banner(),
        Some(Commands::Usage {
            waybar,
            no_cache,
            refresh,
            ..
        }) => commands::tools::usage(waybar, no_cache || refresh),
        Some(Commands::Token) => commands::tools::token(),

        // Interactive
        Some(Commands::Status { tick }) => {
            zion_tui::run_status(tick)?;
            Ok(())
        }

        // Auto — delegates to bash CLI
        Some(Commands::Auto { dry_run, steps }) => {
            commands::agents::auto(dry_run, steps)
        }

        // Run — delegates to bash CLI
        Some(Commands::Run { name, steps }) => {
            commands::agents::run_unified(&name, steps)
        }

        // Agents
        Some(Commands::Agents { action }) => match action.unwrap_or(AgentsAction::List) {
            AgentsAction::List => exec::bash_delegate(&["agents"]),
            AgentsAction::Log => commands::agents::log(),
            AgentsAction::Phone { name } => {
                let mut args = vec!["agents".to_string(), "phone".to_string()];
                if let Some(n) = name { args.push(n); }
                exec::bash_delegate(&args.iter().map(|s| s.as_str()).collect::<Vec<_>>())
            },
        },

        // Tasks
        Some(Commands::Tasks { action }) => match action.unwrap_or(TasksAction::Log) {
            TasksAction::Log => commands::agents::tasks_log(),
        },

        // Git
        Some(Commands::Git { action }) => match action {
            GitAction::Append { branch } => commands::git::append(&branch),
        },

        // No subcommand = implicit `new`
        None => {
            let mut flags = cli.flags;
            if cli.haiku {
                flags.model = Some("haiku".into());
            } else if cli.opus {
                flags.model = Some("opus".into());
            } else if cli.sonnet {
                flags.model = Some("sonnet".into());
            }
            commands::session::new(flags)
        }
    }
}
