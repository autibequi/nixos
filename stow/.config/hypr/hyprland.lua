-- ==========================================================
--  HYPRLAND CONFIG — 0.55 LUA
--  Migrado de hyprlang em 2026-05-16
--  Refactor incremental em 2026-05-20 (core/keymap/launcher unificados)
--  Wiki: https://wiki.hypr.land/Configuring/Start/
-- ==========================================================

-- Permite require() de módulos em ~/.config/hypr/
local _cfgdir = os.getenv("HOME") .. "/.config/hypr"
package.path = _cfgdir .. "/?.lua;" .. package.path

-- =============================================
--  1. ENV VARS (devem vir antes dos requires
--     pra que processos spawned em hyprland.start herdem)
-- =============================================

-- Electron: Wayland nativo evita popup-behind-tiled via XWayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ydotool: socket do daemon de sistema (programs.ydotool cria em /run/ydotoold/)
hl.env("YDOTOOL_SOCKET", "/run/ydotoold/.ydotool_socket")

-- Cursor
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE",  "48")
hl.env("XCURSOR_SIZE",     "48")
hl.env("XCURSOR_THEME",    "BreezeX-RosePine-Linux")

-- =============================================
--  2. MÓDULOS — ordem importa (deps lexicais)
-- =============================================

-- Infra: helpers (core), registry (keymap), spawn wrapper (launcher)
require("core")
require("keymap")
require("launcher")

-- Baixo nível: parse hyprctl, services (waybar/qs/reload), screenshots
require("clients")
require("services")
require("screenshots")

-- State + theme (utils usa core.other_monitor; theme usa core.state_file)
require("utils")
require("theme")

-- Hardware + UI rules
require("monitors")
require("windowrules")
require("generated-colors")

-- Keybinds e workspaces (populam o registry keymap)
require("application")
require("systemtools")
require("workspace")
require("special-workspaces")

-- Cheatsheet/help/picker — consomem o registry, vêm depois
require("picker")
require("hyprshortcuts")
require("help")

-- Profiles + features de produtividade
require("profiles")           -- default/focus/meeting/battery cycle (SUPER+SHIFT+P)
require("auto_profile")       -- AC change → switch profile automático
require("cycler")             -- MOD3+I cicla por class
require("hud")                -- SUPER+; peek de estado
require("pomodoro")           -- SUPER+SHIFT+T (depende de profiles)
require("submaps")            -- smart_save/close/reload
require("followme")           -- MOD3+F sync workspaces entre monitores
require("chicote")            -- MOD3+S modo chicote (overlay raylib)
require("layouts")            -- snapshots de janelas por workspace (CLI: hypr-layout)

-- Hooks reativos (consomem registries populados pelos requires acima)
require("events")
require("specials-feed")      -- SIGRTMIN+11 → waybar refresh

-- Watchers / REPL (re-habilitados 2026-05-20: io.popen → io.open + /proc)
require("swallow")            -- ppid via /proc/<pid>/status
require("theme_watcher")      -- marker read via io.open
require("repl")               -- timer 500ms, eval file-based

-- =============================================
--  3. AUTOSTART (hl.on("hyprland.start"))
-- =============================================
require("autostart")

-- =============================================
--  4. CONFIGURAÇÃO GERAL
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
        -- false: única janela no ws respeita column_width e SUPER+Q/E encolhe
        fullscreen_on_one_column = false,
        focus_fit_method         = 1,        -- 0 = center, 1 = fit
        follow_focus             = true,     -- scroll pra janela focada (mouse/teclado)
        follow_min_visible       = 0.01,     -- 0.0 exato pode falhar no 0.55; hover foca coluna parcial
        explicit_column_widths   = "0.2, 0.25, 0.333, 0.5, 0.667, 1.0",
        wrap_swapcol             = false,    -- swap só com coluna vizinha, sem wrap
    },

    misc = {
        vrr                          = 0,    -- EGL fence sync quebra com VRR no AMD 780M
        initial_workspace_tracking   = 1,    -- 1=on, 0=off
        focus_on_activate            = false,  -- bell → só urgent, sem puxar foco
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
        dim_inactive = true,
        dim_strength = 0.1,  -- indicador discreto de monitor/janela ativa (apaga sutilmente o inativo)
    },

    cursor = {
        inactive_timeout = 3,  -- esconde após 3s sem movimento
        no_warps         = true,  -- não teleporta cursor ao trocar foco de monitor (SUPER+Esc)
    },

    input = {
        kb_layout   = "us",
        kb_variant  = "altgr-intl",
        kb_options  = "caps:hyper",  -- Caps Lock → MOD3/Hyper
        follow_mouse = 1,              -- foco segue o mouse (sloppy focus)
        follow_mouse_threshold = 0,    -- sensível desde o primeiro pixel
        float_switch_override_focus = 1,
        scroll_factor = 0.7,

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            tap_to_click         = true,
            drag_lock            = false,
            clickfinger_behavior = false,
        },
    },

    animations = {
        enabled = true,
    },

    xwayland = {
        -- monitores em scale 2.0: sem isso apps X11 renderizam em 1x e são
        -- esticados 2x pelo compositor (popups pequenos borrados/esticados)
        force_zero_scaling = true,
    },
})

-- =============================================
--  5. CURVES + ANIMATIONS
-- =============================================

-- instant: aggressive ease-out, feels like zero delay
hl.curve("instant",  { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })

-- overshot: slight bounce para special workspaces
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",          enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "windowsOut",       enabled = false })
hl.animation({ leaf = "windowsMove",      enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "border",           enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "borderangle",      enabled = false })
hl.animation({ leaf = "fade",             enabled = true,  speed = 1, bezier = "instant" })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 1, bezier = "instant", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 2, bezier = "instant", style = "slidevert" })
