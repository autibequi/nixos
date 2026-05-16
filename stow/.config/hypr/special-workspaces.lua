-- ============================================================
--  SPECIAL WORKSPACES — portado de special-workspaces.conf
-- ============================================================

local defaultGaps = 32

-- ── Gemini ───────────────────────────────────────────────────
hl.workspace_rule({
    workspace      = "special:gemini",
    gaps_out       = defaultGaps,
    on_created_empty = "uwsm app -- gpu-offload google-chrome-stable --ozone-platform=x11 --app=https://gemini.google.com/",
    layout         = "scrolling",
    layout_opt     = "direction:right",
})
hl.window_rule({ match = { workspace = "special:gemini" }, border_color = "rgba(7c3aedcc)" })
hl.window_rule({ match = { workspace = "special:gemini" }, float = false })
hl.bind("SUPER + g",       function() workspace_switch("special:gemini") end)
hl.bind("SUPER SHIFT + g", hl.dsp.window.move({ workspace = "special:gemini", follow = false }))

-- ── Bleh (terminal) ──────────────────────────────────────────
hl.workspace_rule({
    workspace        = "special:bleh",
    gaps_out         = defaultGaps,
    on_created_empty = "uwsm app -- gpu-offload alacritty",
})
hl.window_rule({ match = { workspace = "special:bleh" }, border_color = "rgba(fff700dd)" })
hl.bind("SUPER + grave",       function() workspace_switch("special:bleh") end)
hl.bind("SUPER SHIFT + grave", hl.dsp.window.move({ workspace = "special:bleh", follow = false }))

-- ── F1 — Work Obsidian ───────────────────────────────────────
hl.workspace_rule({
    workspace        = "special:f1",
    gaps_out         = defaultGaps,
    layout           = "scrolling",
    layout_opt       = "direction:right",
    on_created_empty = "uwsm app -- obsidian \"obsidian://open?vault=Work\"",
})
hl.window_rule({ match = { workspace = "special:f1" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F1",       function() workspace_switch("special:f1") end)
hl.bind("SUPER SHIFT + F1", hl.dsp.window.move({ workspace = "special:f1", follow = false }))

-- ── F2 — Slot livre ──────────────────────────────────────────
hl.workspace_rule({ workspace = "special:f2", gaps_out = defaultGaps, layout = "scrolling", layout_opt = "direction:right" })
hl.window_rule({ match = { workspace = "special:f2" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F2",       function() workspace_switch("special:f2") end)
hl.bind("SUPER SHIFT + F2", hl.dsp.window.move({ workspace = "special:f2", follow = false }))

-- ── F3 — Slot livre ──────────────────────────────────────────
hl.workspace_rule({ workspace = "special:f3", gaps_out = defaultGaps, layout = "scrolling", layout_opt = "direction:right" })
hl.window_rule({ match = { workspace = "special:f3" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F3",       function() workspace_switch("special:f3") end)
hl.bind("SUPER SHIFT + F3", hl.dsp.window.move({ workspace = "special:f3", follow = false }))

-- ── F4 — Slot livre ──────────────────────────────────────────
hl.workspace_rule({ workspace = "special:f4", gaps_out = defaultGaps, layout = "scrolling", layout_opt = "direction:right" })
hl.window_rule({ match = { workspace = "special:f4" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F4",       function() workspace_switch("special:f4") end)
hl.bind("SUPER SHIFT + F4", hl.dsp.window.move({ workspace = "special:f4", follow = false }))

-- ── F5 — Chat ────────────────────────────────────────────────
hl.workspace_rule({
    workspace        = "special:f5",
    gaps_out         = defaultGaps,
    layout           = "scrolling",
    layout_opt       = "direction:right",
    on_created_empty = "uwsm app -- gpu-offload google-chrome-stable --ozone-platform=x11 --app=https://chat.google.com",
})
hl.window_rule({ match = { workspace = "special:f5" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F5",       function() workspace_switch("special:f5") end)
hl.bind("SUPER SHIFT + F5", hl.dsp.window.move({ workspace = "special:f5", follow = false }))

-- ── F6 — Slot livre ──────────────────────────────────────────
hl.workspace_rule({ workspace = "special:f6", gaps_out = defaultGaps, layout = "scrolling", layout_opt = "direction:right" })
hl.window_rule({ match = { workspace = "special:f6" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F6",       function() workspace_switch("special:f6") end)
hl.bind("SUPER SHIFT + F6", hl.dsp.window.move({ workspace = "special:f6", follow = false }))

-- ── F7 — Slot livre ──────────────────────────────────────────
hl.workspace_rule({ workspace = "special:f7", gaps_out = defaultGaps, layout = "scrolling", layout_opt = "direction:right" })
hl.window_rule({ match = { workspace = "special:f7" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F7",       function() workspace_switch("special:f7") end)
hl.bind("SUPER SHIFT + F7", hl.dsp.window.move({ workspace = "special:f7", follow = false }))

-- ── F8 — Settings (Zed nixos) ────────────────────────────────
hl.workspace_rule({
    workspace        = "special:f8",
    gaps_out         = defaultGaps,
    layout           = "scrolling",
    layout_opt       = "direction:right",
    on_created_empty = "uwsm app -- gpu-offload zeditor ~/nixos",
})
hl.window_rule({ match = { workspace = "special:f8" }, border_color = "rgba(7c3aedcc)" })
hl.bind("SUPER + F8",       function() workspace_switch("special:f8") end)
hl.bind("SUPER SHIFT + F8", hl.dsp.window.move({ workspace = "special:f8", follow = false }))

-- ── F9 — Personal Obsidian (privado) ─────────────────────────
hl.workspace_rule({
    workspace        = "special:f9",
    gaps_out         = defaultGaps,
    layout           = "scrolling",
    layout_opt       = "direction:right",
    on_created_empty = "uwsm app -- obsidian \"obsidian://open?vault=.ovault\"",
})
hl.window_rule({ match = { workspace = "special:f9" }, border_color = "rgba(7c3aedcc)", no_screen_share = true })
hl.bind("SUPER + F9",       function() workspace_switch("special:f9") end)
hl.bind("SUPER SHIFT + F9", hl.dsp.window.move({ workspace = "special:f9", follow = false }))
