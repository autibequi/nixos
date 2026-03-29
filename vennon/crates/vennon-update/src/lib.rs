//! Pipeline único de update completo: `cargo build --release`, cópia dos binários para `~/.local/bin`,
//! `buzz.yaml`, systemd user — com a mesma UI (“zion utils update”) em todos os pontos de entrada.
//!
//! Chamado por **`deck update`**, **`yaa update`** e **`vennon update`**. Não expõe binário próprio.

use anyhow::{bail, Result};
use crossterm::{
    cursor,
    style::{Attribute, Color, Print, ResetColor, SetAttribute, SetForegroundColor},
    terminal, QueueableCommand,
};
use std::io::{self, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

// ── Catppuccin Mocha ────────────────────────────────────────────
const GREEN: Color = Color::Rgb { r: 166, g: 227, b: 161 };
const MAUVE: Color = Color::Rgb { r: 203, g: 166, b: 247 };
const PEACH: Color = Color::Rgb { r: 250, g: 179, b: 135 };
const RED: Color = Color::Rgb { r: 243, g: 139, b: 168 };
const DIM: Color = Color::Rgb { r: 108, g: 112, b: 134 };
const TEXT: Color = Color::Rgb { r: 205, g: 214, b: 244 };

const SPIN: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

/// Largura entre `│` e `│` na caixa do título (igual à barra `─` de cima/baixo).
const BOX_INNER: usize = 38;

fn pad_box_inner(text: &str, width: usize) -> String {
    let mut s = text.to_string();
    let n = s.chars().count();
    if n > width {
        s = s.chars().take(width).collect();
    } else {
        while s.chars().count() < width {
            s.push(' ');
        }
    }
    s
}

/// Executa o update completo com a UI padronizada (único caminho para `deck` / `yaa` / `vennon`).
pub fn run() -> Result<()> {
    let vennon_dir = find_vennon_dir();
    let install_dir = home().join(".local/bin");

    let mut out = io::stdout();

    // ── Header (│ … │ com exatamente BOX_INNER colunas, alinhado às barras ╭─╮) ──
    out.queue(Print("\n"))?;
    out.queue(SetForegroundColor(DIM))?;
    out.queue(Print("  ╭"))?;
    out.queue(Print("─".repeat(BOX_INNER)))?;
    out.queue(Print("╮\n"))?;
    out.queue(Print("  │"))?;
    out.queue(SetForegroundColor(MAUVE))?;
    out.queue(SetAttribute(Attribute::Bold))?;
    let inner = pad_box_inner("  ↑  zion utils update", BOX_INNER);
    out.queue(Print(inner))?;
    out.queue(SetAttribute(Attribute::Reset))?;
    out.queue(SetForegroundColor(DIM))?;
    out.queue(Print("│\n"))?;
    out.queue(Print("  ╰"))?;
    out.queue(Print("─".repeat(BOX_INNER)))?;
    out.queue(Print("╯\n\n"))?;
    out.queue(ResetColor)?;
    out.flush()?;

    // ── Steps ───────────────────────────────────────────────────
    let steps: &[(&str, &str)] = &[
        ("build", "cargo build --release"),
        ("vennon", "instalando vennon"),
        ("yaa", "instalando yaa"),
        ("deck", "instalando deck"),
        ("buzz", "instalando buzz"),
        ("buzz-yaml", "instalando buzz.yaml"),
        ("buzz-svc", "reiniciando buzz"),
        ("tick-svc", "reiniciando yaa-tick"),
    ];

    // Pre-print all step lines as pending
    for (_, label) in steps {
        out.queue(SetForegroundColor(DIM))?;
        out.queue(Print(format!("  ·  {label}\n")))?;
    }
    out.queue(Print("\n"))?;
    out.flush()?;

    // Move cursor back up to first step
    let total_lines = steps.len() as u16 + 1;
    out.queue(cursor::MoveUp(total_lines))?;
    out.flush()?;

    let mut results: Vec<(bool, Duration)> = Vec::new();

    // ── Step 1: cargo build --release ───────────────────────────
    {
        let start = Instant::now();
        let child = Command::new("nix-shell")
            .args(["-p", "rustc", "cargo", "--run", "cargo build --release"])
            .current_dir(&vennon_dir)
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .spawn();

        match child {
            Err(e) => {
                print_step_fail(&mut out, steps[0].1, Duration::ZERO)?;
                cursor_to_end(&mut out, steps.len(), 0)?;
                bail!("erro ao iniciar nix-shell: {e}");
            }
            Ok(mut child) => {
                let mut frame = 0usize;
                loop {
                    match child.try_wait() {
                        Ok(Some(status)) => {
                            let elapsed = start.elapsed();
                            if status.success() {
                                print_step_ok(&mut out, steps[0].1, elapsed)?;
                                results.push((true, elapsed));
                            } else {
                                print_step_fail(&mut out, steps[0].1, elapsed)?;
                                // Show compiler errors
                                if let Some(stderr) = child.stderr.take() {
                                    let err_output = std::io::read_to_string(stderr).unwrap_or_default();
                                    let errors: Vec<&str> = err_output
                                        .lines()
                                        .filter(|l| l.contains("error") || l.contains("Error"))
                                        .take(20)
                                        .collect();
                                    if !errors.is_empty() {
                                        out.queue(Print("\n"))?;
                                        out.queue(SetForegroundColor(RED))?;
                                        for line in &errors {
                                            out.queue(Print(format!("  {line}\n")))?;
                                        }
                                        out.queue(ResetColor)?;
                                        out.flush()?;
                                    }
                                }
                                cursor_to_end(&mut out, steps.len(), 1)?;
                                bail!("cargo build falhou (exit {})", status.code().unwrap_or(-1));
                            }
                            break;
                        }
                        Ok(None) => {
                            print_step_spin(&mut out, steps[0].1, start.elapsed(), frame)?;
                            frame = (frame + 1) % SPIN.len();
                            std::thread::sleep(Duration::from_millis(80));
                        }
                        Err(e) => {
                            print_step_fail(&mut out, steps[0].1, start.elapsed())?;
                            cursor_to_end(&mut out, steps.len(), 1)?;
                            bail!("erro ao monitorar build: {e}");
                        }
                    }
                }
            }
        }
    }

    // ── Steps 2-4: install binaries ─────────────────────────────
    for (idx, bin) in ["vennon", "yaa", "deck", "buzz"].iter().enumerate() {
        let step_idx = idx + 1;
        let start = Instant::now();

        // Animate the install step briefly
        print_step_spin(&mut out, steps[step_idx].1, Duration::ZERO, 0)?;
        out.flush()?;

        let src = vennon_dir.join("target/release").join(bin);
        let dst = install_dir.join(bin);
        let tmp = install_dir.join(format!(".{bin}.tmp"));

        let reason: Option<String> = 'install: {
            if !src.exists() {
                break 'install Some(format!("binário não encontrado: {}", src.display()));
            }
            if let Err(e) = std::fs::create_dir_all(&install_dir) {
                break 'install Some(format!("mkdir {}: {e}", install_dir.display()));
            }
            // Copy to hidden tmp in same dir (same fs), set perms, then atomic rename.
            // Using rename over a running executable works on Linux (old inode stays alive).
            if let Err(e) = std::fs::copy(&src, &tmp) {
                break 'install Some(format!("copy: {e}"));
            }
            if let Err(e) = set_executable_or_err(&tmp) {
                let _ = std::fs::remove_file(&tmp);
                break 'install Some(format!("chmod: {e}"));
            }
            if let Err(e) = std::fs::rename(&tmp, &dst) {
                let _ = std::fs::remove_file(&tmp);
                break 'install Some(format!("rename: {e}"));
            }
            None
        };

        let elapsed = start.elapsed();
        match reason {
            None => {
                print_step_ok(&mut out, steps[step_idx].1, elapsed)?;
                results.push((true, elapsed));
            }
            Some(reason) => {
                print_step_fail(&mut out, steps[step_idx].1, elapsed)?;
                // Print detail line inline so it's always visible regardless of cursor state
                out.queue(SetForegroundColor(RED))?;
                out.queue(Print(format!("       {reason}\n")))?;
                out.queue(ResetColor)?;
                out.flush()?;
                cursor_to_end(&mut out, steps.len(), step_idx + 1)?;
                bail!("falhou ao instalar {bin}");
            }
        }
    }

    // ── Step 6: install buzz.yaml to secure location ────────────
    {
        let step_idx = 5;
        let start = Instant::now();
        print_step_spin(&mut out, steps[step_idx].1, Duration::ZERO, 0)?;
        out.flush()?;

        let src = home().join("nixos/stow/.config/vennon/buzz.yaml");
        let dst_dir = home().join(".config/buzz");
        let dst = dst_dir.join("config.yaml");

        let reason: Option<String> = 'copy: {
            if !src.exists() {
                break 'copy Some(format!("não encontrado: {}", src.display()));
            }
            if let Err(e) = std::fs::create_dir_all(&dst_dir) {
                break 'copy Some(format!("mkdir: {e}"));
            }
            if let Err(e) = std::fs::copy(&src, &dst) {
                break 'copy Some(format!("copy: {e}"));
            }
            None
        };

        let elapsed = start.elapsed();
        match reason {
            None => {
                print_step_ok(&mut out, steps[step_idx].1, elapsed)?;
                results.push((true, elapsed));
            }
            Some(reason) => {
                print_step_fail(&mut out, steps[step_idx].1, elapsed)?;
                out.queue(SetForegroundColor(RED))?;
                out.queue(Print(format!("       {reason}\n")))?;
                out.queue(ResetColor)?;
                out.queue(SetForegroundColor(DIM))?;
                out.queue(Print(
                    "       atualização abortada (buzz.yaml é obrigatório neste pipeline).\n",
                ))?;
                out.queue(ResetColor)?;
                out.flush()?;
                cursor_to_end(&mut out, steps.len(), step_idx + 1)?;
                bail!("buzz.yaml: {reason}");
            }
        }
    }

    // ── Steps 7-8: restart systemd services ─────────────────────
    // Reload unit files first (silently) so systemctl doesn't warn mid-line
    let _ = Command::new("systemctl")
        .args(["--user", "daemon-reload"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    for (step_idx, (unit, label)) in [
        (6usize, ("buzz.service", steps[6].1)),
        (7usize, ("yaa-tick.timer", steps[7].1)),
    ] {
        let start = Instant::now();
        print_step_spin(&mut out, label, Duration::ZERO, 0)?;
        out.flush()?;

        let status = Command::new("systemctl")
            .args(["--user", "restart", unit])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();

        let elapsed = start.elapsed();
        match status {
            Ok(s) if s.success() => {
                print_step_ok(&mut out, label, elapsed)?;
                results.push((true, elapsed));
            }
            Ok(s) => {
                print_step_fail(&mut out, label, elapsed)?;
                out.queue(SetForegroundColor(RED))?;
                out.queue(Print(format!("       exit {}\n", s.code().unwrap_or(-1))))?;
                out.queue(ResetColor)?;
                out.flush()?;
                results.push((false, elapsed));
            }
            Err(e) => {
                print_step_fail(&mut out, label, elapsed)?;
                out.queue(SetForegroundColor(DIM))?;
                out.queue(Print(format!("       {e}\n")))?;
                out.queue(ResetColor)?;
                out.flush()?;
                results.push((false, elapsed));
            }
        }
        let _ = step_idx;
    }

    // ── Tempo total: mesma coluna que os passos (sem linha extra “pronto” / sem separador) ──
    out.queue(Print("\n"))?;
    let total: Duration = results.iter().map(|(_, d)| *d).sum();
    print_step_ok(&mut out, "Σ total", total)?;
    out.flush()?;

    Ok(())
}

// ── Step renderers ───────────────────────────────────────────────

fn print_step_spin(out: &mut impl Write, label: &str, elapsed: Duration, frame: usize) -> Result<()> {
    out.queue(terminal::Clear(terminal::ClearType::CurrentLine))?;
    out.queue(cursor::MoveToColumn(0))?;
    out.queue(SetForegroundColor(PEACH))?;
    out.queue(Print(format!("  {}  ", SPIN[frame % SPIN.len()])))?;
    out.queue(SetForegroundColor(TEXT))?;
    out.queue(Print(format!("{:<30}", label)))?;
    if elapsed.as_secs() > 0 {
        out.queue(SetForegroundColor(DIM))?;
        out.queue(Print(format!("  {}", fmt_dur(elapsed))))?;
    }
    out.queue(ResetColor)?;
    out.flush()?;
    Ok(())
}

fn print_step_ok(out: &mut impl Write, label: &str, elapsed: Duration) -> Result<()> {
    out.queue(terminal::Clear(terminal::ClearType::CurrentLine))?;
    out.queue(cursor::MoveToColumn(0))?;
    out.queue(SetForegroundColor(GREEN))?;
    out.queue(Print("  ✓  "))?;
    out.queue(SetForegroundColor(TEXT))?;
    out.queue(Print(format!("{:<30}", label)))?;
    out.queue(SetForegroundColor(DIM))?;
    out.queue(Print(format!("  {}\n", fmt_dur(elapsed))))?;
    out.queue(ResetColor)?;
    out.flush()?;
    Ok(())
}

fn print_step_fail(out: &mut impl Write, label: &str, elapsed: Duration) -> Result<()> {
    out.queue(terminal::Clear(terminal::ClearType::CurrentLine))?;
    out.queue(cursor::MoveToColumn(0))?;
    out.queue(SetForegroundColor(RED))?;
    out.queue(Print("  ✗  "))?;
    out.queue(SetForegroundColor(TEXT))?;
    out.queue(Print(format!("{:<30}", label)))?;
    out.queue(SetForegroundColor(DIM))?;
    out.queue(Print(format!("  {}\n", fmt_dur(elapsed))))?;
    out.queue(ResetColor)?;
    out.flush()?;
    Ok(())
}

/// Move cursor past remaining pending steps (printed as DIM ·) to end.
fn cursor_to_end(out: &mut impl Write, total_steps: usize, done: usize) -> Result<()> {
    let remaining = total_steps.saturating_sub(done) + 1; // +1 for blank line
    out.queue(cursor::MoveDown(remaining as u16))?;
    out.queue(Print("\n"))?;
    out.flush()?;
    Ok(())
}

// ── Helpers ──────────────────────────────────────────────────────

fn fmt_dur(d: Duration) -> String {
    let s = d.as_secs();
    if s == 0 {
        format!("{:.0}ms", d.as_millis())
    } else if s < 60 {
        format!("{s}s")
    } else {
        format!("{}m{}s", s / 60, s % 60)
    }
}

fn set_executable_or_err(path: &PathBuf) -> Result<(), String> {
    use std::os::unix::fs::PermissionsExt;
    let meta = std::fs::metadata(path).map_err(|e| format!("stat {}: {e}", path.display()))?;
    let mut perms = meta.permissions();
    perms.set_mode(0o755);
    std::fs::set_permissions(path, perms).map_err(|e| format!("chmod {}: {e}", path.display()))
}

fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| "/root".into()))
}

