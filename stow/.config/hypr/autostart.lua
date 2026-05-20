-- ============================================================
--  AUTOSTART — daemons + cursor + tema inicial em hyprland.start
--
--  Todo spawn passa por launcher.build (uwsm app -- + flags) pra
--  que HYPR_NO_UWSM tenha efeito também aqui.
-- ============================================================

local L = require("launcher")

hl.on("hyprland.start", function()
    -- Cursor XWayland
    hl.exec_cmd("xrdb ~/.Xresources")
    hl.exec_cmd("hyprctl setcursor BreezeX-RosePine-Linux 48")

    -- Session core (todos via uwsm — alguns precisam raw=true se já incluírem 'uwsm')
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(L.build("swayosd-server"))
    hl.exec_cmd(L.build("waybar"))
    hl.exec_cmd(L.build("qs"))
    hl.exec_cmd(L.build("swww-daemon"))
    hl.exec_cmd("swww img " .. os.getenv("HOME") ..
        "/assets/wallpapers/the-wild-hunt-of-odin.jpg --transition-type none")
    hl.exec_cmd(L.build("swaync"))

    -- Clipboard
    hl.exec_cmd(L.build("wl-paste --watch cliphist store"))

    -- Tema escuro inicial
    dark_theme()
end)
