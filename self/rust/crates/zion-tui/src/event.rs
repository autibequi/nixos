//! Input event polling and key-to-action mapping.

use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use std::time::Duration;

/// Events produced by the event loop.
pub enum AppEvent {
    /// A keyboard key was pressed.
    Key(KeyEvent),
    /// No input arrived within the poll timeout.
    Tick,
}

/// Poll for input events or tick.
pub fn poll(tick_rate: Duration) -> std::io::Result<AppEvent> {
    if event::poll(tick_rate)? {
        if let Event::Key(key) = event::read()? {
            // Ignore key release / repeat to avoid double-firing
            if key.kind == KeyEventKind::Press {
                return Ok(AppEvent::Key(key));
            }
        }
    }
    Ok(AppEvent::Tick)
}

/// Map a key event to an action string, returning `None` for unbound keys.
pub fn map_key(key: KeyEvent) -> Option<&'static str> {
    // Ctrl+C always quits
    if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c') {
        return Some("quit");
    }

    match key.code {
        KeyCode::Char('q') => Some("quit"),
        KeyCode::Up | KeyCode::Char('k') => Some("up"),
        KeyCode::Down | KeyCode::Char('j') => Some("down"),
        KeyCode::Char('e') => Some("cycle_env"),
        KeyCode::Char('[') | KeyCode::PageUp => Some("log_up"),
        KeyCode::Char(']') | KeyCode::PageDown => Some("log_down"),
        KeyCode::Enter => Some("menu_open"),
        _ => None,
    }
}
