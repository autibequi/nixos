//! Leech CLI — command-line interface for the Leech agent orchestration system.
//!
//! DIRECTIVE: When adding or changing commands, update help.rs too.
//! Every command needs: about, long_about (if complex), and after_help with examples.

use anyhow::Result;
use clap::{CommandFactory, Parser, Subcommand};

mod commands;
mod exec;
mod help;

use commands::SessionFlags;

#[derive(Parser)]
#[command(
    name = "leech",
    version,
    about = "LEECH — agent orchestration system",
    before_help = help::BANNER,
    after_help = help::MAIN_AFTER,
    subcommand_precedence_over_arg = true,
)]
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

    /// Print shell scripts and mounted prompts (set env var LEECH_VERBOSE=1)
    #[arg(long, global = true)]
    verbose: bool,
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
    Continue {
        dir: Option<String>,
        #[arg(long)]
        host: bool,
    },
    /// Claude tools (usage, token)
    #[command(before_help = help::CLAUDE_BEFORE)]
    Claude {
        #[command(subcommand)]
        action: Option<ClaudeAction>,
    },
    /// Resume a session by ID
    Resume {
        dir: Option<String>,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
        #[arg(long)]
        host: bool,
    },
    /// Bash shell inside container
    #[command(alias = "sh")]
    Shell {
        dir: Option<String>,
        #[arg(long)]
        host: bool,
    },
    /// Ephemeral session (auto-detect nixos)
    #[command(alias = "l", hide = true)]
    Leech {
        #[command(flatten)]
        flags: SessionFlags,
        #[arg(long, short = 's')]
        shell: bool,
    },
    /// Build Docker image
    Build {
        #[arg(long)]
        danger: bool,
        /// Alias for --danger: rebuild base image without cache (refreshes cursor-agent)
        #[arg(long)]
        no_cache: bool,
    },
    /// Stop compose containers
    #[command(alias = "down")]
    Stop,
    /// Stop all + kill strays
    Shutdown,
    /// Remove stopped containers
    #[command(alias = "gc", alias = "prune")]
    Clean {
        #[arg(long, short = 'f')]
        force: bool,
    },
    /// Zombies bash: listar pais e opcionalmente SIGTERM (host Linux; não apaga arquivos)
    #[command(alias = "zombies", alias = "clean-up", after_help = help::CLEANUP_AFTER)]
    Cleanup {
        /// SIGTERM nos processos pai que acumulam zombies (resumo + confirmação; --yes pula)
        #[arg(long)]
        reap: bool,
        /// Confirmar --reap sem perguntar (scripts)
        #[arg(long, short = 'y')]
        yes: bool,
        #[arg(long, default_value_t = 1)]
        min: usize,
        /// Listar todos os pais (não só stack dev)
        #[arg(long)]
        all: bool,
    },

    /// Deploy dotfiles via GNU stow
    #[command(before_help = help::STOW_BEFORE)]
    Stow {
        #[arg(default_value = "restow")]
        action: String,
        #[arg(long, short = 'r')]
        reload: bool,
    },
    /// NixOS operations (switch/test/boot/build)
    #[command(before_help = help::OS_BEFORE)]
    Os {
        #[command(subcommand)]
        action: OsAction,
    },
    /// Build and install leech CLI
    #[command(alias = "install", hide = true)]
    Update,
    /// Set default engine
    #[command(hide = true)]
    Set { engine: String },

    /// Execute a Claude Code hook
    #[command(alias = "hook", hide = true)]
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
    /// List inbox files
    #[command(alias = "ib")]
    Inbox,
    /// List outbox files
    #[command(alias = "ob", hide = true)]
    Outbox,
    /// Full documentation
    Man,
    /// Show banner
    #[command(alias = "h", hide = true)]
    Banner,
    /// Generate shell completions (source dynamically: eval "$(leech completions zsh)")
    #[command(hide = true)]
    Completions {
        /// Shell: bash, zsh, fish, elvish
        shell: clap_complete::Shell,
    },
    /// Claude usage stats (alias for `claude usage`)
    #[command(hide = true)]
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
    #[command(hide = true)]
    Token,

    /// Interactive status dashboard
    #[command(alias = "st", before_help = help::STATUS_BEFORE)]
    Status {
        #[arg(long, short = 't', default_value = "5")]
        tick: u64,
        #[arg(long)]
        json: bool,
    },

    // ── Worktree ─────────────────────────────────────────────────
    /// List git worktrees across services
    #[command(alias = "wt", before_help = help::WORKTREE_BEFORE)]
    Worktree {
        service: Option<String>,
        #[arg(long)]
        json: bool,
    },

    // ── Runner (service orchestration) ──────────────────────────
    /// Service orchestration (start/stop/logs/shell/install/test/build/flush)
    #[command(alias = "docker", before_help = help::RUNNER_BEFORE)]
    Runner {
        service: String,
        action: String,
        #[arg(long, default_value = "local")]
        env: String,
        #[arg(long)]
        worktree: Option<String>,
        #[arg(long, default_value = "carreiras-juridicas")]
        vertical: String,
        #[arg(long, default_value = "app")]
        container: String,
        #[arg(long)]
        cmd: Option<String>,
        #[arg(long, default_value = "100")]
        tail: u32,
        #[arg(long)]
        debug: bool,
        #[arg(long)]
        dev: bool,
        #[arg(long)]
        detach: bool,
    },

    // ── Tick (timer systemd) ─────────────────────────────────────
    /// Auto-execute due agents + tasks (systemd timer)
    #[command(alias = "auto", before_help = help::TICK_BEFORE)]
    Tick {
        #[arg(long, short = 'n')]
        dry_run: bool,
        #[arg(long, short = 's')]
        steps: Option<u32>,
    },

    /// Shortcut for 'leech run tasker'
    #[command(hide = true)]
    Tasker {
        #[arg(long, short = 's')]
        steps: Option<u32>,
    },

    // ── Run (agent or task) ─────────────────────────────────────
    /// Run an agent or task immediately
    #[command(alias = "r", before_help = help::RUN_BEFORE)]
    Run {
        name: String,
        #[arg(long, short = 's')]
        steps: Option<u32>,
    },

    // ── Sentinel ─────────────────────────────────────────────────
    /// Keep machine awake for remote access (systemd-inhibit)
    #[command(alias = "caffeine")]
    Sentinel {
        #[arg(default_value = "start")]
        action: String,
    },

    /// Destroy containers + volumes + leech image (full reset)
    Destroy,

    /// Shared tmux session (host ↔ container)
    #[command(alias = "tm")]
    Tmux {
        #[command(subcommand)]
        action: TmuxAction,
    },

    // ── Git ──────────────────────────────────────────────────────
    /// Git utilities
    #[command(alias = "g", hide = true)]
    Git {
        #[command(subcommand)]
        action: GitAction,
    },

    // ── Agents ──────────────────────────────────────────────────
    /// Agent management (list, phone, status)
    #[command(alias = "ag", alias = "a", before_help = help::AGENTS_BEFORE)]
    Agents {
        #[command(subcommand)]
        action: Option<AgentsAction>,
    },

    // ── Tasks ───────────────────────────────────────────────────
    /// Task kanban (DOING/TODO/DONE)
    #[command(alias = "t", before_help = help::TASKS_BEFORE)]
    Tasks {
        #[command(subcommand)]
        action: Option<TasksAction>,
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
    List {
        #[arg(long)]
        json: bool,
    },
    /// Conversa interativa com um agente
    #[command(alias = "p", alias = "call")]
    Phone {
        name: Option<String>,
    },
    /// Activity log: fila + historico de execucoes
    #[command(alias = "log", alias = "st")]
    Status {
        name: Option<String>,
        #[arg(long)]
        json: bool,
    },
}

