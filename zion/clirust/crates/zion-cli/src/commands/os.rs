use std::process::Command;

use anyhow::{bail, Result};
use zion_sdk::paths;

/// Run `nh os <action> <nixos_dir>`.
pub fn execute(action: &str) -> Result<()> {
    if std::env::var("in_docker").unwrap_or_default() == "1" {
        bail!("cannot run nixos-rebuild inside container — run on the host");
    }

    let nixos_dir = paths::nixos_dir();

    let status = Command::new("nh")
        .args(["os", action, &nixos_dir.to_string_lossy()])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()?;

    if !status.success() {
        bail!(
            "nh os {} failed with exit code {}",
            action,
            status.code().unwrap_or(-1)
        );
    }

    Ok(())
}
