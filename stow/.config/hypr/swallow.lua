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
    ["clipboard-history-popup"] = true,
    ["rofi"] = true,
}

local core = require("core")

local _swallowed = {}  -- [child_addr] = { parent_addr = ..., parent_ws = ... }

-- Lê /proc/<pid>/status (pseudo-fs syscall) em vez de io.popen("ps -p ...").
-- Não fork; muito mais barato; não bloqueia o compositor.
local function ppid_of(pid)
    if not pid or pid == 0 then return nil end
    local f = io.open("/proc/" .. pid .. "/status", "r")
    if not f then return nil end
    for line in f:lines() do
        local p = line:match("^PPid:%s+(%d+)")
        if p then f:close(); return tonumber(p) end
    end
    f:close()
    return nil
end

local function find_client_by_pid(pid)
    -- Usa clients_stale() — nunca faz io.popen.
    -- Se cache estiver vazio, retorna nil e swallow é skipped.
    if not pid then return nil end
    for _, c in ipairs(core.clients_stale()) do
        if c.pid == pid then return c end
    end
    return nil
end

core.on("window.open", function(ev)
    local child_addr = ev and (ev.address or ev.window_address)
    local child_class = ev and (ev.class or ev.window_class) or ""
    local child_pid = ev and (ev.pid)
    if not child_addr then return end
    if SKIP_CLASSES[child_class] then return end
    if TERMINAL_CLASSES[child_class] then return end  -- terminal abrindo terminal: skip

    -- Sem fallback via clients_cached() — io.popen("hyprctl clients") em
    -- window.open handler deadloca o IPC e causa freeze ao abrir apps.
    -- O evento de Hyprland 0.55 deveria trazer ev.pid; se não trouxer, skip.
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

core.on("window.close", function(ev)
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
