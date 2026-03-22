//! Agent commands — delegates to bash CLI for execution.

use anyhow::Result;

use crate::exec;

/// `leech auto` — execute due agents + tasks (delegates to bash).
pub fn auto(dry_run: bool, steps: Option<u32>) -> Result<()> {
    let mut args = vec!["auto"];
    let steps_str;
    if dry_run {
        args.push("--dry-run");
    }
    if let Some(s) = steps {
        args.push("--steps");
        steps_str = s.to_string();
        args.push(&steps_str);
    }
    exec::bash_delegate(&args)
}

/// `leech run <name>` — run agent or task immediately (delegates to bash).
pub fn run_unified(name: &str, steps: Option<u32>) -> Result<()> {
    let mut args = vec!["run", name];
    let steps_str;
    if let Some(s) = steps {
        args.push("--steps");
        steps_str = s.to_string();
        args.push(&steps_str);
    }
    exec::bash_delegate(&args)
}

/// `leech agents log` — show _schedule/_running/done.
pub fn log() -> Result<()> {
    exec::bash_delegate(&["agents", "log"])
}

/// `leech tasks log` — show DOING/TODO/DONE.
pub fn tasks_log() -> Result<()> {
    exec::bash_delegate(&["tasks", "log"])
}
