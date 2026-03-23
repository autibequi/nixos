//! Overlay popups: action menu (rounded borders) and error dialog.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, Clear, List, ListItem, ListState, Paragraph};
use ratatui::Frame;

use crate::app::{App, AppMode, MENU_ITEMS};
use crate::theme;

pub fn render(frame: &mut Frame, app: &App) {
    match &app.mode {
        AppMode::Menu        => render_menu(frame, app),
        AppMode::Error(msg)  => render_error(frame, &msg.clone()),
        AppMode::Normal      => {}
    }
}

fn render_menu(frame: &mut Frame, app: &App) {
    let svc   = app.current_service();
    let env   = app.current_env();
    let title = format!(" {svc} [{env}] ");

    let height = (MENU_ITEMS.len() as u16) + 2;
    let width  = 26u16;
    let area   = centered_rect(width, height, frame.area());

    frame.render_widget(Clear, area);

    let items: Vec<ListItem> = MENU_ITEMS
        .iter()
        .map(|(label, _)| ListItem::new(format!("  {label}")))
        .collect();

    let mut state = ListState::default();
    state.select(Some(app.menu_cursor));

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .title(title)
                .title_style(theme::header())
                .border_style(theme::separator()),
        )
        .highlight_style(theme::selected())
        .highlight_symbol("> ");

    frame.render_stateful_widget(list, area, &mut state);
}

fn render_error(frame: &mut Frame, msg: &str) {
    let lines: Vec<&str> = msg.lines().collect();
    let height = (lines.len() as u16 + 2).max(4);
    let width  = 64u16.min(frame.area().width.saturating_sub(4));
    let area   = centered_rect(width, height, frame.area());

    frame.render_widget(Clear, area);

    let text_lines: Vec<Line> = lines
        .iter()
        .map(|l| Line::from(vec![Span::raw(format!(" {l}"))]))
        .collect();

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title(" Error ")
        .title_style(theme::down_icon())
        .border_style(theme::down_icon());

    frame.render_widget(Paragraph::new(text_lines).block(block), area);
}

fn centered_rect(width: u16, height: u16, r: Rect) -> Rect {
    let x = r.x + r.width.saturating_sub(width) / 2;
    let y = r.y + r.height.saturating_sub(height) / 2;
    Rect::new(x, y, width.min(r.width), height.min(r.height))
}
