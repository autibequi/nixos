//! Leech TUI v2 — ratatui dashboard with Catppuccin Mocha theme,
//! mouse-scrollable logs, and ANSI color passthrough.

#[cfg(unix)]
extern crate libc;

/// No-op SIGINT handler: parent ignores the signal without propagating SIG_IGN to children.
/// Unlike SIG_IGN, a custom handler is NOT inherited by exec'd child processes (they get SIG_DFL).
#[cfg(unix)]
extern "C" fn noop_sigint(_: libc::c_int) {}

mod app;
mod event;
mod theme;
mod ui;

use std::io;
use std::process::Stdio;
use std::sync::mpsc;
use std::time::Duration;

use anyhow::Result;
use crossterm::{
    event::{DisableMouseCapture, EnableMouseCapture, MouseEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;
use ratatui::Terminal;

use app::{App, AppMode};
use event::{map_key, poll, AppEvent};
use crate::paths;
use crate::status::StatusSnapshot;

// ── CLI helpers ───────────────────────────────────────────────────────────────

fn leech_cmd() -> std::process::Command {
    let bin = paths::bin_dir().join("leech");
    if bin.exists() {
        return std::process::Command::new(bin);
    }
    // Fallback: try leech-bash, then bare leech on PATH
    let bash = paths::bin_dir().join("leech-bash");
    if bash.exists() {
        return std::process::Command::new(bash);
    }
    std::process::Command::new("leech")
}

/// Collect status by calling `leech status --json` and deserializing the output.
/// Falls back to direct SDK call if the subprocess fails (e.g., binary not in PATH yet).
fn collect_status() -> Option<StatusSnapshot> {
    let out = leech_cmd()
        .args(["status", "--json"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !out.status.success() { return None; }
    serde_json::from_slice(&out.stdout).ok()
}

fn load_agents_via_cli() -> Vec<app::AgentInfo> {
    let out = leech_cmd()
        .args(["agents", "list", "--json"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok();
    out.and_then(|o| serde_json::from_slice(&o.stdout).ok())
        .unwrap_or_default()
}

fn load_worktrees_via_cli() -> Vec<app::WorktreeInfo> {
    let out = leech_cmd()
        .args(["worktree", "--json"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok();
    out.and_then(|o| serde_json::from_slice(&o.stdout).ok())
        .unwrap_or_default()
}

fn load_agent_log_via_cli(name: &str) -> Vec<app::AgentLogEntry> {
    let out = leech_cmd()
        .args(["agents", "status", name, "--json"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok();
    out.and_then(|o| serde_json::from_slice(&o.stdout).ok())
        .unwrap_or_default()
}

fn docker_stop_wait(container_name: &str) {
    let _ = std::process::Command::new("docker")
        .args(["stop", "--time=5", container_name])
        .stdin(Stdio::null()).stdout(Stdio::null()).stderr(Stdio::null())
        .output();
}

fn run_bg_cmd(svc: &str, env: &str, action: &str, debug: bool) -> Option<String> {
    let mut cmd = leech_cmd();
    let env_flag = format!("--env={env}");
    let mut args: Vec<&str> = vec!["runner", svc, action];
    if (action == "start" || action == "start-hotreload") && !env.is_empty() {
        args.push(&env_flag);
        args.push("--detach");
    }
    if debug {
        args.push("--debug");
    }
    match cmd.args(&args).output() {
        Err(e) => Some(format!("Could not run command: {e}")),
        Ok(out) if !out.status.success() => {
            let stderr = String::from_utf8_lossy(&out.stderr);
            let stdout = String::from_utf8_lossy(&out.stdout);
            let raw = if !stderr.is_empty() { stderr } else { stdout };
            Some(format!("{action} {svc} failed\n{}", clean_output(&raw)))
        }
        Ok(_) => None,
    }
}

fn clean_output(s: &str) -> String {
    let normalized = s.replace("\r\n", "\n").replace('\r', "\n");
    let mut out = String::with_capacity(normalized.len());
    let mut chars = normalized.chars().peekable();
    while let Some(ch) = chars.next() {
        if ch == '\x1b' {
            match chars.peek() {
                Some('[') => {
                    chars.next();
                    for c in chars.by_ref() {
                        if ('\x40'..='\x7e').contains(&c) { break; }
                    }
                }
                _ => { chars.next(); }
            }
        } else {
            out.push(ch);
        }
    }
    let lines: Vec<&str> = out.lines().map(str::trim).filter(|l| !l.is_empty()).collect();
    let start = lines.len().saturating_sub(10);
    lines[start..].join("\n")
}

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run_status(tick: u64) -> Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend  = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    if let Some(snap) = collect_status() {
        app.snapshot = snap;
    }

    let (tx, rx)          = mpsc::channel();
    let tx_bg             = tx.clone();
    let refresh_interval  = Duration::from_secs(tick);

    std::thread::spawn(move || loop {
        std::thread::sleep(refresh_interval);
        if let Some(snap) = collect_status() {
            if tx.send(snap).is_err() { break; }
        }
    });

    let (bg_err_tx, bg_err_rx)   = mpsc::channel::<String>();
    let (bg_done_tx, bg_done_rx) = mpsc::channel::<usize>();

    loop {
        if let Ok(err) = bg_err_rx.try_recv() { app.set_error(err); }
        if let Ok(idx) = bg_done_rx.try_recv() { app.clear_action_for(idx); }

        if matches!(app.mode, AppMode::Normal) {
            if let Ok(snap) = rx.try_recv() {
                app.snapshot = snap;
                app.snapshot_at = std::time::Instant::now();
            }
        }

        terminal.draw(|frame| { ui::status::render(frame, &app); })?;
        app.render_tick = app.render_tick.wrapping_add(1);

        match poll(Duration::from_millis(250))? {
            // ── Mouse ─────────────────────────────────────────────────────────
            AppEvent::Mouse(mouse) => {
                if matches!(app.mode, AppMode::Normal) {
                    match mouse.kind {
                        MouseEventKind::ScrollUp => {
                            if app.allow_mouse_scroll() { app.log_scroll_up(1); }
                        }
                        MouseEventKind::ScrollDown => {
                            if app.allow_mouse_scroll() { app.log_scroll_down(1); }
                        }
                        _ => {}
                    }
                }
            }

            // ── Keyboard ──────────────────────────────────────────────────────
            AppEvent::Key(key) => {
                match &app.mode {
                    AppMode::Error(_) => { app.clear_error(); }

                    AppMode::Menu => {
                        use crossterm::event::KeyCode;
                        match key.code {
                            KeyCode::Up   | KeyCode::Char('k') => app.menu_prev(),
                            KeyCode::Down | KeyCode::Char('j') => app.menu_next(),
                            KeyCode::Esc  | KeyCode::Char('q') => app.close_menu(),
                            KeyCode::Enter => {
                                let action = app.menu_action();
                                match action {
                                    "cancel" => app.close_menu(),

                                    "stop" => {
                                        let svc  = app.current_service().to_string();
                                        let idx  = app.cursor_idx;
                                        let cname = find_container(&app, &svc);
                                        app.close_menu();
                                        app.last_action = Some((idx, format!("stopping {svc}…")));
                                        let done_tx = bg_done_tx.clone();
                                        let snap_tx = tx_bg.clone();
                                        std::thread::spawn(move || {
                                            if let Some(name) = cname { docker_stop_wait(&name); }
                                            let _ = done_tx.send(idx);
                                            if let Some(snap) = collect_status() {
                                                let _ = snap_tx.send(snap);
                                            }
                                        });
                                    }

                                    "debug" => {
                                        app.toggle_debug();
                                        app.close_menu();
                                    }

                                    "start" | "start-hotreload" => {
                                        let action = action.to_string();
                                        let svc    = app.current_service().to_string();
                                        let env    = app.current_env().to_string();
                                        let debug  = app.is_debug();
                                        let idx    = app.cursor_idx;
                                        let label  = match action.as_str() {
                                            "start-hotreload" => format!("hotreload {svc}…"),
                                            _ if debug        => format!("starting {svc} [dbg]…"),
                                            _                 => format!("starting {svc}…"),
                                        };
                                        app.close_menu();
                                        app.last_action = Some((idx, label));
                                        let err_tx  = bg_err_tx.clone();
                                        let snap_tx = tx_bg.clone();
                                        let done_tx = bg_done_tx.clone();
                                        std::thread::spawn(move || {
                                            if let Some(err) = run_bg_cmd(&svc, &env, &action, debug) {
                                                let _ = err_tx.send(err);
                                            }
                                            let _ = done_tx.send(idx);
                                            if let Some(snap) = collect_status() {
                                                let _ = snap_tx.send(snap);
                                            }
                                        });
                                    }

                                    "restart" => {
                                        let svc    = app.current_service().to_string();
                                        let env    = app.current_env().to_string();
                                        let debug  = app.is_debug();
                                        let idx    = app.cursor_idx;
                                        let cname  = find_container(&app, &svc);
                                        app.close_menu();
                                        app.last_action = Some((idx, format!("restarting {svc}…")));
                                        let err_tx  = bg_err_tx.clone();
                                        let snap_tx = tx_bg.clone();
                                        let done_tx = bg_done_tx.clone();
                                        std::thread::spawn(move || {
                                            if let Some(name) = cname { docker_stop_wait(&name); }
                                            if let Some(err) = run_bg_cmd(&svc, &env, "start", debug) {
                                                let _ = err_tx.send(err);
                                            }
                                            let _ = done_tx.send(idx);
                                            if let Some(snap) = collect_status() {
                                                let _ = snap_tx.send(snap);
                                            }
                                        });
                                    }

                                    "logs" | "test" | "install" | "shell" => {
                                        let action = action.to_string();
                                        let svc    = app.current_service().to_string();
                                        app.close_menu();
                                        disable_raw_mode()?;
                                        execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;

                                        // Ignore SIGINT in this process so Ctrl+C only kills the
                                        // child (docker logs / shell) and returns us to the TUI.
                                        // Uses a no-op handler (not SIG_IGN) so children inherit
                                        // SIG_DFL and can be killed by Ctrl+C normally.
                                        #[cfg(unix)]
                                        let _prev_sigint = unsafe {
                                            libc::signal(libc::SIGINT, noop_sigint as libc::sighandler_t)
                                        };

                                        let result = leech_cmd()
                                            .args(["runner", &svc, &action])
                                            .stdin(Stdio::inherit())
                                            .stdout(Stdio::inherit())
                                            .stderr(Stdio::inherit())
                                            .status();

                                        // Restore default SIGINT handler.
                                        #[cfg(unix)]
                                        unsafe { libc::signal(libc::SIGINT, libc::SIG_DFL); }

                                        enable_raw_mode()?;
                                        execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
                                        terminal.clear()?;

                                        if let Some(snap) = collect_status() { app.snapshot = snap; }
                                        if let Err(e) = result {
                                            app.set_error(format!("Failed to run {action}: {e}"));
                                        }
                                    }

                                    _ => app.close_menu(),
                                }
                            }
                            _ => {}
                        }
                    }

                    AppMode::AgentPanel => {
                        use crossterm::event::KeyCode;
                        if !app.agent_log.is_empty() {
                            // Log view — any key closes it
                            match key.code {
                                KeyCode::Esc | KeyCode::Char('q') | KeyCode::Enter => {
                                    app.close_agent_log();
                                }
                                _ => {}
                            }
                        } else if app.agent_menu {
                            // ── Agent action sub-menu ──────────────────────
                            match key.code {
                                KeyCode::Esc | KeyCode::Char('q') => app.close_agent_menu(),
                                KeyCode::Up   | KeyCode::Char('k') => app.agent_menu_prev(),
                                KeyCode::Down | KeyCode::Char('j') => app.agent_menu_next(),
                                KeyCode::Enter => {
                                    let action = app.agent_menu_action().to_string();
                                    let name   = app.selected_agent_name()
                                        .unwrap_or("").to_string();
                                    app.close_agent_menu();

                                    match action.as_str() {
                                        "cancel" => {}

                                        "run" => {
                                            // Non-interactive background run
                                            let err_tx = bg_err_tx.clone();
                                            std::thread::spawn(move || {
                                                let mut cmd = leech_cmd();
                                                let out = cmd.args(["run", &name]).output();
                                                match out {
                                                    Err(e) => { let _ = err_tx.send(format!("run {name}: {e}")); }
                                                    Ok(o) if !o.status.success() => {
                                                        let msg = String::from_utf8_lossy(&o.stderr);
                                                        let _ = err_tx.send(clean_output(&msg));
                                                    }
                                                    Ok(_) => {}
                                                }
                                            });
                                        }

                                        "phone" => {
                                            // Replace TUI process with a new leech session
                                            app.close_agents();
                                            disable_raw_mode()?;
                                            execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
                                            terminal.show_cursor()?;

                                            #[cfg(unix)]
                                            use std::os::unix::process::CommandExt;
                                            #[cfg(unix)]
                                            {
                                                let err = leech_cmd()
                                                    .args(["agents", "phone", &name])
                                                    .exec();
                                                // Only reached if exec failed
                                                enable_raw_mode()?;
                                                execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
                                                terminal.clear()?;
                                                app.set_error(format!("Failed to launch: {err}"));
                                            }
                                            #[cfg(not(unix))]
                                            {
                                                enable_raw_mode()?;
                                                execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
                                                terminal.clear()?;
                                                app.set_error("phone not supported on non-unix".into());
                                            }
                                        }

                                        "status" => {
                                            // Show activity log inline in the TUI
                                            let entries = load_agent_log_via_cli(&name);
                                            app.open_agent_log(&name, entries);
                                        }

                                        _ => {}
                                    }
                                }
                                _ => {}
                            }
                        } else {
                            // ── Agent list navigation ──────────────────────
                            match key.code {
                                KeyCode::Esc
                                | KeyCode::Char('q')
                                | KeyCode::Char('a') => app.close_agents(),
                                KeyCode::Up   | KeyCode::Char('k') => app.agents_move_up(),
                                KeyCode::Down | KeyCode::Char('j') => app.agents_move_down(),
                                KeyCode::Enter => app.open_agent_menu(),
                                _ => {}
                            }
                        }
                    }

                    AppMode::WorktreePanel => {
                        use crossterm::event::KeyCode;
                        if app.wt_menu {
                            match key.code {
                                KeyCode::Esc | KeyCode::Char('q') => app.close_wt_menu(),
                                KeyCode::Up   | KeyCode::Char('k') => app.wt_menu_prev(),
                                KeyCode::Down | KeyCode::Char('j') => app.wt_menu_next(),
                                KeyCode::Enter => {
                                    let action = app.wt_menu_action().to_string();
                                    let wt = app.selected_wt().cloned();
                                    app.close_wt_menu();

                                    if action == "cancel" {
                                        // noop
                                    } else if let Some(wt) = wt {
                                        let wt_flag = if wt.is_main {
                                            None
                                        } else {
                                            Some(wt.name.clone())
                                        };

                                        // Interactive actions: logs, shell — leave TUI
                                        if matches!(action.as_str(), "logs" | "shell") {
                                            app.close_worktrees();
                                            disable_raw_mode()?;
                                            execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;

                                            #[cfg(unix)]
                                            let _prev = unsafe { libc::signal(libc::SIGINT, libc::SIG_IGN) };

                                            let mut cmd = leech_cmd();
                                            cmd.args(["runner", &wt.service, &action]);
                                            if let Some(wt_name) = wt_flag.as_deref() {
                                                cmd.args(["--worktree", wt_name]);
                                            }
                                            let _ = cmd.stdin(Stdio::inherit())
                                                .stdout(Stdio::inherit())
                                                .stderr(Stdio::inherit())
                                                .status();

                                            #[cfg(unix)]
                                            unsafe { libc::signal(libc::SIGINT, libc::SIG_DFL); }

                                            enable_raw_mode()?;
                                            execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
                                            terminal.clear()?;
                                            if let Some(snap) = collect_status() { app.snapshot = snap; }
                                        } else {
                                            // Background actions: start, stop, restart, install, test, build, flush
                                            let err_tx = bg_err_tx.clone();
                                            let snap_tx = tx_bg.clone();
                                            std::thread::spawn(move || {
                                                let mut cmd = leech_cmd();
                                                cmd.args(["runner", &wt.service, &action]);
                                                if let Some(wt_name) = wt_flag.as_deref() {
                                                    cmd.args(["--worktree", wt_name]);
                                                }
                                                if matches!(action.as_str(), "start" | "start-hotreload") {
                                                    cmd.arg("--detach");
                                                }
                                                match cmd.output() {
                                                    Err(e) => { let _ = err_tx.send(format!("{action}: {e}")); }
                                                    Ok(o) if !o.status.success() => {
                                                        let msg = String::from_utf8_lossy(&o.stderr);
                                                        let _ = err_tx.send(clean_output(&msg));
                                                    }
                                                    Ok(_) => {}
                                                }
                                                if let Some(snap) = collect_status() {
                                                    let _ = snap_tx.send(snap);
                                                }
                                            });
                                        }
                                    }
                                }
                                _ => {}
                            }
                        } else {
                            match key.code {
                                KeyCode::Esc | KeyCode::Char('q') | KeyCode::Char('w') => {
                                    app.close_worktrees();
                                }
                                KeyCode::Up   | KeyCode::Char('k') => app.wt_move_up(),
                                KeyCode::Down | KeyCode::Char('j') => app.wt_move_down(),
                                KeyCode::Enter => app.open_wt_menu(),
                                _ => {}
                            }
                        }
                    }

                    AppMode::Normal => {
                        use crossterm::event::KeyCode;
                        if key.code == KeyCode::Char('d') {
                            app.toggle_debug();
                        } else if let Some(action) = map_key(key) {
                            match action {
                                "quit"           => break,
                                "up"             => app.move_up(),
                                "down"           => app.move_down(),
                                "cycle_env"      => app.cycle_env(),
                                "log_up"         => app.log_scroll_up(5),
                                "log_down"       => app.log_scroll_down(5),
                                "menu_open"      => app.open_menu(),
                                "agents_open"    => app.open_agents(load_agents_via_cli()),
                                "worktree_open"  => app.open_worktrees(load_worktrees_via_cli()),
                                _                => {}
                            }
                        }
                    }
                }
            }

            AppEvent::Tick => {}
        }
    }

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;
    Ok(())
}

/// Find the Docker container name for a given service (for direct stop).
fn find_container(app: &App, svc: &str) -> Option<String> {
    if app.is_utils_selected() {
        app.snapshot.utils.iter()
            .find(|u| u.name.contains(svc))
            .map(|u| u.name.clone())
    } else {
        // Prefer the exact app container (leech-dk-<svc>-app) to avoid
        // accidentally stopping a dep (postgres/redis/localstack).
        let app_name = format!("leech-dk-{svc}-app");
        app.snapshot.dk_services.iter()
            .find(|d| d.name == app_name)
            .map(|d| d.name.clone())
            .or_else(|| {
                // Fallback: any container whose name ends with -<svc>-app
                app.snapshot.dk_services.iter()
                    .find(|d| d.name.ends_with(&format!("-{svc}-app")))
                    .map(|d| d.name.clone())
            })
    }
}
