mod app;
mod ui;

use anyhow::Result;
use crossterm::{
    event::{self, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;
use std::io;
use std::time::{Duration, Instant};

pub use app::{App, AppMode};

pub fn run() -> Result<()> {
    // Setup terminal (mouse capture disabled — fewer edge cases on Wayland/Hyprland)
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    app.refresh()?;

    let mut last_auto_refresh = Instant::now();
    let result = run_loop(&mut terminal, &mut app, &mut last_auto_refresh);

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    result
}

fn run_loop(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
    last_auto_refresh: &mut Instant,
) -> Result<()> {
    let poll_interval = Duration::from_millis(100);
    let auto_refresh_period = Duration::from_secs(3);

    loop {
        terminal.draw(|f| ui::render(f, app))?;
        app.poll_refresh_done();

        if last_auto_refresh.elapsed() >= auto_refresh_period && !app.refresh_inflight {
            app.kick_background_refresh();
            *last_auto_refresh = Instant::now();
        }

        if !event::poll(poll_interval)? {
            continue;
        }

        match event::read()? {
            Event::Key(key) => {
                match app.mode {
                    AppMode::Normal => match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
                        KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                            return Ok(())
                        }
                        KeyCode::Down | KeyCode::Char('j') => app.next(),
                        KeyCode::Up | KeyCode::Char('k') => app.prev(),
                        KeyCode::Enter => app.open_menu(),
                        KeyCode::Char('r') => {
                            app.kick_background_refresh();
                            *last_auto_refresh = Instant::now();
                        }
                        KeyCode::Tab => app.switch_tab(),
                        KeyCode::Char('[') | KeyCode::PageUp => app.scroll_logs_up(),
                        KeyCode::Char(']') | KeyCode::PageDown => app.scroll_logs_down(),
                        _ => {}
                    },
                    AppMode::Menu => match key.code {
                        KeyCode::Esc | KeyCode::Char('q') => app.close_menu(),
                        KeyCode::Down | KeyCode::Char('j') => app.menu_next(),
                        KeyCode::Up | KeyCode::Char('k') => app.menu_prev(),
                        KeyCode::Enter => {
                            let action = app.selected_action();
                            if let Some(act) = action {
                                // Suspend TUI for interactive commands
                                disable_raw_mode()?;
                                execute!(terminal.backend_mut(), LeaveAlternateScreen)?;

                                let _ = app.exec_action(&act);

                                // Restore TUI
                                enable_raw_mode()?;
                                execute!(terminal.backend_mut(), EnterAlternateScreen)?;
                                terminal.clear()?;
                                app.close_menu();
                                app.refresh()?;
                                *last_auto_refresh = Instant::now();
                            }
                        }
                        _ => {}
                    },
                }
            }
            Event::Resize(_, _) => {
                // Next draw picks up the new size; crossterm queued this so we don't block.
            }
            _ => {}
        }
    }
}
