//! Agent panel popup — all configured agents sorted by next execution,
//! with an action sub-menu (Run / Phone / Status).

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, Clear, List, ListItem, ListState, Paragraph};
use ratatui::Frame;

use crate::app::{App, AGENT_MENU_ITEMS};
use crate::theme;

pub fn render(frame: &mut Frame, app: &App) {
    let (area, pods_area) = popup_rects(frame.area());

    if !app.agent_log.is_empty() {
        render_log_view(frame, app, area);
        render_pods_box(frame, app, pods_area);
        return;
    }

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title(" Agents ")
        .title_style(theme::header())
        .border_style(theme::separator());
    let inner = block.inner(area);

    frame.render_widget(Clear, area);
    frame.render_widget(block, area);

    render_list(frame, app, inner);

    if app.agent_menu {
        render_agent_menu(frame, app, area);
    }

    render_pods_box(frame, app, pods_area);
}

// ── Agent list ────────────────────────────────────────────────────────────────

fn render_list(frame: &mut Frame, app: &App, area: Rect) {
    if app.agent_list.is_empty() {
        frame.render_widget(
            Paragraph::new(Line::from(vec![
                Span::raw("  "),
                Span::styled("no agent cards found", theme::dim()),
            ])),
            area,
        );
        return;
    }

    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();

    // Reserve 1 line for footer
    let list_h  = area.height.saturating_sub(1) as usize;
    let total   = app.agent_list.len();

    // Scroll to keep cursor visible
    let offset = if app.agent_cursor >= list_h {
        app.agent_cursor + 1 - list_h
    } else {
        0
    };

    let mut lines: Vec<Line> = app.agent_list.iter().enumerate()
        .skip(offset)
        .take(list_h)
        .map(|(i, a)| {
            let is_sel     = i == app.agent_cursor;
            let marker     = if is_sel { "\u{25b6}" } else { " " };
            let mk_style   = if is_sel { theme::selected() } else { theme::dim() };
            let nm_style   = if is_sel { theme::selected() } else { theme::name() };

            // Status icon: task pending = green dot, on-demand = hollow, else dim dot
            let (icon, ic_style) = if a.next_task_ts.is_some() {
                ("\u{25cf}", theme::up_icon())
            } else if a.clock_mins.is_some() {
                ("\u{25cf}", theme::dim())
            } else {
                ("\u{25cb}", theme::dim())
            };

            // Schedule column
            let sched = schedule_str(a, now);

            // Task badge
            let badge = if a.task_count > 0 {
                format!(" [{}]", a.task_count)
            } else {
                String::new()
            };

            Line::from(vec![
                Span::raw("  "),
                Span::styled(marker,                      mk_style),
                Span::raw(" "),
                Span::styled(icon,                        ic_style),
                Span::raw(" "),
                Span::styled(format!("{:<14}", a.name),   nm_style),
                Span::styled(format!(" {:<6}", a.model),  theme::dim()),
                Span::raw("  "),
                Span::styled(format!("{:<22}", sched),    theme::uptime()),
                Span::styled(badge,                       theme::pending_label()),
            ])
        })
        .collect();

    // Footer hint
    let scroll_hint = if total > list_h {
        format!("  {}/{}", app.agent_cursor + 1, total)
    } else {
        String::new()
    };
    lines.push(Line::from(vec![
        Span::styled("  \u{2191}\u{2193}", theme::footer_dim()),
        Span::styled(" nav  ", theme::footer_dim()),
        Span::styled("Enter", theme::footer_key()),
        Span::styled(" actions  ", theme::footer_dim()),
        Span::styled("a/Esc", theme::footer_key()),
        Span::styled(" close", theme::footer_dim()),
        Span::styled(scroll_hint, theme::dim()),
    ]));

    frame.render_widget(Paragraph::new(lines), area);
}

// ── Action sub-menu ───────────────────────────────────────────────────────────

