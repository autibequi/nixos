//! Quota panel — Claude API usage bars embedded in the header.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;
use leech_sdk::quota;


pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let q = &app.snapshot.quota;
    if q.pct_5h == 0 && q.pct_7d == 0 {
        return;
    }

    let bar_w = 20usize;
    let make_line = |label: &'static str, pct: u8| -> Line<'static> {
        let bar = quota::bar(pct, bar_w);
        Line::from(vec![
            Span::raw("  "),
            Span::styled("claude", theme::dim()),
            Span::raw(" "),
            Span::styled(format!("{label:<3}"), theme::dim()),
            Span::raw(" "),
            Span::styled(bar, theme::pct_color(pct)),
            Span::raw(" "),
            Span::styled(format!("{pct:>3}%", ), theme::pct_color(pct)),
        ])
    };

    frame.render_widget(
        Paragraph::new(vec![make_line("5h", q.pct_5h), make_line("7d", q.pct_7d)]),
        area,
    );
}
