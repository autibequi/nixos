-- ============================================================
--  SPECIAL WORKSPACES — portado de special-workspaces.conf
-- ============================================================

local DEFAULT_GAPS    = 32
local DEFAULT_BORDER  = "rgba(7c3aedcc)"

-- Helper: cada special workspace tem mesmo shape (rule + border + binds)
local function define_special(name, key, opts)
    opts = opts or {}
    local ws = "special:" .. name

    local rule = { workspace = ws, gaps_out = DEFAULT_GAPS, layout = "scrolling" }
    if opts.on_created_empty then rule.on_created_empty = opts.on_created_empty end
    hl.workspace_rule(rule)

    local win = { match = { workspace = ws }, border_color = opts.border or DEFAULT_BORDER }
    if opts.no_screen_share then win.no_screen_share = true end
    hl.window_rule(win)

    if opts.tile then
        hl.window_rule({ match = { workspace = ws }, tile = true })
    end

    hl.bind("SUPER + "         .. key, function() workspace_switch(ws) end)
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = false }))
end

-- ── Nomeados ─────────────────────────────────────────────────
define_special("gemini", "g", {
    on_created_empty = "uwsm app -- gpu-offload google-chrome-stable --ozone-platform=x11 --app=https://gemini.google.com/",
    tile             = true,
})
define_special("bleh", "grave", {
    on_created_empty = "uwsm app -- gpu-offload alacritty",
    border           = "rgba(fff700dd)",
})

-- ── F-keys ───────────────────────────────────────────────────
define_special("f1", "F1", { on_created_empty = "uwsm app -- obsidian \"obsidian://open?vault=Work\"" })
define_special("f2", "F2")
define_special("f3", "F3")
define_special("f4", "F4")
define_special("f5", "F5", { on_created_empty = "uwsm app -- gpu-offload google-chrome-stable --ozone-platform=x11 --app=https://chat.google.com" })
define_special("f6", "F6")
define_special("f7", "F7")
define_special("f8", "F8", { on_created_empty = "uwsm app -- gpu-offload zeditor ~/nixos" })
define_special("f9", "F9", {
    on_created_empty = "uwsm app -- obsidian \"obsidian://open?vault=.ovault\"",
    no_screen_share  = true,
})
