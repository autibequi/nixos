-- ============================================================
--  HUD — peek do estado atual via notify-send
--
--  Bind: SUPER + semicolon (;)
--  Mostra: workspace atual, profile, special-stack, contagens.
-- ============================================================

local function get_profile_current()
    local ok, profiles = pcall(require, "profiles")
    if ok and profiles and profiles.current then return profiles.current() end
    return "?"
end

function show_hud()
    local mon  = hl.get_active_monitor() or {}
    local ws   = mon.activeWorkspace or {}
    local sws  = mon.specialWorkspace or {}
    local clients = hl.get_clients() or {}

    -- contagem por workspace
    local count_ws, count_class = 0, {}
    for _, c in ipairs(clients) do
        if c.workspace and c.workspace.id == ws.id then
            count_ws = count_ws + 1
        end
        count_class[c.class or "?"] = (count_class[c.class or "?"] or 0) + 1
    end

    local top_classes = {}
    for k, v in pairs(count_class) do table.insert(top_classes, { k = k, v = v }) end
    table.sort(top_classes, function(a, b) return a.v > b.v end)

    local top_str = ""
    for i = 1, math.min(3, #top_classes) do
        top_str = top_str .. top_classes[i].k .. "×" .. top_classes[i].v .. " "
    end

    local lines = {
        "<b>Monitor:</b> " .. (mon.name or "?"),
        "<b>Workspace:</b> " .. (ws.name or tostring(ws.id or "?")) ..
            " (" .. count_ws .. " janelas)",
        "<b>Special:</b> " .. ((sws.name and sws.name ~= "") and sws.name or "—"),
        "<b>Profile:</b> " .. get_profile_current(),
        "<b>Top apps:</b> " .. (top_str ~= "" and top_str or "—"),
        "<b>Total clients:</b> " .. #clients,
    }

    local body = table.concat(lines, "\n")
    hl.exec_cmd("notify-send -t 3500 -a HUD '⌘ Hyprland HUD' '" ..
        body:gsub("'", "'\\''") .. "'")
end

hl.bind("SUPER + semicolon", function() show_hud() end)
