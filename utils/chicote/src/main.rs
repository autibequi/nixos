// chicote — overlay modal: o cursor vira um chicote com física.
// Sacudiu forte (a ponta estala) → manda "mais rapido" + Enter pro terminal.
// Roda em modo one-shot: mod3+s liga, 1 estalo → "mais rapido" + Enter e fecha. ESC também fecha.

use std::process::Command;
use std::time::{Duration, Instant};
use raylib::prelude::*;
use serde_json::Value;

const N: usize = 14;
const SEG: f32 = 22.0;
const DAMP: f32 = 0.96;
const GRAV: f32 = 1.0;
const CONSTRAINT_ITERS: usize = 12;
const CRACK_SPEED_DEFAULT: f32 = 165.0;
const GEO_POLL_S: f64 = 0.05;

struct Node {
    pos: Vector2,
    prev: Vector2,
}

struct WinGeo {
    origin: Vector2,
    width: f32,
    height: f32,
}

fn hyprctl_out(args: &[&str]) -> Option<String> {
    Command::new("hyprctl")
        .args(args)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
}

fn hyprctl_json(args: &[&str]) -> Option<Value> {
    let raw = hyprctl_out(args)?;
    serde_json::from_str(&raw).ok()
}

fn chicote_client() -> Option<Value> {
    let clients = match hyprctl_json(&["clients", "-j"]) {
        Some(v) => v,
        None => return None,
    };
    let cs = match clients.as_array() {
        Some(a) => a,
        None => return None,
    };
    cs.iter()
        .find(|c| c.get("title").and_then(|t| t.as_str()) == Some("chicote"))
        .cloned()
}

fn chicote_window_geo() -> Option<WinGeo> {
    let c = chicote_client()?;
    let at = c.get("at").and_then(|a| a.as_array());
    let size = c.get("size").and_then(|s| s.as_array());
    let (ax, ay) = match at {
        Some(at) => (
            at.first().and_then(|v| v.as_f64()).unwrap_or(0.0) as f32,
            at.get(1).and_then(|v| v.as_f64()).unwrap_or(0.0) as f32,
        ),
        None => return None,
    };
    let (w, h) = match size {
        Some(sz) => (
            sz.first().and_then(|v| v.as_f64()).unwrap_or(800.0) as f32,
            sz.get(1).and_then(|v| v.as_f64()).unwrap_or(600.0) as f32,
        ),
        None => return None,
    };
    Some(WinGeo {
        origin: Vector2::new(ax, ay),
        width: w.max(400.0),
        height: h.max(300.0),
    })
}

fn focused_monitor_geo() -> WinGeo {
    let monitors = match hyprctl_json(&["monitors", "-j"]) {
        Some(v) => v,
        None => return WinGeo::default(),
    };
    let ms = match monitors.as_array() {
        Some(a) => a,
        None => return WinGeo::default(),
    };
    let m = ms
        .iter()
        .find(|m| m.get("focused").and_then(|v| v.as_bool()) == Some(true))
        .or_else(|| ms.first());
    match m {
        Some(m) => {
            let x = m.get("x").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
            let y = m.get("y").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
            let scale = m.get("scale").and_then(|v| v.as_f64()).unwrap_or(1.0) as f32;
            let w = m.get("width").and_then(|v| v.as_f64()).unwrap_or(800.0) as f32;
            let h = m.get("height").and_then(|v| v.as_f64()).unwrap_or(600.0) as f32;
            WinGeo {
                origin: Vector2::new(x, y),
                width: (w / scale).max(400.0),
                height: (h / scale).max(300.0),
            }
        }
        None => WinGeo::default(),
    }
}

impl Default for WinGeo {
    fn default() -> Self {
        Self {
            origin: Vector2::zero(),
            width: 800.0,
            height: 600.0,
        }
    }
}

fn cursor_pos_global(fallback: Vector2) -> Vector2 {
    let s = match hyprctl_out(&["cursorpos"]) {
        Some(v) => v,
        None => return fallback,
    };
    let (x, y) = match s.split_once(',') {
        Some(p) => p,
        None => return fallback,
    };
    match (x.trim().parse::<f32>(), y.trim().parse::<f32>()) {
        (Ok(x), Ok(y)) => Vector2::new(x, y),
        _ => fallback,
    }
}

fn cursor_offset() -> Vector2 {
    let x = std::env::var("CHICOTE_OFS_X")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.0);
    let y = std::env::var("CHICOTE_OFS_Y")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.0);
    Vector2::new(x, y)
}

