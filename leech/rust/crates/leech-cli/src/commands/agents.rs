//! Agent and task commands — native Rust implementation with optional JSON output.

use anyhow::{bail, Result};
use leech_cli::{agents, executor, paths, tasks};
use std::process::Command;

// ── Agents ────────────────────────────────────────────────────────────────────

/// `leech agents list` — list all agents with model, clock, and queue info.
pub fn list(json: bool) -> Result<()> {
    let all = agents::load_all_agents();

    if json {
        println!("{}", serde_json::to_string_pretty(&all)?);
        return Ok(());
    }

    println!("\n\x1b[1m\x1b[35m  AGENTS\x1b[0m\n");
    for a in &all {
        let task_badge = if a.task_count > 0 {
            format!(" \x1b[33m[{}]\x1b[0m", a.task_count)
        } else {
            String::new()
        };
        let clock = a
            .clock_mins
            .map(|m| format!("every{}m", m))
            .unwrap_or_else(|| "on-demand".into());
        println!(
            "  \x1b[32m{:<18}\x1b[0m  \x1b[2m{:<8}  {:<12}\x1b[0m{}",
            a.name, a.model, clock, task_badge
        );
    }
    println!();
    Ok(())
}

/// `leech agents status [name]` — show activity log entries.
pub fn agent_log(name: Option<&str>, json: bool) -> Result<()> {
    if json {
        let entries = name.map(agents::load_agent_log).unwrap_or_default();
        println!("{}", serde_json::to_string_pretty(&entries)?);
        return Ok(());
    }

    // Native: show activity log for an agent (or all)
    let entries = match name {
        Some(n) => agents::load_agent_log(n),
        None => {
            // Show all recent entries (load for each agent, merge)
            let all = agents::load_all_agents();
            let mut merged = Vec::new();
            for a in &all {
                merged.extend(agents::load_agent_log(&a.name));
            }
            merged.truncate(30);
            merged
        }
    };

    let filter_hint = name.unwrap_or("todos");
    println!(
        "\n\x1b[1m\x1b[36m▸ ACTIVITY LOG\x1b[0m \x1b[2m(ultimas {} | {})\x1b[0m",
        entries.len(),
        filter_hint
    );
    println!();
    println!(
        "  \x1b[2m{:<14}  {:<8}  {:<12}  {:<4}  {}\x1b[0m",
        "starttime", "duration", "agent", "st", "topic"
    );
    println!("  \x1b[2m{}\x1b[0m", "─".repeat(70));

    for entry in &entries {
        let st = match entry.status.as_str() {
            "ok" => "\x1b[32mok\x1b[0m  ",
            "fail" => "\x1b[31m!!\x1b[0m  ",
            "timeout" => "\x1b[33mto\x1b[0m  ",
            _ => "?   ",
        };
        println!(
            "  {:<14}  {:<8}  {:<12}  {}  {}",
            entry.ts_short, entry.duration, "", st, entry.card
        );
    }
    println!();
    Ok(())
}

/// `leech agents phone [name]` — open a session to talk to an agent.
pub fn phone(name: Option<&str>) -> Result<()> {
    let Some(name) = name else {
        // List available agents
        println!("\n  Agentes disponiveis:\n");
        let all = agents::load_all_agents();
        for a in &all {
            let call_style = paths::agent_file(&a.name)
                .and_then(|p| std::fs::read_to_string(p).ok())
                .and_then(|c| agents::frontmatter_field(&c, "call_style"))
                .unwrap_or_else(|| "phone".into());
            println!("  {:<16}  {:<8}  {}", a.name, a.model, call_style);
        }
        println!("\n  Uso: leech agents phone <nome>");
        println!("  Dentro do Claude Code: /meta:phone call <nome>\n");
        return Ok(());
    };

    let agent_file = paths::agent_file(name)
        .ok_or_else(|| anyhow::anyhow!("Agente '{}' nao encontrado.", name))?;

    let content = std::fs::read_to_string(&agent_file)?;
    let call_style = agents::frontmatter_field(&content, "call_style")
        .unwrap_or_else(|| "phone".into());

    println!();
    if call_style == "personal" {
        println!("  Convocando {name}...\n");
    } else {
        println!("  Ligando para {name}...\n");
        println!("    bip...    bip...    bip...\n");
    }
    println!("  Abrindo sessao. Na sessao, use:");
    println!("    /meta:phone call {name}\n");

    // Replace process with `leech new --host`
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        let err = Command::new(std::env::current_exe()?)
            .args(["new", "--host"])
            .exec();
        bail!("Failed to exec: {err}");
    }
    #[cfg(not(unix))]
    {
        Command::new(std::env::current_exe()?)
            .args(["new", "--host"])
            .status()?;
        Ok(())
    }
}

