use anyhow::{Context, Result};
use std::io::Write;

use crate::config::{self, YaaConfig};

pub fn show(engine: Option<&str>, flag: Option<&str>, config: &YaaConfig) -> Result<()> {
    let engine = engine.unwrap_or(&config.session.engine);

    match engine {
        "claude" => claude_usage(flag, config),
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

fn claude_usage(flag: Option<&str>, config: &YaaConfig) -> Result<()> {
    let home = config::home();
    let web = config.token("claude_web_session").is_some();
    let candidates = claude_usage_script_candidates(&home, web);

    if let Some(script) = candidates.iter().find(|p| p.exists()) {
        let mut args: Vec<&str> = vec![script.to_str().unwrap_or("")];
        if let Some(f) = flag {
            args.push(f);
        }

        let mut cmd = std::process::Command::new("bash");
        cmd.args(&args)
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped());
        if let Some(s) = config.token("claude_web_session") {
            cmd.env("CLAUDE_AI_SESSION_KEY", s);
        }
        if let Some(o) = config.token("claude_org_id") {
            cmd.env("CLAUDE_AI_ORG_ID", o);
        }
        if let Some(g) = config.token("github") {
            cmd.env("GH_TOKEN", g);
        }
        if let Some(j) = config.token("jira") {
            cmd.env("JIRA_TOKEN", j);
        }

        let out = cmd
            .output()
            .with_context(|| format!("não foi possível executar bash (script: {})", script.display()))?;

        if !out.status.success() {
            eprintln!("yaa usage: o script de uso do Claude falhou.");
            eprintln!("  script: {}", script.display());
            eprintln!(
                "  exit: {}",
                out.status
                    .code()
                    .map(|c| c.to_string())
                    .unwrap_or_else(|| "terminado por sinal".into())
            );
            let stderr = String::from_utf8_lossy(&out.stderr);
            let stdout = String::from_utf8_lossy(&out.stdout);
            if !stderr.trim().is_empty() {
                eprintln!("  stderr:\n{}", stderr.trim_end());
            }
            if !stdout.trim().is_empty() {
                eprintln!("  stdout:\n{}", stdout.trim_end());
            }
            eprintln!("  teste manual: bash {}", script.display());
            eprintln!("  debug: bash -x {} 2>&1 | tail -50", script.display());
            anyhow::bail!(
                "usage script saiu com {}",
                out.status
                    .code()
                    .map(|c| format!("código {c}"))
                    .unwrap_or_else(|| "sinal".into())
            );
        }

        std::io::stdout().write_all(&out.stdout)?;
        std::io::stderr().write_all(&out.stderr)?;
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

/// Sem `claude_web_session` em `~/yaa.yaml`: OAuth primeiro (comportamento anterior).
/// Com sessão web preenchida: `claude-ai-usage.sh` primeiro (mesma fonte que o site).
fn claude_usage_script_candidates(home: &std::path::Path, web_session: bool) -> Vec<std::path::PathBuf> {
    let nix_oauth = config::expand_path("~/nixos/vennon/self/scripts/usage/claude-oauth-usage.sh");
    let nix_ai = config::expand_path("~/nixos/vennon/self/scripts/usage/claude-ai-usage.sh");
    let home_oauth = home.join(".claude/scripts/usage/claude-oauth-usage.sh");
    let home_ai = home.join(".claude/scripts/usage/claude-ai-usage.sh");
    if web_session {
        vec![nix_ai, home_ai, nix_oauth, home_oauth]
    } else {
        vec![nix_oauth, nix_ai, home_oauth, home_ai]
    }
}
