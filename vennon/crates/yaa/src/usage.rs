use anyhow::Result;

use crate::config::{self, YaaConfig};

pub fn show(engine: Option<&str>, flag: Option<&str>, config: &YaaConfig) -> Result<()> {
    let engine = engine.unwrap_or(&config.session.engine);

    match engine {
        "claude" => claude_usage(flag),
        "cursor" => {
            println!("Cursor: check usage at cursor.com/settings");
            Ok(())
        }
        "opencode" => {
            println!("OpenCode: usage depends on configured provider");
            Ok(())
        }
        _ => {
            println!("Usage not available for {engine}");
            Ok(())
        }
    }
}

fn claude_usage(flag: Option<&str>) -> Result<()> {
    let home = config::home();
    let candidates = [
        config::expand_path("~/nixos/vennon/self/scripts/claude-oauth-usage.sh"),
        config::expand_path("~/nixos/leech/self/scripts/claude-oauth-usage.sh"),
        config::expand_path("~/nixos/vennon/self/scripts/claude-ai-usage.sh"),
        config::expand_path("~/nixos/leech/self/scripts/claude-ai-usage.sh"),
        home.join(".claude/scripts/claude-oauth-usage.sh"),
        home.join(".claude/scripts/claude-ai-usage.sh"),
    ];

    if let Some(script) = candidates.iter().find(|p| p.exists()) {
        let mut args: Vec<&str> = vec![script.to_str().unwrap_or("")];
        if let Some(f) = flag {
            args.push(f);
        }

        let status = std::process::Command::new("bash")
            .args(&args)
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()?;
        if !status.success() {
            eprintln!("Script exited with {status}");
        }
        return Ok(());
    }

    // No script found
    if flag == Some("--waybar") {
        println!(r#"{{"text":" 󱙺 --","tooltip":"usage script not found","class":""}}"#);
    } else {
        println!("No usage script found. Searched:");
        for c in &candidates {
            println!("  {}", c.display());
        }
    }
    Ok(())
}
