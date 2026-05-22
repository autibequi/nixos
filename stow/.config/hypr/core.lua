-- ============================================================
--  CORE — helpers compartilhados
--
--  Substitui wrappers redundantes em events/screenshare_guard/
--  followme/specials-feed (on), theme/profiles/pomodoro
--  (state_file/notify/timer), cycler/submaps/hud/picker
--  (focused/clients_cached), hyprshortcuts/picker (escape_sh/trunc),
--  utils (other_monitor).
--
--  Carregado primeiro em hyprland.lua. Não depende de utils.lua
--  (clients_cached só chama get_clients_compat() em runtime).
-- ============================================================

local M = {}

local HOME      = os.getenv("HOME")
local CACHE_DIR = HOME .. "/.cache/hyprland"

-- ── shell-escape pra strings em '...' (single-quoted shell) ───
function M.escape_sh(s)
    return (s or ""):gsub("'", "'\\''")
end

-- ── trunc(s, n) — limita strings longas pra UI ────────────────
function M.trunc(s, n)
    s = s or ""
    if #s <= n then return s end
    return s:sub(1, n - 1) .. "…"
end

-- ── notify(title, body, opts) — notify-send com escape ────────
--    opts = { urgency = "low|normal|critical", timeout = ms, app = "name" }
function M.notify(title, body, opts)
    opts = opts or {}
    local parts = { "notify-send" }
    if opts.timeout then table.insert(parts, "-t " .. opts.timeout) end
    if opts.urgency then table.insert(parts, "-u " .. opts.urgency) end
    if opts.app     then table.insert(parts, "-a " .. opts.app)     end
    table.insert(parts, "'" .. M.escape_sh(title) .. "'")
    if body and body ~= "" then
        table.insert(parts, "'" .. M.escape_sh(body) .. "'")
    end
    hl.exec_cmd(table.concat(parts, " "))
end

-- ── on(event, handler) — hl.on com pcall + logger fallback ────
function M.on(event, handler)
    local ok, err = pcall(function() hl.on(event, handler) end)
    if not ok then
        hl.exec_cmd("logger -t hyprland-lua 'hl.on(" .. event ..
            ") falhou: " .. tostring(err) .. "'")
    end
end

-- ── timer(ms, fn) — hl.timer oneshot com pcall ────────────────
function M.timer(ms, fn)
    pcall(function()
        hl.timer(fn, { timeout = ms, type = "oneshot" })
    end)
end

-- ── state_file(name) → { path, load(), save(str) } ────────────
--    Centraliza padrão dos profiles/theme/pomodoro:
--    ~/.cache/hyprland/<name>
function M.state_file(name)
    local path = CACHE_DIR .. "/" .. name
    return {
        path = path,
        load = function()
            local f = io.open(path, "r")
            if not f then return nil end
            local s = f:read("*l")
            f:close()
            return s
        end,
        save = function(s)
            os.execute("mkdir -p " .. CACHE_DIR)
            local f = io.open(path, "w")
            if f then f:write(s) f:close() end
        end,
    }
end

-- ── other_monitor(cur_name) — devolve outro monitor (≠ cur) ───
function M.other_monitor(cur_name)
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name ~= cur_name then return m end
    end
end

-- ── clients_cached(ttl_s?) — cache em torno de get_clients_compat
--    Reduz io.popen("hyprctl clients -j") em keybinds rápidos
--    (cycler/submaps/hud/picker/hyprshortcuts).
--
--  Invalidação dupla:
--    1. TTL (default 1s) — fallback se algum evento escapar
--    2. Event-driven (window.open/close/move_to_workspace) — preferencial:
--       cache fica válido 100% do tempo entre eventos. Registrado em
--       events.lua via core.invalidate_clients_cache().
local _clients_cache = { at = 0, data = nil }

function M.invalidate_clients_cache()
    _clients_cache.data = nil
end

-- clients_stale() — retorna o cache como está, SEM nunca chamar io.popen.
-- Útil em event handlers onde io.popen("hyprctl clients") deadlocaria o IPC.
-- Retorna lista vazia se o cache nunca foi populado.
function M.clients_stale()
    return _clients_cache.data or {}
end

