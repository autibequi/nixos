-- ============================================================
--  SPECIALS FEED — gera JSON pro módulo waybar custom/special-workspaces.
--
--  Versão zero-io.popen:
--    - Lista de specials vem de core.known_specials (populado por define_special)
--    - Workspace ativo vem de hl.get_active_monitor() — API nativa, sem fork
--    - Sem ícones de apps (que exigiam hyprctl clients + io.popen)
--
--  Output (waybar custom module):
--    { "text": "<pango...>", "tooltip": "<lines>", "class": "special|empty" }
-- ============================================================

local core   = require("core")
local SIGNAL = "pkill -RTMIN+11 waybar"
local OUTPUT = "/tmp/waybar-specials.json"

-- #region agent log
local function agent_debug_log(message, data)
    local fields = {}
    for k, v in pairs(data or {}) do
        local value = tostring(v or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", " ")
        table.insert(fields, '"' .. tostring(k) .. '":"' .. value .. '"')
    end
    local f = io.open("/home/pedrinho/nixos/.cursor/debug-1605cf.log", "a")
    if f then
        f:write(string.format(
            '{"sessionId":"1605cf","runId":"open-close-freeze-debug","hypothesisId":"H8","location":"stow/.config/hypr/specials-feed.lua","message":"%s","data":{%s},"timestamp":%d}\n',
            message,
            table.concat(fields, ","),
            os.time() * 1000
        ))
        f:close()
    end
end
-- #endregion

local function json_escape(s)
    return (s or ""):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
end

local function build_payload()
    local mon      = hl.get_active_monitor()
    local active   = (mon and mon.specialWorkspace and mon.specialWorkspace.name) or ""

    local parts, tips = {}, {}
    for _, s in ipairs(core.known_specials) do
        local is_active = (s.ws == active)
        -- Mostra só o ativo; se quiser todos com janelas precisaria de clients
        if is_active then
            local label = string.format(
                "<span foreground='%s' weight='bold'>%s</span>",
                s.color, s.label)
            table.insert(parts, label)
            table.insert(tips, s.label .. " (ativo)")
        end
    end

    if #parts == 0 then
        return '{"text":"","tooltip":"sem special workspace ativo","class":"empty"}'
    end

    return string.format('{"text":"%s","tooltip":"%s","class":"special"}',
        json_escape(table.concat(parts, "  ")),
        json_escape(table.concat(tips, "\n")))
end

local function refresh()
    -- #region agent log
    agent_debug_log("refresh start", {})
    -- #endregion
    local payload = build_payload()
    local f = io.open(OUTPUT, "w")
    if f then f:write(payload); f:close() end
    hl.exec_cmd(SIGNAL)
    -- #region agent log
    agent_debug_log("refresh end", {})
    -- #endregion
end

-- Coalescing: event handlers apenas marcam dirty + timer 100ms.
-- O refresh real acontece fora do event handler com IPC livre.
local _dirty = false
local function schedule_refresh()
    -- #region agent log
    agent_debug_log("schedule_refresh", { dirty = tostring(_dirty) })
    -- #endregion
    if _dirty then return end
    _dirty = true
    pcall(function()
        hl.timer(function()
            _dirty = false
            refresh()
        end, { timeout = 100, type = "oneshot" })
    end)
end

core.on("workspace.created",        schedule_refresh)
core.on("workspace.removed",        schedule_refresh)
core.on("workspace.active",         schedule_refresh)
core.on("window.open",              schedule_refresh)
core.on("window.close",             schedule_refresh)
core.on("window.move_to_workspace", schedule_refresh)

-- Só dispara após Hyprland totalmente iniciado (IPC livre).
-- Reloads são cobertos pelos eventos acima no próximo workspace switch.
hl.on("hyprland.start", function() schedule_refresh() end)