fn to_framebuffer(p: Vector2, geo: &WinGeo, fb_w: i32, fb_h: i32) -> Vector2 {
    if geo.width <= 0.0 || geo.height <= 0.0 {
        return p;
    }
    Vector2::new(
        p.x * fb_w as f32 / geo.width,
        p.y * fb_h as f32 / geo.height,
    )
}

fn crack_speed_threshold() -> f32 {
    std::env::var("CHICOTE_CRACK_SPEED")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(CRACK_SPEED_DEFAULT)
}

fn crack() {
    let _ = Command::new("wtype")
        .args(["mais rapido", "-k", "Return"])
        .spawn();
}

fn wait_for_window_geo() -> WinGeo {
    let deadline = Instant::now() + Duration::from_secs(5);
    while Instant::now() < deadline {
        if let Some(g) = chicote_window_geo() {
            return g;
        }
        std::thread::sleep(Duration::from_millis(25));
    }
    eprintln!("chicote: janela não apareceu no Hyprland (timeout 5s)");
    focused_monitor_geo()
}

fn main() {
    if std::env::var_os("WAYLAND_DISPLAY").is_some() {
        std::env::remove_var("DISPLAY");
    }
    if std::env::var_os("GLFW_PLATFORM").is_none() {
        std::env::set_var("GLFW_PLATFORM", "wayland");
    }
    if std::env::var_os("WAYLAND_APP_ID").is_none() {
        std::env::set_var("WAYLAND_APP_ID", "chicote");
    }

    let opaque = std::env::var_os("CHICOTE_OPAQUE").is_some();
    let ofs = cursor_offset();
    let mut geo = wait_for_window_geo();

    let (mut rl, thread) = if opaque {
        raylib::init()
            .size(geo.width.round() as i32, geo.height.round() as i32)
            .title("chicote")
            .undecorated()
            .resizable()
            .build()
    } else {
        raylib::init()
            .size(geo.width.round() as i32, geo.height.round() as i32)
            .title("chicote")
            .transparent()
            .undecorated()
            .resizable()
            .build()
    };

    unsafe { raylib::ffi::SetWindowState(0x800); }
    rl.set_target_fps(60);

    let start_global = cursor_pos_global(
        geo.origin + Vector2::new(geo.width / 2.0, geo.height / 2.0),
    );
    let start = start_global - geo.origin;
    let mut whip: Vec<Node> = (0..N)
        .map(|i| Node {
            pos: Vector2::new(start.x, start.y + i as f32 * SEG),
            prev: Vector2::new(start.x, start.y + i as f32 * SEG),
        })
        .collect();

    let mut last_geo_poll = 0.0f64;

    while !rl.window_should_close() {
        let now = rl.get_time();
        if now - last_geo_poll >= GEO_POLL_S {
            if let Some(g) = chicote_window_geo() {
                geo = g;
            }
            last_geo_poll = now;
        }

        let global = cursor_pos_global(geo.origin + whip[0].pos) + ofs;
        let cursor = global - geo.origin;

        for n in whip.iter_mut().skip(1) {
            let vel = (n.pos - n.prev) * DAMP;
            n.prev = n.pos;
            n.pos = n.pos + vel;
            n.pos.y += GRAV;
        }

        whip[0].pos = cursor;
        whip[0].prev = cursor;
        for _ in 0..CONSTRAINT_ITERS {
            for i in 1..N {
                let delta = whip[i].pos - whip[i - 1].pos;
                let dist = delta.length();
                if dist > 0.0 {
                    let corr = (dist - SEG) / dist;
                    whip[i].pos = whip[i].pos - delta * corr;
                }
            }
        }

        let tip = &whip[N - 1];
        let tip_speed = (tip.pos - tip.prev).length();
        if tip_speed > crack_speed_threshold() {
            crack();
            break;
        }

        let fb_w = rl.get_screen_width();
        let fb_h = rl.get_screen_height();
        let mut d = rl.begin_drawing(&thread);
        if opaque {
            d.clear_background(Color::new(8, 6, 5, 255));
        } else {
            d.clear_background(Color::BLANK);
        }

        let leather = Color::new(120, 72, 40, 255);
        for i in 1..N {
            let t = i as f32 / N as f32;
            let thick = 9.0 * (1.0 - t) + 1.5;
            let a = to_framebuffer(whip[i - 1].pos, &geo, fb_w, fb_h);
            let b = to_framebuffer(whip[i].pos, &geo, fb_w, fb_h);
            d.draw_line_ex(a, b, thick, leather);
        }
    }
}
