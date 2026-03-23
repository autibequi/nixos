//! Top-level status dashboard: header, sessions, services, utils, logs, footer.

use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use super::{logs, popup, quota, services, sessions, utils};
use crate::app::App;
use crate::theme;

/// Render the full status dashboard.
pub fn render(frame: &mut Frame, app: &App) {
    let services_h = dk_services_height(app);
    let utils_h    = utils_height(app);

    // Cap sessions_h so logs always gets at least MIN_LOGS content lines
    // + 1 for the Block top border.
    const MIN_LOGS: u16 = 5;
    let fixed = 1u16 + services_h + utils_h + 1 + MIN_LOGS + 1;
    let sessions_h = sessions_height(app).min(frame.area().height.saturating_sub(fixed));

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),           // header
            Constraint::Length(sessions_h),  // agents + background
            Constraint::Length(services_h),  // dk services
            Constraint::Length(utils_h),     // utils
            Constraint::Min(0),              // logs (Block with top border = separator)
            Constraint::Length(1),           // footer
        ])
        .split(frame.area());

    render_header(frame, app, chunks[0]);
    sessions::render(frame, app, chunks[1]);
    services::render(frame, app, chunks[2]);
    utils::render(frame, app, chunks[3]);
    logs::render(frame, app, chunks[4]);
    render_footer(frame, app, chunks[5]);

    popup::render(frame, app);
}

fn sessions_height(app: &App) -> u16 {
    fn group_height(sessions: &[leech_sdk::status::SessionInfo]) -> usize {
        if sessions.is_empty() { return 0; }
        let mut folder_counts: std::collections::HashMap<&str, usize> =
            std::collections::HashMap::new();
        for s in sessions {
            let key = if s.mnt_path.is_empty() { s.name.as_str() } else { s.mnt_path.as_str() };
            *folder_counts.entry(key).or_insert(0) += 1;
        }
        let multi_sessions: usize = folder_counts.values()
            .map(|&n| if n > 1 { n } else { 0 }).sum();
        1 + folder_counts.len() * 2 + multi_sessions
    }
    let agents_h = group_height(&app.snapshot.agents);
    let bg_h     = group_height(&app.snapshot.background);
    let between  = if agents_h > 0 && bg_h > 0 { 1 } else { 0 };
    ((agents_h + bg_h + between) as u16).max(1)
}

fn dk_services_height(_app: &App) -> u16 {
    let dep_rows: usize = crate::app::DK_SERVICES
        .iter()
        .map(|&svc| services::service_dep_count(svc))
        .sum();
    (crate::app::DK_SERVICES.len() as u16) + 1 + dep_rows as u16
}

fn utils_height(app: &App) -> u16 {
    if app.snapshot.utils.is_empty() { 0 }
    else { (app.snapshot.utils.len() as u16) + 1 }
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let now = utc_time_str();
    let mut spans = vec![
        Span::raw("  "),
        Span::styled("Leech Status", theme::header()),
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
        Span::styled("  scroll", theme::footer_dim()),
        Span::styled(" mouse/[/]", theme::footer_key()),
        Span::styled("  ", theme::footer_dim()),
        Span::styled("q", theme::footer_key()),
        Span::styled(" quit  ", theme::footer_dim()),
        Span::styled(format!("[{svc}]"), theme::dim()),
    ]);
    frame.render_widget(Paragraph::new(line), area);
}

fn utc_time_str() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let s = secs % 86400;
    format!("{:02}:{:02}:{:02} UTC", s / 3600, (s % 3600) / 60, s % 60)
}
