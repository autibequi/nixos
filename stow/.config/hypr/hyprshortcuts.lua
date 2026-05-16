-- ============================================================
--  HYPRSHORTCUTS — porta do hyprshortcuts.sh para Lua
--
--  Estratégia:
--    1. io.popen("hyprctl binds") → parse em Lua (rápido, < 50ms)
--    2. Gera um shell script temporário com o input do rofi e
--       o mapa display→cmd já embutido
--    3. hl.exec_cmd(script) → rofi roda async, não trava o compositor
-- ============================================================

local function decode_modmask(mask)
    local mods = {}
    if mask & 64 ~= 0 then table.insert(mods, "Super")  end
    if mask & 32 ~= 0 then table.insert(mods, "Mod3")   end
    if mask & 8  ~= 0 then table.insert(mods, "Alt")    end
    if mask & 4  ~= 0 then table.insert(mods, "Ctrl")   end
    if mask & 1  ~= 0 then table.insert(mods, "Shift")  end
    return table.concat(mods, "+")
end

local function pretty_action(dispatcher, arg)
    if dispatcher == "exec" then
        local ws = arg:match("workspace_switch%s+(.+)")
        if ws then return "Go to W: " .. ws end
        return "Run: " .. arg
    end
    local map = {
        killactive             = "Close Window",
        exit                   = "Exit Hyprland",
        togglefloating         = "Toggle Float",
        fullscreen             = "Toggle Fullscreen",
        movetoworkspace        = "Move to W: " .. arg,
        movetoworkspacesilent  = "Move to W: " .. arg .. " (silent)",
        workspace              = "Go to W: " .. arg,
        submap                 = "[SUBMAP] " .. arg,
        movefocus              = "Focus: " .. arg,
        movewindow             = "Move Window: " .. arg,
        resizeactive           = "Resize: " .. arg,
        layoutmsg              = "Layout: " .. arg,
        focusmonitor           = "Monitor: " .. arg,
    }
    return map[dispatcher] or (dispatcher .. " " .. arg)
end

local function parse_binds()
    local f = io.popen("hyprctl binds 2>/dev/null")
    if not f then return {} end
    local raw = f:read("*a")
    f:close()

    local binds = {}
    local cur = { modmask = 0 }

    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        -- nova entrada de bind
        if line:match("^bind") then
            if cur.key and cur.key ~= "" then
                table.insert(binds, {
                    modmask    = cur.modmask or 0,
                    key        = cur.key,
                    dispatcher = cur.dispatcher or "",
                    arg        = cur.arg or "",
                })
            end
            cur = { modmask = 0 }
        else
            local v
            v = line:match("^%s+modmask:%s+(%d+)")
            if v then cur.modmask = tonumber(v) or 0 end

            v = line:match("^%s+key:%s+(.+)")
            if v then cur.key = v end

            v = line:match("^%s+dispatcher:%s+(.+)")
            if v then cur.dispatcher = v end

            v = line:match("^%s+arg:%s+(.*)")
            if v then cur.arg = v end
        end
    end
    -- flush último bloco
    if cur.key and cur.key ~= "" then
        table.insert(binds, {
            modmask    = cur.modmask or 0,
            key        = cur.key,
            dispatcher = cur.dispatcher or "",
            arg        = cur.arg or "",
        })
    end
    return binds
end

local function escape_sh(s)
    -- escapa aspas simples para uso em strings shell single-quoted
    return s:gsub("'", "'\\''")
end

function show_shortcuts()
    local binds = parse_binds()

    -- Formata e ordena por action
    local entries = {}
    for _, b in ipairs(binds) do
        if b.key ~= "" then
            local mods   = decode_modmask(b.modmask)
            local combo  = mods ~= "" and (mods .. "+" .. b.key) or b.key
            local action = pretty_action(b.dispatcher, b.arg)
            local display = string.format("%-26s %s", combo, action)

            local cmd
            if b.dispatcher == "exec" then
                cmd = b.arg
            else
                cmd = "hyprctl dispatch " .. b.dispatcher ..
                      (b.arg ~= "" and (" " .. b.arg) or "")
            end

            table.insert(entries, { sort = action, display = display, cmd = cmd })
        end
    end
    table.sort(entries, function(a, b) return a.sort < b.sort end)

    if #entries == 0 then return end

    -- Monta o script shell temporário
    -- Usa um array bash indexado por número + array paralelo de cmds
    -- para evitar problemas com caracteres especiais em keys associativas
    local lines = {
        "#!/usr/bin/env bash",
        "rofi_input=''",
        "declare -a cmds=()",
    }

    for i, e in ipairs(entries) do
        table.insert(lines,
            "rofi_input+=$'" .. escape_sh(e.display) .. "\\n'")
        table.insert(lines,
            "cmds[" .. i .. "]=" .. "'" .. escape_sh(e.cmd) .. "'")
    end

    -- seleção via rofi; índice via grep -n para mapear de volta ao cmd
    table.insert(lines, [[
selected=$(printf "%s" "$rofi_input" | rofi -dmenu -i -p "Shortcuts" -width 160)
[ -z "$selected" ] && exit 0
idx=$(printf "%s" "$rofi_input" | grep -nxF "$selected" | head -1 | cut -d: -f1)
[ -z "$idx" ] && exit 0
cmd="${cmds[$idx]}"
[ -n "$cmd" ] && eval "$cmd" &
]])

    -- escreve e executa o script
    local tmpf = os.tmpname()
    local sf = io.open(tmpf, "w")
    if not sf then return end
    sf:write(table.concat(lines, "\n"))
    sf:close()

    hl.exec_cmd("sh '" .. tmpf .. "' ; rm -f '" .. tmpf .. "'")
end
