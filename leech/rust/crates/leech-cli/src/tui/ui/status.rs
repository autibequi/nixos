//! Top-level status dashboard: header, sessions, services, utils, logs, footer.

use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use super::{logs, popup, quota, services, sessions, utils};
use crate::tui::app::App;
use crate::tui::theme;

/// Render the full status dashboard.
pub fn render(frame: &mut Frame, app: &App) {
    let services_h = dk_services_height(app);
    let utils_h    = utils_height(app);

    // Cap sessions_h so logs always gets at least MIN_LOGS content lines
    // + 2 for the Block top+bottom border (Borders::ALL).
    const MIN_LOGS: u16 = 5;
    let fixed = 1u16 + services_h + utils_h + 2 + MIN_LOGS + 1;
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
    fn group_height(sessions: &[crate::status::SessionInfo]) -> usize {
        if sessions.is_empty() { return 0; }
        let mut folder_set = std::collections::HashSet::new();
        for s in sessions {
            let key = if s.mnt_path.is_empty() { s.name.as_str() } else { s.mnt_path.as_str() };
            folder_set.insert(key);
        }
        // 1 group-header + 2 rows per folder (folder-header + stats/count line)
        1 + folder_set.len() * 2
    }
    let agents_h = group_height(&app.snapshot.agents);
    let bg_h     = group_height(&app.snapshot.background);
    let between  = if agents_h > 0 && bg_h > 0 { 1 } else { 0 };
    ((agents_h + bg_h + between) as u16).max(1)
}

fn dk_services_height(_app: &App) -> u16 {
    let dep_rows: usize = crate::tui::app::DK_SERVICES
        .iter()
        .map(|&svc| services::service_dep_count(svc))
        .sum();
    (crate::tui::app::DK_SERVICES.len() as u16) + 1 + dep_rows as u16
}

fn utils_height(app: &App) -> u16 {
    if app.snapshot.utils.is_empty() { 0 }
    else { (app.snapshot.utils.len() as u16) + 1 }
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let now = utc_time_str();
    let elapsed = app.snapshot_at.elapsed().as_secs();
    let (stale_text, stale_style) = if elapsed >= 15 {
        (format!(" [stale {}s]", elapsed), Style::default().fg(Color::Rgb(243, 139, 168))) // red
    } else if elapsed >= 5 {
        (format!(" ⟳ {}s", elapsed), Style::default().fg(Color::Rgb(249, 226, 175))) // yellow
    } else {
        (format!(" ⟳ {}s", elapsed), theme::dim().fg(Color::Rgb(108, 112, 134))) // dim
    };
    let left: Vec<Span<'static>> = vec![
        Span::raw("  "),
        Span::styled("Leech Status", theme::header()),
        Span::raw("  "),
        Span::styled(now, theme::dim()),
        Span::styled(stale_text, stale_style),
    ];
    let right = quota::header_spans(app);
    if right.is_empty() {
        frame.render_widget(Paragraph::new(Line::from(left)), area);
        return;
    }
    let left_w: usize = left.iter().map(|s| s.content.chars().count()).sum();
    let right_w = quota::header_spans_width(app);
    let pad = (area.width as usize).saturating_sub(left_w + right_w);
    let mut spans = left;
    spans.push(Span::raw(" ".repeat(pad)));
    spans.extend(right);
    frame.render_widget(Paragraph::new(Line::from(spans)), area);
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let env = app.current_env();
    let svc = app.current_service();
    let dbg_indicator = if app.is_debug() {
        Span::styled(" [dbg]", Style::default().fg(Color::Rgb(249, 226, 175)))
    } else {
        Span::raw("")
    };
    let line = Line::from(vec![
        Span::styled("  ↑↓", theme::footer_dim()),
        Span::styled(" nav  ", theme::footer_dim()),
        Span::styled("Enter", theme::footer_key()),
        Span::styled(" menu  ", theme::footer_dim()),
        Span::styled("a", theme::footer_key()),
        Span::styled(" agents  ", theme::footer_dim()),
        Span::styled("e", theme::footer_key()),
        Span::styled(format!("[{env}]"), theme::dim()),
        Span::styled("  d", theme::footer_key()),
        Span::styled(" debug", theme::footer_dim()),
        dbg_indicator,
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
