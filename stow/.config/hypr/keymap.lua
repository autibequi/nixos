-- ============================================================
--  KEYMAP — wrapper de hl.bind com registry semântico
--
--  Cada bind carrega metadata (desc, group, icon) → cheatsheet
--  rica (rofi/quickshell) sem reverse-engineer de hyprctl binds.
--
--  Uso:
--    local km = require("keymap")
--    km.app("MOD3 + t", terminal, { desc = "Terminal", icon = "" })
--    km.bind("SUPER + l", hl.dsp.exec_cmd("hyprlock"),
--            { desc = "Lock", group = "System" })
--    km.fn("SUPER + n", toggle_theme,
--            { desc = "Toggle dark/light", group = "System" })
-- ============================================================

local M = {
    _binds = {},          -- registry ordenado
    _by_combo = {},       -- indice combo → entry (último vence em conflito)
}

local function register(combo, opts)
    opts = opts or {}
    local entry = {
        combo = combo,
        desc  = opts.desc  or "",
        group = opts.group or "Misc",
        icon  = opts.icon  or "",
    }
    table.insert(M._binds, entry)
    M._by_combo[combo] = entry
end

-- bind: ação já é um dispatcher ou function. Repassa opts.flags pra hl.bind.
function M.bind(combo, action, opts)
    opts = opts or {}
    hl.bind(combo, action, opts.flags)
    register(combo, opts)
end

-- app: ação é um comando string; spawn via hl.dsp.exec_cmd.
function M.app(combo, cmd, opts)
    opts = opts or {}
    opts.group = opts.group or "Apps"
    opts.desc  = opts.desc  or cmd
    M.bind(combo, hl.dsp.exec_cmd(cmd), opts)
end

-- fn: ação é uma função Lua.
function M.fn(combo, f, opts)
    M.bind(combo, function() f() end, opts)
end

-- dispatcher: helper pra hl.dsp.* (sem ter que escrever wrapper)
function M.dispatch(combo, dispatcher, opts)
    M.bind(combo, dispatcher, opts)
end

-- cheatsheet() → lista ordenada por (group, desc) pra UI
function M.cheatsheet()
    local list = {}
    for _, e in ipairs(M._binds) do table.insert(list, e) end
    table.sort(list, function(a, b)
        if a.group == b.group then return a.desc < b.desc end
        return a.group < b.group
    end)
    return list
end

-- groups() → set de grupos únicos
function M.groups()
    local seen, out = {}, {}
    for _, e in ipairs(M._binds) do
        if not seen[e.group] then
            seen[e.group] = true
            table.insert(out, e.group)
        end
    end
    table.sort(out)
    return out
end

return M
