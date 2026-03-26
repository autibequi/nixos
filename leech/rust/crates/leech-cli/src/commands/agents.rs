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

/// `leech auto/tick` — lê commands/tick.md e passa o body para o Claude executar.
pub fn auto(dry_run: bool, _steps: Option<u32>, message: Option<String>) -> Result<()> {
    let home = paths::home();
    let obsidian = paths::obsidian_path();
    let self_dir = paths::leech_root();

    // Se recebeu mensagem direta, usar ela em vez do tick.md
    let prompt = if let Some(ref msg) = message {
        if dry_run {
            eprintln!("[tick] --dry-run: mensagem direta: {msg}");
            return Ok(());
        }
        format!(
            "Você é o agente autônomo do sistema Leech.\n\
             OBSIDIAN={obsidian}\n\
             SELF={self_dir}\n\
             HEADLESS=1 — execute sem perguntar nada, sem explicar o ambiente.\n\n\
             {msg}",
            obsidian = obsidian.display(),
            self_dir = self_dir.display(),
        )
    } else {
        // Localizar commands/tick.md (fonte da verdade do /tick)
        let tick_cmd = {
            let root = paths::leech_root();
            let candidates = [
                root.join("commands/tick.md"),
                std::path::PathBuf::from("/workspace/self/commands/tick.md"),
            ];
            candidates.into_iter().find(|p| p.exists())
                .or_else(|| paths::agent_file("tick"))
                .ok_or_else(|| anyhow::anyhow!("[tick] commands/tick.md nao encontrado"))?
        };

        if dry_run {
            eprintln!("[tick] --dry-run: tick cmd em {}", tick_cmd.display());
            return Ok(());
        }

        let content = std::fs::read_to_string(&tick_cmd)?;
        let body = extract_body(&content);
        let tick_body = if body.trim().is_empty() { content.as_str() } else { body.as_str() };

        format!(
            "Você é o agente autônomo do sistema Leech.\n\
             OBSIDIAN={obsidian}\n\
             SELF={self_dir}\n\
             HEADLESS=1 — execute sem perguntar nada, sem explicar o ambiente.\n\n\
             {tick_body}",
            obsidian = obsidian.display(),
            self_dir = self_dir.display(),
        )
    };

    let t0 = std::time::Instant::now();
    let started_at = utc_stamp();
    eprintln!("[tick] {} — iniciando", started_at);

    let status = Command::new("claude")
        .args([
            "--permission-mode", "bypassPermissions",
            "--model", "haiku",
            "--max-turns", "30",
            "-p", &prompt,
            "--add-dir", &home.to_string_lossy(),
            "--add-dir", &obsidian.to_string_lossy(),
            "--add-dir", &self_dir.to_string_lossy(),
        ])
        .env("HEADLESS", "1")
        .env("LEECH_OBSIDIAN", &obsidian)
        .env("LEECH_SELF", &self_dir)
        .current_dir(&home)
        .status()
        .map_err(|e| anyhow::anyhow!("[tick] falhou ao executar claude: {e}"))?;

    let elapsed = t0.elapsed();
    let secs = elapsed.as_secs();
    let duration = if secs >= 60 {
        format!("{}m{}s", secs / 60, secs % 60)
    } else {
        format!("{}s", secs)
    };

    if status.success() {
        eprintln!("[tick] ok — durou {}", duration);
    } else {
        eprintln!("[tick] falhou (exit={:?}) — durou {}", status.code(), duration);
    }

    Ok(())
}

// ── Ask ───────────────────────────────────────────────────────────────────────

