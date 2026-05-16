-- ============================================================
--  FOLLOW-ME — sync de workspaces entre monitores
--
--  Pares (DP-2 ↔ eDP-1):
--    1 ↔ 7   2 ↔ 8   3 ↔ 9   4 ↔ 10   5/6 sem par
--
--  MOD3+F → toggle follow_mode
--  Quando ON: trocar workspace em um monitor força o par no outro.
--  Útil pra "código no 4K + docs no laptop" sempre alinhados.
-- ============================================================

local PAIRS = {
    ["1"]  = "7",   ["7"]  = "1",
    ["2"]  = "8",   ["8"]  = "2",
    ["3"]  = "9",   ["9"]  = "3",
    ["4"]  = "10",  ["10"] = "4",
}

local _follow_enabled = false
local _re_entry_guard = false  -- evita loop (a→b dispara workspace.active de b)

local function find_other_monitor(current_name)
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name ~= current_name then return m end
    end
end

pcall(function()
    hl.on("workspace.active", function(ev)
        if not _follow_enabled then return end
        if _re_entry_guard then return end
        local name = (ev and (ev.name or ev.workspace)) or ""
        local pair = PAIRS[name]
        if not pair then return end

        local mon = hl.get_active_monitor()
        if not mon then return end
        local other = find_other_monitor(mon.name)
        if not other then return end

        _re_entry_guard = true
        -- focusworkspace no monitor sem mover foco do mouse: usar focusworkspaceoncurrentmonitor é diferente.
        -- Truque: usar workspace dispatcher com prefixo de monitor não existe; mas dispatch ao monitor + workspace funciona.
        hl.exec_cmd("hyprctl dispatch focusmonitor " .. other.name)
        hl.exec_cmd("hyprctl dispatch workspace " .. pair)
        hl.exec_cmd("hyprctl dispatch focusmonitor " .. mon.name)
        -- libera guard depois de ~150ms (depois que os eventos foram processados)
        pcall(function()
            hl.timer(function() _re_entry_guard = false end,
                { timeout = 150, type = "oneshot" })
        end)
    end)
end)

function followme_toggle()
    _follow_enabled = not _follow_enabled
    hl.exec_cmd("notify-send -t 1000 '🔗 Follow-me' '" ..
        (_follow_enabled and "ON — workspaces pareados" or "OFF") .. "' -u low")
end

function followme_status() return _follow_enabled end

hl.bind("MOD3 + f", function() followme_toggle() end)
