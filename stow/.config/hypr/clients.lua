-- ============================================================
--  CLIENTS — get_clients_compat()
--
--  hl.get_clients() não existe no Hyprland 0.55 Lua. Fallback:
--  parse simples de `hyprctl clients -j` com gsub (sem json lib).
--  Retorna lista de:
--    { address, class, title, pid, focused, workspace = {id, name} }
--
--  Wrap por core.clients_cached(ttl) pra evitar io.popen redundante
--  em keybinds rápidos (cycler/submaps/hud/picker).
-- ============================================================

local function _num(s) return tonumber(s) end

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
            '{"sessionId":"1605cf","runId":"open-close-freeze-debug","hypothesisId":"H6","location":"stow/.config/hypr/clients.lua","message":"%s","data":{%s},"timestamp":%d}\n',
            message,
            table.concat(fields, ","),
            os.time() * 1000
        ))
        f:close()
    end
end
-- #endregion

function get_clients_compat()
    -- #region agent log
    local t0 = os.clock()
    agent_debug_log("hyprctl clients start", {})
    -- #endregion
    local p = io.popen("hyprctl clients -j 2>/dev/null")
    if not p then return {} end
    local raw = p:read("*a") or ""
    p:close()

    local out = {}
    -- Cada janela é um objeto JSON top-level. Em hyprctl clients -j vêm
    -- separados por },\n{. Estratégia: extrai cada bloco entre { ... } no
    -- nível raiz com depth counter.
    local depth, start = 0, nil
    for i = 1, #raw do
        local ch = raw:sub(i, i)
        if ch == "{" then
            if depth == 0 then start = i end
            depth = depth + 1
        elseif ch == "}" then
            depth = depth - 1
            if depth == 0 and start then
                local block = raw:sub(start, i)
                local addr  = block:match('"address"%s*:%s*"([^"]+)"')
                local class = block:match('"class"%s*:%s*"([^"]+)"')
                local title = block:match('"title"%s*:%s*"([^"]*)"')
                local pid   = _num(block:match('"pid"%s*:%s*(%-?%d+)'))
                local fhist = _num(block:match('"focusHistoryID"%s*:%s*(%-?%d+)'))
                -- workspace é objeto aninhado: "workspace": { "id": N, "name": "..." }
                local ws_block = block:match('"workspace"%s*:%s*(%b{})')
                local ws_id, ws_name
                if ws_block then
                    ws_id   = _num(ws_block:match('"id"%s*:%s*(%-?%d+)'))
                    ws_name = ws_block:match('"name"%s*:%s*"([^"]*)"')
                end
                if addr then
                    table.insert(out, {
                        address   = addr,
                        class     = class or "",
                        title     = title or "",
                        pid       = pid,
                        focused   = fhist == 0,
                        workspace = { id = ws_id, name = ws_name },
                    })
                end
                start = nil
            end
        end
    end
    -- #region agent log
    agent_debug_log("hyprctl clients end", {
        count = tostring(#out),
        cpuSeconds = string.format("%.3f", os.clock() - t0)
    })
    -- #endregion
    return out
end