// ── Tasks ─────────────────────────────────────────────────────────────────────

/// `leech tasks log` — show DOING/TODO/DONE kanban view.
pub fn tasks_log(json: bool) -> Result<()> {
    let cards = tasks::list_tasks();

    if json {
        println!("{}", serde_json::to_string_pretty(&cards)?);
        return Ok(());
    }

    let doing: Vec<_> = cards.iter().filter(|c| c.state == "doing").collect();
    let todo: Vec<_> = cards.iter().filter(|c| c.state == "todo").collect();
    let done: Vec<_> = cards.iter().filter(|c| c.state == "done").collect();

    println!();
    println!(
        "\x1b[1m\x1b[33m▸ DOING\x1b[0m \x1b[2m({})\x1b[0m",
        doing.len()
    );
    if doing.is_empty() {
        println!("  \x1b[2m(nenhuma)\x1b[0m");
    } else {
        for c in &doing {
            println!("  {:<50}  {}", c.label, c.age_display());
        }
    }
    println!();

    println!(
        "\x1b[1m\x1b[36m▸ TODO\x1b[0m \x1b[2m({} total, proximas 10)\x1b[0m",
        todo.len()
    );
    if todo.is_empty() {
        println!("  \x1b[2m(nenhuma)\x1b[0m");
    } else {
        for c in todo.iter().take(10) {
            println!("  {:<50}  {}", c.label, c.when_display());
        }
    }
    println!();

    println!(
        "\x1b[1m\x1b[2m▸ DONE\x1b[0m \x1b[2m(ultimas {})\x1b[0m",
        done.len().min(15)
    );
    for c in done.iter().take(15) {
        println!("  {:<50}  {}", c.label, c.age_display());
    }
    println!();

    Ok(())
}

// ── Run / Auto / Tasker ──────────────────────────────────────────────────────

/// `leech run <name>` — run agent or task immediately.
pub fn run_unified(name: &str, steps: Option<u32>) -> Result<()> {
    // Check if it's an agent
    if let Some(agent_file) = paths::agent_file(name) {
        let content = std::fs::read_to_string(&agent_file)?;
        let model = agents::frontmatter_field(&content, "model")
            .unwrap_or_else(|| "sonnet".into());
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

        let when = utc_stamp();
        let card = format!("{when}_{name}.md");

        // Create card in schedule dir
        let schedule = paths::schedule_dir()
            .or_else(|| {
                let p = paths::obsidian_path().join("agents/_waiting");
                p.is_dir().then_some(p)
            })
            .ok_or_else(|| anyhow::anyhow!("[run] schedule dir not found"))?;
        std::fs::create_dir_all(&schedule)?;

        let body = extract_body(&content);
        let card_content = format!(
            "---\nmodel: {model}\ntimeout: {timeout}\nmcp: false\nagent: {name}\n---\n{body}\n\n#steps{steps}"
        );
        std::fs::write(schedule.join(&card), &card_content)?;

        eprintln!("[run] agent '{name}' -> card {card}");
        eprintln!("[run] model={model}  timeout={timeout}s  steps={steps}\n");

        // Clean stale lock
        let _ = std::fs::remove_dir_all(format!("/tmp/leech-locks/{when}_{name}.lock"));

        // Set env vars for executor
        let contractors_dir = schedule.parent().unwrap_or(&schedule);
        std::env::set_var("TASK_CONTRACTORS_DIR", contractors_dir);
        std::env::set_var("SCHEDULE_DIR", &schedule);
        std::env::set_var("TASK_MAX_TURNS", steps.to_string());

        executor::run_card(&card).map_err(|e| anyhow::anyhow!(e))
    } else {
        // Try as a task
        let tasks_dir = paths::tasks_dir()
            .ok_or_else(|| anyhow::anyhow!("[run] tasks dir not found"))?;

        let mut card = None;
        for dir_name in &["TODO", "DOING"] {
            let dir = tasks_dir.join(dir_name);
            if !dir.is_dir() { continue; }
            if let Ok(entries) = std::fs::read_dir(&dir) {
                for entry in entries.flatten() {
                    let fname = entry.file_name().to_string_lossy().into_owned();
                    if fname.contains(name) && fname.ends_with(".md") {
                        card = Some(fname);
                        break;
                    }
                }
            }
            if card.is_some() { break; }
        }

        let card = card.ok_or_else(|| {
            anyhow::anyhow!("[run] '{name}' nao encontrado como agente nem task")
        })?;

        eprintln!("[run] task: {card}");

        let base = card.trim_end_matches(".md");
        let _ = std::fs::remove_dir_all(format!("/tmp/leech-locks/{base}.lock"));

        // Set env for executor
        let agents_dir = paths::obsidian_path().join("agents");
        std::env::set_var("SCHEDULE_DIR", agents_dir.join("_waiting"));
        std::env::set_var("RUNNING_DIR", agents_dir.join("_working"));
        let contractors_dir = tasks_dir.parent()
            .map(|p| p.join("vault/agents"))
            .unwrap_or_default();
        std::env::set_var("TASK_CONTRACTORS_DIR", &contractors_dir);
        if let Some(s) = steps {
            std::env::set_var("TASK_MAX_TURNS", s.to_string());
        }

        executor::run_card(&card).map_err(|e| anyhow::anyhow!(e))
    }
}

