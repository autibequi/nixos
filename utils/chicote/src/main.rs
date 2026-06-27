// chicote — overlay modal: o cursor vira um chicote com física.
// Sacudiu forte (a ponta estala) → manda "mais rapido" + Enter pro terminal.
// Roda em modo modal (mod3+s liga/desliga via chicote.lua). ESC também fecha.

use std::process::Command;
use raylib::prelude::*;

const N: usize = 14; // nós do chicote
const SEG: f32 = 22.0; // distância alvo entre nós
const DAMP: f32 = 0.92; // amortecimento da velocidade (inércia da ponta)
const GRAV: f32 = 1.2; // gravidade por frame
const CONSTRAINT_ITERS: usize = 12; // mais iterações = chicote mais "duro"
const CRACK_SPEED: f32 = 90.0; // velocidade da ponta que conta como estalo
const COOLDOWN_S: f64 = 1.5; // silêncio entre estalos

struct Node {
    pos: Vector2,
    prev: Vector2,
}

// Lê a posição global do cursor via Hyprland. Processo externo: sem o risco de
// deadlock do io.popen dentro do compositor (aquilo é um problema só do Lua embarcado).
fn cursor_pos(fallback: Vector2) -> Vector2 {
    let out = match Command::new("hyprctl").arg("cursorpos").output() {
        Ok(o) => o,
        Err(_) => return fallback,
    };
    let s = String::from_utf8_lossy(&out.stdout);
    let (x, y) = match s.trim().split_once(',') {
        Some(p) => p,
        None => return fallback,
    };
    match (x.trim().parse::<f32>(), y.trim().parse::<f32>()) {
        (Ok(x), Ok(y)) => Vector2::new(x, y),
        _ => fallback,
    }
}

fn crack() {
    // nofocus na janela (windowrule) garante que isto cai no terminal de baixo.
    let _ = Command::new("wtype")
        .args(["mais rapido", "-k", "Return"])
        .spawn();
}

fn main() {
    let (mut rl, thread) = raylib::init()
        .size(800, 600) // a windowrule fullscreen do Hyprland redimensiona; resizable acompanha
        .title("chicote")
        .transparent()
        .undecorated()
        .resizable()
        .build();
    // topmost/unfocused não existem no builder desta versão → set via flags de estado.
    // Valores das ConfigFlags do raylib (ABI estável): TOPMOST=0x1000, UNFOCUSED=0x800.
    unsafe { raylib::ffi::SetWindowState(0x1000 | 0x800); }
    rl.set_target_fps(60);

    let start = cursor_pos(Vector2::new(400.0, 300.0));
    let mut whip: Vec<Node> = (0..N)
        .map(|i| Node {
            pos: Vector2::new(start.x, start.y + i as f32 * SEG),
            prev: Vector2::new(start.x, start.y + i as f32 * SEG),
        })
        .collect();

    let mut last_crack = -COOLDOWN_S;
    let mut flash = 0.0f32; // brilho residual do último estalo (0..1)

    while !rl.window_should_close() {
        let cursor = cursor_pos(whip[0].pos);

        // Verlet: cada nó guarda inércia (pos - prev). A ponta chicoteia.
        for n in whip.iter_mut().skip(1) {
            let vel = (n.pos - n.prev) * DAMP;
            n.prev = n.pos;
            n.pos = n.pos + vel;
            n.pos.y += GRAV;
        }

        // Restrição de distância: nó 0 colado no cursor, cada nó puxado pro anterior.
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

        // Estalo: velocidade da ponta cruzou o limiar e o cooldown zerou.
        let tip = &whip[N - 1];
        let tip_speed = (tip.pos - tip.prev).length();
        let now = rl.get_time();
        if tip_speed > CRACK_SPEED && now - last_crack > COOLDOWN_S {
            crack();
            last_crack = now;
            flash = 1.0;
        }
        flash = (flash - rl.get_frame_time() * 2.0).max(0.0);

        let mut d = rl.begin_drawing(&thread);
        d.clear_background(Color::BLANK); // fundo transparente

        // Couro: grosso no cabo, fino na ponta. Vermelho quando estala.
        let base = Color::new(120, 72, 40, 255);
        let hot = Color::new(255, 80, 40, 255);
        for i in 1..N {
            let t = i as f32 / N as f32;
            let thick = 9.0 * (1.0 - t) + 1.5;
            let col = if flash > 0.0 { hot } else { base };
            d.draw_line_ex(whip[i - 1].pos, whip[i].pos, thick, col);
        }
        // Brilho na ponta no momento do estalo.
        if flash > 0.0 {
            let tip = whip[N - 1].pos;
            d.draw_circle_v(tip, 6.0 + 10.0 * flash, Color::new(255, 220, 120, (200.0 * flash) as u8));
        }
    }
}
