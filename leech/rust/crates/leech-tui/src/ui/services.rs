//! Render the dockerized-services panel with status, uptime, CPU, and memory.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::{App, DK_SERVICES};
use crate::theme;

/// Spinner frames for pending actions (◐◓◑◒ cycling ~1s).
const SPINNER: &[&str] = &["◐", "◓", "◑", "◒"];


/// Dep container suffixes for each service (shown as sub-rows).
fn service_dep_names(svc: &str) -> &'static [&'static str] {
    match svc {
        "monolito" => &["postgres", "redis", "localstack"],
        _ => &[],
    }
}

/// Number of dep rows for a given service (used by height calculation).
pub fn service_dep_count(svc: &str) -> usize {
    service_dep_names(svc).len()
}

/// Render dockerized services panel.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    if app.snapshot.dk_services.is_empty() {
        // Still show the service list from navigation
        lines.push(Line::from(vec![
            Span::styled("\u{25cb}", theme::down_icon()),
            Span::raw(" "),
            Span::styled("projects", theme::group_label()),
        ]));

        for (i, &svc) in DK_SERVICES.iter().enumerate() {
            let is_selected = i == app.cursor_idx;
            let marker = if is_selected { "\u{25b6}" } else { " " };
            let style = if is_selected {
                theme::selected()
            } else {
                theme::dim()
            };

            lines.push(Line::from(vec![
                Span::raw("   "),
                Span::styled(marker.to_string(), style),
                Span::raw(" "),
                Span::styled("\u{25cb}", theme::down_icon()),
                Span::raw(" "),
                Span::styled(format!("{svc:<20}"), style),
                Span::raw(" "),
                Span::styled("stop ", theme::dim()),
            ]));

            for (di, &dep) in service_dep_names(svc).iter().enumerate() {
                let is_last = di == service_dep_names(svc).len() - 1;
                let tree = if is_last { "└─" } else { "├─" };
                lines.push(Line::from(vec![
                    Span::raw("        "),
                    Span::styled(tree, theme::dim()),
                    Span::raw(" "),
                    Span::styled("\u{25cb}", theme::down_icon()),
                    Span::raw(" "),
                    Span::styled(format!("{dep:<14}"), theme::dim()),
                    Span::raw(" "),
                    Span::styled("stopped", theme::uptime()),
                ]));
            }

        }
    } else {
        let any_up = app.snapshot.dk_services.iter().any(|s| s.is_up);
        let icon = if any_up { "\u{25cf}" } else { "\u{25cb}" };
        let icon_style = if any_up {
            theme::up_icon()
        } else {
            theme::down_icon()
        };

        lines.push(Line::from(vec![
            Span::styled(icon, icon_style),
            Span::raw(" "),
            Span::styled("projects", theme::group_label()),
        ]));

        for (i, &svc) in DK_SERVICES.iter().enumerate() {
            let is_selected = i == app.cursor_idx;
            let marker = if is_selected { "\u{25b6}" } else { " " };

            // Find matching dk_service (main app container: leech-dk-{svc}-app)
            let app_container = format!("leech-dk-{svc}-app");
            let dk = app
                .snapshot
                .dk_services
                .iter()
                .find(|d| d.name == app_container);

            // Check if there's a pending action for this service
            let is_pending = matches!(&app.last_action, Some((idx, _)) if *idx == i);

            let name_style = if is_selected {
                theme::selected()
            } else {
                theme::name()
            };
            let marker_style = if is_selected {
                theme::selected()
            } else {
                theme::dim()
            };

            if is_pending {
                let frame = SPINNER[(app.render_tick as usize / 2) % SPINNER.len()];
                let action_label = app
                    .last_action
                    .as_ref()
                    .map(|(_, s)| s.as_str())
                    .unwrap_or("…");
                let spans = vec![
                    Span::raw("   "),
                    Span::styled(marker.to_string(), marker_style),
                    Span::raw(" "),
                    Span::styled(frame, theme::pending_icon()),
                    Span::raw(" "),
                    Span::styled(format!("{svc:<20}"), name_style),
                    Span::raw(" "),
                    Span::styled(format!("{:<5}", "…"), theme::pending_icon()),
                    Span::raw("  "),
                    Span::styled(action_label.to_string(), theme::pending_label()),
                ];
                lines.push(Line::from(spans));
                continue;
            }

            let (status_icon, status_style, status_text, cpu, mem) = if let Some(d) = dk {
                if d.is_up {
                    (
                        "\u{25cf}",
                        theme::up_icon(),
                        format_uptime(&d.status),
                        d.cpu.clone(),
                        d.mem.clone(),
                    )
                } else {
                    (
                        "\u{25cb}",
                        theme::down_icon(),
                        "stopped".to_string(),
                        String::new(),
                        String::new(),
                    )
                }
            } else {
                (
                    "\u{25cb}",
                    theme::down_icon(),
                    "stopped".to_string(),
                    String::new(),
                    String::new(),
                )
            };

            let mut spans = vec![
                Span::raw("   "),
                Span::styled(marker.to_string(), marker_style),
                Span::raw(" "),
                Span::styled(status_icon, status_style),
                Span::raw(" "),
                Span::styled(format!("{svc:<20}"), name_style),
                Span::raw(" "),
                Span::styled(format!("{status_text:<5}"), theme::uptime()),
            ];

            if !cpu.is_empty() {
                let cpu_pct = parse_pct(&cpu);
                let cpu_bar = mini_bar(cpu_pct, 6);
                let cpu_style = pct_color(cpu_pct);
                spans.push(Span::raw("  "));
                spans.push(Span::styled(cpu_bar, cpu_style));
                spans.push(Span::styled(format!(" {cpu:<6}", cpu = cpu.trim()), theme::cpu()));

                let mem_short = mem
                    .replace("MiB", "M")
                    .replace("GiB", "G")
                    .replace(" / ", "/");
                // Parse used/total for memory bar
                let mem_bar = mem_bar_from_str(&mem);
                spans.push(Span::raw(" "));
                spans.push(Span::styled(mem_bar, theme::mem()));
                spans.push(Span::styled(format!(" {mem_short}"), theme::dim()));
            }

            lines.push(Line::from(spans));

            // Dep sub-rows (postgres, redis, localstack, …)
            let deps = service_dep_names(svc);
            for (di, &dep) in deps.iter().enumerate() {
                let is_last = di == deps.len() - 1;
                let tree = if is_last { "└─" } else { "├─" };
                let dep_container = format!("leech-dk-{svc}-{dep}");
                let dep_info = app.snapshot.dk_services.iter().find(|d| d.name == dep_container);
                let (dep_icon, dep_style, dep_status, dep_cpu, dep_mem) = match dep_info {
                    Some(d) if d.is_up => (
                        "\u{25cf}", theme::up_icon(), format_uptime(&d.status),
                        d.cpu.clone(), d.mem.clone(),
                    ),
                    _ => ("\u{25cb}", theme::down_icon(), "stopped".to_string(), String::new(), String::new()),
                };
                let mut dep_spans = vec![
                    Span::raw("        "),
                    Span::styled(tree, theme::dim()),
                    Span::raw(" "),
                    Span::styled(dep_icon, dep_style),
                    Span::raw(" "),
                    Span::styled(format!("{dep:<14}"), theme::dim()),
                    Span::raw(" "),
                    Span::styled(format!("{dep_status:<5}"), theme::uptime()),
                ];
                if !dep_cpu.is_empty() {
                    let cpu_pct = parse_pct(&dep_cpu);
                    let cpu_bar = mini_bar(cpu_pct, 6);
                    let cpu_style = pct_color(cpu_pct);
                    dep_spans.push(Span::raw("  "));
                    dep_spans.push(Span::styled(cpu_bar, cpu_style));
                    dep_spans.push(Span::styled(format!(" {:<6}", dep_cpu.trim()), theme::cpu()));
                    let mem_short = dep_mem.replace("MiB", "M").replace("GiB", "G").replace(" / ", "/");
                    let mem_bar = mem_bar_from_str(&dep_mem);
                    dep_spans.push(Span::raw(" "));
                    dep_spans.push(Span::styled(mem_bar, theme::mem()));
                    dep_spans.push(Span::styled(format!(" {mem_short}"), theme::dim()));
                }
                lines.push(Line::from(dep_spans));
            }

        }

    }

    let widget = Paragraph::new(lines);
    frame.render_widget(widget, area);
}

