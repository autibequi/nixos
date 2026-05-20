-- ============================================================
--  PICKER — window picker fuzzy (Alt-Tab Wayland-friendly)
--
--  Lista clients via core.clients_cached() → rofi (core.rofi_menu)
--  → hyprctl dispatch focuswindow address:<addr>.
--
--  Binds: MOD3+Tab (todas) / MOD3+SHIFT+Tab (workspace atual).
-- ============================================================

local core  = require("core")
local km    = require("keymap")
local trunc = core.trunc

function window_picker(opts)
    opts = opts or {}
    local current_ws_only = opts.current_ws

    local clients = core.clients_cached()

    local cur_ws_id
    if current_ws_only then
        local m = hl.get_active_monitor()
        cur_ws_id = m and m.activeWorkspace and m.activeWorkspace.id
    end

    local entries = {}
    for _, c in ipairs(clients) do
        local ws = c.workspace or {}
        local ws_label = (ws.name and ws.name ~= "") and ws.name or tostring(ws.id or "?")
        local addr = c.address or ""
        if addr ~= "" and (not cur_ws_id or ws.id == cur_ws_id) then
            table.insert(entries, {
                display = string.format("[%-10s] %-20s %s",
                    trunc(ws_label, 10),
                    trunc(c.class or "?", 20),
                    trunc(c.title or "", 80)),
                payload = addr,
            })
        end
    end

    if #entries == 0 then
        core.notify("Window picker", "Nenhuma janela", { urgency = "low" })
        return
    end

    table.sort(entries, function(a, b) return a.display < b.display end)

    core.rofi_menu(entries, {
        prompt    = "Window",
        width     = 140,
        on_select = 'hyprctl dispatch focuswindow address:"$payload" &',
    })
end

-- Binds: MOD3+Tab = todas; MOD3+SHIFT+Tab = só workspace atual
km.fn("MOD3 + Tab",         function() window_picker() end,
    { desc = "Window picker (all workspaces)", group = "Navigation", icon = "🪟" })
km.fn("MOD3 + SHIFT + Tab", function() window_picker({ current_ws = true }) end,
    { desc = "Window picker (current workspace)", group = "Navigation", icon = "🪟" })
