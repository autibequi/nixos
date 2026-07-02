-- ============================================================
--  AUTOSTART — daemons + cursor + tema inicial em hyprland.start
--
--  Todo spawn passa por launcher.build (uwsm app -- + flags) pra
--  que HYPR_NO_UWSM tenha efeito também aqui.
-- ============================================================

local L = require("launcher")

hl.on("hyprland.start", function()
    _G.HYPRLAND_STARTED = true

    -- Cursor XWayland
    hl.exec_cmd("xrdb ~/.Xresources")
    hl.exec_cmd("hyprctl setcursor BreezeX-RosePine-Linux 48")

    -- Session core (todos via uwsm — alguns precisam raw=true se já incluírem 'uwsm')
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- warp-taskbar antes do waybar (systray); XDG autostart não roda sem graphical-session
    hl.exec_cmd("systemctl --user start warp-taskbar.service")
    -- waybar, qs e hypridle rodam como systemd user service — reiniciam sozinhos se cair
    -- graphical-session.target não é ativado pelo UWSM neste setup, então iniciamos manualmente
    hl.exec_cmd("systemctl --user start waybar")
    hl.exec_cmd("systemctl --user start quickshell")
    hl.exec_cmd("systemctl --user start hypridle")
    hl.exec_cmd("systemctl --user start elephant")
    hl.exec_cmd("systemctl --user start walker")
    hl.exec_cmd(L.build("awww-daemon"))
    hl.exec_cmd("awww img " .. os.getenv("HOME") ..
        "/assets/wallpapers/the-wild-hunt-of-odin.jpg --transition-type none")
    -- Notification daemon (Quickshell Notifications desativado — conflita no D-Bus)
    hl.exec_cmd("systemctl --user start swaync")
    -- Clipboard
    hl.exec_cmd(L.build("wl-paste --watch cliphist store"))
    -- Toast no waybar + "pop" ao copiar (módulo custom/cliptoast)
    hl.exec_cmd(L.build("wl-paste --watch " .. os.getenv("HOME") .. "/.config/hypr/clip-toast.sh"))

    -- Notificador de tarefas Todoist (exec-once; loop interno de 60s)
    hl.exec_cmd(L.build(os.getenv("HOME") .. "/.config/hypr/todoist-notifier.sh"))

    -- Shader agendado (blue-light-filter à noite) — timer só cobre os boundaries
    hl.exec_cmd("hyprshade auto")

    -- Tema escuro inicial
    dark_theme()
end)
