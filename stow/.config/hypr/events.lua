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
-- Políticas opt-in declaradas em special-workspaces.lua via define_special
-- (on_active = fn). Workspaces regulares 1-3 forçam DND off (não pertence a um
-- special específico, fica aqui).

on("workspace.active", function(ev)
    local name = (ev and (ev.name or ev.workspace)) or ""
    -- Workspace regular ativo: esconde qualquer special visível (cobre clique no Waybar)
    if name ~= "" and name:sub(1, 8) ~= "special:" then
        hide_active_special_workspaces()
    end
    -- Handler declarado em define_special({ on_active = ... })
    local handler = core.workspace_active_handlers[name]
    if handler then
        local ok, err = pcall(handler, ev)
        if not ok then
            hl.exec_cmd("logger -t hyprland-lua 'on_active(" .. name ..
                ") falhou: " .. tostring(err) .. "'")
        end
    elseif name == "1" or name == "2" or name == "3" then
        -- workspaces "neutros" DP-2: garante DND off
        hl.exec_cmd("swaync-client -d 2>/dev/null | grep -q true && swaync-client -d")
    end
end)

-- ── Window auto-routing ──────────────────────────────────────
-- Classes declaradas em define_special({ auto_route_classes = {...} })
-- são roteadas pro special workspace correspondente.

on("window.open", function(ev)
    local class = (ev and (ev.class or ev.window_class)) or ""
    local target = core.workspace_auto_route_classes[class]
    if target then
        local addr = ev and (ev.address or ev.window_address)
        if addr then
            hl.exec_cmd("hyprctl dispatch movetoworkspacesilent special:" ..
                target .. ",address:" .. addr)
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

-- ── Clients cache invalidation ───────────────────────────────
-- Invalida apenas em eventos estruturais (nova janela, janela fechou, moveu
-- de workspace). NÃO inclui window.title/window.class — esses disparam
-- frequentemente (Chrome/YouTube) e forçariam io.popen("hyprctl clients")
-- dentro do event handler → conecta ao IPC do Hyprland na mesma thread →
-- freeze de 10s. TTL de 1s é suficiente como fallback.
local function invalidate() core.invalidate_clients_cache() end
on("window.open",              invalidate)
on("window.close",             invalidate)
on("window.move_to_workspace", invalidate)
