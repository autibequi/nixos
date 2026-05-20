-- ============================================================
--  EVENTS — hooks reativos via hl.on(...)
--
--  Wrappear cada hook em pcall: se a versão do Hyprland Lua não
--  suportar o nome do evento, falha silenciosa em vez de quebrar
--  o config inteiro.
--
--  Eventos válidos (Hyprland 0.55 — listados em hl.on error):
--    hyprland.start / hyprland.shutdown / config.reloaded
--    workspace.active / workspace.created / workspace.removed / workspace.move_to_monitor
--    window.open / window.open_early / window.close / window.destroy / window.kill
--    window.active / window.title / window.class / window.urgent / window.pin
--    window.fullscreen / window.update_rules / window.move_to_workspace
--    monitor.added / monitor.removed / monitor.focused / monitor.layout_changed
--    layer.opened / layer.closed
--    keybinds.submap / screenshare.state
-- ============================================================

local core = require("core")
local on   = core.on

-- ── Workspace policy ─────────────────────────────────────────
-- F1 (Work): silenciar notif pessoais; F9 (.ovault): mute mic.

on("workspace.active", function(ev)
    local name = (ev and (ev.name or ev.workspace)) or ""
    -- Workspace regular ativo: esconde qualquer special visível (cobre clique no Waybar)
    if name ~= "" and name:sub(1, 8) ~= "special:" then
        hide_active_special_workspaces()
    end
    -- Políticas por workspace
    if name == "special:f1" then
        hl.exec_cmd("swaync-client -d")  -- DND on
        core.notify("Modo Work", "F1 — notif pessoais silenciadas", { timeout = 800, urgency = "low" })
    elseif name == "special:f9" then
        hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1")
        core.notify("Modo Pessoal", "F9 — mic mutado, no_screen_share", { timeout = 800, urgency = "low" })
    elseif name == "1" or name == "2" or name == "3" then
        -- workspaces "neutros" DP-2: garante DND off
        hl.exec_cmd("swaync-client -d 2>/dev/null | grep -q true && swaync-client -d")
    end
end)

-- ── Window auto-routing ──────────────────────────────────────
-- Slack/Zoom abrem em special:f5 (chat), evita poluir wsp de código.

local CHAT_APPS = { ["Slack"] = true, ["zoom"] = true, ["zoom_linux_float_video_window"] = true }

on("window.open", function(ev)
    local class = (ev and (ev.class or ev.window_class)) or ""
    if CHAT_APPS[class] then
        local addr = ev and (ev.address or ev.window_address)
        if addr then
            hl.exec_cmd("hyprctl dispatch movetoworkspacesilent special:f5,address:" .. addr)
        end
    end
end)

-- ── Monitor hotplug ──────────────────────────────────────────
-- Dock in/out: reaplica workspace rules, reload waybar.

on("monitor.added", function(ev)
    core.notify("Monitor conectado", (ev and ev.name) or "?", { timeout = 1500, urgency = "low" })
    hl.exec_cmd("hyprctl reload")
    if type(waybar_refresh) == "function" then waybar_refresh() end
end)

on("monitor.removed", function(ev)
    core.notify("Monitor desconectado", (ev and ev.name) or "?", { timeout = 1500, urgency = "low" })
    if type(waybar_refresh) == "function" then waybar_refresh() end
end)

-- ── Urgent (atenção visual) ─────────────────────────────────
on("window.urgent", function(ev)
    local class = (ev and (ev.class or ev.window_class)) or "?"
    core.notify("Urgent: " .. class, nil, { timeout = 1200, urgency = "normal" })
end)
