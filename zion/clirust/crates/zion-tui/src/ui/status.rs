//! Top-level status dashboard: header, sessions, services, boot, quota, logs, footer.

use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use super::{boot, logs, quota, services, sessions};
use crate::app::App;
use crate::theme;

/// Render the full status dashboard.
pub fn render(frame: &mut Frame, app: &App) {
    let sessions_h = sessions_height(app);
    let services_h = dk_services_height(app);
    let logs_h = logs_height(app);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),           // header
            Constraint::Length(sessions_h),  // agents + background
            Constraint::Length(services_h),  // dk services
            Constraint::Length(1),           // separator
            Constraint::Length(1),           // boot flags
            Constraint::Length(1),           // separator
            Constraint::Length(2),           // quota bars
            Constraint::Length(1),           // separator
            Constraint::Min(logs_h),         // logs tail
            Constraint::Length(1),           // footer
        ])
        .split(frame.area());

    render_header(frame, chunks[0]);
    sessions::render(frame, app, chunks[1]);
    services::render(frame, app, chunks[2]);
    render_separator(frame, "Boot", chunks[3]);
    boot::render(frame, app, chunks[4]);
    render_separator(frame, "Quota", chunks[5]);
    quota::render(frame, app, chunks[6]);
    render_separator(frame, "Logs", chunks[7]);
    logs::render(frame, app, chunks[8]);
    render_footer(frame, app, chunks[9]);
}

fn sessions_height(app: &App) -> u16 {
    let n = app.snapshot.agents.len() + app.snapshot.background.len();
    // group header per group + rows + 1 blank between groups
    let groups = (if app.snapshot.agents.is_empty() { 0 } else { 1 })
        + (if app.snapshot.background.is_empty() { 0 } else { 1 });
    let between = if groups == 2 { 1 } else { 0 };
    let rows = n + groups + between;
    (rows as u16).max(2)
}

fn dk_services_height(app: &App) -> u16 {
    let count = app.snapshot.dk_services.len();
    if count == 0 {
        // Still show the static list
        (crate::app::DK_SERVICES.len() as u16) + 1
    } else {
        (count as u16) + 1
    }
}

fn logs_height(app: &App) -> u16 {
    (app.snapshot.logs.len() as u16).min(8).max(3)
}

fn render_separator(frame: &mut Frame, label: &str, area: Rect) {
    let line = Line::from(vec![
        Span::styled(format!("─ {label} "), theme::dim()),
    ]);
    frame.render_widget(Paragraph::new(line), area);
}

fn render_header(frame: &mut Frame, area: Rect) {
    let now = chrono_now();
    let line = Line::from(vec![
        Span::raw("  "),
        Span::styled("Zion Status", theme::header()),
        Span::raw("  "),
        Span::styled(now, theme::dim()),
    ]);
    frame.render_widget(Paragraph::new(line), area);
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let env = app.current_env();
    let svc = app.current_service();
    let line = Line::from(vec![
        Span::styled("  ↑↓", theme::footer_dim()),
        Span::styled(" nav  ", theme::footer_dim()),
        Span::styled("e", theme::footer_key()),
        Span::styled(format!("[{env}]"), theme::dim()),
        Span::styled("  s", theme::footer_key()),
        Span::styled(" start  ", theme::footer_dim()),
        Span::styled("S", theme::footer_key()),
        Span::styled(" stop  ", theme::footer_dim()),
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
    frame.render_widget(Paragraph::new(line), area);
}

fn chrono_now() -> String {
    use std::process::Command;
    Command::new("date")
        .arg("+%H:%M:%S")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "--:--:--".to_string())
}
