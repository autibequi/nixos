//! Quota panel — renders Claude API usage bars.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;
use ratatui::style::{Color, Style};

use crate::app::App;
use crate::theme;
use leech_sdk::quota;

/// Compact inline spans for embedding in the header line.
/// Returns empty vec when quota is n/a.
pub fn header_spans(app: &App) -> Vec<Span<'static>> {
    let q = &app.snapshot.quota;
    if q.pct_5h == 0 && q.pct_7d == 0 {
        return vec![];
    }

    let bar_w = 10usize;
    let pct_color = |pct: u8| -> ratatui::style::Style {
        if pct >= 85 {
            ratatui::style::Style::default().fg(Color::Red)
        } else if pct >= 70 {
            ratatui::style::Style::default().fg(Color::Yellow)
        } else {
            ratatui::style::Style::default().fg(Color::Green)
        }
    };

    let bar_5h = quota::bar(q.pct_5h, bar_w);
    let bar_7d = quota::bar(q.pct_7d, bar_w);
    let p5h = q.pct_5h;
    let p7d = q.pct_7d;

    vec![
        Span::raw("  "),
        Span::styled("5h", theme::dim()),
        Span::raw(" "),
        Span::styled(bar_5h, pct_color(p5h)),
        Span::raw(" "),
        Span::styled(format!("{p5h}%"), pct_color(p5h)),
        Span::raw("  "),
        Span::styled("7d", theme::dim()),
        Span::raw(" "),
        Span::styled(bar_7d, pct_color(p7d)),
        Span::raw(" "),
        Span::styled(format!("{p7d}%"), pct_color(p7d)),
    ]
}

/// Render the quota section (standalone, kept for compatibility).
#[allow(dead_code)]
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let q = &app.snapshot.quota;

    if q.pct_5h == 0 && q.pct_7d == 0 {
        let line = Line::from(vec![
            Span::raw("  "),
            Span::styled("quota: n/a", theme::dim()),
        ]);
        frame.render_widget(Paragraph::new(vec![line]), area);
        return;
    }

    let bar_w = 20usize;

    let pct_color = |pct: u8| -> Style {
        if pct >= 85 {
            Style::default().fg(Color::Red)
        } else if pct >= 70 {
            Style::default().fg(Color::Yellow)
        } else {
            Style::default().fg(Color::Green)
        }
    };

    let make_line = |label: &'static str, pct: u8| -> Line<'static> {
        let bar = quota::bar(pct, bar_w);
        Line::from(vec![
            Span::raw("  "),
            Span::styled(format!("{label:<3}"), theme::dim()),
            Span::raw(" "),
            Span::styled(bar, pct_color(pct)),
            Span::raw(" "),
            Span::styled(format!("{pct}%"), pct_color(pct)),
        ])
    };

    let lines = vec![
        make_line("5h", q.pct_5h),
        make_line("7d", q.pct_7d),
    ];

    frame.render_widget(Paragraph::new(lines), area);
}
