use anyhow::{bail, Result};
use std::process::Command;

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

#[cfg(unix)]
pub fn exec_replace(program: &str, args: &[&str]) -> ! {
    use std::os::unix::process::CommandExt;
    let err = Command::new(program).args(args).exec();
    eprintln!("exec failed: {err}");
    std::process::exit(1);
}
