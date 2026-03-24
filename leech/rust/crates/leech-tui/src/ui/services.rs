//! Render the dockerized-services panel with status, uptime, CPU, and memory.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::{App, DK_SERVICES, ENVS};
use crate::theme;

const SPINNER: &[&str] = &["◐", "◓", "◑", "◒"];

/// Abbreviate / truncate env names to at most 5 chars for consistent column width.
fn abbrev_env(env: &str) -> &str {
    match env {
        "sandbox"    => "sand",
        "production" => "prod",
        "devbox"     => "dev",
        s if s.len() <= 5 => s,
        s            => &s[..5],
    }
}

fn service_dep_names(svc: &str) -> &'static [&'static str] {
    match svc {
        "monolito" => &["postgres", "redis", "localstack"],
        _ => &[],
    }
}

pub fn service_dep_count(svc: &str) -> usize { service_dep_names(svc).len() }

pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    let any_up     = app.snapshot.dk_services.iter().any(|s| s.is_up);
    let icon       = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let icon_style = if any_up { theme::up_icon() } else { theme::down_icon() };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled("projects", theme::group_label()),
    ]));

    for (i, &svc) in DK_SERVICES.iter().enumerate() {
        let is_selected  = i == app.cursor_idx;
        let is_last_svc  = i == DK_SERVICES.len() - 1;
        let svc_branch   = if is_last_svc { "\u{2514}\u{2500}" } else { "\u{251c}\u{2500}" };
        let vert_pad     = if is_last_svc { "  " } else { "\u{2502} " };
        let marker       = if is_selected { "\u{25b6}" } else { " " };
        let name_style   = if is_selected { theme::selected() } else { theme::name() };
        let marker_style = if is_selected { theme::selected() } else { theme::dim() };

        let app_container = format!("leech-dk-{svc}-app");
        let dk = app.snapshot.dk_services.iter().find(|d| d.name == app_container);
        let is_pending = matches!(&app.last_action, Some((idx, _)) if *idx == i);

        if is_pending {
            let frame_ch     = SPINNER[(app.render_tick as usize / 2) % SPINNER.len()];
            let action_label = app.last_action.as_ref().map(|(_, s)| s.as_str()).unwrap_or("…");
            let raw_env      = dk.and_then(|d| if d.is_up && !d.env.is_empty() { Some(d.env.as_str()) } else { None })
                                 .unwrap_or(ENVS[app.svc_envs[i]]);
            let env          = abbrev_env(raw_env);
            lines.push(Line::from(vec![
                Span::raw("  "),
                Span::styled(svc_branch.to_string(), theme::tree_branch()),
                Span::raw(" "),
                Span::styled(marker.to_string(), marker_style),
                Span::raw(" "),
                Span::styled(frame_ch, theme::pending_icon()),
                Span::raw(" "),
                Span::styled(format!("{svc:<14}"), name_style),
                Span::styled(format!(" {env:<5}"), theme::dim()),
                Span::raw("  "),
                Span::styled(action_label.to_string(), theme::pending_label()),
            ]));
            continue;
        }

        let (status_icon, status_style, status_text, cpu_str, mem_str) =
            if let Some(d) = dk {
                if d.is_up {
                    ("\u{25cf}", theme::up_icon(), format_uptime(&d.status),
                     d.cpu.clone(), d.mem.clone())
                } else {
                    ("\u{25cb}", theme::down_icon(), "stopped".to_string(),
                     String::new(), String::new())
                }
            } else {
                ("\u{25cb}", theme::down_icon(), "stopped".to_string(),
                 String::new(), String::new())
            };

        // Show the real running env (from APP_ENV) when container is up,
        // otherwise show the selected env for the next start.
        let raw_env = if let Some(d) = dk {
            if d.is_up && !d.env.is_empty() { d.env.as_str() } else { ENVS[app.svc_envs[i]] }
        } else {
            ENVS[app.svc_envs[i]]
        };
        let env = abbrev_env(raw_env);
        let mut spans = vec![
            Span::raw("  "),
            Span::styled(svc_branch.to_string(), theme::tree_branch()),
            Span::raw(" "),
            Span::styled(marker.to_string(), marker_style),
            Span::raw(" "),
            Span::styled(status_icon, status_style),
            Span::raw(" "),
            Span::styled(format!("{svc:<14}"), name_style),
            Span::styled(format!(" {env:<5}"), theme::dim()),
            Span::styled(format!(" {status_text:<5}"), theme::uptime()),
        ];

        if !cpu_str.is_empty() {
            let cpu_pct  = parse_pct(&cpu_str);
            let cpu_bar  = mini_bar(cpu_pct, 6);
            let cpu_sty  = pct_color(cpu_pct);
            let mem_used = mem_str.split('/').next().unwrap_or(&mem_str)
                .replace("MiB", "M").replace("GiB", "G").trim().to_string();
            let mem_bar  = mem_bar_from_str(&mem_str);
            spans.push(Span::raw("  "));
            spans.push(Span::styled(cpu_bar, cpu_sty));
            spans.push(Span::styled(format!(" {:>6}", cpu_str.trim()), theme::cpu()));
            spans.push(Span::raw("  "));
            spans.push(Span::styled(mem_bar, theme::mem()));
            spans.push(Span::styled(format!(" {mem_used}"), theme::mem()));
        }

        lines.push(Line::from(spans));

        // Dep sub-rows
        // PREFIX for dep rows has 4 more chars than main rows (deeper indent).
        // To align bars: dep gets "   " (3 sp) instead of env(6)+space(1)=7 → net -4 = 3.
        let deps = service_dep_names(svc);
        for (di, &dep) in deps.iter().enumerate() {
            let is_last        = di == deps.len() - 1;
            let tree           = if is_last { "\u{2514}\u{2500}" } else { "\u{251c}\u{2500}" };
            let dep_container  = format!("leech-dk-{svc}-{dep}");
            let dep_info       = app.snapshot.dk_services.iter().find(|d| d.name == dep_container);
            let (d_icon, d_sty, d_status, d_cpu, d_mem) = match dep_info {
                Some(d) if d.is_up => (
                    "\u{25cf}", theme::up_icon(), format_uptime(&d.status),
                    d.cpu.clone(), d.mem.clone(),
                ),
                _ => ("\u{25cb}", theme::down_icon(), "stopped".to_string(),
                      String::new(), String::new()),
            };

            let mut dep_spans = vec![
                Span::raw("  "),
                Span::styled(vert_pad.to_string(), theme::tree_branch()),
                Span::raw("    "),
                Span::styled(tree, theme::tree_branch()),
                Span::raw(" "),
                Span::styled(d_icon, d_sty),
                Span::raw(" "),
                Span::styled(format!("{dep:<14}"), theme::dim()),
                Span::raw("   "),  // 3 sp aligns bars with main rows (no env col here)
                Span::styled(format!("{d_status:<5}"), theme::uptime()),
            ];
            if !d_cpu.is_empty() {
                let cpu_pct  = parse_pct(&d_cpu);
                let cpu_bar  = mini_bar(cpu_pct, 6);
                let cpu_sty  = pct_color(cpu_pct);
                let mem_used = d_mem.split('/').next().unwrap_or(&d_mem)
                    .replace("MiB", "M").replace("GiB", "G").trim().to_string();
                let mem_bar  = mem_bar_from_str(&d_mem);
                dep_spans.push(Span::raw("  "));
                dep_spans.push(Span::styled(cpu_bar, cpu_sty));
                dep_spans.push(Span::styled(format!(" {:>6}", d_cpu.trim()), theme::cpu()));
                dep_spans.push(Span::raw("  "));
                dep_spans.push(Span::styled(mem_bar, theme::mem()));
                dep_spans.push(Span::styled(format!(" {mem_used}"), theme::mem()));
            }
            lines.push(Line::from(dep_spans));
        }
    }

    frame.render_widget(Paragraph::new(lines), area);
}

