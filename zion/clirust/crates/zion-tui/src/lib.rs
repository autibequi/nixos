//! Zion TUI — interactive terminal dashboard using ratatui.

mod app;
mod event;
mod theme;
mod ui;

use std::io;
use std::sync::mpsc;
use std::time::Duration;

use anyhow::Result;
use crossterm::{
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;
use ratatui::Terminal;

use app::{App, AppMode};
use event::{map_key, poll, AppEvent};
use zion_sdk::{paths, status};

/// Build a `Command` for the bash CLI (`zion-bash` or fallback to `zion`).
///
/// On the host, the bash CLI is at `~/.local/bin/zion-bash`.
/// Inside a container, it lives directly on PATH as `zion`.
fn bash_cmd() -> std::process::Command {
    // Prefer zion-bash (installed by `zion update`)
    let candidates = [
        paths::bin_dir().join("zion-bash"),
        paths::clibash_dir().join("zion"),
    ];
    for p in &candidates {
        if p.exists() {
            return std::process::Command::new(p);
        }
    }
    // Last resort: whatever `zion` is on PATH
    std::process::Command::new("zion")
}

/// Run a background (non-interactive) docker command and return an error string if it fails.
fn run_bg_cmd(svc: &str, env: &str, action: &str) -> Option<String> {
    let mut cmd = bash_cmd();
    // bash CLI format: zion runner <service> <action> [--env=<env>]
    let env_flag = format!("--env={env}");
    let mut full_args: Vec<&str> = vec!["runner", svc, action];
    if action == "start" && !env.is_empty() {
        full_args.push(&env_flag);
    }

    match cmd.args(&full_args).output() {
        Err(e) => Some(format!("Could not run command: {e}")),
        Ok(out) if !out.status.success() => {
            let stderr = String::from_utf8_lossy(&out.stderr);
            let stdout = String::from_utf8_lossy(&out.stdout);
            let detail = if !stderr.is_empty() { stderr } else { stdout };
            Some(format!(
                "{action} {svc} failed (exit {:?})\n{}",
                out.status.code(),
                detail.trim()
            ))
        }
        Ok(_) => None,
    }
}

/// Entry point: run the interactive status TUI.
pub fn run_status(tick: u64) -> Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();

    // Initial data collection
    if let Ok(snap) = status::collect() {
        app.snapshot = snap;
    }

    // Background data refresh channel
    let (tx, rx) = mpsc::channel();
    let refresh_interval = Duration::from_secs(tick);

    std::thread::spawn(move || loop {
        std::thread::sleep(refresh_interval);
        if let Ok(snap) = status::collect() {
            if tx.send(snap).is_err() {
                break;
            }
        }
    });

    // Main loop
    loop {
        // Check for background updates (only in normal mode to avoid flicker during menu)
        if matches!(app.mode, AppMode::Normal) {
            if let Ok(snap) = rx.try_recv() {
                app.snapshot = snap;
            }
        }

        terminal.draw(|frame| {
            ui::status::render(frame, &app);
        })?;

        match poll(Duration::from_millis(500))? {
            AppEvent::Key(key) => {
                match &app.mode {
                    AppMode::Error(_) => {
                        // Any key dismisses the error
                        app.clear_error();
                    }
                    AppMode::Menu => {
                        use crossterm::event::KeyCode;
                        match key.code {
                            KeyCode::Up | KeyCode::Char('k') => app.menu_prev(),
                            KeyCode::Down | KeyCode::Char('j') => app.menu_next(),
                            KeyCode::Esc | KeyCode::Char('q') => app.close_menu(),
                            KeyCode::Enter => {
                                let action = app.menu_action();
                                match action {
                                    "cancel" => app.close_menu(),
                                    "start" | "stop" => {
                                        let svc = app.current_service().to_string();
                                        let env = app.current_env().to_string();
                                        app.close_menu();
                                        let err = run_bg_cmd(&svc, &env, action);
                                        if let Some(msg) = err {
                                            app.set_error(msg);
                                        }
                                    }
                                    "logs" | "test" | "shell" => {
                                        let action = action.to_string();
                                        let svc = app.current_service().to_string();
                                        app.close_menu();
                                        disable_raw_mode()?;
                                        execute!(terminal.backend_mut(), LeaveAlternateScreen)?;

                                        let result = bash_cmd()
                                            .args(["runner", &svc, &action])
                                            .stdin(std::process::Stdio::inherit())
                                            .stdout(std::process::Stdio::inherit())
                                            .stderr(std::process::Stdio::inherit())
                                            .status();

                                        enable_raw_mode()?;
                                        execute!(terminal.backend_mut(), EnterAlternateScreen)?;
                                        terminal.clear()?;

                                        if let Ok(snap) = status::collect() {
                                            app.snapshot = snap;
                                        }

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
                                "quit" => break,
                                "up" => app.move_up(),
                                "down" => app.move_down(),
                                "cycle_env" => app.cycle_env(),
                                "log_up" => app.log_scroll_up(5),
                                "log_down" => app.log_scroll_down(5),
                                "menu_open" => app.open_menu(),
                                _ => {}
                            }
                        }
                    }
                }
            }
            AppEvent::Tick => {}
        }
    }

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    Ok(())
}
