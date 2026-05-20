-- ============================================================
--  SPECIALS FEED — event-driven refresh do módulo waybar
--  custom/special-workspaces.
--
--  Lua reage a eventos do Hyprland (sem polling) e dispara
--  SIGRTMIN+11 pro waybar, que então re-executa o script bash
--  ~/.config/waybar/special-workspaces.sh (consulta hyprctl + jq).
--
--  Sem polling 1s = atualização instantânea + zero CPU quando
--  nada muda.
-- ============================================================

local core   = require("core")
local SIGNAL = "pkill -RTMIN+11 waybar"

local function refresh()
    hl.exec_cmd(SIGNAL)
end

local on = core.on

-- ── Eventos que mudam o estado dos specials ──────────────────
on("workspace.created",         refresh)
on("workspace.removed",         refresh)
on("workspace.active",          refresh)
on("window.open",               refresh)
on("window.close",              refresh)
on("window.move_to_workspace",  refresh)

-- Disparo inicial pro waybar pegar o estado atual ao subir
hl.on("hyprland.start", function() refresh() end)
