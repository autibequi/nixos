-- ============================================================
--  HYPRSHORTCUTS — cheatsheet walker a partir do registry keymap
--
--  Migrado de rofi (core.rofi_menu) pra walker/elephant em 2026-07-02,
--  unificado com os menus wifi/power/screenshot/áudio.
--
--  Fluxo: SUPER+/ → dump do registry em ~/.cache/hypr-shortcuts.tsv →
--  walker --provider menus:shortcuts (elephant/menus/shortcuts.lua lê o
--  TSV). Enter executa via walker-shortcut-exec.sh (mesma lógica awk de
--  lookup no `hyprctl binds` do on_select antigo).
-- ============================================================

local km   = require("keymap")
local core = require("core")

local TSV = os.getenv("HOME") .. "/.cache/hypr-shortcuts.tsv"

function show_shortcuts()
    local registry = km.cheatsheet()
    if #registry == 0 then
        core.notify("show_shortcuts", "Registry vazio", { urgency = "low" })
        return
    end

    local f = io.open(TSV, "w")
    if f then
        for _, e in ipairs(registry) do
            f:write(string.format("%s\t%s\t%s\n",
                e.group or "", e.combo or "", e.desc or ""))
        end
        f:close()
    end

    hl.exec_cmd(os.getenv("HOME") ..
        "/.config/hypr/walker-launch.sh --provider menus:shortcuts")
end
