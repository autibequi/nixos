//! Logs panel — tail of the selected service's log lines, scrollable.

use ratatui::layout::Rect;
use ratatui::style::{Color, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;

/// Render the logs tail section for the currently selected service.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let svc = app.current_service();

    // Filter to only entries for the selected service
    let entries: Vec<&zion_sdk::logs::LogEntry> = app
        .snapshot
        .logs
        .iter()
        .filter(|e| e.service == svc)
        .collect();

    if entries.is_empty() {
        let line = Line::from(vec![
            Span::raw("  "),
            Span::styled("no logs", theme::dim()),
        ]);
        frame.render_widget(Paragraph::new(vec![line]), area);
        return;
    }

    let max_lines = area.height as usize;
    let total = entries.len();

    // scroll=0 → bottom, scroll=N → N lines up from bottom
    let scroll_clamped = app.log_scroll.min(total.saturating_sub(1));
    let end = total.saturating_sub(scroll_clamped);
    let start = end.saturating_sub(max_lines);

    let lines: Vec<Line> = entries[start..end]
        .iter()
        .map(|entry| {
            let (level, line_text) = detect_level(&entry.line);
            let level_style = level_style(level);
            Line::from(vec![
                Span::raw("  "),
                Span::styled(format!("{:<5}", level), level_style),
                Span::raw(" "),
                Span::styled(line_text.to_string(), theme::dim()),
            ])
        })
        .collect();

    frame.render_widget(Paragraph::new(lines), area);
}

fn detect_level(line: &str) -> (&'static str, &str) {
    let upper = line.to_uppercase();
    if upper.contains("ERROR") || upper.contains("FATAL") || upper.contains("CRIT") {
        ("ERR", line)
    } else if upper.contains("WARN") {
        ("WARN", line)
    } else if upper.contains("DEBUG") || upper.contains("TRACE") {
        ("DBG", line)
    } else {
        ("INFO", line)
    }
}

fn level_style(level: &str) -> ratatui::style::Style {
    match level {
        "ERR"  => Style::default().fg(Color::Red),
        "WARN" => Style::default().fg(Color::Yellow),
        "DBG"  => Style::default().fg(Color::DarkGray),
        _      => Style::default().fg(Color::Green),
    }
}
