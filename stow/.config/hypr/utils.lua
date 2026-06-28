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
        -- Se abrindo (não fechando) e o special tem on_created_empty, registrar home.
        -- Só confiamos nisso com cache já populado; cache vazio/desconhecido fazia
        -- qualquer toggle parecer "workspace vazio" e empilhava pending_home.
        if not was_active and core.special_empty_launchers[name]
            and core.clients_cache_ready and core.clients_cache_ready() then
            local full_ws = "special:" .. name
            local empty = true
            for _, c in ipairs(core.clients_stale()) do
                if c.workspace and c.workspace.name == full_ws then
                    empty = false; break
                end
            end
            if empty then core.push_home(full_ws) end
        end
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

-- ── Colresize sem wrap (SUPER+Q/E) ────────────────────────────
-- Incrementos relativos de 20% da largura do monitor.
-- Hyprland 0.55: win.size = { x, y }, não array indexado.

local COLRESIZE_STEP = 0.2

function colresize_no_wrap(direction)
    local win = hl.get_active_window()
    if not win then return end

    if win.floating then
        hl.dispatch(hl.dsp.window.float({}))
        return
    end

    local g = win.grouped
    if type(g) == "table" and #g > 0 then
        hl.dispatch(hl.dsp.layout("promote"))
    end

    local mon = hl.get_active_monitor()
    local w = win.size and win.size.x
    if w and mon and mon.width and mon.scale and mon.scale > 0 then
        local ratio = w / (mon.width / mon.scale)
        if direction == "+" and ratio >= 0.99 then return end
        if direction == "-" and ratio <= 0.19 then return end
    end

    hl.dispatch(hl.dsp.layout("colresize " .. direction .. COLRESIZE_STEP))
end

-- ── Swapcol preservando coluna (SUPER+SHIFT+A/D) ──────────────
-- Janela empilhada → promote na direção do swap; depois swapcol.
-- Coluna única → swapcol troca posição com a vizinha (sem merge).

local COLUMN_X_EPS = 8

local function window_at_x(win)
    if not win or not win.at then return nil end
    return win.at.x or win.at[1]
end

local function shares_column(win)
    local wx = window_at_x(win)
    local ws_id = win.workspace and win.workspace.id
    if not wx or not ws_id then return false end

    -- Nunca io.popen no keybind — só cache populado por events.lua
    local clients = core.clients_stale()
    if #clients == 0 then return false end

    for _, c in ipairs(clients) do
        if c.address ~= win.address
            and c.workspace and c.workspace.id == ws_id
            and c.at_x and math.abs(c.at_x - wx) <= COLUMN_X_EPS then
            return true
        end
    end
    return false
end

function swapcol_preserve(dir)
    local win = hl.get_active_window()
    if not win then return end

    if win.floating then
        hl.dispatch(hl.dsp.window.float({}))
        return
    end

    if shares_column(win) then
        hl.dispatch(hl.dsp.layout("promote " .. dir))
    end

    hl.dispatch(hl.dsp.layout("swapcol " .. dir))
end

-- ── Toggle maximize (scrolling layout) ────────────────────────
-- Maximize no scrolling = coluna largura 1.0 (não usa fullscreen state).
-- hl.dsp.window.fullscreen toggle não des-maximiza no 0.55 — colresize direto.

local _max_restore = {}  -- window address → column ratio (0.0–1.0)

local function column_ratio()
    local win = hl.get_active_window()
    local mon = hl.get_active_monitor()
    if not win or not win.size or not win.size.x then return nil end
    if not mon or not mon.width or not mon.scale or mon.scale == 0 then return nil end
    return win.size.x / (mon.width / mon.scale)
end

function toggle_maximize()
    local win = hl.get_active_window()
    if not win or not win.address then return end

    if win.floating then
        hl.dispatch(hl.dsp.window.float({}))
        return
    end

    local addr = win.address
    local ratio = column_ratio()

    if ratio and ratio >= 0.95 then
        local restore = _max_restore[addr] or 0.5
        _max_restore[addr] = nil
        hl.dispatch(hl.dsp.layout("colresize " .. restore))
    else
        if ratio then _max_restore[addr] = ratio end
        hl.dispatch(hl.dsp.layout("colresize 1.0"))
    end
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
