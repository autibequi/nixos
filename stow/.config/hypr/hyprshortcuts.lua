-- ============================================================
--  HYPRSHORTCUTS — rofi cheatsheet a partir do registry keymap
--
--  Antes: parse de `hyprctl binds` + map dispatcher→pretty
--  Agora: consome keymap._binds (com desc/group/icon semânticos),
--  renderiza via core.rofi_menu.
--
--  Reusa o dispatcher já registrado no Hyprland via `hyprctl dispatch`
--  (busca o bind pelo combo no `hyprctl binds`), sem duplicar a action.
-- ============================================================

local km   = require("keymap")
local core = require("core")

-- Render: "[group] icon  combo  ⟶  desc"
local function format_entry(e)
    return string.format("[%-10s] %s %-26s  ⟶  %s",
        e.group, e.icon ~= "" and e.icon or " ",
        e.combo, e.desc)
end

function show_shortcuts()
    local registry = km.cheatsheet()
    if #registry == 0 then
        core.notify("show_shortcuts", "Registry vazio", { urgency = "low" })
        return
    end

    local entries = {}
    for _, e in ipairs(registry) do
        table.insert(entries, { display = format_entry(e), payload = e.combo })
    end

    -- on_select normaliza "MOD3 + t" → key/mods e procura no hyprctl binds.
    local on_select = [[
combo="$payload"
key="${combo##*+}"; key="${key// /}"
match=$(hyprctl binds | awk -v k="$key" '
    /^bind/ { reset=1; next }
    reset && /key:/ && index($0, "key: " k) { found=1 }
    reset && /dispatcher:/ && found { sub(/^[ \t]+dispatcher: /, ""); disp=$0 }
    reset && /arg:/ && found { sub(/^[ \t]+arg: /, ""); print disp" "$0; exit }
')
[ -n "$match" ] && hyprctl dispatch $match &
]]

    core.rofi_menu(entries, {
        prompt    = "Shortcuts",
        width     = 160,
        on_select = on_select,
    })
end
