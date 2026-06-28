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
    -- waybar, qs e hypridle rodam como systemd user service — reiniciam sozinhos se cair
    -- graphical-session.target não é ativado pelo UWSM neste setup, então iniciamos manualmente
    hl.exec_cmd("systemctl --user start waybar")
    hl.exec_cmd("systemctl --user start quickshell")
    hl.exec_cmd("systemctl --user start hypridle")
    hl.exec_cmd(L.build("awww-daemon"))
    hl.exec_cmd("awww img " .. os.getenv("HOME") ..
        "/assets/wallpapers/the-wild-hunt-of-odin.jpg --transition-type none")
    -- substituído por notif in-house (hypr-shell Onda 3)
    -- hl.exec_cmd(L.build("swaync"))

    -- Clipboard
    hl.exec_cmd(L.build("wl-paste --watch cliphist store"))

    -- Tema escuro inicial
    dark_theme()
end)
