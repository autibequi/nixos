//! Contractor commands — run and inspect background agent workers.

use anyhow::{bail, Result};
use zion_sdk::paths;

/// `zion contractors run <name>` — run a contractor immediately.
pub fn run(name: &str, steps: Option<u32>) -> Result<()> {
    let agent_file =
        paths::agent_file(name).ok_or_else(|| anyhow::anyhow!("contractor '{name}' not found"))?;
    let runner = paths::task_runner().ok_or_else(|| anyhow::anyhow!("task-runner.sh not found"))?;
    let tasks = paths::tasks_dir().ok_or_else(|| anyhow::anyhow!("tasks dir not found"))?;

    let content = std::fs::read_to_string(&agent_file)?;
    let model = fm_value(&content, "model").unwrap_or_else(|| "sonnet".into());
    let timeout: u32 = match model.as_str() {
        "haiku" => 900,
        "opus" => 3600,
        _ => 1800,
    };
    let steps = steps.unwrap_or(match model.as_str() {
        "haiku" => 20,
        "opus" => 60,
        _ => 40,
    });

    let when = paths::timestamp();
    let card = format!("{when}_{name}.md");
    let todo = tasks.join("TODO");
    std::fs::create_dir_all(&todo)?;

    std::fs::write(todo.join(&card), format!(
        "---\nmodel: {model}\ntimeout: {timeout}\nmcp: false\nagent: {name}\n---\n{}\n\n#steps{steps}\n",
        fm_body(&content),
    ))?;

    println!("[contractor] '{name}' -> {card}  model={model}  steps={steps}");
    let _ = std::fs::remove_dir_all(format!("/tmp/zion-locks/{when}_{name}.lock"));

    let agents_dir = tasks.parent().map(|p| p.join("vault/agents"));
    let mut cmd = std::process::Command::new(&runner);
    cmd.arg(&card)
        .env("TASK_DIR", &tasks)
        .env("TASK_MAX_TURNS", steps.to_string());
    if let Some(ad) = &agents_dir {
        cmd.env("TASK_AGENTS_DIR", ad);
    }

    let s = cmd
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()?;
    if !s.success() {
        bail!("contractor runner failed");
    }
    Ok(())
}

/// `zion contractors status` — show TODO/DOING/DONE.
pub fn status() -> Result<()> {
    let tasks = paths::tasks_dir().ok_or_else(|| anyhow::anyhow!("tasks dir not found"))?;

    for (label, color, dir, limit) in [
        ("DOING", "36", "DOING", 0usize),
        ("TODO", "33", "TODO", 0),
        ("DONE", "2", "DONE", 10),
    ] {
        let mut files = md_files(&tasks.join(dir));
        if dir == "DONE" {
            files.reverse();
        }
        if limit > 0 && files.len() > limit {
            files.truncate(limit);
        }

        println!(
            "\x1b[1m\x1b[{color}m▸ {label}\x1b[0m \x1b[2m({})\x1b[0m",
            files.len()
        );
        if files.is_empty() {
            println!("  \x1b[2m(nenhum)\x1b[0m");
        } else {
            for f in &files {
                println!(
                    "  {}",
                    f.trim_start_matches(|c: char| c.is_ascii_digit() || c == '_')
                        .trim_end_matches(".md")
                );
            }
        }
        println!();
    }
    Ok(())
}

