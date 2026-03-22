//! Shell execution helpers — thin wrappers for commands that delegate to external tools.

use std::process::{Command, Stdio};

use anyhow::{bail, Result};

/// Run a command interactively (inherit stdin/stdout/stderr). Bail on failure.
pub fn run(program: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(program)
        .args(args)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()?;
    if !status.success() {
        bail!("{program} failed (exit {})", status.code().unwrap_or(-1));
    }
    Ok(())
}

/// Run a command interactively in a specific directory.
pub fn run_in(dir: &std::path::Path, program: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(program)
        .args(args)
        .current_dir(dir)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()?;
    if !status.success() {
        bail!("{program} failed (exit {})", status.code().unwrap_or(-1));
    }
    Ok(())
}

/// Run a command silently and return stdout as String.
pub fn capture(program: &str, args: &[&str]) -> Result<String> {
    let output = Command::new(program).args(args).output()?;
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

/// Run a command silently, return lines of stdout.
pub fn capture_lines(program: &str, args: &[&str]) -> Result<Vec<String>> {
    Ok(capture(program, args)?
        .lines()
        .filter(|l| !l.is_empty())
        .map(|l| l.to_string())
        .collect())
}

/// Run bash script file interactively.
pub fn bash_script(path: &std::path::Path) -> Result<()> {
    run("bash", &[&path.to_string_lossy()])
}

/// Run and ignore exit code (fire-and-forget).
pub fn fire(program: &str, args: &[&str]) {
    let _ = Command::new(program)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

/// Delegate to the bash CLI (leech/bash/leech) with the given args.
pub fn bash_delegate(args: &[&str]) -> Result<()> {
    let bash_cli = leech_sdk::paths::bash_dir().join("leech");
    if !bash_cli.exists() {
        bail!("bash CLI not found at {}", bash_cli.display());
    }
    run(&bash_cli.to_string_lossy(), args)
}

/// Delegate to bash CLI with optional --steps flag.
pub fn bash_delegate_with_flags(cmd: &str, args: &[&str], steps: Option<&str>) -> Result<()> {
    let mut all: Vec<&str> = vec![cmd];
    all.extend_from_slice(args);
    if let Some(s) = steps {
        all.push("--steps");
        all.push(s);
    }
    bash_delegate(&all)
}

/// Bail if running inside container.
pub fn require_host() -> Result<()> {
    if leech_sdk::paths::in_container() {
        bail!("this command must run on the host, not inside a container");
    }
    Ok(())
}
