mod audit;
mod client;
mod config;
mod daemon;
mod execute;
mod protocol;
mod validate;

use anyhow::Result;
use clap::{Parser, Subcommand};
use std::collections::HashMap;

#[derive(Parser)]
#[command(
    name = "buzz",
    version,
    about = "buzz — container→host IPC daemon with YAML permissions"
)]
struct Cli {
    /// Config file (default: ~/.config/vennon/buzz.yaml)
    #[arg(long, short = 'c', global = true)]
    config: Option<std::path::PathBuf>,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Send an action request to the daemon
    Call {
        /// Action name (e.g. open-editor, notify, relay-start)
        action: String,
        /// Arguments as --key=value
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        args: Vec<String>,
    },

    /// Show daemon status
    Status,

    /// List available actions
    List,
}

fn load_config(path: Option<&std::path::Path>) -> Result<config::BuzzConfig> {
    match path {
        Some(p) => config::BuzzConfig::load_from(p),
        None => config::BuzzConfig::load(),
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let cfg_path = cli.config.as_deref();

    match cli.command {
        // No subcommand: start daemon
        None => {
            let config = load_config(cfg_path)?;
            if config.actions.is_empty() {
                eprintln!("[buzz] aviso: nenhuma action definida em buzz.yaml");
            }
            daemon::run(&config)
        }

        Some(Commands::Call { action, args }) => {
            let config = load_config(cfg_path)?;
            let parsed = parse_call_args(&args);
            let resp = client::call(&config.socket_path(), &action, parsed)?;

            match resp.status.as_str() {
                "ok" => {
                    if let Some(output) = &resp.output {
                        print!("{output}");
                    }
                    Ok(())
                }
                "denied" => {
                    eprintln!("denied: {}", resp.error.unwrap_or_default());
                    std::process::exit(2);
                }
                _ => {
                    eprintln!("error: {}", resp.error.unwrap_or_default());
                    std::process::exit(1);
                }
            }
        }

        Some(Commands::Status) => {
            let config = load_config(cfg_path)?;
            let socket = config.socket_path();
            if socket.exists() {
                match std::os::unix::net::UnixStream::connect(&socket) {
                    Ok(_) => println!("buzz running — {}", socket.display()),
                    Err(_) => println!("socket exists but not responding — {}", socket.display()),
                }
            } else {
                println!("buzz not running (no socket at {})", socket.display());
            }
            Ok(())
        }

        Some(Commands::List) => {
            let config = load_config(cfg_path)?;
            if config.actions.is_empty() {
                println!("nenhuma action definida");
                return Ok(());
            }
            let mut names: Vec<&String> = config.actions.keys().collect();
            names.sort();
            for name in names {
                let action = &config.actions[name];
                let capture = if action.capture { " [capture]" } else { "" };
                let args: Vec<String> = action
                    .args
                    .iter()
                    .map(|a| {
                        if a.required {
                            format!("--{}", a.name)
                        } else {
                            format!("[--{}]", a.name)
                        }
                    })
                    .collect();
                println!("  {name:<20} {}{capture}", args.join(" "));
                if !action.description.is_empty() {
                    println!("  {:<20} {}", "", action.description);
                }
            }
            Ok(())
        }
    }
}

fn parse_call_args(args: &[String]) -> HashMap<String, serde_json::Value> {
    let mut map = HashMap::new();
    for arg in args {
        if let Some(kv) = arg.strip_prefix("--") {
            if let Some((key, value)) = kv.split_once('=') {
                let val = if let Ok(n) = value.parse::<i64>() {
                    serde_json::Value::Number(n.into())
                } else {
                    serde_json::Value::String(value.into())
                };
                map.insert(key.to_string(), val);
            } else {
                map.insert(kv.to_string(), serde_json::Value::Bool(true));
            }
        }
    }
    map
}