/// `zion contractors work` — execute all due contractor cards from schedule.
pub fn work(dry_run: bool) -> Result<()> {
    let schedule = paths::schedule_dir()
        .ok_or_else(|| anyhow::anyhow!("contractors/_schedule not found"))?;
    let runner = paths::task_runner()
        .ok_or_else(|| anyhow::anyhow!("task-runner.sh not found"))?;

    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;
    let threshold = now + 300; // 5min tolerance

    let mut due: Vec<(String, String)> = Vec::new(); // (filename, agent_name)

    for entry in std::fs::read_dir(&schedule)?.flatten() {
        let filename = entry.file_name().to_string_lossy().to_string();
        if !filename.ends_with(".md") {
            continue;
        }
        let ts = card_epoch(&filename);
        if ts == 0 || ts > threshold {
            continue;
        }
        let path = entry.path();
        let content = std::fs::read_to_string(&path).unwrap_or_default();
        if !is_contractor_card(&content) {
            continue;
        }
        let agent = fm_value(&content, "agent")
            .or_else(|| fm_value(&content, "contractor"))
            .unwrap_or_else(|| "?".into());
        let delay = (now - ts) / 60;
        println!("[work] due: {filename}  agent={agent}  atraso={delay}min");
        due.push((filename, agent));
    }

    if due.is_empty() {
        println!("[work] nenhum contractor card vencido.");
        return Ok(());
    }

    println!("[work] {} card(s) para executar", due.len());

    if dry_run {
        println!("[work] --dry-run: nao executando");
        return Ok(());
    }

    let contractors_dir = schedule.parent().map(|p| p.to_path_buf());

    for (filename, _) in &due {
        println!("[work] → {filename}");
        let mut cmd = std::process::Command::new(&runner);
        cmd.arg(filename)
            .env("SCHEDULE_DIR", &schedule);
        if let Some(ref cd) = contractors_dir {
            cmd.env("TASK_CONTRACTORS_DIR", cd);
        }
        let s = cmd
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status();
        match s {
            Ok(st) if !st.success() => {
                println!("[work] {filename} falhou (continuando)");
            }
            Err(e) => {
                println!("[work] {filename} erro: {e} (continuando)");
            }
            _ => {}
        }
    }

    println!("[work] concluido");
    Ok(())
}

/// Parse card filename `YYYYMMDD_HH_MM_name.md` into unix epoch seconds.
/// Returns 0 if the filename doesn't match the expected pattern.
pub(crate) fn card_epoch(name: &str) -> i64 {
    // Pattern: YYYYMMDD_HH_MM_...
    if name.len() < 15 {
        return 0;
    }
    let bytes = name.as_bytes();
    // Check format: 8 digits _ 2 digits _ 2 digits _
    if bytes[8] != b'_' || bytes[11] != b'_' || bytes[14] != b'_' {
        return 0;
    }
    let date_part = &name[..8];
    let hour_part = &name[9..11];
    let min_part = &name[12..14];

    let y: i64 = date_part[..4].parse().unwrap_or(0);
    let mo: i64 = date_part[4..6].parse().unwrap_or(0);
    let d: i64 = date_part[6..8].parse().unwrap_or(0);
    let h: i64 = hour_part.parse().unwrap_or(0);
    let mi: i64 = min_part.parse().unwrap_or(0);

    if y == 0 || mo == 0 || d == 0 {
        return 0;
    }

    // Simple conversion to epoch (UTC) — good enough for scheduling
    simple_epoch(y, mo, d, h, mi)
}

/// Check if a markdown file's content has `agent:` or `contractor:` in its frontmatter.
pub(crate) fn is_contractor_card(content: &str) -> bool {
    let mut in_fm = false;
    for line in content.lines() {
        if line.trim() == "---" {
            if in_fm {
                break;
            }
            in_fm = true;
            continue;
        }
        if in_fm && (line.starts_with("agent:") || line.starts_with("contractor:")) {
            return true;
        }
    }
    false
}

/// Minimal epoch calculation (UTC) — avoids pulling in chrono.
fn simple_epoch(y: i64, mo: i64, d: i64, h: i64, mi: i64) -> i64 {
    // Days from year 1970 to year y
    let mut days: i64 = 0;
    for yr in 1970..y {
        days += if is_leap(yr) { 366 } else { 365 };
    }
    let month_days = [31, 28 + i64::from(is_leap(y)), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for md in month_days.iter().take((mo - 1).min(11) as usize) {
        days += md;
    }
    days += d - 1;
    days * 86400 + h * 3600 + mi * 60
}

fn is_leap(y: i64) -> bool {
    y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)
}

fn md_files(dir: &std::path::Path) -> Vec<String> {
    let mut v: Vec<String> = std::fs::read_dir(dir)
        .into_iter()
        .flatten()
        .flatten()
        .filter(|e| e.path().extension().is_some_and(|x| x == "md"))
        .map(|e| e.file_name().to_string_lossy().to_string())
        .collect();
    v.sort();
    v
}

