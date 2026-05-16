-- ============================================================
--  SWALLOW — terminal "engole" filho GUI (estilo dwm/awesome)
--
--  Quando você roda `nautilus` ou `nvim --gui` dentro do Alacritty,
--  o terminal vira invisível enquanto o filho existe.
--  Filho fechou → terminal volta no mesmo lugar.
--
--  Heurística:
--    - on window.open: PID nova → ps PPID → match janela com class
--      em TERMINAL_CLASSES → move parent pra special:swallow
--    - on window.close: se está em _swallowed map → reverte
-- ============================================================

local TERMINAL_CLASSES = {
    ["Alacritty"] = true,
    ["alacritty"] = true,
    ["com.mitchellh.ghostty"] = true,
    ["ghostty"] = true,
    ["Ghostty"] = true,
}

-- Apps que NÃO devem disparar swallow (popups efêmeros, file pickers, etc)
local SKIP_CLASSES = {
    ["xdg-desktop-portal-gtk"] = true,
    ["eww-whisper-ptt"] = true,
    ["clipboard-history-popup"] = true,
    ["rofi"] = true,
}

local _swallowed = {}  -- [child_addr] = { parent_addr = ..., parent_ws = ... }

local function ppid_of(pid)
    if not pid or pid == 0 then return nil end
    local p = io.popen("ps -p " .. pid .. " -o ppid= 2>/dev/null")
    if not p then return nil end
    local s = (p:read("*l") or ""):gsub("%s+", "")
    p:close()
    return tonumber(s)
end

local function find_client_by_pid(pid)
    if not pid then return nil end
    for _, c in ipairs(hl.get_clients() or {}) do
        if c.pid == pid then return c end
    end
    return nil
end

pcall(function()
    hl.on("window.open", function(ev)
        local child_addr = ev and (ev.address or ev.window_address)
        local child_class = ev and (ev.class or ev.window_class) or ""
        local child_pid = ev and (ev.pid)
        if not child_addr then return end
        if SKIP_CLASSES[child_class] then return end
        if TERMINAL_CLASSES[child_class] then return end  -- terminal abrindo terminal: skip

        -- Pode ser que o evento ainda não traga pid; tenta via get_clients
        if not child_pid then
            for _, c in ipairs(hl.get_clients() or {}) do
                if c.address == child_addr then child_pid = c.pid break end
            end
        end
        if not child_pid then return end

        local parent_pid = ppid_of(child_pid)
        if not parent_pid then return end

        local parent = find_client_by_pid(parent_pid)
        if not parent then return end
        if not TERMINAL_CLASSES[parent.class or ""] then return end

        -- Swallow: move terminal pai pra special hidden
        local parent_ws = parent.workspace and parent.workspace.id
        _swallowed[child_addr] = {
            parent_addr = parent.address,
            parent_ws = parent_ws,
        }
        hl.exec_cmd("hyprctl dispatch movetoworkspacesilent special:_swallowed,address:" ..
            parent.address)
    end)

    hl.on("window.close", function(ev)
        local addr = ev and (ev.address or ev.window_address)
        if not addr then return end
        local info = _swallowed[addr]
        if not info then return end
        _swallowed[addr] = nil
        -- Devolve o parent pro workspace original
        if info.parent_ws then
            hl.exec_cmd("hyprctl dispatch movetoworkspacesilent " ..
                info.parent_ws .. ",address:" .. info.parent_addr)
        end
    end)
end)
