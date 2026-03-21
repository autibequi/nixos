//! Top-level status dashboard: header, quota, sessions, services, logs, footer.

use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use super::{logs, popup, quota, services, sessions, utils};
use crate::app::App;
use crate::theme;

/// Render the full status dashboard.
pub fn render(frame: &mut Frame, app: &App) {
    let sessions_h = sessions_height(app);
    let services_h = dk_services_height(app);
    let utils_h = utils_height(app);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),           // header (title + time + quota inline)
            Constraint::Length(sessions_h),  // agents + background
            Constraint::Length(services_h),  // dk services
            Constraint::Length(utils_h),     // utils (reverseproxy, etc.)
            Constraint::Length(1),           // separator (Logs [svc])
            Constraint::Min(0),              // logs — fills all remaining space
            Constraint::Length(1),           // footer
        ])
        .split(frame.area());

    render_header(frame, app, chunks[0]);
    sessions::render(frame, app, chunks[1]);
    services::render(frame, app, chunks[2]);
    utils::render(frame, app, chunks[3]);
    render_log_separator(frame, app, chunks[4]);
    logs::render(frame, app, chunks[5]);
    render_footer(frame, app, chunks[6]);

    // Overlay: menu or error popup (rendered last so it's on top)
    popup::render(frame, app);
}

fn sessions_height(app: &App) -> u16 {
    let n = app.snapshot.agents.len() + app.snapshot.background.len();
    // group header per group + rows + 1 blank between groups
    let groups = (if app.snapshot.agents.is_empty() { 0 } else { 1 })
        + (if app.snapshot.background.is_empty() { 0 } else { 1 });
    let between = if groups == 2 { 1 } else { 0 };
    let rows = n + groups + between;
    (rows as u16).max(1)
}

fn dk_services_height(app: &App) -> u16 {
    let svc_count = if app.snapshot.dk_services.is_empty() {
        crate::app::DK_SERVICES.len()
    } else {
        app.snapshot.dk_services.len()
    };
    // +1 for group header
    (svc_count as u16) + 1
}

fn utils_height(app: &App) -> u16 {
    if app.snapshot.utils.is_empty() {
        0
    } else {
        // 1 group header + 1 row per util container
        (app.snapshot.utils.len() as u16) + 1
    }
}

fn render_log_separator(frame: &mut Frame, app: &App, area: Rect) {
    let svc = app.current_service();
    let scroll = app.log_scroll;
    let label = if scroll > 0 {
        format!("─ Logs [{svc}] +{scroll} ─")
    } else {
        format!("─ Logs [{svc}] ─")
    };
    frame.render_widget(Paragraph::new(Line::from(vec![Span::styled(label, theme::dim())])), area);
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let now = chrono_now();
    let mut spans = vec![
        Span::raw("  "),
        Span::styled("Zion Status", theme::header()),
        Span::raw("  "),
        Span::styled(now, theme::dim()),
    ];
    spans.extend(quota::header_spans(app));
    frame.render_widget(Paragraph::new(Line::from(spans)), area);
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let env = app.current_env();
    let svc = app.current_service();
    let line = Line::from(vec![
        Span::styled("  ↑↓", theme::footer_dim()),
        Span::styled(" nav  ", theme::footer_dim()),
        Span::styled("Enter", theme::footer_key()),
        Span::styled(" menu  ", theme::footer_dim()),
        Span::styled("e", theme::footer_key()),
        Span::styled(format!("[{env}]"), theme::dim()),
        Span::styled("  [/]", theme::footer_key()),
        Span::styled(" scroll  ", theme::footer_dim()),
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