fn fm_value(content: &str, key: &str) -> Option<String> {
    let mut in_fm = false;
    for line in content.lines() {
        if line.trim() == "---" {
            if in_fm {
                break;
            }
            in_fm = true;
            continue;
        }
        let prefix = format!("{key}:");
        if in_fm {
            if let Some(rest) = line.strip_prefix(prefix.as_str()) {
                return Some(rest.trim().to_string());
            }
        }
    }
    None
}

/// Extract the body (everything after frontmatter) from a markdown file.
fn fm_body(content: &str) -> String {
    let mut in_fm = false;
    let mut past = false;
    let mut body = String::new();
    for line in content.lines() {
        if past {
            body.push_str(line);
            body.push('\n');
            continue;
        }
        if line.trim() == "---" {
            if in_fm {
                past = true;
            } else {
                in_fm = true;
            }
            continue;
        }
    }
    body
}

#[cfg(test)]
mod tests {
    use super::*;

    const AGENT_MD: &str = "\
---
model: haiku
timeout: 900
mcp: false
agent: wanderer
---
You are the wanderer.
Walk the codebase.
";

    #[test]
    fn fm_value_basic() {
        assert_eq!(fm_value(AGENT_MD, "model"), Some("haiku".into()));
        assert_eq!(fm_value(AGENT_MD, "agent"), Some("wanderer".into()));
        assert_eq!(fm_value(AGENT_MD, "timeout"), Some("900".into()));
    }

    #[test]
    fn fm_value_missing_key() {
        assert_eq!(fm_value(AGENT_MD, "nonexistent"), None);
    }

    #[test]
    fn fm_value_no_frontmatter() {
        assert_eq!(fm_value("just plain text", "model"), None);
    }

    #[test]
    fn fm_body_extracts_content() {
        let body = fm_body(AGENT_MD);
        assert!(body.contains("You are the wanderer."));
        assert!(body.contains("Walk the codebase."));
        assert!(!body.contains("model:"));
        assert!(!body.contains("---"));
    }

    #[test]
    fn fm_body_no_frontmatter() {
        let body = fm_body("no frontmatter here");
        assert!(body.is_empty());
    }

    #[test]
    fn fm_body_empty_body() {
        let body = fm_body("---\nmodel: sonnet\n---\n");
        assert!(body.trim().is_empty());
    }

    // ── card_epoch ──────────────────────────────────────────

    #[test]
    fn card_epoch_valid() {
        // 2026-03-21 14:30 UTC
        let ts = card_epoch("20260321_14_30_wanderer.md");
        assert!(ts > 0);
        // Should be roughly 2026-03-21 14:30 UTC
        // 2026-01-01 = 1735689600, ~80 days later = +6912000, +14*3600+30*60
        assert!(ts > 1_700_000_000); // sanity: after 2023
        assert!(ts < 2_000_000_000); // sanity: before 2033
    }

    #[test]
    fn card_epoch_invalid_format() {
        assert_eq!(card_epoch("not_a_card.md"), 0);
        assert_eq!(card_epoch("short.md"), 0);
        assert_eq!(card_epoch("20260321_14_wanderer.md"), 0); // missing minute separator
    }

    #[test]
    fn card_epoch_zeroed_date() {
        assert_eq!(card_epoch("00000000_00_00_test.md"), 0);
    }

    // ── is_contractor_card ──────────────────────────────────

    #[test]
    fn is_contractor_card_with_agent() {
        let content = "---\nmodel: haiku\nagent: wanderer\n---\nbody\n";
        assert!(is_contractor_card(content));
    }

    #[test]
    fn is_contractor_card_with_contractor() {
        let content = "---\ncontractor: coruja\nmodel: sonnet\n---\nbody\n";
        assert!(is_contractor_card(content));
    }

    #[test]
    fn is_contractor_card_without_agent() {
        let content = "---\nmodel: haiku\ntimeout: 900\n---\nbody\n";
        assert!(!is_contractor_card(content));
    }

    #[test]
    fn is_contractor_card_no_frontmatter() {
        assert!(!is_contractor_card("just plain text"));
    }

    #[test]
    fn is_contractor_card_agent_outside_frontmatter() {
        let content = "---\nmodel: haiku\n---\nagent: wanderer\n";
        assert!(!is_contractor_card(content));
    }
}
