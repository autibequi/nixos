use anyhow::{bail, Result};
use std::process::Command;

/// Run a command interactively.
pub fn run(program: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(program)
        .args(args)
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()?;
    if !status.success() {
        bail!("{} exited with {}", program, status);
    }
    Ok(())
}

/// Run a command and capture stdout as trimmed String.
pub fn capture(program: &str, args: &[&str]) -> Result<String> {
    let output = Command::new(program)
        .args(args)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .output()?;
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

/// Replace current process with the given command.
#[cfg(unix)]
pub fn exec_replace(program: &str, args: &[&str]) -> ! {
    use std::os::unix::process::CommandExt;
    let err = Command::new(program).args(args).exec();
    eprintln!("exec failed: {err}");
    std::process::exit(1);
}
