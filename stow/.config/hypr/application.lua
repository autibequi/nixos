-- ============================================================
--  APPLICATION ALIASES + KEYBINDS — Lua-first
--  Usa keymap (registry) + launcher (decoradores) — sem repetição
-- ============================================================

local km = require("keymap")
local L  = require("launcher")

-- ── App aliases ───────────────────────────────────────────────
local ghostty      = L.build("ghostty --gtk-single-instance=true", { gpu = "offload" })
local terminal     = L.build("alacritty",                          { gpu = "offload" })
local fileManager  = L.build("nautilus -w")
local menu         = L.build("rofi -show drun")
local lock         = L.build("hyprlock",                           { raw = true })
local obsidian_bin = L.build("obsidian")
local chrome       = L.build("google-chrome-stable --ozone-platform=x11", { gpu = "offload" })
local vivaldi      = L.build("vivaldi")
local cursor       = L.build("cursor",                             { gpu = "offload" })
local zed          = L.build("zeditor",                            { gpu = "offload" })
local colorPicker  = L.build("hyprpicker --autocopy --lowercase-hex", { raw = true })
local quickShell   = L.build("qs ipc call overview toggle",        { raw = true })

local displayManager = L.build("nwg-displays")
local networkManager = "nmtui"
local audioManager   = L.term("wiremix")
local emojiPicker    = L.build("rofimoji --skin-tone neutral --action copy")

-- ── PWAs / web apps ──────────────────────────────────────────
local gemini_app   = L.chrome("https://gemini.google.com/")
local calendar     = L.chrome("https://calendar.google.com")
local chat         = L.chrome("https://chat.google.com")
local youtube      = L.chrome("https://www.youtube.com")
local youtubeMusic = L.chrome("https://music.youtube.com")
local monkeyType   = L.chrome("https://monkeytype.com")
local nixSearch    = L.build("google-chrome-stable --ozone-platform=x11 --new-window https://search.nixos.org/", { gpu = "offload" })
local claude_app   = L.chrome("https://claude.ai/new")
local jira         = L.build("google-chrome-stable --ozone-platform=x11 --new-window https://estrategia.atlassian.net/jira/software/c/projects/FUK2/boards/323?quickFilter=1182", { gpu = "offload" })

local settings     = zed .. " ~/nixos"
local workObsidian = obsidian_bin .. " \"obsidian://open?vault=Work\""
local personalObs  = obsidian_bin .. " \"obsidian://open?vault=.ovault\""

local yaak     = "sh -c 'notify-send \"abrindo yaaaaak\" && gpu-offload ~/apps/yaak.AppImage'"
local vennon   = L.term("env CLAUDECODE=1 zsh -c 'vennon claude'")
local yaaFast  = L.term("env CLAUDECODE=1 zsh -c 'yaa --model=haiku'")
local yaa      = L.term("env CLAUDECODE=1 zsh -c 'yaa --model=\"sonnet[1]\"'")

-- ── App Keybinds ──────────────────────────────────────────────

-- Quickshell Overview
km.app("SUPER + Space", quickShell, { desc = "Quickshell overview", group = "System", icon = "" })

-- Quick Apps
km.app("MOD3 + Space",  menu,         { desc = "App launcher (rofi)", icon = "" })
km.app("MOD3 + t",      terminal,     { desc = "Terminal",            icon = "" })
km.app("MOD3 + z",      zed,          { desc = "Zed editor",          icon = "" })
km.app("MOD3 + period", emojiPicker,  { desc = "Emoji picker",        icon = "" })
km.app("MOD3 + a",      audioManager, { desc = "Audio (wiremix)",     icon = "" })

-- Browsers + AI
km.app("MOD3 + b",         chrome,     { desc = "Chrome",          icon = "" })
km.app("MOD3 + g",         gemini_app, { desc = "Gemini app",      group = "AI", icon = "✦" })
km.app("MOD3 + ALT + c",   claude_app, { desc = "Claude.ai (web)", group = "AI", icon = "🅰" })
km.app("MOD3 + c",         yaaFast,    { desc = "yaa Haiku",       group = "AI", icon = "⚡" })
km.app("MOD3 + SHIFT + c", yaa,        { desc = "yaa Sonnet[1M]",  group = "AI", icon = "🧠" })
km.app("MOD3 + p",         vennon,     { desc = "Vennon REPL",     group = "AI", icon = "" })
