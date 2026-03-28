//! Task executor — runs a single card via Claude CLI.
//! Replaces task-runner.sh.

use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::Instant;

use crate::{agents, paths};

/// Parsed card configuration.
pub struct CardConfig {
    pub model: String,
    pub timeout: u32,
    pub max_turns: u32,
    pub mcp: bool,
    pub agent: String,
    pub body: String,
}

/// Result of running a card.
pub struct RunResult {
    pub status: String,   // "ok" | "timeout" | "fail"
    pub elapsed_secs: u64,
    pub tok_in: Option<u64>,
    pub tok_out: Option<u64>,
    pub tok_cache: Option<u64>,
}

/// Run a single task card. This is the Rust equivalent of task-runner.sh.
pub fn run_card(card_name: &str) -> Result<(), String> {
    let obsidian = paths::obsidian_path();
    let contractors_dir = std::env::var("TASK_CONTRACTORS_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| obsidian.join("bedrooms"));
    let schedule_dir = std::env::var("SCHEDULE_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| obsidian.join("agents/_waiting"));
    let running_dir = std::env::var("RUNNING_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| obsidian.join("agents/_working"));

    // ── Find card ────────────────────────────────────────────────
    let card = normalize_card_name(card_name);
    let card_base = card.trim_end_matches(".md");

    let card_path = find_card(&card, &schedule_dir, &running_dir)
        .ok_or_else(|| format!("[runner] card '{}' not found", card))?;

    // ── Lock (atomic mkdir) ──────────────────────────────────────
    let lock_dir = PathBuf::from(format!("/tmp/leech-locks/{card_base}.lock"));
    let _ = std::fs::create_dir_all(lock_dir.parent().unwrap_or(Path::new("/tmp")));

    if lock_dir.exists() {
        let age = lock_age(&lock_dir);
        let max_age = 1860; // default timeout + 60s
        if age > max_age {
            eprintln!("[runner] '{card_base}' — stale lock ({age}s), clearing");
            let _ = std::fs::remove_dir_all(&lock_dir);
        } else {
            eprintln!("[runner] '{card_base}' locked — skip ({age}s old)");
            return Ok(());
        }
    }
    std::fs::create_dir_all(&lock_dir).map_err(|e| format!("lock failed: {e}"))?;
    // Cleanup on any exit path
    let _lock_guard = LockGuard(lock_dir.clone());

    // ── Move to _working ─────────────────────────────────────────
    let _ = std::fs::create_dir_all(&running_dir);
    let running_path = running_dir.join(&card);
    if card_path.parent() != Some(running_dir.as_path()) {
        std::fs::rename(&card_path, &running_path)
            .map_err(|e| format!("move to running failed: {e}"))?;
    }
    let card_path = running_path;

    // ── Parse card ───────────────────────────────────────────────
    let content = std::fs::read_to_string(&card_path)
        .map_err(|e| format!("read card: {e}"))?;
    let config = parse_card(&content);

    // Apply env override for max_turns
    let max_turns = std::env::var("TASK_MAX_TURNS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(config.max_turns);

    // Task name (strip date prefix)
    let task_name = agents::strip_date_prefix(&card);

    // ── Quota check ──────────────────────────────────────────────
    if task_name != "hermes" {
        if let Some(pct) = check_quota() {
            if pct >= 70 {
                eprintln!(
                    "[runner] '{task_name}' — QUOTA_HOLD (week={pct}%), rescheduling +60min"
                );
                let next = utc_stamp_offset(3600);
                let dest = schedule_dir.join(format!("{next}_{task_name}.md"));
                let _ = std::fs::rename(&card_path, &dest);
                return Ok(());
            }
        }
    }

    // ── Build prompt ─────────────────────────────────────────────
    let memory = load_memory(&contractors_dir, &config.agent, &task_name);
    let artifacts_dir = contractors_dir
        .join(if config.agent.is_empty() { &task_name } else { &config.agent })
        .join("outputs");

    let now_utc = utc_iso();
    let prompt = build_prompt(
        &task_name,
        &card,
        &card_path,
        &schedule_dir,
        &contractors_dir,
        &config,
        &memory,
        &artifacts_dir,
        &now_utc,
    );

    // ── Log dir ──────────────────────────────────────────────────
    let log_dir = obsidian.join(format!(".ephemeral/cron-logs/{task_name}"));
    let _ = std::fs::create_dir_all(&log_dir);
    let log_file = log_dir.join(format!("{}.log", utc_file_stamp()));

    // ── Run claude ───────────────────────────────────────────────
    eprintln!(
        "[runner] running '{task_name}' (model={}, timeout={}s, turns={max_turns})",
        config.model, config.timeout
    );

    let start = Instant::now();

    let mut claude_args: Vec<String> = vec![
        "--permission-mode".into(),
        "bypassPermissions".into(),
        "--model".into(),
        config.model.clone(),
        "--max-turns".into(),
        max_turns.to_string(),
    ];

    // MCP config
    if !config.mcp {
        let no_mcp = PathBuf::from("/tmp/leech-no-mcp.json");
        if !no_mcp.exists() {
            let _ = std::fs::write(&no_mcp, r#"{"mcpServers":{}}"#);
        }
        claude_args.push("--mcp-config".into());
        claude_args.push(no_mcp.to_string_lossy().into_owned());
    }

    claude_args.push("-p".into());
    claude_args.push(prompt);
    claude_args.push("--add-dir".into());
    claude_args.push(paths::home().to_string_lossy().into_owned());

    let log_out = std::fs::File::create(&log_file).ok();

    let child = Command::new("timeout")
        .arg(config.timeout.to_string())
        .arg("claude")
        .args(&claude_args)
        .env("HEADLESS", "1")
        .current_dir(paths::home())
        .stdout(log_out.as_ref().map(|f| Stdio::from(f.try_clone().unwrap())).unwrap_or(Stdio::inherit()))
        .stderr(Stdio::inherit())
        .status();

    let elapsed = start.elapsed().as_secs();
    let exit_code = child.map(|s| s.code().unwrap_or(-1)).unwrap_or(-1);

    let status = if exit_code == 124 {
        "timeout"
    } else if exit_code != 0 {
        "fail"
    } else {
        "ok"
    };

    // ── Parse token usage ────────────────────────────────────────
    let (tok_in, tok_out, tok_cache) = if let Ok(log_content) = std::fs::read_to_string(&log_file) {
        (
            parse_token(&log_content, "input_tokens"),
            parse_token(&log_content, "output_tokens"),
            parse_token(&log_content, "cache_read_input_tokens"),
        )
    } else {
        (None, None, None)
    };

    if tok_in.is_some() || tok_out.is_some() {
        eprintln!("  ┌─ usage ──────────────────────────────┐");
        eprintln!(
            "  │  in={:<8}  out={:<8}  cache={}",
            tok_in.map(|n| n.to_string()).unwrap_or("?".into()),
            tok_out.map(|n| n.to_string()).unwrap_or("?".into()),
            tok_cache.map(|n| n.to_string()).unwrap_or("?".into()),
        );
        eprintln!("  └──────────────────────────────────────┘");
    }

    let elapsed_fmt = format!("{}m{}s", elapsed / 60, elapsed % 60);

    if status != "ok" {
        eprintln!("[runner] '{task_name}' — {status} (exit={exit_code}, {elapsed_fmt})");
        eprintln!("[runner] log: {}", log_file.display());
    }

    // ── Activity log ─────────────────────────────────────────────
    let done_agent = if config.agent.is_empty() {
        &task_name
    } else {
        &config.agent
    };

    write_activity_log(
        &obsidian,
        done_agent,
        status,
        &elapsed_fmt,
        tok_in,
        tok_out,
        tok_cache,
        card_base,
    );

    // ── Finish ───────────────────────────────────────────────────
    if !card_path.exists() {
        // Agent rescheduled itself (moved card to _waiting)
        eprintln!("[runner] '{task_name}' — rescheduled ({elapsed_fmt})");
        return Ok(());
    }

    // Move to done/
    let done_dir = contractors_dir.join(done_agent).join("done");
    let _ = std::fs::create_dir_all(&done_dir);
    let _ = std::fs::rename(&card_path, done_dir.join(&card));
    eprintln!("[runner] '{task_name}' → {done_agent}/done/ ({status}, {elapsed_fmt})");

    Ok(())
}

// ── Helpers ──────────────────────────────────────────────────────────────────

struct LockGuard(PathBuf);
impl Drop for LockGuard {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

fn normalize_card_name(name: &str) -> String {
    if name.ends_with(".md") {
        name.to_string()
    } else {
        format!("{name}.md")
    }
}

fn find_card(card: &str, schedule: &Path, running: &Path) -> Option<PathBuf> {
    for dir in &[schedule, running] {
        let p = dir.join(card);
        if p.is_file() {
            return Some(p);
        }
    }
    None
}

fn lock_age(lock: &Path) -> u64 {
    lock.metadata()
        .and_then(|m| m.modified())
        .ok()
        .and_then(|t| t.elapsed().ok())
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn parse_card(content: &str) -> CardConfig {
    let fm = |key| agents::frontmatter_field(content, key);
    let model = fm("model").unwrap_or_else(|| "haiku".into());
    let timeout: u32 = fm("timeout").and_then(|s| s.parse().ok()).unwrap_or(1800);
    let max_turns: u32 = fm("max_turns").and_then(|s| s.parse().ok()).unwrap_or(12);
    let mcp = fm("mcp").map(|s| s != "false" && s != "off").unwrap_or(true);
    let agent = fm("agent")
        .or_else(|| fm("contractor"))
        .unwrap_or_default();

    // Extract body (below frontmatter)
    let mut in_fm = false;
    let mut past_fm = false;
    let mut body = String::new();
    for line in content.lines() {
        if past_fm {
            body.push_str(line);
            body.push('\n');
        } else if line == "---" {
            if in_fm { past_fm = true; } else { in_fm = true; }
        }
    }

    CardConfig { model, timeout, max_turns, mcp, agent, body }
}

fn load_memory(contractors_dir: &Path, agent: &str, task_name: &str) -> String {
    let candidates = [
        contractors_dir.join(agent).join("memory.md"),
        contractors_dir.join(task_name).join("memory.md"),
    ];
    for p in &candidates {
        if p.is_file() {
            if let Ok(m) = std::fs::read_to_string(p) {
                return m;
            }
        }
    }
    String::new()
}

fn build_prompt(
    task_name: &str,
    card: &str,
    card_path: &Path,
    schedule_dir: &Path,
    contractors_dir: &Path,
    config: &CardConfig,
    memory: &str,
    artifacts_dir: &Path,
    now_utc: &str,
) -> String {
    let agent_name = if config.agent.is_empty() { task_name } else { &config.agent };
    let mut p = format!(
        "[HEADLESS MODE] Timeout: {}s | Time: {now_utc}\n\
         Task: {task_name} | Card: {card} | Budget: {}s\n\n\
         ## Task card location\n\
         This card is at: {}\n\
         Schedule dir: {}\n\
         Contractors dir: {}",
        config.timeout, config.timeout,
        card_path.display(), schedule_dir.display(), contractors_dir.display(),
    );

    if !memory.is_empty() {
        p.push_str("\n\n## Agent Memory\n");
        p.push_str(memory);
    }

    p.push_str("\n\n## Instructions\n");
    p.push_str(&config.body);

    p.push_str(&format!(
        "\n\n## Artifacts\n\
         Produce any artifacts (reports, files, outputs) in: {}\n\n\
         ## After completing\n\
         - To reschedule: move this card from agents/_working/ to agents/_waiting/ with a new date prefix (YYYYMMDD_HH_MM_name.md)\n\
         - Path: {}/\n\
         - YOU choose when to run next (minimum 30 minutes)\n\
         - Prefer scheduling between 21h-06h (BRT) — agents' preferred window\n\
         - If nothing urgent, schedule later to conserve quota\n\
         - To finish: the runner will move the card to your done/ folder automatically\n\
         - Update your memory file at {}/{agent_name}/memory.md if you learned something persistent",
        artifacts_dir.display(), schedule_dir.display(), contractors_dir.display(),
    ));

    p
}

fn check_quota() -> Option<u8> {
    let script = paths::leech_root().join("scripts/claude-ai-usage.sh");
    if !script.exists() { return None; }
    let out = Command::new(&script)
        .arg("--json")
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    let json: serde_json::Value = serde_json::from_slice(&out.stdout).ok()?;
    // Try various JSON structures
    let pct = json.pointer("/weekly_limits/0/percentage_used")
        .or_else(|| json.pointer("/weeklyLimits/0/percentageUsed"))
        .or_else(|| json.pointer("/limits/0/percentage_used"))
        .and_then(|v| v.as_f64())
        .map(|f| f as u8)?;
    Some(pct)
}

fn parse_token(log: &str, key: &str) -> Option<u64> {
    for line in log.lines().rev() {
        if let Some(pos) = line.find(&format!("\"{key}\"")) {
            let rest = &line[pos + key.len() + 3..]; // skip `"key":`
            let num: String = rest.chars()
                .skip_while(|c| !c.is_ascii_digit())
                .take_while(|c| c.is_ascii_digit())
                .collect();
            return num.parse().ok();
        }
    }
    None
}

fn write_activity_log(
    obsidian: &Path,
    agent: &str,
    status: &str,
    elapsed: &str,
    tok_in: Option<u64>,
    tok_out: Option<u64>,
    tok_cache: Option<u64>,
    card_base: &str,
) {
    let log_file = obsidian.join("vault/logs/agents.md");
    let _ = std::fs::create_dir_all(log_file.parent().unwrap_or(obsidian));

    let mut tok_str = format!(
        "in={} out={}",
        tok_in.unwrap_or(0),
        tok_out.unwrap_or(0)
    );
    if let Some(c) = tok_cache {
        tok_str.push_str(&format!(" cache={c}"));
    }

    let line = format!(
        "| {} | {} | {} | {} | {} | {} |\n",
        utc_iso(), agent, status, elapsed, tok_str, card_base,
    );

    if let Ok(mut f) = std::fs::OpenOptions::new().append(true).create(true).open(&log_file) {
        let _ = f.write_all(line.as_bytes());
    }
}

fn utc_iso() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let (y, mo, d) = days_to_date(secs / 86400);
    let t = secs % 86400;
    format!("{y:04}-{mo:02}-{d:02}T{:02}:{:02}:{:02}Z", t / 3600, (t % 3600) / 60, t % 60)
}

fn utc_file_stamp() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let (y, mo, d) = days_to_date(secs / 86400);
    let t = secs % 86400;
    format!("{y:04}-{mo:02}-{d:02}_{:02}-{:02}", t / 3600, (t % 3600) / 60)
}

fn utc_stamp_offset(offset_secs: u64) -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        + offset_secs;
    let (y, mo, d) = days_to_date(secs / 86400);
    let t = secs % 86400;
    format!("{y:04}{mo:02}{d:02}_{:02}_{:02}", t / 3600, (t % 3600) / 60)
}

fn days_to_date(days: u64) -> (u64, u64, u64) {
    let z = days + 719468;
    let era = z / 146097;
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    (y, m, d)
}
