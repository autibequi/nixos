use anyhow::Result;

use crate::config::{self, YaaConfig};

pub fn show(engine: Option<&str>, config: &YaaConfig) -> Result<()> {
    let engine = engine.unwrap_or(&config.session.engine);

    match engine {
        "claude" => claude_usage(),
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

fn claude_usage() -> Result<()> {
    let home = config::home();
    let creds_path = home.join(".claude/.credentials.json");

    if !creds_path.exists() {
        println!("No Claude credentials found at {}", creds_path.display());
        println!("Run `claude` first to authenticate.");
        return Ok(());
    }

    let contents = std::fs::read_to_string(&creds_path)?;

    // Parse credentials — find accessToken
    // Format: {"claudeAiOauth":{"accessToken":"...","expiresAt":"...",...}}
    let token = extract_json_field(&contents, "accessToken");

    match token {
        Some(t) => {
            // Use the Claude usage API
            let status = std::process::Command::new("curl")
                .args([
                    "-s",
                    "-H", &format!("Authorization: Bearer {t}"),
                    "-H", "Content-Type: application/json",
                    "https://api.claude.ai/api/organizations",
                ])
                .stdout(std::process::Stdio::piped())
                .stderr(std::process::Stdio::null())
                .output()?;

            let body = String::from_utf8_lossy(&status.stdout);

            if body.contains("error") || body.is_empty() {
                println!("Claude: token may be expired. Re-authenticate with `claude`.");
            } else {
                // Pretty print the response
                println!("Claude API response:");
                println!("{body}");
            }
        }
        None => {
            println!("Could not extract token from {}", creds_path.display());
        }
    }

    Ok(())
}

/// Simple JSON field extraction (avoids serde_json dependency).
fn extract_json_field<'a>(json: &'a str, field: &str) -> Option<&'a str> {
    let pattern = format!("\"{}\":\"", field);
    let start = json.find(&pattern)? + pattern.len();
    let end = json[start..].find('"')? + start;
    Some(&json[start..end])
}
