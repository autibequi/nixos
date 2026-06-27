-- ============================================================
--  SPECIAL WORKSPACES — portado de special-workspaces.conf
-- ============================================================

local km             = require("keymap")
local L              = require("launcher")
local core           = require("core")

local DEFAULT_GAPS   = 32
local DEFAULT_BORDER = "rgba(7c3aedcc)"

-- Helper: cada special workspace tem mesmo shape (rule + border + binds + policy)
-- opts:
--   label              — string pra cheatsheet
--   on_created_empty   — comando shell (use L.build/chrome) que abre na primeira ativação
--   border             — cor da borda (override do DEFAULT_BORDER)
--   tile               — força tile=true em todas as janelas do workspace
--   no_screen_share    — esconde o workspace inteiro de screenshare
--   on_active          — fn() disparada quando o workspace fica ativo
--                        (registrada em core.workspace_active_handlers — events.lua consome)
--   auto_route_classes — list de window classes que serão auto-roteadas pra esse workspace
--                        (registrada em core.workspace_auto_route_classes — events.lua consome)
local function define_special(name, key, opts)
	opts        = opts or {}
	local ws    = "special:" .. name
	local label = opts.label or name

	local rule  = { workspace = ws, gaps_out = DEFAULT_GAPS, layout = "scrolling" }
	if opts.on_created_empty then rule.on_created_empty = opts.on_created_empty end
	hl.workspace_rule(rule)

	local win = { match = { workspace = ws }, border_color = opts.border or DEFAULT_BORDER }
	if opts.no_screen_share then win.no_screen_share = true end
	hl.window_rule(win)

	if opts.tile then
		hl.window_rule({ match = { workspace = ws }, tile = true })
	end

	km.fn("SUPER + " .. key, function() workspace_switch(ws) end,
		{ desc = "Toggle special:" .. label, group = "Special" })
	km.bind("SUPER + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = ws, follow = false }),
		{ desc = "Move window → special:" .. label, group = "Special" })

	-- Policies opt-in (events.lua consome em runtime)
	if opts.on_active then
		core.workspace_active_handlers[ws] = opts.on_active
	end
	if opts.auto_route_classes then
		for _, class in ipairs(opts.auto_route_classes) do
			core.workspace_auto_route_classes[class] = name
		end
	end

	-- Registra specials que têm on_created_empty → utils.lua push_home ao abrir vazio
	if opts.on_created_empty then
		core.special_empty_launchers[name] = true
	end

	-- Registry pra specials-feed (sem io.popen — só metadados estáticos)
	table.insert(core.known_specials, {
		name  = name,
		ws    = ws,
		label = opts.label or name,
		color = opts.border or DEFAULT_BORDER,
	})
end

-- ── Nomeados ─────────────────────────────────────────────────
define_special("gemini", "g", {
	label            = "gemini",
	on_created_empty = L.chrome("https://gemini.google.com/"),
	tile             = true,
})

-- ── F-keys configurados (com app default / policy) ──────────
define_special("f1", "F1", {
	label            = "f1 (Work vault)",
	on_created_empty = L.chrome("https://chat.google.com"),
	on_active        = function()
		hl.exec_cmd("swaync-client -d")     -- DND on
		core.notify("Modo Work",
			"F1 — notif pessoais silenciadas",
			{ timeout = 800, urgency = "low" })
	end,
})
define_special("f2", "F2", {
	label              = "f2 (Chat)",
	on_created_empty   = L.build([[obsidian "obsidian://open?vault=Work"]]),
	auto_route_classes = { "Slack", "zoom", "zoom_linux_float_video_window" },
})
define_special("f8", "F8", {
	label = "f8 (Zed nixos)",
	on_created_empty = L.build("zeditor ~/nixos")
})
define_special("f9", "F9", {
	label            = "f9 (.ovault, no_screen_share)",
	on_created_empty = L.build([[obsidian "obsidian://open?vault=.ovault"]]),
	no_screen_share  = true,
	on_active        = function()
		hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1")
		core.notify("Modo Pessoal",
			"F9 — mic mutado, no_screen_share",
			{ timeout = 800, urgency = "low" })
	end,
})

-- ── F-keys scratchpad (sem app default — abre vazio) ─────────
for _, n in ipairs({ "3", "4", "5", "6", "7" }) do
	define_special("f" .. n, "F" .. n)
end
