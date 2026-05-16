-- ============================================================
--  PICKER — window picker fuzzy (Alt-Tab Wayland-friendly)
--
--  Usa get_clients_compat() → rofi → hyprctl dispatch focuswindow.
--  Bind: MOD3+Tab (vazio no setup; SUPER+Tab é maximize).
-- ============================================================

local function escape_sh(s)
    return (s or ""):gsub("'", "'\\''")
end

-- Trunca títulos longos pra cheatsheet ficar legível
local function trunc(s, n)
    s = s or ""
    if #s <= n then return s end
    return s:sub(1, n - 1) .. "…"
end

function window_picker(opts)
    opts = opts or {}
    local current_ws_only = opts.current_ws

    -- get_clients_compat() devolve table de janelas. Estrutura provável:
    -- { address, class, title, workspace = {id, name}, monitor, ... }
    local clients = get_clients_compat() or {}

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
                addr = addr,
            })
        end
    end

    if #entries == 0 then
        hl.exec_cmd("notify-send 'Window picker' 'Nenhuma janela' -u low")
        return
    end

    table.sort(entries, function(a, b) return a.display < b.display end)

    local lines = {
        "#!/usr/bin/env bash",
        "rofi_input=''",
        "declare -a addrs=()",
    }
    for i, e in ipairs(entries) do
        table.insert(lines, "rofi_input+=$'" .. escape_sh(e.display) .. "\\n'")
        table.insert(lines, "addrs[" .. i .. "]='" .. escape_sh(e.addr) .. "'")
    end
    table.insert(lines, [[
selected=$(printf "%s" "$rofi_input" | rofi -dmenu -i -p "Window" -width 140)
[ -z "$selected" ] && exit 0
idx=$(printf "%s" "$rofi_input" | grep -nxF "$selected" | head -1 | cut -d: -f1)
[ -z "$idx" ] && exit 0
addr="${addrs[$idx]}"
[ -n "$addr" ] && hyprctl dispatch focuswindow address:"$addr" &
]])

    local tmpf = os.tmpname()
    local sf = io.open(tmpf, "w")
    if not sf then return end
    sf:write(table.concat(lines, "\n"))
    sf:close()

    hl.exec_cmd("sh '" .. tmpf .. "' ; rm -f '" .. tmpf .. "'")
end

-- Binds: MOD3+Tab = todas; MOD3+SHIFT+Tab = só workspace atual
hl.bind("MOD3 + Tab",         function() window_picker() end)
hl.bind("MOD3 + SHIFT + Tab", function() window_picker({ current_ws = true }) end)
