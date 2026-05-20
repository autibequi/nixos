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
--    Reduz io.popen("hyprctl clients -j") redundante em keybinds
--    rápidos (cycler/submaps/hud/picker). Default 1s.
local _clients_cache = { at = 0, data = nil }
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

return M
