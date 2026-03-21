//! Logs panel — tail of recent service log lines.

use ratatui::layout::Rect;
use ratatui::style::{Color, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;

/// Render the logs tail section.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    if app.snapshot.logs.is_empty() {
        let line = Line::from(vec![
            Span::raw("  "),
            Span::styled("no logs", theme::dim()),
        ]);
        frame.render_widget(Paragraph::new(vec![line]), area);
        return;
    }

    // How many lines fit in the area
    let max_lines = area.height as usize;
    let entries = &app.snapshot.logs;
    let skip = entries.len().saturating_sub(max_lines);

    let lines: Vec<Line> = entries[skip..]
        .iter()
        .map(|entry| {
            let svc_color = svc_color(&entry.service);
            let (level, line_rest) = detect_level(&entry.line);
            let level_style = level_style(level);

            Line::from(vec![
                Span::raw("  "),
                Span::styled(format!("{:<14}", entry.service), Style::default().fg(svc_color)),
                Span::raw(" "),
                Span::styled(format!("{:<5}", level), level_style),
                Span::raw(" "),
                Span::styled(line_rest.to_string(), theme::dim()),
            ])
        })
        .collect();

    frame.render_widget(Paragraph::new(lines), area);
}

fn svc_color(svc: &str) -> Color {
    match svc {
        "monolito"     => Color::Cyan,
        "bo-container" => Color::Magenta,
        "front-student"=> Color::Yellow,
        "host"         => Color::Blue,
        _              => Color::White,
    }
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
