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

use app::App;
use event::{map_key, poll, AppEvent};
use zion_sdk::status;

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
        // Check for background updates
        if let Ok(snap) = rx.try_recv() {
            app.snapshot = snap;
        }

        terminal.draw(|frame| {
            ui::status::render(frame, &app);
        })?;

        match poll(Duration::from_secs(1))? {
            AppEvent::Key(key) => {
                if let Some(action) = map_key(key) {
                    match action {
                        "quit" => break,
                        "up" => app.move_up(),
                        "down" => app.move_down(),
                        "cycle_env" => app.cycle_env(),
                        "start" => {
                            let svc = app.current_service().to_string();
                            let env = app.current_env().to_string();
                            app.last_action = Some((app.cursor_idx, format!("starting {svc}")));
                            std::thread::spawn(move || {
                                let _ = std::process::Command::new("zion")
                                    .args(["docker", &svc, "start", &format!("--env={env}")])
                                    .stdout(std::process::Stdio::null())
                                    .stderr(std::process::Stdio::null())
                                    .spawn();
                            });
                        }
                        "stop" => {
                            let svc = app.current_service().to_string();
                            app.last_action = Some((app.cursor_idx, format!("stopping {svc}")));
                            std::thread::spawn(move || {
                                let _ = std::process::Command::new("zion")
                                    .args(["docker", &svc, "stop"])
                                    .stdout(std::process::Stdio::null())
                                    .stderr(std::process::Stdio::null())
                                    .spawn();
                            });
                        }
                        "logs" | "test" | "shell" => {
                            // Exit TUI, run interactive command, re-enter
                            disable_raw_mode()?;
                            execute!(terminal.backend_mut(), LeaveAlternateScreen)?;

                            let svc = app.current_service();
                            let _ = std::process::Command::new("zion")
                                .args(["docker", svc, action])
                                .stdin(std::process::Stdio::inherit())
                                .stdout(std::process::Stdio::inherit())
                                .stderr(std::process::Stdio::inherit())
                                .status();

                            enable_raw_mode()?;
                            execute!(terminal.backend_mut(), EnterAlternateScreen)?;
                            terminal.clear()?;

                            // Refresh data after returning
                            if let Ok(snap) = status::collect() {
                                app.snapshot = snap;
                            }
                        }
                        _ => {}
                    }
                }
            }
            AppEvent::Tick => {
                // Tick events handled by background thread + try_recv
            }
        }
    }

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    Ok(())
}
