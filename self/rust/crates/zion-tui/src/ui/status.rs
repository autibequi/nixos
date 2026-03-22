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
            Constraint::Length(sessions_h),  // agents + background (grouped by folder)
            Constraint::Length(services_h),  // dk services (projects)
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
    fn group_height(sessions: &[zion_sdk::status::SessionInfo]) -> usize {
        if sessions.is_empty() { return 0; }
        // Group by folder to know per-folder session count
        let mut folder_counts: std::collections::HashMap<&str, usize> =
            std::collections::HashMap::new();
        for s in sessions {
            let key = if s.mnt_path.is_empty() { s.name.as_str() } else { s.mnt_path.as_str() };
            *folder_counts.entry(key).or_insert(0) += 1;
        }
        // 1 group header
        // Per folder: 1 folder sub-header + 1 counter line + session rows only if >1
        let multi_sessions: usize = folder_counts.values().map(|&n| if n > 1 { n } else { 0 }).sum();
        1 + folder_counts.len() * 2 + multi_sessions
    }
    let agents_h = group_height(&app.snapshot.agents);
    let bg_h = group_height(&app.snapshot.background);
    let between = if agents_h > 0 && bg_h > 0 { 1 } else { 0 };
    ((agents_h + bg_h + between) as u16).max(1)
}

fn dk_services_height(app: &App) -> u16 {
    // 1 group header + DK_SERVICES rows
    (crate::app::DK_SERVICES.len() as u16) + 1
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
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // UTC time: no TZ dependency, no subprocess spawn
    let s = secs % 86400;
    format!("{:02}:{:02}:{:02}", s / 3600, (s % 3600) / 60, s % 60)
}
