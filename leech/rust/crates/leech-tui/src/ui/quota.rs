//! Quota panel — Claude API usage bars embedded in the header.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;
use leech_cli::quota;

/// Compact inline spans for the header line.
pub fn header_spans(app: &App) -> Vec<Span<'static>> {
    let q = &app.snapshot.quota;
    if q.pct_5h == 0 && q.pct_7d == 0 {
        return vec![];
    }

    let bar_w = 10usize;
    let p5h = q.pct_5h;
    let p7d = q.pct_7d;
    let bar_5h = quota::bar(p5h, bar_w);
    let bar_7d = quota::bar(p7d, bar_w);

    vec![
        Span::raw("  "),
        Span::styled("5h", theme::dim()),
        Span::raw(" "),
        Span::styled(bar_5h, theme::pct_color(p5h)),
        Span::raw(" "),
        Span::styled(format!("{p5h}%"), theme::pct_color(p5h)),
        Span::raw("  "),
        Span::styled("7d", theme::dim()),
        Span::raw(" "),
        Span::styled(bar_7d, theme::pct_color(p7d)),
        Span::raw(" "),
        Span::styled(format!("{p7d}%"), theme::pct_color(p7d)),
    ]
}

#[allow(dead_code)]
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let q = &app.snapshot.quota;
    if q.pct_5h == 0 && q.pct_7d == 0 {
        frame.render_widget(
            Paragraph::new(Line::from(vec![
                Span::raw("  "),
                Span::styled("quota: n/a", theme::dim()),
            ])),
            area,
        );
        return;
    }

    let bar_w = 20usize;
    let make_line = |label: &'static str, pct: u8| -> Line<'static> {
        let bar = quota::bar(pct, bar_w);
        Line::from(vec![
            Span::raw("  "),
            Span::styled(format!("{label:<3}"), theme::dim()),
            Span::raw(" "),
            Span::styled(bar, theme::pct_color(pct)),
            Span::raw(" "),
            Span::styled(format!("{pct}%"), theme::pct_color(pct)),
        ])
    };

    frame.render_widget(
        Paragraph::new(vec![make_line("5h", q.pct_5h), make_line("7d", q.pct_7d)]),
        area,
    );
}
