-- ============================================================
--  CHICOTE — modo modal: cursor vira chicote, sacudiu manda "mais rapido"
--  Bind: MOD3 + s (toggle). App: utils/chicote (raylib). ESC também fecha.
--  O toggle real (spawn/kill + cursor + waybar) vive em chicote-toggle.sh
--  pra evitar inferno de quoting shell dentro do Lua.
-- ============================================================

local km = require("keymap")

-- Janela cobre o monitor, flutua e fica pinada. nofocus efetivo vem do
-- FLAG_WINDOW_UNFOCUSED do raylib → wtype cai no terminal de baixo.
hl.window_rule({
    match  = { class = "chicote" },
    float  = true,
    pin    = true,
    center = true,
    size   = { "monitor_w", "monitor_h" },
})

km.fn("MOD3 + s", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/chicote-toggle.sh")
end, { desc = "Modo chicote 🥁", group = "Fun", icon = "🥁" })