/// Parse a CPU percentage string like "21.07%" → 21.
fn parse_pct(s: &str) -> u8 {
    s.trim()
        .trim_end_matches('%')
        .parse::<f32>()
        .map(|f| f as u8)
        .unwrap_or(0)
}

/// Color style based on percentage thresholds.
fn pct_color(pct: u8) -> ratatui::style::Style {
    use ratatui::style::{Color, Style};
    if pct >= 80 {
        Style::default().fg(Color::Red)
    } else if pct >= 50 {
        Style::default().fg(Color::Yellow)
    } else {
        Style::default().fg(Color::Green)
    }
}

/// Build a compact `width`-char bar: `███░░░`
fn mini_bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

/// Parse "1.453GiB / 4GiB" → percentage and render as a bar.
fn mem_bar_from_str(mem: &str) -> String {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() != 2 {
        return String::new();
    }
    let used = parse_bytes(parts[0].trim());
    let total = parse_bytes(parts[1].trim());
    if total == 0 {
        return String::new();
    }
    let pct = ((used * 100) / total).min(100) as u8;
    mini_bar(pct, 6)
}

/// Parse a bytes string like "1.453GiB", "717.8MiB" → bytes.
fn parse_bytes(s: &str) -> u64 {
    let s = s.replace("GiB", "G").replace("MiB", "M").replace("kB", "K");
    if let Some(v) = s.strip_suffix('G') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0 * 1024.0) as u64;
    }
    if let Some(v) = s.strip_suffix('M') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0) as u64;
    }
    if let Some(v) = s.strip_suffix('K') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    s.trim().parse::<u64>().unwrap_or(0)
}