#[derive(Subcommand)]
enum TasksAction {
    /// Kanban view: TODO/DOING/DONE
    Log {
        #[arg(long)]
        json: bool,
    },
    /// Dashboard live de tasks + agents
    #[command(alias = "st", alias = "dash")]
    Status {
        #[arg(long, short = 't', default_value = "5")]
        tick: String,
    },
}

#[derive(Subcommand)]
enum TmuxAction {
    /// Install tmux into nix profile (run once inside container)
    Install,
    /// Start server + session, attach interactively, kill server on exit (host only)
    Serve,
    /// Attach to existing shared session (container → host)
    Open,
    /// Send command to shared session and capture output
    Run {
        #[arg(trailing_var_arg = true)]
        cmd: Vec<String>,
    },
    /// Capture current pane output
    Capture,
    /// Show server + session status
    Status,
}

#[derive(Subcommand)]
enum GitAction {
    /// Stage all + commit with timestamp
    Append {
        branch: Option<String>,
    },
    /// Stage all + commit (sandbox shortcut)
    Sandbox,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Set LEECH_VERBOSE environment variable for all subcommands
    if cli.verbose {
        std::env::set_var("LEECH_VERBOSE", "1");
    }

    match cli.command {
        // Session
        Some(Commands::New { flags }) => commands::session::new(flags),
        Some(Commands::Continue { dir, host }) => commands::session::cont(dir, host),
        Some(Commands::Claude { action }) => match action {
            Some(ClaudeAction::Usage {
                waybar,
                no_cache,
                refresh,
            }) => commands::tools::usage(waybar, no_cache || refresh),
            Some(ClaudeAction::Token) => commands::tools::token(),
            None => commands::tools::usage(false, false),
        },
        Some(Commands::Resume { dir, resume, host }) => commands::session::resume(dir, resume, host),
        Some(Commands::Shell { dir, host }) => commands::session::shell(dir, host),
        Some(Commands::Leech { flags, shell }) => commands::session::leech(flags, shell),

        // Docker
        Some(Commands::Build { danger, no_cache }) => commands::docker::build(danger || no_cache),
        Some(Commands::Stop) => commands::docker::down(),
        Some(Commands::Shutdown) => commands::docker::shutdown(),
        Some(Commands::Clean { force }) => commands::docker::clean(force),
        Some(Commands::Cleanup { reap, yes, min, all }) => {
            commands::cleanup::run(reap, min, all, yes)
        },

        // Host
        Some(Commands::Stow { action, reload }) => commands::host::stow(&action, reload),
        Some(Commands::Os { action }) => commands::host::os(match action {
            OsAction::Switch => "switch",
            OsAction::Test => "test",
            OsAction::Boot => "boot",
            OsAction::Build => "build",
        }),
        Some(Commands::Update) => commands::host::update(),
        Some(Commands::Inbox) => commands::tools::inbox(None),
        Some(Commands::Set { engine }) => commands::host::set_engine(&engine),

        // Tools
        Some(Commands::Hooks {
            hook,
            list,
            env_overrides,
        }) => commands::tools::hooks(hook, list, env_overrides),
        Some(Commands::Relay { action }) => commands::tools::relay(&action),
        Some(Commands::Outbox) => commands::tools::outbox(),
        Some(Commands::Man) => commands::tools::man(),
        Some(Commands::Banner) => commands::tools::help_banner(),
        Some(Commands::Completions { shell }) => {
            clap_complete::generate(shell, &mut Cli::command(), "leech", &mut std::io::stdout());
            Ok(())
        }
        Some(Commands::Usage {
            waybar,
            no_cache,
            refresh,
            ..
        }) => commands::tools::usage(waybar, no_cache || refresh),
        Some(Commands::Token) => commands::tools::token(),

        // Interactive
        Some(Commands::Status { tick, json }) => {
            if json {
                let snap = leech_cli::status::collect()?;
                println!("{}", serde_json::to_string_pretty(&snap)?);
                Ok(())
            } else {
                leech_cli::tui::run_status(tick)?;
                Ok(())
            }
        }

        // Worktree
        Some(Commands::Worktree { service, json }) => {
            let svc = service.as_deref().filter(|s| *s != "list");
            let worktrees = leech_cli::worktree::list_worktrees(svc);
            if json {
                println!("{}", serde_json::to_string_pretty(&worktrees)?);
            } else {
                if worktrees.is_empty() {
                    println!("Nenhum worktree encontrado.");
                } else {
                    let mut last_svc = "";
                    for wt in &worktrees {
                        if wt.service != last_svc {
                            if !last_svc.is_empty() { println!(); }
                            println!("  \x1b[1m\x1b[36m{}\x1b[0m", wt.service);
                            last_svc = &wt.service;
                        }
                        let main = if wt.is_main { " \x1b[33m(main)\x1b[0m" } else { "" };
                        println!(
                            "    \x1b[32m{:<20}\x1b[0m  \x1b[2m[{}]\x1b[0m{}",
                            wt.name, wt.branch, main
                        );
                    }
                    println!();
                }
            }
            Ok(())
        }

        // Runner — native Rust service orchestration
        Some(Commands::Runner {
            service, action, env, worktree, vertical, container, cmd, tail, debug, dev, detach,
        }) => {
            commands::runner::run(&service, &action, &commands::runner::RunnerOpts {
                env: &env,
                worktree: worktree.as_deref(),
                vertical: &vertical,
                container: &container,
                cmd: cmd.as_deref(),
                tail,
                debug,
                dev,
                detach,
            })
        }

        // Sentinel / caffeine
        Some(Commands::Sentinel { action }) => commands::tools::sentinel(&action),

        // Destroy
        Some(Commands::Destroy) => commands::docker::destroy(),

        // Tmux
        Some(Commands::Tmux { action }) => match action {
            TmuxAction::Install => commands::tmux::install(),
            TmuxAction::Serve   => commands::tmux::serve(),
            TmuxAction::Open    => commands::tmux::open(),
            TmuxAction::Run { cmd } => commands::tmux::run(&cmd),
            TmuxAction::Capture => commands::tmux::capture(),
            TmuxAction::Status  => commands::tmux::status(),
        },

        // Git
        Some(Commands::Git { action }) => match action {
            GitAction::Append { branch } => commands::git::append(branch.as_deref().unwrap_or("")),
            GitAction::Sandbox => commands::git::sandbox(),
        },

        // Tick
        Some(Commands::Tick { dry_run, steps }) => {
            commands::agents::auto(dry_run, steps)
        }

        // Tasker — shortcut for `leech run tasker`
        Some(Commands::Tasker { steps }) => {
            commands::agents::run_unified("tasker", steps)
        }

        // Run — delegates to bash CLI
        Some(Commands::Run { name, steps }) => {
            commands::agents::run_unified(&name, steps)
        }

        // Agents
        Some(Commands::Agents { action }) => match action.unwrap_or(AgentsAction::List { json: false }) {
            AgentsAction::List { json } => commands::agents::list(json),
            AgentsAction::Status { name, json } => commands::agents::agent_log(name.as_deref(), json),
            AgentsAction::Phone { name } => {
                commands::agents::phone(name.as_deref())
            },
        },

        // Tasks
        Some(Commands::Tasks { action }) => match action.unwrap_or(TasksAction::Log { json: false }) {
            TasksAction::Log { json } => commands::agents::tasks_log(json),
            TasksAction::Status { tick: _ } => {
                // Show kanban view (live dashboard available via `leech status` TUI)
                commands::agents::tasks_log(false)
            }
        },

        // No subcommand = implicit `new`
        None => {
            if matches!(cli.flags.dir.as_deref(), Some("cleanup" | "clean-up")) {
                anyhow::bail!(
                    "o token \"{}\" foi interpretado como pasta de projeto (sessão implícita), não como subcomando.\n\
                     Isto acontece quando o binário foi compilado sem `Commands::Cleanup` + braço em `main.rs` — o Clap trata a palavra como o positional `dir`.\n\
                     Corrige `crates/leech-cli/src/main.rs` (variante `Cleanup` e `commands::cleanup::run`) e volta a `just install` / `cargo build --release`.",
                    cli.flags.dir.as_deref().unwrap_or("")
                );
            }
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
