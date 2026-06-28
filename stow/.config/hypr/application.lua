-- ============================================================
--  APPLICATION ALIASES + KEYBINDS — Lua-first
--  Usa keymap (registry) + launcher (decoradores) — sem repetição
-- ============================================================

local km = require("keymap")
local L  = require("launcher")

-- ── App aliases ───────────────────────────────────────────────
local terminal     = L.build("alacritty")
local menu         = L.build("walker", { raw = true })
local chrome       = L.build("google-chrome-stable")
local zed          = L.build("zeditor")
local quickShell   = L.build("qs ipc call overview toggle",        { raw = true })
local controlPanel = L.build("nwg-panel-config")
local audioManager = L.term("wiremix")
local emojiPicker  = L.build("rofimoji --skin-tone neutral --action copy")

-- ── PWAs / web apps ──────────────────────────────────────────
local gemini_app   = L.chrome("https://gemini.google.com/")
local claude_app   = L.chrome("https://claude.ai/new")

-- ── REPL/Agents ───────────────────────────────────────────────
local vennon   = L.term("env CLAUDECODE=1 zsh -c 'vennon claude'")
local yaaFast  = L.term("env CLAUDECODE=1 zsh -c 'yaa --model=haiku'")
local yaa      = L.term("env CLAUDECODE=1 zsh -c 'yaa --model=\"sonnet[1]\"'")

-- ── App Keybinds ──────────────────────────────────────────────

-- Quickshell Overview
km.app("SUPER + Space", quickShell, { desc = "Quickshell overview", group = "System", icon = "" })

-- Quick Apps
km.app("MOD3 + Space",  menu,         { desc = "App launcher (Walker)", icon = "" })
km.app("MOD3 + t",      terminal,     { desc = "Terminal",            icon = "" })
km.app("MOD3 + z",      zed,          { desc = "Zed editor",          icon = "" })
km.app("MOD3 + period", emojiPicker,  { desc = "Emoji picker",        icon = "" })
km.app("MOD3 + a",      audioManager, { desc = "Audio (wiremix)",     icon = "" })

-- Control panel: MOD3+SHIFT+p (SUPER+SHIFT+p é cycle profile em profiles.lua)
km.app("MOD3 + SHIFT + p", controlPanel,
    { desc = "Control panel (nwg-panel)", group = "System", icon = "" })

-- Browsers + AI
km.app("MOD3 + b",         chrome,     { desc = "Chrome",          icon = "" })
km.app("MOD3 + g",         gemini_app, { desc = "Gemini app",      group = "AI", icon = "✦" })
km.app("MOD3 + ALT + c",   claude_app, { desc = "Claude.ai (web)", group = "AI", icon = "🅰" })
km.app("MOD3 + c",         yaaFast,    { desc = "yaa Haiku",       group = "AI", icon = "⚡" })
km.app("MOD3 + SHIFT + c", yaa,        { desc = "yaa Sonnet[1M]",  group = "AI", icon = "🧠" })
km.app("MOD3 + p",         vennon,     { desc = "Vennon REPL",     group = "AI", icon = "" })
