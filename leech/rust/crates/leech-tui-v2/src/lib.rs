//! Leech TUI v2 — ratatui dashboard with Catppuccin Mocha theme,
//! mouse-scrollable logs, and ANSI color passthrough.

#[cfg(unix)]
extern crate libc;

mod app;
mod event;
mod theme;
mod ui;

use std::io;
use std::process::Stdio;
use std::sync::mpsc;
use std::time::Duration;

use anyhow::Result;
use crossterm::{
    event::{DisableMouseCapture, EnableMouseCapture, MouseEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;
use ratatui::Terminal;

use app::{App, AppMode};
use event::{map_key, poll, AppEvent};
use leech_sdk::{paths, status};

// ── CLI helpers ───────────────────────────────────────────────────────────────

fn bash_cmd() -> std::process::Command {
    let candidates = [
        paths::bin_dir().join("leech-bash"),
        paths::bash_dir().join("leech"),
    ];
    for p in &candidates {
        if p.exists() {
            return std::process::Command::new(p);
        }
    }
    std::process::Command::new("leech")
}

fn docker_stop_wait(container_name: &str) {
    let _ = std::process::Command::new("docker")
        .args(["stop", "--time=5", container_name])
        .stdin(Stdio::null()).stdout(Stdio::null()).stderr(Stdio::null())
        .output();
}

fn run_bg_cmd(svc: &str, env: &str, action: &str) -> Option<String> {
    let mut cmd = bash_cmd();
    let env_flag = format!("--env={env}");
    let mut args: Vec<&str> = vec!["runner", svc, action];
    if (action == "start" || action == "start-hotreload") && !env.is_empty() {
        args.push(&env_flag);
    }
    match cmd.args(&args).output() {
        Err(e) => Some(format!("Could not run command: {e}")),
        Ok(out) if !out.status.success() => {
            let stderr = String::from_utf8_lossy(&out.stderr);
            let stdout = String::from_utf8_lossy(&out.stdout);
            let raw = if !stderr.is_empty() { stderr } else { stdout };
            Some(format!("{action} {svc} failed\n{}", clean_output(&raw)))
        }
        Ok(_) => None,
    }
}

fn clean_output(s: &str) -> String {
    let normalized = s.replace("\r\n", "\n").replace('\r', "\n");
    let mut out = String::with_capacity(normalized.len());
    let mut chars = normalized.chars().peekable();
    while let Some(ch) = chars.next() {
        if ch == '\x1b' {
            match chars.peek() {
                Some('[') => {
                    chars.next();
                    for c in chars.by_ref() {
                        if ('\x40'..='\x7e').contains(&c) { break; }
                    }
                }
                _ => { chars.next(); }
            }
        } else {
            out.push(ch);
        }
    }
    let lines: Vec<&str> = out.lines().map(str::trim).filter(|l| !l.is_empty()).collect();
    let start = lines.len().saturating_sub(10);
    lines[start..].join("\n")
}

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run_status(tick: u64) -> Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend  = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    if let Ok(snap) = status::collect() {
        app.snapshot = snap;
    }

    let (tx, rx)          = mpsc::channel();
    let tx_bg             = tx.clone();
    let refresh_interval  = Duration::from_secs(tick);

    std::thread::spawn(move || loop {
        std::thread::sleep(refresh_interval);
        if let Ok(snap) = status::collect() {
            if tx.send(snap).is_err() { break; }
        }
    });

    let (bg_err_tx, bg_err_rx)   = mpsc::channel::<String>();
    let (bg_done_tx, bg_done_rx) = mpsc::channel::<usize>();

    loop {
        if let Ok(err) = bg_err_rx.try_recv() { app.set_error(err); }
        if let Ok(idx) = bg_done_rx.try_recv() { app.clear_action_for(idx); }

        if matches!(app.mode, AppMode::Normal) {
            if let Ok(snap) = rx.try_recv() { app.snapshot = snap; }
        }

        terminal.draw(|frame| { ui::status::render(frame, &app); })?;
        app.render_tick = app.render_tick.wrapping_add(1);

        match poll(Duration::from_millis(250))? {
            // ── Mouse ─────────────────────────────────────────────────────────
            AppEvent::Mouse(mouse) => {
                if matches!(app.mode, AppMode::Normal) {
                    match mouse.kind {
                        MouseEventKind::ScrollUp => {
                            if app.allow_mouse_scroll() { app.log_scroll_up(1); }
                        }
                        MouseEventKind::ScrollDown => {
                            if app.allow_mouse_scroll() { app.log_scroll_down(1); }
                        }
                        _ => {}
                    }
                }
            }

            // ── Keyboard ──────────────────────────────────────────────────────
            AppEvent::Key(key) => {
                match &app.mode {
                    AppMode::Error(_) => { app.clear_error(); }

                    AppMode::Menu => {
                        use crossterm::event::KeyCode;
                        match key.code {
                            KeyCode::Up   | KeyCode::Char('k') => app.menu_prev(),
                            KeyCode::Down | KeyCode::Char('j') => app.menu_next(),
                            KeyCode::Esc  | KeyCode::Char('q') => app.close_menu(),
                            KeyCode::Enter => {
                                let action = app.menu_action();
                                match action {
                                    "cancel" => app.close_menu(),

                                    "stop" => {
                                        let svc  = app.current_service().to_string();
                                        let idx  = app.cursor_idx;
                                        let cname = find_container(&app, &svc);
                                        app.close_menu();
                                        app.last_action = Some((idx, format!("stopping {svc}…")));
                                        let done_tx = bg_done_tx.clone();
                                        let snap_tx = tx_bg.clone();
                                        std::thread::spawn(move || {
                                            if let Some(name) = cname { docker_stop_wait(&name); }
                                            let _ = done_tx.send(idx);
                                            if let Ok(snap) = leech_sdk::status::collect() {
                                                let _ = snap_tx.send(snap);
                                            }
                                        });
                                    }

                                    "start" | "start-hotreload" => {
                                        let action = action.to_string();
                                        let svc    = app.current_service().to_string();
                                        let env    = app.current_env().to_string();
                                        let idx    = app.cursor_idx;
                                        let label  = match action.as_str() {
                                            "start-hotreload" => format!("hotreload {svc}…"),
                                            _                 => format!("starting {svc}…"),
                                        };
                                        app.close_menu();
                                        app.last_action = Some((idx, label));
                                        let err_tx  = bg_err_tx.clone();
                                        let snap_tx = tx_bg.clone();
                                        let done_tx = bg_done_tx.clone();
                                        std::thread::spawn(move || {
                                            if let Some(err) = run_bg_cmd(&svc, &env, &action) {
                                                let _ = err_tx.send(err);
                                            }
                                            let _ = done_tx.send(idx);
                                            if let Ok(snap) = status::collect() {
                                                let _ = snap_tx.send(snap);
                                            }
                                        });
                                    }

                                    "restart" => {
                                        let svc    = app.current_service().to_string();
                                        let env    = app.current_env().to_string();
                                        let idx    = app.cursor_idx;
                                        let cname  = find_container(&app, &svc);
                                        app.close_menu();
                                        app.last_action = Some((idx, format!("restarting {svc}…")));
                                        let err_tx  = bg_err_tx.clone();
                                        let snap_tx = tx_bg.clone();
                                        let done_tx = bg_done_tx.clone();
                                        std::thread::spawn(move || {
                                            if let Some(name) = cname { docker_stop_wait(&name); }
                                            if let Some(err) = run_bg_cmd(&svc, &env, "start") {
                                                let _ = err_tx.send(err);
                                            }
                                            let _ = done_tx.send(idx);
                                            if let Ok(snap) = status::collect() {
                                                let _ = snap_tx.send(snap);
                                            }
                                        });
                                    }

                                    "logs" | "test" | "install" | "shell" => {
                                        let action = action.to_string();
                                        let svc    = app.current_service().to_string();
                                        app.close_menu();
                                        disable_raw_mode()?;
                                        execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;

                                        // Ignore SIGINT in this process so Ctrl+C only kills the
                                        // child (docker logs / shell) and returns us to the TUI.
                                        #[cfg(unix)]
                                        let _prev_sigint = unsafe {
                                            libc::signal(libc::SIGINT, libc::SIG_IGN)
                                        };

                                        let result = bash_cmd()
                                            .args(["runner", &svc, &action])
                                            .stdin(Stdio::inherit())
                                            .stdout(Stdio::inherit())
                                            .stderr(Stdio::inherit())
                                            .status();

                                        // Restore default SIGINT handler.
                                        #[cfg(unix)]
                                        unsafe { libc::signal(libc::SIGINT, libc::SIG_DFL); }

                                        enable_raw_mode()?;
                                        execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
                                        terminal.clear()?;

                                        if let Ok(snap) = status::collect() { app.snapshot = snap; }
                                        if let Err(e) = result {
                                            app.set_error(format!("Failed to run {action}: {e}"));
                                        }
                                    }

                                    _ => app.close_menu(),
                                }
                            }
                            _ => {}
                        }
                    }

                    AppMode::Normal => {
                        if let Some(action) = map_key(key) {
                            match action {
                                "quit"      => break,
                                "up"        => app.move_up(),
                                "down"      => app.move_down(),
                                "cycle_env" => app.cycle_env(),
                                "log_up"    => app.log_scroll_up(5),
                                "log_down"  => app.log_scroll_down(5),
                                "menu_open" => app.open_menu(),
                                _           => {}
                            }
                        }
                    }
                }
            }

            AppEvent::Tick => {}
        }
    }

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;
    Ok(())
}

/// Find the Docker container name for a given service (for direct stop).
fn find_container(app: &App, svc: &str) -> Option<String> {
    if app.is_utils_selected() {
        app.snapshot.utils.iter()
            .find(|u| u.name.contains(svc))
            .map(|u| u.name.clone())
    } else {
        // Prefer the exact app container (leech-dk-<svc>-app) to avoid
        // accidentally stopping a dep (postgres/redis/localstack).
        let app_name = format!("leech-dk-{svc}-app");
        app.snapshot.dk_services.iter()
            .find(|d| d.name == app_name)
            .map(|d| d.name.clone())
            .or_else(|| {
                // Fallback: any container whose name ends with -<svc>-app
                app.snapshot.dk_services.iter()
                    .find(|d| d.name.ends_with(&format!("-{svc}-app")))
                    .map(|d| d.name.clone())
            })
    }
}
