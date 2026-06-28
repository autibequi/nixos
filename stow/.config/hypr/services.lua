-- ============================================================
--  SERVICES — wrappers pra restart de bars/shells/notif
--
--  waybar / quickshell / clipboard popup / hypr_reload — cada um
--  é um one-liner sem state. Mantidos juntos pra fácil edição.
--  Todo spawn passa por launcher.build (uwsm app -- + flags).
-- ============================================================

local core = require("core")
local L    = require("launcher")

function waybar_refresh()
    hl.exec_cmd("systemctl --user restart waybar")
    hl.exec_cmd("pkill bongocat")
    -- bongocat só roda quando AC plugged (gate via sh)
    hl.exec_cmd([[sh -c '[ "$(cat /sys/class/power_supply/ADP0/online 2>/dev/null)" = "1" ] && ]]
        .. L.build("bongocat --config ~/.config/bongocat/bongocat.conf")
        .. [[ || true']])
end

function quickshell_restart()
    hl.exec_cmd("pkill quickshell")
    core.timer(300, function() hl.exec_cmd(L.build("qs")) end)
end

function clipboard_history()
    hl.exec_cmd(L.build([[alacritty --class='clipboard-history-popup,clipboard-history-popup' --title='Clipboard History' -o window.dimensions.columns=120 -o window.dimensions.lines=30 -e sh -c 'cliphist list | fzf --preview "echo {} | cliphist decode" --preview-window=right:50%:wrap --layout=reverse --prompt="Clipboard History: " --bind "enter:execute(echo {} | cliphist decode | wl-copy)+abort"']]))
end

function hypr_reload()
    hl.exec_cmd("swaync-client -rs -R")
    waybar_refresh()
    quickshell_restart()
    hl.exec_cmd("hyprctl reload")
    core.notify("Hyprland reloaded", nil, { urgency = "low" })
end
