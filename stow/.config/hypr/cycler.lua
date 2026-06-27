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

local core = require("core")
local km   = require("keymap")

local function siblings_of(class, exclude_addr)
    local out = {}
    for _, c in ipairs(core.clients_stale()) do
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
    local cur = core.focused()
    if not cur then
        core.notify("Cycler", "Sem janela focada", { urgency = "low" })
        return
    end
    local sibs = siblings_of(cur.class, cur.address)
    if #sibs == 0 then
        core.notify("Cycler", (cur.class or "?") .. ": única instância",
            { timeout = 800, urgency = "low" })
        return
    end
    local next_w = sibs[1]
    hl.exec_cmd("hyprctl dispatch focuswindow address:" .. next_w.address)
end

-- Cycle backwards: pega o último irmão por ordem
function cycle_same_class_back()
    local cur = core.focused()
    if not cur then return end
    local sibs = siblings_of(cur.class, cur.address)
    if #sibs == 0 then return end
    local prev_w = sibs[#sibs]
    hl.exec_cmd("hyprctl dispatch focuswindow address:" .. prev_w.address)
end

km.repeating("MOD3 + i", function() cycle_same_class() end,
    { desc = "Cycle next instance of focused class", group = "Cycle", icon = "↻" })
km.repeating("MOD3 + SHIFT + i", function() cycle_same_class_back() end,
    { desc = "Cycle previous instance of focused class", group = "Cycle", icon = "↺" })
