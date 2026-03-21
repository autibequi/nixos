use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use std::time::Duration;

pub enum AppEvent {
    Key(KeyEvent),
    Tick,
}

/// Poll for input events or tick.
pub fn poll(tick_rate: Duration) -> std::io::Result<AppEvent> {
    if event::poll(tick_rate)? {
        if let Event::Key(key) = event::read()? {
            return Ok(AppEvent::Key(key));
        }
    }
    Ok(AppEvent::Tick)
}

/// Map a key event to an action string.
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
        KeyCode::Char('s') => Some("start"),
        KeyCode::Char('S') => Some("stop"),
        KeyCode::Char('l') => Some("logs"),
        KeyCode::Char('t') => Some("test"),
        KeyCode::Char('x') => Some("shell"),
        _ => None,
    }
}
