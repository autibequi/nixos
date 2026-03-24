//! Input event polling — keyboard + mouse + tick.

use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers, MouseEvent};
use std::time::Duration;

/// Events produced by the event loop.
pub enum AppEvent {
    Key(KeyEvent),
    Mouse(MouseEvent),
    Tick,
}

/// Poll for input events or tick.
pub fn poll(tick_rate: Duration) -> std::io::Result<AppEvent> {
    if event::poll(tick_rate)? {
        match event::read()? {
            Event::Key(key) if key.kind == KeyEventKind::Press => return Ok(AppEvent::Key(key)),
            Event::Mouse(mouse) => return Ok(AppEvent::Mouse(mouse)),
            _ => {}
        }
    }
    Ok(AppEvent::Tick)
}

/// Map a key event to an action string, returning `None` for unbound keys.
pub fn map_key(key: KeyEvent) -> Option<&'static str> {
    if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c') {
        return Some("quit");
    }
    match key.code {
        KeyCode::Char('q') => Some("quit"),
        KeyCode::Up   | KeyCode::Char('k') => Some("up"),
        KeyCode::Down | KeyCode::Char('j') => Some("down"),
        KeyCode::Char('e') => Some("cycle_env"),
        KeyCode::Char('[') | KeyCode::PageUp   => Some("log_up"),
        KeyCode::Char(']') | KeyCode::PageDown => Some("log_down"),
        KeyCode::Enter => Some("menu_open"),
        KeyCode::Char('a') => Some("agents_open"),
        KeyCode::Char('w') => Some("worktree_open"),
        _ => None,
    }
}