/// `leech ask [agent] <question>` — one-shot question to an agent or default model.
pub fn ask(agent_name: Option<&str>, question: &str, model_override: Option<&str>) -> Result<()> {
    let obsidian = paths::obsidian_path();
    let self_dir = paths::leech_root();
    let home = paths::home();

    let (model_str, prompt, label) = match agent_name {
        Some(name) => {
            let agent_file = paths::agent_file(name)
                .ok_or_else(|| anyhow::anyhow!("Agente '{}' nao encontrado.", name))?;
            let content = std::fs::read_to_string(&agent_file)?;
            let agent_model = agents::frontmatter_field(&content, "model")
                .unwrap_or_else(|| "haiku".into());
            let model = model_override.unwrap_or(&agent_model).to_string();
            let body = extract_body(&content);
            let prompt = format!(
                "{name}, você foi questionado pelo usuário:\n\n\
                 > {question}\n\n\
                 Responda diretamente, de forma clara e objetiva. \
                 Esta é uma sessão oneshot — não faça perguntas de volta, \
                 não explique o ambiente. Apenas responda.\n\n\
                 --- contexto do agente ---\n\
                 {body}"
            );
            (model, prompt, format!("{name}"))
        }
        None => {
            let model = model_override.unwrap_or("haiku").to_string();
            let prompt = format!(
                "Responda diretamente, de forma clara e objetiva. \
                 Esta é uma sessão oneshot — não faça perguntas de volta. \
                 Apenas responda.\n\n\
                 > {question}"
            );
            (model, prompt, "default".to_string())
        }
    };

    eprintln!("[ask] {label} ({model_str}) — {question}");

    let status = Command::new("claude")
        .args([
            "--permission-mode", "bypassPermissions",
            "--model", &model_str,
            "--max-turns", "10",
            "-p", &prompt,
            "--add-dir", &home.to_string_lossy(),
            "--add-dir", &obsidian.to_string_lossy(),
            "--add-dir", &self_dir.to_string_lossy(),
        ])
        .env("HEADLESS", "1")
        .env("LEECH_OBSIDIAN", &obsidian)
        .env("LEECH_SELF", &self_dir)
        .current_dir(&home)
        .status()
        .map_err(|e| anyhow::anyhow!("[ask] falhou ao executar claude: {e}"))?;

    if !status.success() {
        anyhow::bail!("[ask] claude saiu com erro (exit={:?})", status.code());
    }
    Ok(())
}

// ── Phone ─────────────────────────────────────────────────────────────────────

/// Tema da ligação por agente: (tipo, efeito sonoro)
fn call_theme(agent: &str) -> (&'static str, &'static str) {
    match agent {
        "hermes"    => ("transmissão telepática",  "📡  ...sinal chegando..."),
        "coruja"    => ("chamado noturno",          "🦉  ...a coruja pousa..."),
        "tamagochi" => ("interface de alimentação", "🎮  ...tela acende..."),
        "wanderer"  => ("chamado do vento",         "🌬️  ...sussurro no éter..."),
        "keeper"    => ("sinal de manutenção",      "🔔  ...alarme interno..."),
        "wiseman"   => ("consulta ao oráculo",      "📜  ...névoa se dissipa..."),
        "assistant" => ("ligação direta",           "📱  ...bip... bip... bip..."),
        "paperboy"  => ("telegrama urgente",        "📰  ...campainha..."),
        "jafar"     => ("invocação arcana",         "🔮  ...portal se abre..."),
        "gandalf"   => ("chamado do mago",          "🧙  ...staff bate no chão..."),
        _           => ("chamada telefônica",       "📞  ...bip... bip... bip..."),
    }
}

/// `leech phonebook [nome]` — agenda completa dos agentes.
pub fn phonebook(name: Option<&str>) -> Result<()> {
    let all = agents::load_all_agents();

    // Se pediu um agente específico — cartão de contato completo
    if let Some(target) = name {
        let agent_file = paths::agent_file(target)
            .ok_or_else(|| anyhow::anyhow!("Agente '{}' não encontrado.", target))?;
        let content = std::fs::read_to_string(&agent_file)?;

        let agent_name = agents::frontmatter_field(&content, "name")
            .unwrap_or_else(|| target.to_string());
        let model = agents::frontmatter_field(&content, "model")
            .unwrap_or_else(|| "?".into());
        let clock = agents::frontmatter_field(&content, "clock")
            .unwrap_or_else(|| "on-demand".into());
        let description = agents::frontmatter_field(&content, "description")
            .unwrap_or_else(|| "(sem descrição)".into());
        let call_style = agents::frontmatter_field(&content, "call_style")
            .unwrap_or_else(|| "phone".into());
        let tools = agents::frontmatter_field(&content, "tools")
            .unwrap_or_else(|| "?".into());

        let (call_type, ringing) = call_theme(target);
        let clock_fmt = clock_display(&clock);

        println!();
        println!("  ┌─────────────────────────────────────────────────────┐");
        println!("  │  {}  {:<49}│", contact_emoji(target), agent_name.to_uppercase());
        println!("  │  {:<53}│", format!("{} · {} · {}", model, clock_fmt, call_type));
        println!("  └─────────────────────────────────────────────────────┘");
        println!();

        // Description word-wrapped at ~52 chars
        for chunk in word_wrap(&description, 52) {
            println!("  {}", chunk);
        }
        println!();
        println!("  Estilo:    {}", call_style);
        println!("  Sinal:     {}", ringing);
        println!("  Tools:     {}", tools.trim_matches(|c| c == '[' || c == ']'));
        println!();
        println!("  Como ligar:  leech phone {} <mensagem>", target);
        println!("  Sessão:      leech agents phone {}", target);
        println!();
        return Ok(());
    }

    // Lista completa
    println!();
    println!("  \x1b[1m📒  AGENDA LEECH\x1b[0m\x1b[2m                          {} agentes\x1b[0m", all.len());
    println!();
    println!(
        "  \x1b[2m{:<14}  {:<3}  {:<26}  {:<10}  {}\x1b[0m",
        "NOME", "MOD", "TIPO DE CHAMADA", "CLOCK", "COMO LIGAR"
    );
    println!("  \x1b[2m{}\x1b[0m", "─".repeat(80));

    for a in &all {
        let (call_type, _) = call_theme(&a.name);
        let emoji = contact_emoji(&a.name);
        let clock_fmt = a.clock_mins
            .map(|m| format!("every{}m", m))
            .unwrap_or_else(|| "on-demand".into());
        let model_short = match a.model.as_str() {
            "haiku"  => "hku",
            "sonnet" => "snt",
            "opus"   => "ops",
            other    => &other[..other.len().min(3)],
        };
        println!(
            "  \x1b[32m{:<14}\x1b[0m  \x1b[2m{:<3}  {} {:<24} {:<10}\x1b[0m  leech phone {}",
            a.name,
            model_short,
            emoji,
            call_type,
            clock_fmt,
            a.name,
        );
    }
    println!();
    println!("  \x1b[2mVer detalhes: leech phonebook <nome>\x1b[0m");
    println!();
    Ok(())
}

