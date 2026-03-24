//! Worktree panel — lists git worktrees across services with action sub-menu.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, Clear, List, ListItem, ListState, Paragraph};
use ratatui::Frame;

use crate::tui::app::{App, WT_MENU_ITEMS};
use crate::tui::theme;

pub fn render(frame: &mut Frame, app: &App) {
    let area = popup_rect(frame.area());

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title(" Worktrees ")
        .title_style(theme::header())
        .border_style(theme::separator());
    let inner = block.inner(area);

    frame.render_widget(Clear, area);
    frame.render_widget(block, area);

    render_list(frame, app, inner);

    if app.wt_menu {
        render_wt_menu(frame, app, area);
    }
}

fn render_list(frame: &mut Frame, app: &App, area: Rect) {
    if app.wt_list.is_empty() {
        frame.render_widget(
            Paragraph::new(Line::from(vec![
                Span::raw("  "),
                Span::styled("no worktrees found", theme::dim()),
            ])),
            area,
        );
        return;
    }

    let list_h = area.height.saturating_sub(1) as usize;
    let total = app.wt_list.len();

    let offset = if app.wt_cursor >= list_h {
        app.wt_cursor + 1 - list_h
    } else {
        0
    };

    let mut lines: Vec<Line> = Vec::new();
    let mut last_svc = "";

    for (i, wt) in app.wt_list.iter().enumerate().skip(offset).take(list_h) {
        // Group header when service changes
        if wt.service != last_svc {
            last_svc = &wt.service;
            if i > offset {
                lines.push(Line::from(""));
            }
            lines.push(Line::from(vec![
                Span::raw("  "),
                Span::styled(&wt.service, theme::header()),
            ]));
        }

        let is_sel = i == app.wt_cursor;
        let marker = if is_sel { "\u{25b6}" } else { " " };
        let mk_style = if is_sel { theme::selected() } else { theme::dim() };
        let nm_style = if is_sel { theme::selected() } else { theme::name() };

        let main_badge = if wt.is_main { " (main)" } else { "" };
        let branch_display = if wt.branch.is_empty() {
            String::new()
        } else {
            format!("  [{}]", wt.branch)
        };

        lines.push(Line::from(vec![
            Span::raw("    "),
            Span::styled(marker, mk_style),
            Span::raw(" "),
            Span::styled(format!("{:<20}", wt.name), nm_style),
            Span::styled(branch_display, theme::dim()),
            Span::styled(main_badge, theme::pending_label()),
        ]));
    }

    // Footer hint
    let scroll_hint = if total > list_h {
        format!("  {}/{}", app.wt_cursor + 1, total)
    } else {
        String::new()
    };
    lines.push(Line::from(vec![
        Span::styled("  \u{2191}\u{2193}", theme::footer_dim()),
        Span::styled(" nav  ", theme::footer_dim()),
        Span::styled("Enter", theme::footer_key()),
        Span::styled(" actions  ", theme::footer_dim()),
        Span::styled("w/Esc", theme::footer_key()),
        Span::styled(" close", theme::footer_dim()),
        Span::styled(scroll_hint, theme::dim()),
    ]));

    frame.render_widget(Paragraph::new(lines), area);
}

fn render_wt_menu(frame: &mut Frame, app: &App, parent: Rect) {
    let wt = app.selected_wt();
    let title = wt
        .map(|w| format!(" {} — {} ", w.service, w.name))
        .unwrap_or_else(|| " action ".into());

    let height = WT_MENU_ITEMS.len() as u16 + 2;
    let width = 24u16;
    let x = parent.x + parent.width.saturating_sub(width + 2);
    let y = parent.y + parent.height.saturating_sub(height + 2);
    let area = Rect::new(x, y, width, height);

    frame.render_widget(Clear, area);

    let items: Vec<ListItem> = WT_MENU_ITEMS
        .iter()
        .map(|(label, _)| ListItem::new(format!("  {label}")))
        .collect();

    let mut state = ListState::default();
    state.select(Some(app.wt_menu_cursor));

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

fn popup_rect(r: Rect) -> Rect {
    let width = (r.width * 4 / 5).min(72).max(50);
    let height = (r.height * 5 / 6).min(30).max(10);
    let x = r.x + r.width.saturating_sub(width) / 2;
    let y = r.y + r.height.saturating_sub(height) / 2;
    Rect::new(x, y, width.min(r.width), height.min(r.height))
}