function M.clients_cached(ttl_s)
    ttl_s = ttl_s or 1
    local now = os.time()
    if _clients_cache.data and (now - _clients_cache.at) < ttl_s then
        return _clients_cache.data
    end
    _clients_cache.data = (type(get_clients_compat) == "function"
        and get_clients_compat()) or {}
    _clients_cache.at = now
    return _clients_cache.data
end

-- ── focused() — client focado (via cache) ─────────────────────
function M.focused()
    for _, c in ipairs(M.clients_cached()) do
        if c.focused then return c end
    end
    return nil
end

-- ── Policy registries (preenchidos por special-workspaces.lua) ─
--    workspace_active_handlers[ws_name_com_prefixo]    → fn(ev)
--    workspace_auto_route_classes[window_class]        → ws_name_sem_prefixo
--    known_specials                                     → { {name, label, color}, ... }
--
--  Consumidos por events.lua e specials-feed.lua. Defaults vazios.
M.workspace_active_handlers     = {}
M.workspace_auto_route_classes  = {}
M.known_specials                = {}  -- registry sem io.popen pra specials-feed

-- ── rofi_menu(entries, opts) — shell-out unificado ────────────
--    entries = list of { display = "...", payload = "..." }
--    opts:
--      prompt    = "Window" / "Shortcuts"
--      width     = 140 (int, opcional)
--      on_select = string bash que usa "$payload" no contexto selecionado
--                  (e.g. 'hyprctl dispatch focuswindow address:"$payload" &')
--
--  Substitui o boilerplate idêntico de hyprshortcuts.lua e picker.lua:
--  monta script bash temporário com rofi -dmenu + lookup do índice → payload.
function M.rofi_menu(entries, opts)
    opts = opts or {}
    if #entries == 0 then return end

    local lines = {
        "#!/usr/bin/env bash",
        "rofi_input=''",
        "declare -a payloads=()",
    }
    for i, e in ipairs(entries) do
        table.insert(lines,
            "rofi_input+=$'" .. M.escape_sh(e.display) .. "\\n'")
        table.insert(lines,
            "payloads[" .. i .. "]='" .. M.escape_sh(e.payload) .. "'")
    end

    local prompt = M.escape_sh(opts.prompt or "Select")
    local width  = tostring(opts.width or 140)
    table.insert(lines, "selected=$(printf \"%s\" \"$rofi_input\" | " ..
        "rofi -dmenu -i -p '" .. prompt .. "' -width " .. width .. ")")
    table.insert(lines, "[ -z \"$selected\" ] && exit 0")
    table.insert(lines, "idx=$(printf \"%s\" \"$rofi_input\" | " ..
        "grep -nxF \"$selected\" | head -1 | cut -d: -f1)")
    table.insert(lines, "[ -z \"$idx\" ] && exit 0")
    table.insert(lines, "payload=\"${payloads[$idx]}\"")
    table.insert(lines, "[ -z \"$payload\" ] && exit 0")
    if opts.on_select then
        table.insert(lines, opts.on_select)
    end

    local tmpf = os.tmpname()
    local sf = io.open(tmpf, "w")
    if not sf then return end
    sf:write(table.concat(lines, "\n"))
    sf:close()

    hl.exec_cmd("sh '" .. tmpf .. "' ; rm -f '" .. tmpf .. "'")
end

-- ── Launch-home workspace routing ─────────────────────────────
-- Registra o workspace no momento do lançamento. Quando a janela
-- abre (possivelmente em outro workspace), events.lua a devolve
-- silenciosamente ao workspace de origem.
local _HOME_TTL_S = 120
M._pending_homes  = {}

function M.get_active_ws()
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.focused then
            local ws = m.active_workspace
            if ws then return ws.name or tostring(ws.id) end
        end
    end
    return nil
end

function M.push_home(ws)
    local now, fresh = os.time(), {}
    for _, e in ipairs(M._pending_homes) do
        if (now - e.at) < _HOME_TTL_S then table.insert(fresh, e) end
    end
    table.insert(fresh, { ws = ws, at = now })
    M._pending_homes = fresh
end

function M.pop_home()
    local now = os.time()
    while #M._pending_homes > 0 do
        local e = table.remove(M._pending_homes, 1)
        if (now - e.at) < _HOME_TTL_S then return e.ws end
    end
    return nil
end

return M