fn render_agent_menu(frame: &mut Frame, app: &App, parent: Rect) {
    let name = app.selected_agent_name().unwrap_or("agent");
    let title = format!(" {} ", name);

    let height = AGENT_MENU_ITEMS.len() as u16 + 2;
    let width  = 22u16;
    // Place bottom-right inside parent popup
    let x = parent.x + parent.width.saturating_sub(width + 2);
    let y = parent.y + parent.height.saturating_sub(height + 2);
    let area = Rect::new(x, y, width, height);

    frame.render_widget(Clear, area);

    let items: Vec<ListItem> = AGENT_MENU_ITEMS
        .iter()
        .map(|(label, _)| ListItem::new(format!("  {label}")))
        .collect();

    let mut state = ListState::default();
    state.select(Some(app.agent_menu_cursor));

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

// ── Helpers ───────────────────────────────────────────────────────────────────

fn schedule_str(a: &crate::app::AgentInfo, now: u64) -> String {
    if let Some(ts) = a.next_task_ts {
        if ts <= now {
            "overdue".into()
        } else {
            let diff = ts - now;
            format!("in {}", fmt_duration(diff))
        }
    } else if let Some(m) = a.clock_mins {
        if m < 60 {
            format!("every {m}min")
        } else {
            format!("every {}h", m / 60)
        }
    } else {
        "on-demand".into()
    }
}

fn fmt_duration(secs: u64) -> String {
    let h   = secs / 3600;
    let m   = (secs % 3600) / 60;
    if h > 0 { format!("{h}h{m:02}min") } else { format!("{m}min") }
}

// ── Agent log view ────────────────────────────────────────────────────────────

fn render_log_view(frame: &mut Frame, app: &App, area: Rect) {
    let title = format!(" {} — log ", app.agent_log_name);
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title(title)
        .title_style(theme::header())
        .border_style(theme::separator());
    let inner = block.inner(area);

    frame.render_widget(Clear, area);
    frame.render_widget(block, area);

    let mut lines: Vec<Line> = Vec::new();

    // Header
    lines.push(Line::from(vec![
        Span::styled("  ", theme::dim()),
        Span::styled(format!("{:<14}", "started"),  theme::dim()),
        Span::styled(format!("  {:<8}", "dur"),     theme::dim()),
        Span::styled(format!("  {:<5}", "st"),      theme::dim()),
        Span::styled("  topic", theme::dim()),
    ]));

    if app.agent_log.is_empty() {
        lines.push(Line::from(vec![
            Span::raw("  "),
            Span::styled("no log entries yet", theme::dim()),
        ]));
    } else {
        let max_rows = inner.height.saturating_sub(3) as usize; // header + footer
        for entry in app.agent_log.iter().take(max_rows) {
            let (st_span, st_style) = match entry.status.as_str() {
                "ok"      => ("ok  ", theme::up_icon()),
                "fail"    => ("fail", theme::down_icon()),
                "timeout" => ("to  ", theme::dim()),
                other     => (other, theme::dim()),
            };
            lines.push(Line::from(vec![
                Span::raw("  "),
                Span::styled(format!("{:<14}", entry.ts_short), theme::uptime()),
                Span::raw("  "),
                Span::styled(format!("{:<8}", entry.duration),  theme::dim()),
                Span::raw("  "),
                Span::styled(format!("{:<4}", st_span),         st_style),
                Span::raw("  "),
                Span::styled(entry.card.clone(),                theme::name()),
            ]));
        }
    }

    // Footer hint
    lines.push(Line::from(vec![
        Span::styled("  Esc", theme::footer_key()),
        Span::styled(" / ", theme::footer_dim()),
        Span::styled("q", theme::footer_key()),
        Span::styled(" close", theme::footer_dim()),
    ]));

    frame.render_widget(Paragraph::new(lines), inner);
}

/// Returns (main_area, pods_area).
/// pods_area is a 3-line box immediately below the main popup.
fn popup_rects(r: Rect) -> (Rect, Rect) {
    const PODS_H: u16 = 3;
    const GAP:    u16 = 1;
    let width   = (r.width  * 4 / 5).min(72).max(50);
    let total_h = (r.height * 5 / 6).min(36 + PODS_H + GAP).max(12);
    let main_h  = total_h.saturating_sub(PODS_H + GAP);
    let x = r.x + r.width.saturating_sub(width) / 2;
    let y = r.y + r.height.saturating_sub(total_h) / 2;
    let main  = Rect::new(x, y, width.min(r.width), main_h.min(r.height));
    let pods_y = y + main_h + GAP;
    let pods  = Rect::new(x, pods_y, width.min(r.width),
        PODS_H.min(r.height.saturating_sub(pods_y.saturating_sub(r.y))));
    (main, pods)
}

// ── Pods summary box ──────────────────────────────────────────────────────────

fn render_pods_box(frame: &mut Frame, app: &App, area: Rect) {
    if area.height == 0 { return; }

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title(" pods ")
        .title_style(theme::dim())
        .border_style(theme::separator());
    let inner = block.inner(area);

    frame.render_widget(Clear, area);
    frame.render_widget(block, area);

    // Collect running pods grouped by mnt_path, sum session_count
    let mut pods: Vec<(String, usize)> = {
        let mut map: std::collections::HashMap<String, usize> =
            std::collections::HashMap::new();
        for s in app.snapshot.agents.iter().chain(app.snapshot.background.iter()) {
            if !s.is_up { continue; }
            let key = pod_short_name(&s.mnt_path, &s.name);
            *map.entry(key).or_insert(0) += s.session_count.max(1);
        }
        let mut v: Vec<_> = map.into_iter().collect();
        v.sort_by(|a, b| a.0.cmp(&b.0));
        v
    };

    let line = if pods.is_empty() {
        Line::from(vec![
            Span::raw("  "),
            Span::styled("no running pods", theme::dim()),
        ])
    } else {
        let pod_count = pods.len();
        let total_inst: usize = pods.iter().map(|(_, n)| n).sum();
        let mut spans: Vec<Span> = vec![
            Span::styled(
                format!("  {} pod{}  {} inst  •  ",
                    pod_count,
                    if pod_count == 1 { "" } else { "s" },
                    total_inst),
                theme::dim()),
        ];
        for (i, (name, count)) in pods.iter().enumerate() {
            if i > 0 { spans.push(Span::styled("  ", theme::dim())); }
            spans.push(Span::styled(name.clone(), theme::name()));
            spans.push(Span::styled(format!(" ×{count}"), theme::uptime()));
        }
        Line::from(spans)
    };

    frame.render_widget(Paragraph::new(vec![line]), inner);
}

fn pod_short_name(mnt_path: &str, fallback: &str) -> String {
    if mnt_path.is_empty() {
        // use last segment of container name
        return fallback.rsplit('-').next().unwrap_or(fallback).to_string();
    }
    // ~/projects/monolito → "monolito"
    mnt_path.rsplit('/').next().unwrap_or(mnt_path).to_string()
}
