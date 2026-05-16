-- ============================================================
--  SYSTEM TOOLS KEYBINDS — portado de systemtools.conf
-- ============================================================

-- App Control
hl.bind("MOD3 + Escape", hl.dsp.window.close())

-- System Utils
hl.bind("MOD3 + d",    hl.dsp.exec_cmd("uwsm app -- nwg-displays"))
hl.bind("SUPER + p",   hl.dsp.exec_cmd("hyprpicker --autocopy --lowercase-hex"))

-- Special workspace: toggle_or_hide ao soltar SUPER sozinho
hl.bind("SUPER + Super_L", function() toggle_or_hide_special_workspace() end, { release = true })

-- Lock
hl.bind("SUPER + l", hl.dsp.exec_cmd("hyprlock"))

-- Reload / Power
hl.bind("SUPER + Delete", function() hypr_reload() end)
hl.bind("MOD3 + F10", hl.dsp.exec_cmd("sh -c 'zenity --question --text \"Log out?\" --title \"Logout\" && hyprctl dispatch exit'"))
hl.bind("MOD3 + F11", hl.dsp.exec_cmd("sh -c 'zenity --question --text \"Suspend system?\" --title \"Suspend\" && systemctl suspend'"))
hl.bind("MOD3 + F12", hl.dsp.exec_cmd("sh -c 'zenity --question --text \"Shut down?\" --title \"Shutdown\" && systemctl poweroff'"))

-- Shortcuts popup
hl.bind("SUPER + slash", function() show_shortcuts() end)

-- Window Management
hl.bind("SUPER + Tab",       hl.dsp.window.fullscreen({ mode = "maximized" }))  -- maximize
hl.bind("SUPER + ALT + Tab", hl.dsp.window.float({}))

-- Fullscreen
hl.bind("SUPER + F11",       hl.dsp.window.fullscreen_state({ internal = 0, client = 3 }))
hl.bind("SUPER + SHIFT + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Screenshots
hl.bind("SUPER + u",           function() print_screen_to_clipboard() end)
hl.bind("SUPER + ALT + u",       function() print_screen_full_then_crop() end)
hl.bind("SUPER + SHIFT + u",     function() tesseract_region() end)
hl.bind("SUPER + CTRL + u",      function() print_screen_full_then_crop() end)

-- Clipboard History
hl.bind("SUPER + SHIFT + v", function() clipboard_history() end)

-- Paste sem newlines (Ctrl+Alt+V)
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("sh -c 'wl-paste | tr -d \"\\n\" | wtype --'"))

-- Whisper Push-to-Talk
hl.bind("SUPER + v",           hl.dsp.exec_cmd("whisper-ctl start"))
hl.bind("SUPER + v",           hl.dsp.exec_cmd("whisper-ctl stop"), { release = true })

-- Dark Mode toggle
hl.bind("SUPER + n", function() toggle_theme() end)

-- ── Multimedia ────────────────────────────────────────────────

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { ["repeat"] = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-"), { ["repeat"] = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"))

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 2%+"), { ["repeat"] = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 2%-"), { ["repeat"] = true })
