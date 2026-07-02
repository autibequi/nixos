-- ============================================================
--  CLIENTS — get_clients_compat()
--
--  hl.get_clients() não existe no Hyprland 0.55 Lua. Fallback:
--  parse simples de `hyprctl clients -j` com gsub (sem json lib).
--  Retorna lista de:
--    { address, class, title, pid, focused, at_x, at_y, workspace = {id, name} }
--
--  Wrap por core.clients_cached(ttl) pra evitar io.popen redundante
--  em keybinds rápidos (cycler/submaps/hud/picker).
-- ============================================================

local function _num(s) return tonumber(s) end

function get_clients_compat()
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
                local at_block = block:match('"at"%s*:%s*(%b[])')
                local at_x, at_y
                if at_block then
                    at_x = _num(at_block:match('%[%s*(%-?%d+)'))
                    at_y = _num(at_block:match(',%s*(%-?%d+)'))
                end
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
                        at_x      = at_x,
                        at_y      = at_y,
                        workspace = { id = ws_id, name = ws_name },
                    })
                end
                start = nil
            end
        end
    end
    return out
end