fn contact_emoji(agent: &str) -> &'static str {
    match agent {
        "hermes"    => "📡",
        "coruja"    => "🦉",
        "tamagochi" => "🎮",
        "wanderer"  => "🌬",
        "keeper"    => "🔔",
        "wiseman"   => "📜",
        "assistant" => "📱",
        "paperboy"  => "📰",
        "jafar"     => "🔮",
        "gandalf"   => "🧙",
        "wikister"  => "📚",
        "jonathas"  => "🏗",
        _           => "📞",
    }
}

fn clock_display(clock: &str) -> String {
    if clock == "on-demand" || clock.is_empty() {
        return "on-demand".into();
    }
    // "every30" → "every30m", "30" → "every30m"
    if clock.starts_with("every") {
        format!("{}m", clock)
    } else if let Ok(n) = clock.parse::<u32>() {
        format!("every{}m", n)
    } else {
        clock.to_string()
    }
}

fn word_wrap(text: &str, width: usize) -> Vec<String> {
    let mut lines = Vec::new();
    let mut current = String::new();
    for word in text.split_whitespace() {
        if current.is_empty() {
            current = word.to_string();
        } else if current.len() + 1 + word.len() <= width {
            current.push(' ');
            current.push_str(word);
        } else {
            lines.push(current.clone());
            current = word.to_string();
        }
    }
    if !current.is_empty() {
        lines.push(current);
    }
    lines
}

/// `leech phone [agente] <mensagem>` — ligação telepática one-shot para um agente.
pub fn phone_msg(agent_name: &str, message: &str) -> Result<()> {
    let obsidian = paths::obsidian_path();
    let self_dir = paths::leech_root();
    let home = paths::home();

    // Carrega contexto do agente
    let agent_file = paths::agent_file(agent_name);
    let (model_str, agent_body) = if let Some(ref path) = agent_file {
        let content = std::fs::read_to_string(path)?;
        let model = agents::frontmatter_field(&content, "model")
            .unwrap_or_else(|| "haiku".into());
        let body = extract_body(&content);
        (model, body)
    } else {
        ("haiku".into(), String::new())
    };

    let (call_type, ringing) = call_theme(agent_name);
    let now_str = utc_stamp();

    // Cabeçalho da chamada
    eprintln!();
    eprintln!("  ┌─────────────────────────────────────────────┐");
    eprintln!("  │  LIGAÇÃO TELEPÁTICA          {}  │", &now_str);
    eprintln!("  │  De:   Pedrinho                             │");
    eprintln!("  │  Para: {:<37}│", agent_name);
    eprintln!("  │  Tipo: {:<37}│", call_type);
    eprintln!("  └─────────────────────────────────────────────┘");
    eprintln!();
    eprintln!("  {}", ringing);
    eprintln!();

    let prompt = format!(
        "LIGAÇÃO ENTRANTE — {now_str}\n\
         De: Pedrinho  →  Para: {agent_name}\n\
         Tipo: {call_type}\n\
         ───────────────────────────────────────\n\n\
         Você está recebendo uma {call_type} do Pedrinho.\n\
         Ele está dizendo:\n\n\
         \"{message}\"\n\n\
         Responda como numa ligação — breve, direto, sem prefácio.\n\
         - Tarefa ou pedido → confirme o que vai fazer\n\
         - Pergunta → responda em 1-3 linhas\n\
         - Lembrete → confirme que registrou\n\
         Sem 'Claro!', sem 'Entendido!' — vai direto ao ponto.\n\n\
         --- contexto do agente ---\n\
         {agent_body}",
    );

    let t0 = std::time::Instant::now();

    let status = Command::new("claude")
        .args([
            "--permission-mode", "bypassPermissions",
            "--model", &model_str,
            "--max-turns", "10",
            "-p", &prompt,
            "--add-dir", &home.to_string_lossy(),
            "--add-dir", &obsidian.to_string_lossy(),
            "--add-dir", &self_dir.to_string_lossy(),
        ])
        .env("HEADLESS", "1")
        .env("LEECH_OBSIDIAN", &obsidian)
        .env("LEECH_SELF", &self_dir)
        .current_dir(&home)
        .status()
        .map_err(|e| anyhow::anyhow!("[phone] falhou ao executar claude: {e}"))?;

    let elapsed = t0.elapsed();
    let secs = elapsed.as_secs();
    let duration = if secs >= 60 {
        format!("{}m{}s", secs / 60, secs % 60)
    } else {
        format!("{}s", secs)
    };

    eprintln!();
    eprintln!("  ─────────────────────────────────────────────");
    eprintln!("  ⏱  {}   Pedrinho → {}", duration, agent_name);
    eprintln!("  ─────────────────────────────────────────────");
    eprintln!();

    if !status.success() {
        anyhow::bail!("[phone] claude saiu com erro (exit={:?})", status.code());
    }
    Ok(())
}

