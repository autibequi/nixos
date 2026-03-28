//! `leech cleanup` — lista e opcionalmente encerra **processos** (via sinais ao SO).
//!
//! **Não apaga, não move e não altera arquivos** — só lê `/proc` e pode enviar `SIGTERM` a PIDs.
//!
//! Zombies não podem ser mortos diretamente; o kernel só os remove quando o pai faz `wait()`.
//! Enviar SIGTERM ao pai costuma forçar o encerramento e o init (PID 1) adota os filhos.

use anyhow::Result;
use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::Path;

/// Zombies `bash`/`sh`/`zsh` agrupados por PPID; opcionalmente SIGTERM nos pais.
pub fn run(reap: bool, min_per_parent: usize, all_parents: bool, assume_yes: bool) -> Result<()> {
    crate::exec::require_host()?;

    #[cfg(not(unix))]
    {
        let _ = (reap, min_per_parent, all_parents, assume_yes);
        anyhow::bail!("leech cleanup só é suportado em Linux/unix");
    }

    #[cfg(unix)]
    {
        run_unix(reap, min_per_parent, all_parents, assume_yes)
    }
}

#[cfg(unix)]
fn run_unix(reap: bool, min_per_parent: usize, all_parents: bool, assume_yes: bool) -> Result<()> {
    let zombies = scan_zombie_shells()?;
    if zombies.is_empty() {
        println!("Nenhum processo zombie com comm bash/sh/zsh encontrado.");
        return Ok(());
    }

    let mut by_parent: HashMap<i32, Vec<i32>> = HashMap::new();
    for z in zombies {
        by_parent.entry(z.ppid).or_default().push(z.pid);
    }

    let mut rows: Vec<(i32, usize, String)> = Vec::new();
    for (ppid, zpids) in by_parent {
        if zpids.len() < min_per_parent {
            continue;
        }
        let cmd = read_cmdline(ppid).unwrap_or_else(|| format!("(pid {ppid}, sem cmdline)"));
        if !all_parents && !matches_leechish_stack(&cmd) {
            continue;
        }
        rows.push((ppid, zpids.len(), cmd));
    }

    rows.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));

    if rows.is_empty() {
        println!(
            "Nenhum pai qualificado (min={min_per_parent}, all_parents={all_parents}).\n\
             Tente: leech cleanup --all  (lista todos os pais de zombies bash)"
        );
        return Ok(());
    }

    println!(
        "\n\x1b[1mZombies bash/sh/zsh por processo pai\x1b[0m  (min {} zombie(s) por pai)\n",
        min_per_parent
    );
    println!("  {:>8}  {:>5}  {}", "PPID", "N", "cmdline do pai");
    println!("  {}", "─".repeat(76));
    for (ppid, n, cmd) in &rows {
        let short = if cmd.len() > 68 {
            format!("{}…", &cmd[..67])
        } else {
            cmd.clone()
        };
        println!("  {:>8}  {:>5}  {}", ppid, n, short);
    }
    println!();

    if !reap {
        println!(
            "\x1b[2mModo listagem. Nada foi encerrado; nenhum arquivo foi alterado.\n\
             Para pedir encerramento dos pais (com confirmação):\x1b[0m\n\
             \x1b[33m  leech cleanup --reap\x1b[0m\n\
             \x1b[2m  (use --yes para pular a confirmação, ex.: scripts)\x1b[0m\n"
        );
        return Ok(());
    }

    let total_zombies: usize = rows.iter().map(|(_, n, _)| *n).sum();
    let num_parents = rows.len();

    println!(
        "\n\x1b[1mResumo — encerramento de processos\x1b[0m\n\
         \x1b[2m  (apenas sinais ao kernel; \x1b[32mnenhum arquivo\x1b[2m é apagado ou modificado)\x1b[0m\n"
    );
    println!(
        "  • {} processo(s) zombie (shell) no total",
        total_zombies
    );
    println!(
        "  • {} processo(s) \x1b[1mpai\x1b[0m receberão \x1b[33mSIGTERM\x1b[0m (PPIDs abaixo)",
        num_parents
    );
    println!("\n  {:>8}  {:>5}  {}", "PPID", "N", "nome / argv0");
    println!("  {}", "─".repeat(56));
    const MAX_HINT: usize = 20;
    for (ppid, n, cmd) in rows.iter().take(MAX_HINT) {
        println!(
            "  {:>8}  {:>5}  {}",
            ppid,
            n,
            argv0_hint(cmd)
        );
    }
    if rows.len() > MAX_HINT {
        println!(
            "  \x1b[2m… e mais {} pai(is)\x1b[0m",
            rows.len() - MAX_HINT
        );
    }
    println!();

    if !assume_yes && !confirm_reap(num_parents, total_zombies)? {
        println!("Cancelado. Nenhum sinal foi enviado.");
        return Ok(());
    }

    let mut ok = 0;
    let mut err = 0;
    for (ppid, n, cmd) in &rows {
        print!("  SIGTERM → PPID {} ({} zombies) … ", ppid, n);
        let r = unsafe { libc::kill(*ppid, libc::SIGTERM) };
        if r == 0 {
            println!("\x1b[32mok\x1b[0m");
            ok += 1;
        } else {
            let snippet = truncate_ascii(cmd, 40);
            println!("\x1b[31merrno\x1b[0m  ({snippet}…)");
            err += 1;
        }
    }
    println!(
        "\n  \x1b[32m{ok}\x1b[0m sinal(is) enviado(s), \x1b[31m{err}\x1b[0m falha(s). \
         Os zombies somem quando o pai morre ou reaparece.\n"
    );
    Ok(())
}

