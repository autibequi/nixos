use anyhow::{bail, Result};

use crate::config;

pub fn show(engine: Option<&str>, config: &config::YaaConfig) -> Result<()> {
    let engine = engine.unwrap_or(&config.session.engine);

    match engine {
        "claude" => claude_token(),
        _ => {
            println!("Token not available for {engine}");
            Ok(())
        }
    }
}

fn claude_token() -> Result<()> {
    let home = config::home();
    let creds_path = home.join(".claude/.credentials.json");

    if !creds_path.exists() {
        bail!("No credentials at {}\nRun `claude` first to authenticate.", creds_path.display());
    }

    let contents = std::fs::read_to_string(&creds_path)?;

    // Extract accessToken from JSON
    let pattern = "\"accessToken\":\"";
    let start = contents.find(pattern)
        .ok_or_else(|| anyhow::anyhow!("accessToken not found in credentials"))?
        + pattern.len();
    let end = contents[start..].find('"')
        .ok_or_else(|| anyhow::anyhow!("malformed credentials"))? + start;

    println!("{}", &contents[start..end]);
    Ok(())
}
