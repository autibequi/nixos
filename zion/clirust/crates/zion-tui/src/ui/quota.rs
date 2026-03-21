//! Quota panel — renders Claude API usage bars.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;
use ratatui::style::{Color, Style};

use crate::app::App;
use crate::theme;
use zion_sdk::quota;

/// Render the quota section.
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
