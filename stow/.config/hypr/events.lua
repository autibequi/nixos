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

-- #region agent log
local function agent_debug_json(s)
    return tostring(s or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", " ")
end

local function agent_debug_log(hypothesis_id, message, data)
    local fields = {}
    for k, v in pairs(data or {}) do
        table.insert(fields, '"' .. agent_debug_json(k) .. '":"' .. agent_debug_json(v) .. '"')
    end

    local f = io.open("/home/pedrinho/nixos/.cursor/debug-1605cf.log", "a")
    if f then
        f:write(string.format(
            '{"sessionId":"1605cf","runId":"hyprland-freeze-debug","hypothesisId":"%s","location":"stow/.config/hypr/events.lua","message":"%s","data":{%s},"timestamp":%d}\n',
            agent_debug_json(hypothesis_id),
            agent_debug_json(message),
            table.concat(fields, ","),
            os.time() * 1000
        ))
        f:close()
    end
end
-- #endregion

-- ── Workspace policy ─────────────────────────────────────────
-- Políticas opt-in declaradas em special-workspaces.lua via define_special
-- (on_active = fn). Workspaces regulares 1-3 forçam DND off (não pertence a um
-- special específico, fica aqui).

on("workspace.active", function(ev)
    local name = (ev and (ev.name or ev.workspace)) or ""
    -- #region agent log
    agent_debug_log("H4,H5", "workspace.active start", { workspace = name })
    -- #endregion
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
    -- #region agent log
    agent_debug_log("H4,H5", "workspace.active end", { workspace = name })
    -- #endregion
end)

-- ── Window routing ───────────────────────────────────────────
-- 1. Classes com auto_route_classes vão pro special workspace.
-- 2. Demais janelas são devolvidas ao workspace onde o app foi
--    lançado (launch-home), evitando que apps lentos abram no
--    workspace errado quando você troca enquanto espera.

on("window.open", function(ev)
    local class = (ev and (ev.class or ev.window_class)) or ""
    local addr  = ev and (ev.address or ev.window_address)
    -- #region agent log
    agent_debug_log("H4,H5", "window.open start", { class = class, hasAddress = tostring(addr ~= nil) })
    -- #endregion

    if class == "org.quickshell" then
        -- #region agent log
        agent_debug_log("H4", "window.open skip-shell", { class = class })
        -- #endregion
        return
    end

    -- Auto-route para special workspace (não consome pending_home)
    local target = core.workspace_auto_route_classes[class]
    if target then
        -- #region agent log
        agent_debug_log("H4", "window.open auto-route", { class = class, target = target })
        -- #endregion
        if addr then
            hl.exec_cmd("hyprctl dispatch movetoworkspacesilent special:" ..
                target .. ",address:" .. addr)
        end
        -- #region agent log
        agent_debug_log("H4,H5", "window.open end", { class = class, branch = "auto-route" })
        -- #endregion
        return
    end

    -- Launch-home: devolve ao workspace de origem do lançamento
    local home_ws = core.pop_home()
    if home_ws and addr then
        -- #region agent log
        agent_debug_log("H4", "window.open launch-home", { class = class, homeWorkspace = home_ws })
        -- #endregion
        hl.exec_cmd("hyprctl dispatch movetoworkspacesilent " ..
            home_ws .. ",address:" .. addr)
    end
    -- #region agent log
    agent_debug_log("H4,H5", "window.open end", { class = class, branch = "default" })
    -- #endregion
end)

-- ── Monitor hotplug ──────────────────────────────────────────
-- Dock in/out: reaplica workspace rules, reload waybar.

on("monitor.added", function(ev)
    core.notify("Monitor conectado", (ev and ev.name) or "?", { timeout = 1500, urgency = "low" })
    hl.exec_cmd("hyprctl reload")
    -- Só reinicia waybar em hotplug real; no boot o monitor.added dispara pra cada
    -- monitor antes do hyprland.start, e chamar waybar_refresh() N vezes resulta em
    -- N instâncias simultâneas de waybar.
    if _G.HYPRLAND_STARTED and type(waybar_refresh) == "function" then waybar_refresh() end
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
on("window.close", function(ev)
    local class = (ev and (ev.class or ev.window_class)) or ""
    local addr = ev and (ev.address or ev.window_address)
    -- #region agent log
    agent_debug_log("H6,H8", "window.close", { class = class, hasAddress = tostring(addr ~= nil) })
    -- #endregion
    invalidate()
end)
on("window.move_to_workspace", invalidate)
