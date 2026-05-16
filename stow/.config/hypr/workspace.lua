-- ============================================================
--  WORKSPACE CONFIG + KEYBINDS — portado de workspace.conf
--  API: https://wiki.hypr.land/Configuring/Basics/Dispatchers/
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
-- maximize state (1 = maximize) → borda grossa vermelha
hl.window_rule({ match = { fullscreen_state_internal = 1 }, border_size = 5 })
hl.window_rule({ match = { fullscreen_state_internal = 1 }, border_color = { colors = { "rgba(ff0000ff)", "rgba(cc0000ff)" }, angle = 45 } })

-- Special workspaces (selector s[true]) → rosa e verde
hl.window_rule({ match = { workspace = "s[true]" }, border_color = { colors = { "rgba(ff69b4ff)", "rgba(00ff88ff)" }, angle = 45 } })

-- Special + maximizado → borda grossa
hl.window_rule({ match = { workspace = "s[true]", fullscreen_state_internal = 1 }, border_size = 12 })
hl.window_rule({ match = { workspace = "s[true]", fullscreen_state_internal = 1 }, border_color = { colors = { "rgba(ff69b4ff)", "rgba(00ff88ff)" }, angle = 45 } })

-- ── Workspace switch (SUPER + 1-0) ───────────────────────────
-- Esconde special workspace ativo antes de trocar

for i = 1, 9 do
    local ws = tostring(i)
    hl.bind("SUPER + " .. ws,         function() workspace_switch(ws) end)
    hl.bind("SUPER + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws, follow = false }))
end
hl.bind("SUPER + 0",         function() workspace_switch("10") end)
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10", follow = false }))

-- ── WASD Focus/Move/Resize ────────────────────────────────────

-- Focus — dispatch direto pro layout (scrolling/dwindle)
hl.bind("SUPER + a", hl.dsp.layout("focus l"), { ["repeat"] = true })
hl.bind("SUPER + d", hl.dsp.layout("focus r"), { ["repeat"] = true })
hl.bind("SUPER + w", hl.dsp.layout("focus u"), { ["repeat"] = true })
hl.bind("SUPER + s", hl.dsp.layout("focus d"), { ["repeat"] = true })

-- Move windows
hl.bind("SUPER + SHIFT + a", hl.dsp.window.move({ direction = "l" }), { ["repeat"] = true })
hl.bind("SUPER + SHIFT + d", hl.dsp.window.move({ direction = "r" }), { ["repeat"] = true })
hl.bind("SUPER + SHIFT + w", hl.dsp.window.move({ direction = "u" }), { ["repeat"] = true })
hl.bind("SUPER + SHIFT + s", hl.dsp.window.move({ direction = "d" }), { ["repeat"] = true })

-- Resize (SUPER + CTRL + WASD) — relative=true para delta
hl.bind("SUPER + CTRL + a", hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { ["repeat"] = true })
hl.bind("SUPER + CTRL + d", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { ["repeat"] = true })
hl.bind("SUPER + CTRL + w", hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { ["repeat"] = true })
hl.bind("SUPER + CTRL + s", hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { ["repeat"] = true })

-- Scrolling layout: cycle column widths (Q/E), promote (SHIFT+X)
hl.bind("SUPER + q", function() colresize_no_wrap("-") end, { ["repeat"] = true })
hl.bind("SUPER + e", function() colresize_no_wrap("+") end, { ["repeat"] = true })
hl.bind("SUPER + SHIFT + x", hl.dsp.layout("promote"))

-- ── Mouse ─────────────────────────────────────────────────────

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Monitor switching ─────────────────────────────────────────

hl.bind("SUPER + Escape",         hl.dsp.focus({ monitor = "+1" }))
hl.bind("SUPER + SHIFT + Escape", hl.dsp.window.move({ monitor = "+1" }))

-- Special workspace → próximo monitor
hl.bind("SUPER + ALT + Right",        function() move_special_workspace_to_monitor() end)
hl.bind("SUPER + ALT + bracketright", function() move_special_workspace_to_monitor() end)

-- Normal workspace → próximo monitor
hl.bind("SUPER + ALT + Down", function() move_normal_workspace_to_monitor() end)
hl.bind("SUPER + ALT + Left", function() move_normal_workspace_to_monitor() end)

-- ── Special workspace history (browser-like back/forward) ─────
hl.bind("SUPER + bracketleft",  function() special_back() end)
hl.bind("SUPER + bracketright", function() special_forward() end)
