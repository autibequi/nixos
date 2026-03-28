use anyhow::{bail, Result};
use std::collections::HashMap;
use std::time::Instant;

use crate::config::{self, YaaConfig};
use crate::exec;

/// Parse YAML frontmatter from a markdown file.
/// Returns (key-value map, body after frontmatter).
fn parse_frontmatter(contents: &str) -> (HashMap<String, String>, &str) {
    let mut map = HashMap::new();
    let body_start;

    if contents.starts_with("---") {
        if let Some(end) = contents[3..].find("---") {
            let fm = &contents[3..3 + end];
            body_start = 3 + end + 3;
            for line in fm.lines() {
                if let Some((k, v)) = line.split_once(':') {
                    let k = k.trim().to_string();
                    let v = v.trim().trim_matches('"').to_string();
                    if !k.is_empty() && !v.is_empty() {
                        map.insert(k, v);
                    }
                }
            }
            return (map, &contents[body_start..]);
        }
    }
    (map, contents)
}

fn now_hhmm() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    // UTC-3 (BRT)
    let local = secs as i64 - 3 * 3600;
    let h = (local % 86400) / 3600;
    let m = (local % 3600) / 60;
    format!("{h:02}:{m:02}")
}

fn format_duration(d: std::time::Duration) -> String {
    let s = d.as_secs();
    if s < 60 {
        format!("{s}s")
    } else if s < 3600 {
        format!("{}m {}s", s / 60, s % 60)
    } else {
        format!("{}h {}m", s / 3600, (s % 3600) / 60)
    }
}

/// Call an agent by name. Reads agent.md, parses frontmatter, execs claude -p inside container.
pub fn call(agent_name: &str, message: Option<&str>, config: &YaaConfig) -> Result<()> {
    let start = Instant::now();
    let start_time = now_hhmm();

    // Find agent file: try ego/<name>/agent.md, then ego/<name>.md
    let agents_dir = config.vennon_path().join("self/ego");
    let candidates = [
        agents_dir.join(agent_name).join("agent.md"),  // ego/hermes/agent.md
        agents_dir.join(format!("{agent_name}.md")),    // ego/hermes.md
    ];
    let agent_file = candidates.iter().find(|p| p.exists());

    let agent_file = match agent_file {
        Some(f) => f.clone(),
        None => {
            let mut available = vec![];
            if let Ok(entries) = std::fs::read_dir(&agents_dir) {
                for e in entries.flatten() {
                    if e.path().is_dir() {
                        if e.path().join("agent.md").exists() {
                            available.push(e.file_name().to_string_lossy().to_string());
                        }
                    } else {
                        let name = e.file_name().to_string_lossy().to_string();
                        if name.ends_with(".md") {
                            available.push(name.trim_end_matches(".md").to_string());
                        }
                    }
                }
            }
            available.sort();
            bail!("agent not found: {agent_name}\nAvailable: {}", available.join(", "));
        }
    };

    let contents = std::fs::read_to_string(&agent_file)?;
    let (fm, body) = parse_frontmatter(&contents);

    let model = fm.get("model").cloned().unwrap_or_else(|| "haiku".into());
    let max_turns = fm.get("max_turns").cloned().unwrap_or_else(|| "30".into());

    // Call header
    println!("\x1b[36m📞 Calling {agent_name}...\x1b[0m");
    println!("   Start:  {start_time}");
    println!("   Model:  {model}");
    println!("   Turns:  {max_turns}");
    println!();

    // Build prompt
    let prompt = match message {
        Some(msg) => format!("{}\n\n---\n{}", body.trim(), msg),
        None => body.trim().to_string(),
    };

    // Write prompt to temp file (avoids shell escaping issues)
    let tmp = format!("/tmp/yaa-phone-{agent_name}.md");
    std::fs::write(&tmp, &prompt)?;

    // Ensure container is running (without exec-replacing into it)
    let cid = exec::capture("podman", &["ps", "-q", "--filter", "name=vennon-claude"])?;
    let cid = if cid.is_empty() {
        // Container not running — start it via compose (not vennon start which does exec)
        let _ = std::process::Command::new("podman-compose")
            .args(["-f", &format!("{}/.config/vennon/containers/claude/docker-compose.yml",
                std::env::var("HOME").unwrap_or_default()),
                "-p", "vennon-claude", "up", "-d"])
            .status();
        // Retry find
        let cid2 = exec::capture("podman", &["ps", "-q", "--filter", "name=vennon-claude"])?;
        if cid2.is_empty() {
            bail!("claude container not running — start with `yaa .` first");
        }
        cid2
    } else {
        cid
    };
    let cid = cid.lines().next().unwrap_or(&cid).trim();

    // Copy prompt file into container, then run claude -p
    let container_tmp = format!("/tmp/yaa-phone-{agent_name}.md");
    let _ = std::process::Command::new("podman")
        .args(["cp", &tmp, &format!("{cid}:{container_tmp}")])
        .status();

    let claude_cmd = format!(
        "cd /workspace/home && claude -p \"$(cat {container_tmp})\" --model {model} --max-turns {max_turns} --verbose < /dev/null"
    );

    let result = std::process::Command::new("podman")
        .args(["exec", cid, "/bin/bash", "-c", &claude_cmd])
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status();

    // Call footer
    let duration = start.elapsed();
    let end_time = now_hhmm();
    println!();
    println!("\x1b[36m📞 Call ended\x1b[0m");
    println!("   {start_time} → {end_time} ({})", format_duration(duration));

    // Cleanup temp
    let _ = std::fs::remove_file(&tmp);

    match result {
        Ok(s) if s.success() => Ok(()),
        Ok(s) => bail!("claude exited with {s}"),
        Err(e) => bail!("failed to exec: {e}"),
    }
}
