-- ==========================================================
--  HYPRLAND CONFIG — 0.55 LUA
--  Migrado de hyprlang em 2026-05-16
--  Wiki: https://wiki.hypr.land/Configuring/Start/
-- ==========================================================

-- Permite require() de módulos em ~/.config/hypr/
local _cfgdir = os.getenv("HOME") .. "/.config/hypr"
package.path = _cfgdir .. "/?.lua;" .. package.path

-- Utils e theme carregados primeiro (outros módulos dependem das funções)
require("utils")
require("theme")

-- Infra Lua-first: keymap (registry) e launcher (decoradores)
-- Devem vir ANTES de application/systemtools que consomem ambos.
require("keymap")
require("launcher")

-- Hardware
require("monitors")

-- UI / regras
require("windowrules")
require("generated-colors")

-- Keybinds (preenchem o registry keymap)
require("application")
require("systemtools")

-- Workspace
require("workspace")
require("special-workspaces")

-- Picker (Alt-Tab Wayland) — depende do registry estar populado
require("picker")

-- Cheatsheet consome keymap._binds; deve vir DEPOIS de application/systemtools
require("hyprshortcuts")

-- Profiles (cycle modes: default/focus/meeting/battery)
require("profiles")

-- Features novas
require("cycler")             -- MOD3+I cicla por class
require("hud")                -- SUPER+; peek de estado
require("pomodoro")           -- SUPER+SHIFT+T (depende de profiles)
require("submaps")            -- smart_save/close/reload
require("followme")           -- MOD3+F sync workspaces (depende de events API)
require("help")               -- SUPER+, manual

-- Reativos: hooks de evento + watcher de tema + REPL debug
require("events")
require("screenshare_guard")  -- depende de hl.on

-- ⚠️ DESABILITADOS — usam hl.timer periódico + io.popen, que bloqueia
--    o main thread do compositor (5s lag em todos os keybinds).
--    Re-habilitar só depois de migrar pra async ou descobrir API non-blocking.
-- require("swallow")         -- io.popen("ps -p") em window.open trava ao abrir janelas
-- require("theme_watcher")   -- hl.timer 1500ms + io.popen("stat ...") trava periodicamente
-- require("repl")            -- hl.timer 250ms + io.popen, pior dos três

-- =============================================
--  ENV VARS
-- =============================================

-- Electron: Wayland nativo evita popup-behind-tiled via XWayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Cursor
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE",  "48")
hl.env("XCURSOR_SIZE",     "48")
hl.env("XCURSOR_THEME",    "BreezeX-RosePine-Linux")

-- =============================================
--  AUTOSTART
-- =============================================

hl.on("hyprland.start", function()
    -- Cursor XWayland
    hl.exec_cmd("xrdb ~/.Xresources")
    hl.exec_cmd("hyprctl setcursor BreezeX-RosePine-Linux 48")

    -- Session core
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("uwsm app -- swayosd-server")
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- qs")
    hl.exec_cmd("uwsm app -- swww-daemon")
    hl.exec_cmd("swww img " .. os.getenv("HOME") ..
        "/assets/wallpapers/the-wild-hunt-of-odin.jpg --transition-type none")
    hl.exec_cmd("uwsm app -- swaync")

    -- Clipboard
    hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")

    -- Tema escuro inicial
    dark_theme()
end)

-- =============================================
--  CONFIGURAÇÃO GERAL
-- =============================================

hl.config({
    general = {
        gaps_in                 = 2,
        -- gaps_out: bottom menor pra encostar perto da waybar
        gaps_out                = { top = 5, right = 5, bottom = 2, left = 5 },
        border_size             = 3,
        layout                  = "scrolling",
        allow_tearing           = false,
        resize_on_border        = false,
        extend_border_grab_area = 10,
    },

    scrolling = {
        column_width             = 0.5,
        fullscreen_on_one_column = true,
        focus_fit_method         = 1,        -- 0 = center, 1 = fit
        follow_focus             = true,
        follow_min_visible       = 0.0,
        explicit_column_widths   = "0.2, 0.25, 0.333, 0.5, 0.667, 1.0",
    },

    misc = {
        vrr                          = 0,    -- EGL fence sync quebra com VRR no AMD 780M
        initial_workspace_tracking   = 1,    -- 1=on, 0=off
        focus_on_activate            = true,
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,
    },

    render = {
        -- new_render_scheduling = false: AMD 780M não suporta eglDupNativeFenceFDANDROID
        new_render_scheduling = false,
        direct_scanout        = false,
    },

    decoration = {
        rounding = 10,
        blur     = { enabled = false },
        shadow   = { enabled = false },
    },

    -- ── INPUT ─────────────────────────────────────────────────
    input = {
        kb_layout   = "us",
        kb_variant  = "altgr-intl",
        kb_options  = "caps:hyper",  -- Caps Lock → MOD3/Hyper
        follow_mouse = 1,
        float_switch_override_focus = 0,
        scroll_factor = 0.7,

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            tap_to_click         = true,
            drag_lock            = false,
            clickfinger_behavior = false,
        },
    },

    -- ── ANIMATIONS ────────────────────────────────────────────
    animations = {
        enabled = true,
    },
})

-- ── Curves ────────────────────────────────────────────────────

-- instant: aggressive ease-out, feels like zero delay
hl.curve("instant", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })

-- overshot: slight bounce para special workspaces
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

-- ── Animations ────────────────────────────────────────────────

hl.animation({ leaf = "windows",          enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 1, bezier = "instant", style = "popin 90%" })
hl.animation({ leaf = "windowsMove",      enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "border",           enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "borderangle",      enabled = false })
hl.animation({ leaf = "fade",             enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 1, bezier = "instant", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 1, bezier = "overshot", style = "slidevert" })
