-- ============================================================
--  SYSTEM TOOLS KEYBINDS — registry-aware
--  Apps de sistema, screenshots, multimedia, theme toggle.
-- ============================================================

local km = require("keymap")
local L  = require("launcher")

-- ── Window control ──────────────────────────────────────────
km.bind("MOD3 + Escape", hl.dsp.window.close(),
    { desc = "Close window", group = "Window", icon = "✕" })

-- ── System utils ────────────────────────────────────────────
km.app("MOD3 + d", L.build("nwg-displays"),
    { desc = "Display settings (nwg-displays)", group = "System", icon = "🖥" })

km.app("SUPER + p", "hyprpicker --autocopy --lowercase-hex",
    { desc = "Color picker", group = "System", icon = "🎨" })

-- Special workspace: toggle_or_hide ao soltar SUPER sozinho
km.release("SUPER + Super_L",
    function() toggle_or_hide_special_workspace() end,
    { desc = "Hide active special workspace", group = "Special" })

-- ── Lock + Power ────────────────────────────────────────────
km.app("SUPER + l", "hyprlock",
    { desc = "Lock screen", group = "System", icon = "🔒" })

km.fn("SUPER + Delete", function() hypr_reload() end,
    { desc = "Reload Hyprland", group = "System", icon = "↻" })

-- NOTA: SUPER + Escape virou focus monitor +1 (em workspace.lua).
-- Power menu fica só em MOD3 + F12.
km.app("MOD3 + F12", L.build("qs ipc call powermenu toggle", { raw = true }),
    { desc = "Power menu", group = "System", icon = "⏻" })

-- ── Help / Shortcuts ────────────────────────────────────────
km.fn("SUPER + slash", function() show_shortcuts() end,
    { desc = "Shortcuts (rofi)", group = "Help", icon = "?" })

-- ── Window management ───────────────────────────────────────
km.bind("SUPER + Tab",
    hl.dsp.window.fullscreen({ mode = "maximized" }),
    { desc = "Maximize window", group = "Window", icon = "🗖" })

km.bind("SUPER + ALT + Tab", hl.dsp.window.float({}),
    { desc = "Toggle floating", group = "Window" })

km.bind("SUPER + F11",
    hl.dsp.window.fullscreen_state({ internal = 0, client = 3 }),
    { desc = "Fullscreen state (client only)", group = "Window" })

km.bind("SUPER + SHIFT + F11",
    hl.dsp.window.fullscreen({ mode = "fullscreen" }),
    { desc = "True fullscreen", group = "Window" })

-- ── Screenshots ─────────────────────────────────────────────
km.fn("SUPER + u",         function() print_screen_to_clipboard() end,
    { desc = "Region → clipboard", group = "Screenshot", icon = "📸" })

km.fn("SUPER + ALT + u",   function() print_screen_full_then_crop() end,
    { desc = "Full monitor + crop", group = "Screenshot", icon = "📸" })

km.fn("SUPER + SHIFT + u", function() tesseract_region() end,
    { desc = "OCR region → clipboard", group = "Screenshot", icon = "🔡" })

-- NOTA: SUPER + CTRL + u removido (duplicado com SUPER + ALT + u).

-- ── Clipboard ───────────────────────────────────────────────
km.fn("SUPER + SHIFT + v", function() clipboard_history() end,
    { desc = "Clipboard history", group = "Clipboard", icon = "📋" })

km.app("CTRL + ALT + V",
    "sh -c 'wl-paste | tr -d \"\\n\" | wtype --'",
    { desc = "Paste without newlines", group = "Clipboard", icon = "📋" })

-- ── Whisper Push-to-Talk ────────────────────────────────────
km.app("SUPER + v", "whisper-ctl start",
    { desc = "Whisper PTT start", group = "Voice", icon = "🎤" })

km.release("SUPER + v", hl.dsp.exec_cmd("whisper-ctl stop"),
    { desc = "Whisper PTT stop (release)", group = "Voice" })

-- ── Theme toggle ────────────────────────────────────────────
km.fn("SUPER + n", function() toggle_theme() end,
    { desc = "Toggle dark/light theme", group = "Theme", icon = "🌓" })

-- ── Multimedia ──────────────────────────────────────────────
-- Sem swayosd: waybar mostra `pulseaudio` e `backlight` em tempo real
-- (pulseaudio module subscreve eventos pipewire; backlight via sysfs inotify).
-- Pra mic/caps usamos notify-send com x-canonical-private-synchronous,
-- que substitui a notif anterior em vez de stackar — discreto.
local SYNC_HINT_MIC  = "--hint string:x-canonical-private-synchronous:mic"
local SYNC_HINT_CAPS = "--hint string:x-canonical-private-synchronous:caps"

km.repeating("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
    { desc = "Volume up", group = "Audio", icon = "🔊" })

km.repeating("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { desc = "Volume down", group = "Audio", icon = "🔉" })

km.bind("XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { desc = "Mute toggle", group = "Audio", icon = "🔇" })

km.app("XF86AudioMicMute",
    "sh -c 'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && " ..
    "state=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo MUTED || echo on); " ..
    "notify-send -t 800 " .. SYNC_HINT_MIC .. " \"🎙 Mic $state\"'",
    { desc = "Mic mute toggle", group = "Audio", icon = "🎙" })

km.bind("XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { desc = "Play/pause", group = "Media", icon = "⏯" })

km.bind("XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { desc = "Play/pause (alt)", group = "Media", icon = "⏯" })

km.bind("XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { desc = "Next track", group = "Media", icon = "⏭" })

km.bind("XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { desc = "Previous track", group = "Media", icon = "⏮" })

km.repeating("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set +5%"),
    { desc = "Brightness up", group = "Brightness", icon = "☀" })

km.repeating("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 5%-"),
    { desc = "Brightness down", group = "Brightness", icon = "🌙" })

km.release("Caps_Lock",
    hl.dsp.exec_cmd("sh -c 'state=$(grep -q on <(xset q | grep \"Caps Lock\") && echo ON || echo OFF); " ..
        "notify-send -t 600 " .. SYNC_HINT_CAPS .. " \"⇪ Caps $state\"'"),
    { desc = "Caps Lock indicator (discreet)", group = "System" })
