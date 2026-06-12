-- ============================================================
--  UTILS — state de special workspaces + helpers de navegação
--
--  Funções de baixo nível espalhadas para módulos dedicados:
--    get_clients_compat → clients.lua
--    print_screen_*     → screenshots.lua
--    waybar/qs/clipboard/hypr_reload → services.lua
-- ============================================================

local core = require("core")

-- ── State em memória (substitui arquivos ~/.cache/hyprland/) ──
-- Perdido em reload — aceitável (mesmo comportamento de arquivos em /tmp em novos boots)
local _last_special_ws = {}  -- { monitor_name = ws_name }

-- Stack de specials por monitor (back/forward browser-like)
-- { monitor_name = { stack = {"f1", "f5", "bleh", ...}, idx = N } }
local _special_history = {}
local SPECIAL_HISTORY_MAX = 16

local function _hist(mon)
    _special_history[mon] = _special_history[mon] or { stack = {}, idx = 0 }
    return _special_history[mon]
end

local function _push_history(mon, name)
    local h = _hist(mon)
    -- se estamos no meio do stack (após back), trunca o "forward" antes de empurrar
    while #h.stack > h.idx do table.remove(h.stack) end
    -- dedupe: não empurra se já é o topo
    if h.stack[#h.stack] == name then return end
    table.insert(h.stack, name)
    if #h.stack > SPECIAL_HISTORY_MAX then table.remove(h.stack, 1) end
    h.idx = #h.stack
end

-- ── Helpers ──────────────────────────────────────────────────

local function active_monitor()
    return hl.get_active_monitor()
end

local function active_monitor_name()
    local m = active_monitor()
    return m and m.name or ""
end

local function active_special_name()
    -- Nome do special ativo no monitor focado, sem prefixo "special:". "" se nenhum.
    local m = active_monitor()
    local sw = m and m.specialWorkspace
    if sw and sw.name and sw.name ~= "" then
        return sw.name:gsub("^special:", "")
    end
    return ""
end

-- ── Workspace Switch ─────────────────────────────────────────

function workspace_switch(ws)
    if ws:sub(1, 8) == "special:" then
        local name = ws:sub(9)
        local mon = active_monitor_name()
        _last_special_ws[mon] = name
        _push_history(mon, name)
        local was_active = active_special_name() == name
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        if was_active then hl.exec_cmd("pkill -x rofi") end
    else
        hide_active_special_workspaces()
        hl.dispatch(hl.dsp.focus({ workspace = ws }))
    end
end

function special_back()
    local mon = active_monitor_name()
    local h = _hist(mon)
    if h.idx <= 1 then return end
    h.idx = h.idx - 1
    local target = h.stack[h.idx]
    if not target then return end
    hide_active_special_workspaces()
    hl.dispatch(hl.dsp.workspace.toggle_special(target))
    _last_special_ws[mon] = target
end

function special_forward()
    local mon = active_monitor_name()
    local h = _hist(mon)
    if h.idx >= #h.stack then return end
    h.idx = h.idx + 1
    local target = h.stack[h.idx]
    if not target then return end
    hide_active_special_workspaces()
    hl.dispatch(hl.dsp.workspace.toggle_special(target))
    _last_special_ws[mon] = target
end

function toggle_last_special_workspace()
    local mon     = active_monitor_name()
    local current = active_special_name()
    if current ~= "" then
        _last_special_ws[mon] = current
        hl.dispatch(hl.dsp.workspace.toggle_special(current))
        hl.exec_cmd("pkill -x rofi")
        return
    end
    local last = _last_special_ws[mon]
    if last and last ~= "" then
        hl.dispatch(hl.dsp.workspace.toggle_special(last))
    end
end

function hide_active_special_workspaces()
    local name = active_special_name()
    if name ~= "" then
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        hl.exec_cmd("pkill -x rofi")
    end
end

-- Alias usado pelo bind SUPER (release)
toggle_or_hide_special_workspace = hide_active_special_workspaces

-- ── Colresize sem wrap ────────────────────────────────────────
-- Para no mínimo (0.22) e máximo (0.85) em vez de cyclar

function colresize_no_wrap(direction)
    local win = hl.get_active_window()
    local mon = active_monitor()

    if win and mon and win.size and win.size[1] and mon.width and mon.scale then
        local ratio = win.size[1] / (mon.width / mon.scale)
        if direction == "+" and ratio >= 0.85 then return end
        if direction == "-" and ratio <= 0.22 then return end
    end

    hl.dispatch(hl.dsp.layout("colresize " .. direction .. "conf"))
end

-- ── Monitor switching ─────────────────────────────────────────

function move_special_workspace_to_monitor()
    local active = active_special_name()
    if active == "" then
        core.notify("Hyprland", "No special workspace visible", { urgency = "low" })
        return
    end

    local next_mon = core.other_monitor(active_monitor_name())
    if not next_mon then return end

    hl.dispatch(hl.dsp.workspace.toggle_special(active))
    hl.dispatch(hl.dsp.focus({ monitor = next_mon.name }))
    hl.dispatch(hl.dsp.workspace.toggle_special(active))
end

function move_normal_workspace_to_monitor()
    local next_mon = core.other_monitor(active_monitor_name())
    if not next_mon then return end

    hl.dispatch(hl.dsp.focus({ monitor = next_mon.name }))
    if next_mon.activeWorkspace then
        hl.dispatch(hl.dsp.focus({ workspace = tostring(next_mon.activeWorkspace.id) }))
    end
end