/// Render the leeches section — Leech instances attached to a project folder.
pub fn render_leeches(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    let any_up = app.snapshot.leech.iter().any(|l| l.is_up);
    let icon = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let icon_style = if any_up { theme::up_icon() } else { theme::down_icon() };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled("leeches", theme::group_label()),
    ]));

    for leech in &app.snapshot.leech {
        let ident = if !leech.mnt_path.is_empty() {
            shorten_path(&leech.mnt_path)
        } else {
            leech
                .name
                .strip_prefix("leech-projects-leech-run-")
                .or_else(|| leech.name.strip_prefix("leech-projects-"))
                .unwrap_or(&leech.name)
                .to_string()
        };

        let (status_icon, status_style, uptime) = if leech.is_up {
            ("\u{25cf}", theme::up_icon(), format_uptime(&leech.status))
        } else {
            ("\u{25cb}", theme::down_icon(), "stop ".to_string())
        };

        let mut spans = vec![
            Span::raw("     "),
            Span::styled(status_icon, status_style),
            Span::raw(" "),
            Span::styled(format!("{ident:<20}"), theme::name()),
            Span::raw(" "),
            Span::styled(format!("{uptime:<5}"), theme::uptime()),
        ];

        if leech.is_up && !leech.cpu.is_empty() {
            let cpu_pct = parse_pct(&leech.cpu);
            let cpu_bar = mini_bar(cpu_pct, 6);
            let cpu_style = pct_color(cpu_pct);
            let mem_short = leech.mem.replace("MiB", "M").replace("GiB", "G").replace(" / ", "/");
            let mem_bar = mem_bar_from_str(&leech.mem);
            spans.push(Span::raw("  "));
            spans.push(Span::styled(cpu_bar, cpu_style));
            spans.push(Span::styled(format!(" {:<6}", leech.cpu.trim()), theme::cpu()));
            spans.push(Span::raw(" "));
            spans.push(Span::styled(mem_bar, theme::mem()));
            spans.push(Span::styled(format!(" {mem_short}"), theme::dim()));
        }

        lines.push(Line::from(spans));
    }

    frame.render_widget(Paragraph::new(lines), area);
}

fn shorten_path(p: &str) -> String {
    let home = std::env::var("HOME").unwrap_or_default();
    if !home.is_empty() && p.starts_with(&home) {
        format!("~{}", &p[home.len()..])
    } else {
        p.to_string()
    }
}

/// Strip the "Up " prefix and abbreviate common duration words for compact display.
fn format_uptime(status: &str) -> String {
    status
        .strip_prefix("Up ")
        .or_else(|| status.strip_prefix("up "))
        .unwrap_or(status)
        .replace("About an hour", "~1h")
        .replace(" seconds", "s")
        .replace(" minutes", "min")
        .replace(" hours", "h")
        .replace(" days", "d")
        .split(" (")
        .next()
        .unwrap_or("")
        .to_string()
}
