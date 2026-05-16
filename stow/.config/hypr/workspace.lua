-- ============================================================
--  WORKSPACE CONFIG + KEYBINDS — portado de workspace.conf
-- ============================================================

-- ── Workspace → monitor mapping ───────────────────────────────

hl.workspace_rule({ workspace = "1",  monitor = "DP-2",  default = true })
hl.workspace_rule({ workspace = "2",  monitor = "DP-2",  default = true })
hl.workspace_rule({ workspace = "3",  monitor = "DP-2",  default = true })
hl.workspace_rule({ workspace = "4",  monitor = "DP-2",  default = true })
hl.workspace_rule({ workspace = "5",  monitor = "DP-2",  default = true })
hl.workspace_rule({ workspace = "6",  monitor = "DP-2",  default = true })
hl.workspace_rule({ workspace = "7",  monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "8",  monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "9",  monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1", default = true })

-- ── Dynamic borders (visual feedback) ────────────────────────
-- fullscreen maximize → borda grossa vermelha
hl.window_rule({ match = { fullscreen = 1 }, border_size = 5 })
hl.window_rule({ match = { fullscreen = 1 }, border_color = { colors = { "rgba(ff0000ff)", "rgba(cc0000ff)" }, angle = 45 } })

-- Special workspaces → rosa e verde
hl.window_rule({ match = { special = true }, border_color = { colors = { "rgba(ff69b4ff)", "rgba(00ff88ff)" }, angle = 45 } })

-- Special + maximizado → borda grossa
hl.window_rule({ match = { special = true, fullscreen = 1 }, border_size = 12 })
hl.window_rule({ match = { special = true, fullscreen = 1 }, border_color = { colors = { "rgba(ff69b4ff)", "rgba(00ff88ff)" }, angle = 45 } })

-- ── Workspace switch (SUPER + 1-0) ───────────────────────────
-- Esconde special workspace ativo antes de trocar

for i = 1, 9 do
    local ws = tostring(i)
    hl.bind("SUPER + " .. ws, function() workspace_switch(ws) end)
    hl.bind("SUPER SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws, follow = false }))
end
hl.bind("SUPER + 0", function() workspace_switch("10") end)
hl.bind("SUPER SHIFT + 0", hl.dsp.window.move({ workspace = "10", follow = false }))

-- ── WASD Focus/Move/Resize ────────────────────────────────────

-- Focus (sem wrap)
hl.bind("SUPER + a", function() focus_no_wrap("l") end, { repeat = true })
hl.bind("SUPER + d", function() focus_no_wrap("r") end, { repeat = true })
hl.bind("SUPER + w", hl.dsp.layout({ message = "focus u" }), { repeat = true })
hl.bind("SUPER + s", hl.dsp.layout({ message = "focus d" }), { repeat = true })

-- Move windows
hl.bind("SUPER SHIFT + a", hl.dsp.window.move("l"), { repeat = true })
hl.bind("SUPER SHIFT + d", hl.dsp.window.move("r"), { repeat = true })
hl.bind("SUPER SHIFT + w", hl.dsp.window.move("u"), { repeat = true })
hl.bind("SUPER SHIFT + s", hl.dsp.window.move("d"), { repeat = true })

-- Resize (SUPER + CTRL + WASD)
hl.bind("SUPER CTRL + a", hl.dsp.window.resize({ x = -40, y = 0 }),  { repeat = true })
hl.bind("SUPER CTRL + d", hl.dsp.window.resize({ x = 40,  y = 0 }),  { repeat = true })
hl.bind("SUPER CTRL + w", hl.dsp.window.resize({ x = 0,   y = -20 }), { repeat = true })
hl.bind("SUPER CTRL + s", hl.dsp.window.resize({ x = 0,   y = 20 }),  { repeat = true })

-- Scrolling layout: cycle column widths (Q/E), promote (SHIFT+X)
hl.bind("SUPER + q", function() colresize_no_wrap("-") end, { repeat = true })
hl.bind("SUPER + e", function() colresize_no_wrap("+") end, { repeat = true })
hl.bind("SUPER SHIFT + x", hl.dsp.layout({ message = "promote" }))

-- ── Mouse ─────────────────────────────────────────────────────

hl.bind("SUPER + mouse:272", hl.dsp.window.move(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Monitor switching ─────────────────────────────────────────

hl.bind("SUPER + Escape",       hl.dsp.monitor.focus("+1"))
hl.bind("SUPER SHIFT + Escape", hl.dsp.window.move({ monitor = "+1" }))

-- Special workspace → próximo monitor
hl.bind("SUPER ALT + Right",        function() move_special_workspace_to_monitor() end)
hl.bind("SUPER ALT + bracketright", function() move_special_workspace_to_monitor() end)

-- Normal workspace → próximo monitor
hl.bind("SUPER ALT + Down", function() move_normal_workspace_to_monitor() end)
hl.bind("SUPER ALT + Left", function() move_normal_workspace_to_monitor() end)

-- ── Gestures ─────────────────────────────────────────────────

-- 3 dedos horizontal → troca workspace
hl.gesture({ fingers = 3, direction = "horizontal", dispatcher = hl.dsp.focus({ workspace = "next" }) })

-- 4 dedos horizontal/vertical → resize (scale 0.5)
-- NOTA: API de gesture com scale ainda não documentada em Lua — verificar
hl.gesture({ fingers = 4, direction = "horizontal", scale = 0.5, dispatcher = hl.dsp.window.resize() })
hl.gesture({ fingers = 4, direction = "vertical",   scale = 0.5, dispatcher = hl.dsp.window.resize() })