/// `leech auto/tick` — aciona o tick agent, que cuida de tudo.
pub fn auto(dry_run: bool, _steps: Option<u32>) -> Result<()> {
    let tick_agent = paths::agent_file("tick")
        .ok_or_else(|| anyhow::anyhow!("[tick] agents/tick/agent.md nao encontrado"))?;

    if dry_run {
        eprintln!("[tick] --dry-run: tick agent em {}", tick_agent.display());
        return Ok(());
    }

    let content = std::fs::read_to_string(&tick_agent)?;
    let prompt = extract_body(&content);

    let status = Command::new("timeout")
        .arg("300")
        .arg("claude")
        .args([
            "--permission-mode", "bypassPermissions",
            "--model", "haiku",
            "--max-turns", "20",
            "-p", &prompt,
            "--add-dir", &paths::home().to_string_lossy(),
        ])
        .env("HEADLESS", "1")
        .current_dir(paths::home())
        .status()
        .map_err(|e| anyhow::anyhow!("[tick] falhou ao executar claude: {e}"))?;

    if !status.success() {
        eprintln!("[tick] falhou (exit={:?})", status.code());
    }

    Ok(())
}

// ── Helpers ──────────────────────────────────────────────────────────────────

fn utc_stamp() -> String {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // Convert epoch to YYYYMMDD_HH_MM in UTC
    let s = now;
    let days = s / 86400;
    let time_of_day = s % 86400;
    let h = time_of_day / 3600;
    let m = (time_of_day % 3600) / 60;

    // Civil date from days since epoch (simplified)
    let (y, mo, d) = days_to_date(days);
    format!("{y:04}{mo:02}{d:02}_{h:02}_{m:02}")
}

fn days_to_date(days: u64) -> (u64, u64, u64) {
    // Algorithm from http://howardhinnant.github.io/date_algorithms.html
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

fn now_epoch() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

/// Extract content below the YAML frontmatter.
fn extract_body(content: &str) -> String {
    let mut in_fm = false;
    let mut past_fm = false;
    let mut body = String::new();
    for line in content.lines() {
        if past_fm {
            body.push_str(line);
            body.push('\n');
            continue;
        }
        if line == "---" {
            if in_fm {
                past_fm = true;
            } else {
                in_fm = true;
            }
            continue;
        }
    }
    body
}

/// Extract `#stepsN` from card content.
fn extract_steps(content: &str) -> Option<u32> {
    for line in content.lines() {
        if let Some(rest) = line.strip_prefix("#steps") {
            if let Ok(n) = rest.trim().parse() {
                return Some(n);
            }
        }
    }
    None
}