/// `leech phones <mensagem>` — assistente pessoal: lembretes, tasks, pesquisas.
pub fn phones_msg(message: &str) -> Result<()> {
    let obsidian = paths::obsidian_path();
    let self_dir = paths::leech_root();
    let home = paths::home();

    // Rota para assistant, fallback hermes
    let target = if paths::agent_file("assistant").is_some() { "assistant" } else { "hermes" };

    let agent_file = paths::agent_file(target);
    let (model_str, agent_body) = if let Some(ref path) = agent_file {
        let content = std::fs::read_to_string(path)?;
        let model = agents::frontmatter_field(&content, "model")
            .unwrap_or_else(|| "haiku".into());
        let body = extract_body(&content);
        (model, body)
    } else {
        ("haiku".into(), String::new())
    };

    let now_str = utc_stamp();

    eprintln!();
    eprintln!("  📱  Assistente pessoal — {}  →  {}", "Pedrinho", target);
    eprintln!();

    let prompt = format!(
        "Você é o assistente pessoal do Pedrinho, recebendo uma solicitação direta.\n\
         Hora: {now_str}\n\
         OBSIDIAN={obsidian}\n\n\
         O Pedrinho disse:\n\
         \"{message}\"\n\n\
         Sua função nesta chamada:\n\
         - Lembrete → crie {obsidian}/inbox/lembrete-{now_str}.md e confirme\n\
         - Task → adicione em {obsidian}/tasks/TODO/ e confirme\n\
         - Pergunta → responda em até 3 linhas\n\
         - Pesquisa → execute e traga o resultado resumido\n\n\
         Responda em 1-3 linhas confirmando o que foi feito. Direto ao ponto.\n\n\
         --- contexto ---\n\
         {agent_body}",
        obsidian = obsidian.display(),
    );

    let t0 = std::time::Instant::now();

    let status = Command::new("claude")
        .args([
            "--permission-mode", "bypassPermissions",
            "--model", &model_str,
            "--max-turns", "15",
            "-p", &prompt,
            "--add-dir", &home.to_string_lossy(),
            "--add-dir", &obsidian.to_string_lossy(),
            "--add-dir", &self_dir.to_string_lossy(),
        ])
        .env("HEADLESS", "1")
        .env("LEECH_OBSIDIAN", &obsidian)
        .env("LEECH_SELF", &self_dir)
        .current_dir(&home)
        .status()
        .map_err(|e| anyhow::anyhow!("[phones] falhou ao executar claude: {e}"))?;

    let elapsed = t0.elapsed();
    let secs = elapsed.as_secs();
    let duration = if secs >= 60 {
        format!("{}m{}s", secs / 60, secs % 60)
    } else {
        format!("{}s", secs)
    };

    eprintln!();
    eprintln!("  ✓  assistente  ⏱ {}", duration);
    eprintln!();

    if !status.success() {
        anyhow::bail!("[phones] claude saiu com erro (exit={:?})", status.code());
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