fn parse_pct(s: &str) -> u8 {
    s.trim().trim_end_matches('%').parse::<f32>().map(|f| f as u8).unwrap_or(0)
}

fn pct_color(pct: u8) -> ratatui::style::Style {
    use ratatui::style::{Color, Style};
    if pct >= 80      { Style::default().fg(Color::Rgb(243, 139, 168)) } // Red
    else if pct >= 50 { Style::default().fg(Color::Rgb(249, 226, 175)) } // Yellow
    else              { Style::default().fg(Color::Rgb(166, 227, 161)) } // Green
}

fn mini_bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty  = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

fn mem_bar_from_str(mem: &str) -> String {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() != 2 { return String::new(); }
    let used  = parse_bytes(parts[0].trim());
    let total = parse_bytes(parts[1].trim());
    if total == 0 { return String::new(); }
    mini_bar(((used * 100) / total).min(100) as u8, 6)
}

fn parse_bytes(s: &str) -> u64 {
    let s = s.replace("GiB", "G").replace("MiB", "M").replace("kB", "K");
    if let Some(v) = s.strip_suffix('G') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1_073_741_824.0) as u64;
    }
    if let Some(v) = s.strip_suffix('M') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1_048_576.0) as u64;
    }
    if let Some(v) = s.strip_suffix('K') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    s.trim().parse::<u64>().unwrap_or(0)
}

fn format_uptime(status: &str) -> String {
    status
        .strip_prefix("Up ").or_else(|| status.strip_prefix("up "))
        .unwrap_or(status)
        .replace("About an hour", "~1h")
        .replace(" seconds", "s")
        .replace(" minutes", "min")
        .replace(" hours", "h")
        .replace(" days", "d")
        .split(" (").next().unwrap_or("").to_string()
}
