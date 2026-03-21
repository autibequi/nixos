use anyhow::{bail, Result};
use clap::{Parser, Subcommand};

mod commands;
mod output;

/// Not-yet-ported commands — show a helpful message instead of "dir not found".
const BASH_ONLY_COMMANDS: &[&str] = &[
    "man", "help", "start", "shell", "sh", "build", "down", "shutdown", "clean", "gc", "prune",
    "init", "set", "runner", "dk", "docker", "hooks", "hook", "contractors",
    "ct", "stow", "os", "leech", "l", "lab", "git", "g", "inbox", "ib", "outbox", "ob", "relay",
    "beta", "resume",
];

#[derive(Parser)]
#[command(name = "zion", version, about = "ZION - agent orchestration system")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    // Global flags (used when no subcommand = implicit `new`)
    /// Engine: claude | cursor | opencode
    #[arg(long)]
    engine: Option<String>,

    /// Model: haiku | sonnet | opus (or full model ID)
    #[arg(long)]
    model: Option<String>,

    /// Shortcut: --model haiku
    #[arg(long)]
    haiku: bool,

    /// Shortcut: --model opus
    #[arg(long)]
    opus: bool,

    /// Shortcut: --model sonnet
    #[arg(long)]
    sonnet: bool,

    /// Instance suffix (e.g. 2 = zion-projeto-2)
    #[arg(long)]
    instance: Option<String>,

    /// Mount project read-write
    #[arg(long)]
    rw: bool,

    /// Mount project read-only
    #[arg(long)]
    ro: bool,

    /// Bypass engine permissions
    #[arg(long)]
    danger: bool,

    /// Resume session (UUID or empty for last)
    #[arg(long, num_args = 0..=1, default_missing_value = "1")]
    resume: Option<String>,

    /// Initial markdown file loaded by engines
    #[arg(long, default_value = "contexto.md")]
    init_md: Option<String>,

    /// Analysis mode
    #[arg(long, short = 'A')]
    analysis_mode: bool,

    /// Project directory
    dir: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    /// New session (default command)
    #[command(alias = "run", alias = "r", alias = "open", alias = "code")]
    New {
        /// Project directory
        dir: Option<String>,
        #[arg(long)]
        engine: Option<String>,
        #[arg(long)]
        model: Option<String>,
        #[arg(long)]
        instance: Option<String>,
        #[arg(long)]
        rw: bool,
        #[arg(long)]
        ro: bool,
        #[arg(long)]
        danger: bool,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
        #[arg(long, default_value = "contexto.md")]
        init_md: Option<String>,
        #[arg(long, short = 'A')]
        analysis_mode: bool,
    },

    /// Continue last session
    #[command(alias = "cont")]
    Continue {
        /// Project directory
        dir: Option<String>,
    },

    /// New session with Claude engine
    Claude {
        /// Project directory
        dir: Option<String>,
        #[arg(long)]
        model: Option<String>,
        #[arg(long)]
        instance: Option<String>,
        #[arg(long)]
        rw: bool,
        #[arg(long)]
        ro: bool,
        #[arg(long)]
        danger: bool,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
        #[arg(long, default_value = "contexto.md")]
        init_md: Option<String>,
    },

    /// New session with Cursor engine
    Cursor {
        /// Project directory
        dir: Option<String>,
        #[arg(long)]
        model: Option<String>,
        #[arg(long)]
        instance: Option<String>,
        #[arg(long)]
        rw: bool,
        #[arg(long)]
        ro: bool,
        #[arg(long)]
        danger: bool,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
        #[arg(long, default_value = "contexto.md")]
        init_md: Option<String>,
    },

    /// New session with OpenCode engine
    #[command(alias = "oc")]
    Opencode {
        /// Project directory
        dir: Option<String>,
        #[arg(long)]
        model: Option<String>,
        #[arg(long)]
        instance: Option<String>,
        #[arg(long)]
        rw: bool,
        #[arg(long)]
        ro: bool,
        #[arg(long)]
        danger: bool,
        #[arg(long, num_args = 0..=1, default_missing_value = "1")]
        resume: Option<String>,
        #[arg(long, default_value = "contexto.md")]
        init_md: Option<String>,
    },

    /// Interactive status dashboard
    #[command(alias = "st")]
    Status {
        /// Refresh interval in seconds
        #[arg(long, short = 't', default_value = "5")]
        tick: u64,
    },

    /// Build and install zionrust binary
    #[command(alias = "install")]
    Update,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Catch bash-only commands passed as positional dir
    if cli.command.is_none() {
        if let Some(ref dir) = cli.dir {
            if BASH_ONLY_COMMANDS.contains(&dir.as_str()) {
                bail!(
                    "'{}' is not yet ported to zionrust. Use the bash CLI: zion {}",
                    dir,
                    dir
                );
            }
        }
    }

    match cli.command {
        Some(Commands::New {
            dir,
            engine,
            model,
            instance,
            rw,
            ro,
            danger,
            resume,
            init_md,
            analysis_mode,
        }) => {
            commands::new::execute(
                dir,
                engine,
                model,
                instance,
                rw,
                ro,
                danger,
                resume,
                init_md,
                analysis_mode,
            )?;
        }
        Some(Commands::Continue { dir }) => {
            commands::cont::execute(dir)?;
        }
        Some(Commands::Claude {
            dir,
            model,
            instance,
            rw,
            ro,
            danger,
            resume,
            init_md,
        }) => {
            commands::engine::execute(
                "claude", dir, model, instance, rw, ro, danger, resume, init_md,
            )?;
        }
        Some(Commands::Cursor {
            dir,
            model,
            instance,
            rw,
            ro,
            danger,
            resume,
            init_md,
        }) => {
            commands::engine::execute(
                "cursor", dir, model, instance, rw, ro, danger, resume, init_md,
            )?;
        }
        Some(Commands::Opencode {
            dir,
            model,
            instance,
            rw,
            ro,
            danger,
            resume,
            init_md,
        }) => {
            commands::engine::execute(
                "opencode", dir, model, instance, rw, ro, danger, resume, init_md,
            )?;
        }
        Some(Commands::Status { tick }) => {
            commands::status::execute(tick)?;
        }
        Some(Commands::Update) => {
            commands::update::execute()?;
        }
        // No subcommand = implicit `new`
        None => {
            let model = if cli.haiku {
                Some("haiku".to_string())
            } else if cli.opus {
                Some("opus".to_string())
            } else if cli.sonnet {
                Some("sonnet".to_string())
            } else {
                cli.model
            };
            commands::new::execute(
                cli.dir,
                cli.engine,
                model,
                cli.instance,
                cli.rw,
                cli.ro,
                cli.danger,
                cli.resume,
                cli.init_md,
                cli.analysis_mode,
            )?;
        }
    }

    Ok(())
}