#[cfg(unix)]
fn truncate_ascii(s: &str, max: usize) -> &str {
    if s.len() <= max {
        s
    } else {
        &s[..max]
    }
}

#[cfg(unix)]
fn argv0_hint(cmd: &str) -> String {
    cmd.split_whitespace()
        .next()
        .map(|s| {
            s.rsplit('/').next().unwrap_or(s).to_string()
        })
        .unwrap_or_else(|| "?".into())
}

#[cfg(unix)]
fn confirm_reap(num_parents: usize, num_zombies: usize) -> Result<bool> {
    print!(
        "\x1b[1mConfirmar encerramento?\x1b[0m\n\
         Enviar SIGTERM a \x1b[33m{num_parents}\x1b[0m processo(s) pai \
         (relacionados a \x1b[33m{num_zombies}\x1b[0m zombie(s) de shell).\n\
         \x1b[2mIsto não remove arquivos — só tenta encerrar esses processos no SO.\x1b[0m\n\
         Digite \x1b[1msim\x1b[0m ou \x1b[1myes\x1b[0m para confirmar (ou Ctrl+C para cancelar): "
    );
    io::stdout().flush().map_err(|e| anyhow::anyhow!("stdout: {e}"))?;
    let mut line = String::new();
    io::stdin()
        .read_line(&mut line)
        .map_err(|e| anyhow::anyhow!("stdin: {e}"))?;
    let t = line.trim().to_lowercase();
    Ok(matches!(t.as_str(), "s" | "sim" | "y" | "yes"))
}

#[cfg(unix)]
struct ZombieShell {
    pid: i32,
    ppid: i32,
}

#[cfg(unix)]
fn scan_zombie_shells() -> Result<Vec<ZombieShell>> {
    let mut out = Vec::new();
    for ent in fs::read_dir("/proc").map_err(|e| anyhow::anyhow!("/proc: {e}"))? {
        let ent = ent.map_err(|e| anyhow::anyhow!("readdir: {e}"))?;
        let name = ent.file_name();
        let name = name.to_string_lossy();
        if !name.chars().all(|c| c.is_ascii_digit()) {
            continue;
        }
        let pid: i32 = match name.parse() {
            Ok(p) => p,
            Err(_) => continue,
        };
        let stat_path = Path::new("/proc").join(&*name).join("stat");
        let stat = match fs::read_to_string(&stat_path) {
            Ok(s) => s,
            Err(_) => continue,
        };
        let Some((comm, state, ppid)) = parse_proc_stat(&stat) else {
            continue;
        };
        if state != 'Z' {
            continue;
        }
        if !is_shell_comm(&comm) {
            continue;
        }
        out.push(ZombieShell { pid, ppid });
    }
    Ok(out)
}

#[cfg(unix)]
fn parse_proc_stat(content: &str) -> Option<(String, char, i32)> {
    let lp = content.find('(')?;
    let rest_after_open = &content[lp + 1..];
    let rp_rel = rest_after_open.find(')')?;
    let comm = rest_after_open[..rp_rel].to_string();
    let after = &content[lp + 1 + rp_rel + 1..];
    let after = after.trim_start();
    let mut it = after.split_ascii_whitespace();
    let state = it.next()?.chars().next()?;
    let ppid: i32 = it.next()?.parse().ok()?;
    Some((comm, state, ppid))
}

#[cfg(unix)]
fn is_shell_comm(comm: &str) -> bool {
    matches!(comm, "bash" | "sh" | "zsh" | "dash" | "ash")
}

#[cfg(unix)]
fn matches_leechish_stack(cmd: &str) -> bool {
    let lower = cmd.to_lowercase();
    [
        "agent",
        "cursor",
        "claude",
        "leech",
        "/node",
        "node ",
        "bun",
        "timeout",
        "npm",
        "yarn",
        "pnpm",
        "esbuild",
        "webpack",
        "tsserver",
        "deno",
    ]
    .iter()
    .any(|k| lower.contains(k))
}

#[cfg(unix)]
fn read_cmdline(pid: i32) -> Option<String> {
    let raw = fs::read(format!("/proc/{pid}/cmdline")).ok()?;
    if raw.is_empty() {
        return None;
    }
    let s = String::from_utf8_lossy(&raw)
        .split('\0')
        .filter(|x| !x.is_empty())
        .collect::<Vec<_>>()
        .join(" ");
    if s.is_empty() {
        None
    } else {
        Some(s)
    }
}

#[cfg(test)]
mod tests {
    use super::parse_proc_stat;

    #[test]
    fn parses_bash_zombie_stat() {
        let line = "1899988 (bash) Z 1896266 1896266 0 -1 4194304 123\n";
        let (comm, st, ppid) = parse_proc_stat(line).unwrap();
        assert_eq!(comm, "bash");
        assert_eq!(st, 'Z');
        assert_eq!(ppid, 1896266);
    }
}
