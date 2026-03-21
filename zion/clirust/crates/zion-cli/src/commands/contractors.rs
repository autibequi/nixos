use anyhow::{bail, Result};
use zion_sdk::paths;

/// `zion contractors run <name>` — run a contractor immediately.
pub fn run(name: &str, steps: Option<u32>) -> Result<()> {
    let agent_file = paths::agent_file(name).ok_or_else(|| anyhow::anyhow!("contractor '{name}' not found"))?;
    let runner = paths::task_runner().ok_or_else(|| anyhow::anyhow!("task-runner.sh not found"))?;
    let tasks = paths::tasks_dir().ok_or_else(|| anyhow::anyhow!("tasks dir not found"))?;

    let content = std::fs::read_to_string(&agent_file)?;
    let model = fm_value(&content, "model").unwrap_or_else(|| "sonnet".into());
    let timeout: u32 = match model.as_str() { "haiku" => 900, "opus" => 3600, _ => 1800 };
    let steps = steps.unwrap_or(match model.as_str() { "haiku" => 20, "opus" => 60, _ => 40 });

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
    cmd.arg(&card).env("TASK_DIR", &tasks).env("TASK_MAX_TURNS", steps.to_string());
    if let Some(ad) = &agents_dir { cmd.env("TASK_AGENTS_DIR", ad); }

    let s = cmd.stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()?;
    if !s.success() { bail!("contractor runner failed"); }
    Ok(())
}

/// `zion contractors status` — show TODO/DOING/DONE.
pub fn status() -> Result<()> {
    let tasks = paths::tasks_dir().ok_or_else(|| anyhow::anyhow!("tasks dir not found"))?;

    for (label, color, dir, limit) in [("DOING", "36", "DOING", 0usize), ("TODO", "33", "TODO", 0), ("DONE", "2", "DONE", 10)] {
        let mut files = md_files(&tasks.join(dir));
        if dir == "DONE" { files.reverse(); }
        if limit > 0 && files.len() > limit { files.truncate(limit); }

        println!("\x1b[1m\x1b[{color}m▸ {label}\x1b[0m \x1b[2m({})\x1b[0m", files.len());
        if files.is_empty() { println!("  \x1b[2m(nenhum)\x1b[0m"); }
        else { for f in &files { println!("  {}", f.trim_start_matches(|c: char| c.is_ascii_digit() || c == '_').trim_end_matches(".md")); } }
        println!();
    }
    Ok(())
}

fn md_files(dir: &std::path::Path) -> Vec<String> {
    let mut v: Vec<String> = std::fs::read_dir(dir).into_iter().flatten().flatten()
        .filter(|e| e.path().extension().is_some_and(|x| x == "md"))
        .map(|e| e.file_name().to_string_lossy().to_string()).collect();
    v.sort(); v
}

fn fm_value(content: &str, key: &str) -> Option<String> {
    let mut in_fm = false;
    for line in content.lines() {
        if line.trim() == "---" { if in_fm { break; } in_fm = true; continue; }
        if in_fm && line.starts_with(&format!("{key}:")) {
            return Some(line[key.len() + 1..].trim().to_string());
        }
    }
    None
}

fn fm_body(content: &str) -> String {
    let mut in_fm = false;
    let mut past = false;
    let mut body = String::new();
    for line in content.lines() {
        if past { body.push_str(line); body.push('\n'); continue; }
        if line.trim() == "---" { if in_fm { past = true; } else { in_fm = true; } continue; }
    }
    body
}
