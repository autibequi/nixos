-- ============================================================
--  WORKSPACE CONFIG + KEYBINDS — registry-aware
--  API: https://wiki.hypr.land/Configuring/Basics/Dispatchers/
-- ============================================================

local km = require("keymap")

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
    km.fn("SUPER + " .. ws,
        function() workspace_switch(ws) end,
        { desc = "Go to workspace " .. ws, group = "Workspace" })
    km.bind("SUPER + SHIFT + " .. ws,
        hl.dsp.window.move({ workspace = ws, follow = false }),
        { desc = "Move window to workspace " .. ws, group = "Workspace" })
end
km.fn("SUPER + 0", function() workspace_switch("10") end,
    { desc = "Go to workspace 10", group = "Workspace" })
km.bind("SUPER + SHIFT + 0",
    hl.dsp.window.move({ workspace = "10", follow = false }),
    { desc = "Move window to workspace 10", group = "Workspace" })

-- ── WASD Focus/Move/Resize ────────────────────────────────────

-- SUPER+ALT+WASD → Ctrl+arrow (pular palavra) — ydotool: uinput, sem modifier leakage
km.repeating("SUPER + ALT + a", hl.dsp.exec_cmd("ydotool key ctrl+left"),
    { desc = "Word left",  group = "Navigation" })
km.repeating("SUPER + ALT + d", hl.dsp.exec_cmd("ydotool key ctrl+right"),
    { desc = "Word right", group = "Navigation" })
km.repeating("SUPER + ALT + w", hl.dsp.exec_cmd("ydotool key ctrl+up"),
    { desc = "Word up",    group = "Navigation" })
km.repeating("SUPER + ALT + s", hl.dsp.exec_cmd("ydotool key ctrl+down"),
    { desc = "Word down",  group = "Navigation" })

-- ALT+WASD → setas puras — ydotool: uinput, sem modifier leakage
km.repeating("ALT + a", hl.dsp.exec_cmd("ydotool key left"),
    { desc = "Arrow left",  group = "Navigation" })
km.repeating("ALT + d", hl.dsp.exec_cmd("ydotool key right"),
    { desc = "Arrow right", group = "Navigation" })
km.repeating("ALT + w", hl.dsp.exec_cmd("ydotool key up"),
    { desc = "Arrow up",    group = "Navigation" })
km.repeating("ALT + s", hl.dsp.exec_cmd("ydotool key down"),
    { desc = "Arrow down",  group = "Navigation" })

-- Move windows
km.repeating("SUPER + SHIFT + a",
    hl.dsp.window.move({ direction = "l" }),
    { desc = "Move window left",  group = "Window" })
km.repeating("SUPER + SHIFT + d",
    hl.dsp.window.move({ direction = "r" }),
    { desc = "Move window right", group = "Window" })
km.repeating("SUPER + SHIFT + w",
    hl.dsp.window.move({ direction = "u" }),
    { desc = "Move window up",    group = "Window" })
km.repeating("SUPER + SHIFT + s",
    hl.dsp.window.move({ direction = "d" }),
    { desc = "Move window down",  group = "Window" })

-- Resize (SUPER + CTRL + WASD) — relative=true para delta
km.repeating("SUPER + CTRL + a",
    hl.dsp.window.resize({ x = -40, y = 0, relative = true }),
    { desc = "Resize -40 w", group = "Window" })
km.repeating("SUPER + CTRL + d",
    hl.dsp.window.resize({ x = 40,  y = 0, relative = true }),
    { desc = "Resize +40 w", group = "Window" })
km.repeating("SUPER + CTRL + w",
    hl.dsp.window.resize({ x = 0, y = -20, relative = true }),
    { desc = "Resize -20 h", group = "Window" })
km.repeating("SUPER + CTRL + s",
    hl.dsp.window.resize({ x = 0, y = 20, relative = true }),
    { desc = "Resize +20 h", group = "Window" })

-- Scrolling layout: cycle column widths (Q/E), promote (SHIFT+X)
km.repeating("SUPER + q", function() colresize_no_wrap("-") end,
    { desc = "Column narrower", group = "Window" })
km.repeating("SUPER + e", function() colresize_no_wrap("+") end,
    { desc = "Column wider",    group = "Window" })
km.bind("SUPER + SHIFT + x", hl.dsp.layout("promote"),
    { desc = "Promote column", group = "Window" })

-- ── Mouse ─────────────────────────────────────────────────────

km.bind("SUPER + mouse:272", hl.dsp.window.drag(),
    { desc = "Drag window (mouse)",   group = "Window", flags = { mouse = true } })
km.bind("SUPER + mouse:273", hl.dsp.window.resize(),
    { desc = "Resize window (mouse)", group = "Window", flags = { mouse = true } })

-- ── Monitor switching ─────────────────────────────────────────

km.bind("SUPER + Escape", hl.dsp.focus({ monitor = "+1" }),
    { desc = "Focus next monitor", group = "Monitor" })
km.bind("SUPER + SHIFT + Escape", hl.dsp.window.move({ monitor = "+1" }),
    { desc = "Move window to next monitor", group = "Monitor" })

-- Special workspace → próximo monitor
km.fn("SUPER + ALT + Right",
    function() move_special_workspace_to_monitor() end,
    { desc = "Move special workspace → other monitor", group = "Monitor" })
km.fn("SUPER + ALT + bracketright",
    function() move_special_workspace_to_monitor() end,
    { desc = "Move special workspace → other monitor (alt)", group = "Monitor" })

-- Normal workspace → próximo monitor
km.fn("SUPER + ALT + Down",
    function() move_normal_workspace_to_monitor() end,
    { desc = "Focus other monitor (down)", group = "Monitor" })
km.fn("SUPER + ALT + Left",
    function() move_normal_workspace_to_monitor() end,
    { desc = "Focus other monitor (left)", group = "Monitor" })

-- ── Special workspace history (browser-like back/forward) ─────
km.fn("SUPER + bracketleft",  function() special_back() end,
    { desc = "Special workspace back",    group = "Special" })
km.fn("SUPER + bracketright", function() special_forward() end,
    { desc = "Special workspace forward", group = "Special" })

-- SUPER + ` → reabre/fecha o último special workspace usado
-- code:49 = tecla física grave/tilde. Usar keycode (não keysym) ignora o
-- layout altgr-intl, onde grave é dead key e o keysym não casa no bind.
km.fn("SUPER + code:49", function() toggle_last_special_workspace() end,
    { desc = "Toggle last special workspace", group = "Special" })
