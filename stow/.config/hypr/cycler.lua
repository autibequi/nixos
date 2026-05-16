-- ============================================================
--  CYCLER — Alt-Tab por aplicação (cicla janelas do mesmo class)
--
--  Caso de uso: você tem 4 Chromes ou 3 Zeds. Em vez de abrir
--  picker e filtrar, MOD3+i pula direto pra próxima instância
--  do mesmo app que está focado.
--
--  Bind: MOD3 + i (i de "instance")
--    + SHIFT → próxima janela do app (forward)
--    sem SHIFT → próxima janela do app (forward — alt-tab style)
-- ============================================================

local function focused_window()
    local clients = get_clients_compat() or {}
    for _, c in ipairs(clients) do
        if c.focused then return c end
    end
    return nil
end

local function siblings_of(class, exclude_addr)
    local out = {}
    for _, c in ipairs(get_clients_compat() or {}) do
        if c.class == class and c.address ~= exclude_addr then
            table.insert(out, c)
        end
    end
    -- ordena por workspace.id, depois por address pra estabilidade
    table.sort(out, function(a, b)
        local aw = (a.workspace and a.workspace.id) or 99
        local bw = (b.workspace and b.workspace.id) or 99
        if aw ~= bw then return aw < bw end
        return (a.address or "") < (b.address or "")
    end)
    return out
end

function cycle_same_class()
    local cur = focused_window()
    if not cur then
        hl.exec_cmd("notify-send 'Cycler' 'Sem janela focada' -u low")
        return
    end
    local sibs = siblings_of(cur.class, cur.address)
    if #sibs == 0 then
        hl.exec_cmd("notify-send -t 800 'Cycler' " ..
            "'" .. (cur.class or "?") .. ": única instância' -u low")
        return
    end
    local next_w = sibs[1]
    hl.exec_cmd("hyprctl dispatch focuswindow address:" .. next_w.address)
end

-- Cycle backwards: pega o último irmão por ordem
function cycle_same_class_back()
    local cur = focused_window()
    if not cur then return end
    local sibs = siblings_of(cur.class, cur.address)
    if #sibs == 0 then return end
    local prev_w = sibs[#sibs]
    hl.exec_cmd("hyprctl dispatch focuswindow address:" .. prev_w.address)
end

hl.bind("MOD3 + i",         function() cycle_same_class() end,      { ["repeat"] = true })
hl.bind("MOD3 + SHIFT + i", function() cycle_same_class_back() end, { ["repeat"] = true })
