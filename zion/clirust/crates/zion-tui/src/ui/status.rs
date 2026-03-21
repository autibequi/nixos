use ratatui::layout::{Constraint, Direction, Layout};
use ratatui::Frame;

use super::services;
use super::sessions;
use crate::app::App;

/// Render the full status dashboard.
pub fn render(frame: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),                       // header
            Constraint::Min(5),                          // sessions (agents + background)
            Constraint::Length(dk_services_height(app)), // dk services
            Constraint::Length(3),                       // footer
        ])
        .split(frame.area());

    render_header(frame, chunks[0]);
    sessions::render(frame, app, chunks[1]);
    services::render(frame, app, chunks[2]);
    render_footer(frame, app, chunks[3]);
}

fn dk_services_height(app: &App) -> u16 {
    let count = app.snapshot.dk_services.len();
    if count == 0 {
        0
    } else {
        (count as u16) + 3
    }
}

fn render_header(frame: &mut Frame, area: ratatui::layout::Rect) {
    use crate::theme;
    use ratatui::text::{Line, Span};
    use ratatui::widgets::Paragraph;

    let now = chrono_now();
    let header = Line::from(vec![
        Span::raw("  "),
        Span::styled("Zion Status", theme::header()),
        Span::raw("  "),
        Span::styled(now, theme::dim()),
    ]);
    let widget = Paragraph::new(header);
    frame.render_widget(widget, area);
}

fn render_footer(frame: &mut Frame, app: &App, area: ratatui::layout::Rect) {
    use crate::theme;
    use ratatui::text::{Line, Span};
    use ratatui::widgets::Paragraph;

    let env = app.current_env();
    let svc = app.current_service();
    let footer = Line::from(vec![
        Span::styled("  \u{2191}\u{2193}", theme::footer_dim()),
        Span::styled(" navegar  ", theme::footer_dim()),
        Span::styled("e", theme::footer_key()),
        Span::styled(format!("[{env}]"), theme::dim()),
        Span::styled("  s", theme::footer_key()),
        Span::styled(" iniciar  ", theme::footer_dim()),
        Span::styled("S", theme::footer_key()),
        Span::styled(" parar  ", theme::footer_dim()),
        Span::styled("l", theme::footer_key()),
        Span::styled(" logs  ", theme::footer_dim()),
        Span::styled("t", theme::footer_key()),
        Span::styled(" test  ", theme::footer_dim()),
        Span::styled("x", theme::footer_key()),
        Span::styled(" shell  ", theme::footer_dim()),
        Span::styled("q", theme::footer_key()),
        Span::styled(" quit  ", theme::footer_dim()),
        Span::styled(format!("[{svc}]"), theme::dim()),
    ]);
    let widget = Paragraph::new(footer);
    frame.render_widget(widget, area);
}

fn chrono_now() -> String {
    use std::process::Command;
    // Simple: use date command since we don't have chrono crate
    Command::new("date")
        .arg("+%H:%M:%S")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "--:--:--".to_string())
}
