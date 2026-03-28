mod app;
mod ui;

use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;
use std::io;
use std::time::Duration;

pub use app::{App, AppMode};

pub fn run() -> Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    app.refresh()?;

    let result = run_loop(&mut terminal, &mut app);

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    result
}

fn run_loop(terminal: &mut Terminal<CrosstermBackend<io::Stdout>>, app: &mut App) -> Result<()> {
    let tick_rate = Duration::from_secs(3);

    loop {
        terminal.draw(|f| ui::render(f, app))?;

        if event::poll(tick_rate)? {
            if let Event::Key(key) = event::read()? {
                match app.mode {
                    AppMode::Normal => match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
                        KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                            return Ok(())
                        }
                        KeyCode::Down | KeyCode::Char('j') => app.next(),
                        KeyCode::Up | KeyCode::Char('k') => app.prev(),
                        KeyCode::Enter => app.open_menu(),
                        KeyCode::Char('r') => app.refresh()?,
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
                                execute!(
                                    terminal.backend_mut(),
                                    LeaveAlternateScreen,
                                    DisableMouseCapture
                                )?;

                                let _ = app.exec_action(&act);

                                // Restore TUI
                                enable_raw_mode()?;
                                execute!(
                                    terminal.backend_mut(),
                                    EnterAlternateScreen,
                                    EnableMouseCapture
                                )?;
                                terminal.clear()?;
                                app.close_menu();
                                app.refresh()?;
                            }
                        }
                        _ => {}
                    },
                }
            }
        } else {
            // Tick — refresh data
            app.refresh()?;
        }
    }
}