fn find_vennon_dir() -> PathBuf {
    let h = home();
    // Try ~/.yaa.yaml paths.vennon
    let yaml = h.join(".yaa.yaml");
    if let Ok(contents) = std::fs::read_to_string(&yaml) {
        for line in contents.lines() {
            if let Some(rest) = line.trim().strip_prefix("vennon:") {
                let v = rest.trim().trim_matches('"').trim_matches('\'');
                let expanded = v
                    .replace("~/", &format!("{}/", h.display()))
                    .replace("$HOME", &h.to_string_lossy());
                let p = PathBuf::from(expanded);
                if p.exists() {
                    return p;
                }
            }
        }
    }
    // Fallbacks
    for candidate in &[h.join("nixos/vennon"), h.join("nixos/host/vennon")] {
        if candidate.exists() {
            return candidate.clone();
        }
    }
    h.join("nixos/vennon")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    #[test]
    fn pad_box_inner_pads_to_width() {
        assert_eq!(pad_box_inner("ab", 4).chars().count(), 4);
        assert_eq!(pad_box_inner("ab", 4), "ab  ");
    }

    #[test]
    fn pad_box_inner_truncates() {
        assert_eq!(pad_box_inner("abcdefgh", 5), "abcde");
    }

    #[test]
    fn fmt_dur_zero_ms() {
        let s = fmt_dur(Duration::from_millis(12));
        assert!(s.ends_with("ms"), "got {s}");
    }

    #[test]
    fn fmt_dur_seconds() {
        assert_eq!(fmt_dur(Duration::from_secs(3)), "3s");
    }

    #[test]
    fn fmt_dur_minutes() {
        assert_eq!(fmt_dur(Duration::from_secs(125)), "2m5s");
    }
}
