-- ============================================================
--  HYPRSHORTCUTS — rofi cheatsheet a partir do registry keymap
--
--  Antes: parse de `hyprctl binds` + map dispatcher→pretty
--  Agora: consome keymap._binds (com desc/group/icon semânticos)
-- ============================================================

local km = require("keymap")

local function escape_sh(s)
    return (s or ""):gsub("'", "'\\''")
end

-- Render: "[group] icon  combo  ⟶  desc"
local function format_entry(e)
    return string.format("[%-10s] %s %-26s  ⟶  %s",
        e.group, e.icon ~= "" and e.icon or " ",
        e.combo, e.desc)
end

-- Para items sem dispatcher (são lua fns), o re-invoke seria via FIFO/REPL.
-- Pra cheatsheet, basta listar e permitir disparar via hyprctl dispatch quando
-- houver combo identificado em hyprctl binds.

function show_shortcuts()
    local entries = km.cheatsheet()
    if #entries == 0 then
        hl.exec_cmd("notify-send 'show_shortcuts' 'Registry vazio' -u low")
        return
    end

    local lines = {
        "#!/usr/bin/env bash",
        "rofi_input=''",
        "declare -a combos=()",
    }

    for i, e in ipairs(entries) do
        table.insert(lines,
            "rofi_input+=$'" .. escape_sh(format_entry(e)) .. "\\n'")
        table.insert(lines,
            "combos[" .. i .. "]='" .. escape_sh(e.combo) .. "'")
    end

    -- Seleção via rofi; mapeia o item de volta ao combo.
    -- Tenta disparar via hyprctl: encontra bind no `hyprctl binds` e
    -- executa o dispatcher original — sem precisar duplicar a action.
    table.insert(lines, [[
selected=$(printf "%s" "$rofi_input" | rofi -dmenu -i -p "Shortcuts" -width 160)
[ -z "$selected" ] && exit 0
idx=$(printf "%s" "$rofi_input" | grep -nxF "$selected" | head -1 | cut -d: -f1)
[ -z "$idx" ] && exit 0
combo="${combos[$idx]}"
[ -z "$combo" ] && exit 0

# Normaliza "MOD3 + t" → "MOD3 t" pra grep no hyprctl binds
key="${combo##*+}"; key="${key// /}"
mods="${combo% +*}"

# Reusa o dispatcher já registrado no Hyprland via "hyprctl dispatch"
# (não duplica a action Lua — busca o dispatcher equivalente).
match=$(hyprctl binds | awk -v k="$key" '
    /^bind/ { reset=1; next }
    reset && /key:/ && index($0, "key: " k) { found=1 }
    reset && /dispatcher:/ && found { sub(/^[ \t]+dispatcher: /, ""); disp=$0 }
    reset && /arg:/ && found { sub(/^[ \t]+arg: /, ""); print disp" "$0; exit }
')
[ -n "$match" ] && hyprctl dispatch $match &
]])

    local tmpf = os.tmpname()
    local sf = io.open(tmpf, "w")
    if not sf then return end
    sf:write(table.concat(lines, "\n"))
    sf:close()

    hl.exec_cmd("sh '" .. tmpf .. "' ; rm -f '" .. tmpf .. "'")
end
