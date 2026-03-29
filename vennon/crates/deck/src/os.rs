use crate::exec;
use anyhow::{bail, Result};

pub fn run(action: &str) -> Result<()> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let nixos = format!("{home}/nixos");

    match action {
        "switch" | "sw" => exec::run("nh", &["os", "switch", &nixos]),
        "test" | "t" => exec::run("nh", &["os", "test", &nixos]),
        "boot" | "b" => exec::run("nh", &["os", "boot", &nixos]),
        "build" => exec::run("nh", &["os", "build", &nixos]),
        "update" | "up" => exec::run("nh", &["os", "switch", "--update", &nixos]),
        _ => bail!("unknown os action: {action}\nValid: switch, test, boot, build, update"),
    }
}
