use crate::exec;
use anyhow::{bail, Result};

pub fn run(action: &str, reload: bool) -> Result<()> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let nixos = format!("{home}/nixos");
    let stow_dir = format!("{nixos}/stow");

    let args: Vec<&str> = match action {
        "restow" | "re" | "" => vec!["-d", &stow_dir, "-t", &home, "-R", "."],
        "delete" | "un" | "unstow" => vec!["-d", &stow_dir, "-t", &home, "-D", "."],
        "status" => vec!["-d", &stow_dir, "-t", &home, "-n", "-R", "."],
        _ => bail!("unknown stow action: {action}\nValid: restow, delete, status"),
    };

    exec::run("stow", &args)?;

    if reload {
        let _ = exec::run("hyprctl", &["reload"]);
        let _ = exec::run("killall", &["waybar"]);
        let _ = std::process::Command::new("waybar").spawn();
        println!("Reloaded hyprland + waybar");
    }

    Ok(())
}
