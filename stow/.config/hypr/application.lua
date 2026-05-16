-- ============================================================
--  APPLICATION ALIASES + KEYBINDS — portado de application.conf
-- ============================================================

-- ── App aliases ───────────────────────────────────────────────
local ghostty      = "uwsm app -- gpu-offload ghostty --gtk-single-instance=true"
local terminal     = "uwsm app -- gpu-offload alacritty"
local fileManager  = "uwsm app -- nautilus -w"
local menu         = "uwsm app -- rofi -show drun"
local lock         = "hyprlock"
local obsidian_bin = "uwsm app -- obsidian"
local chrome       = "uwsm app -- gpu-offload google-chrome-stable --ozone-platform=x11"
local vivaldi      = "uwsm app -- vivaldi"
local cursor       = "uwsm app -- gpu-offload cursor"
local zed          = "uwsm app -- gpu-offload zeditor"
local colorPicker  = "hyprpicker --autocopy --lowercase-hex"
local quickShell   = "qs ipc call overview toggle"

local displayManager  = "uwsm app -- nwg-displays"
local networkManager  = "nmtui"
local audioManager    = terminal .. " -e wiremix"
local emojiPicker     = "uwsm app -- rofimoji --skin-tone neutral --action copy"

local settings       = zed .. " ~/nixos"
local workObsidian   = obsidian_bin .. " \"obsidian://open?vault=Work\""
local personalObs    = obsidian_bin .. " \"obsidian://open?vault=.ovault\""

local youtubeMusic   = chrome .. " --app=https://music.youtube.com"
local monkeyType     = chrome .. " --app=https://monkeytype.com"
local nixSearch      = chrome .. " --new-window https://search.nixos.org/"
local gemini_app     = chrome .. " --app=https://gemini.google.com/"
local calendar       = chrome .. " --app=https://calendar.google.com"
local chat           = chrome .. " --app=https://chat.google.com"
local youtube        = chrome .. " --app=https://www.youtube.com"
local jira           = chrome .. " --new-window https://estrategia.atlassian.net/jira/software/c/projects/FUK2/boards/323?quickFilter=1182"
local yaak           = "sh -c 'notify-send \"abrindo yaaaaak\" && gpu-offload ~/apps/yaak.AppImage'"

local claude_app = chrome .. " --app=https://claude.ai/new"
local vennon     = terminal .. " -e env CLAUDECODE=1 zsh -c 'vennon claude'"
local yaaFast    = terminal .. " -e env CLAUDECODE=1 zsh -c 'yaa --model=haiku'"
local yaa        = terminal .. " -e env CLAUDECODE=1 zsh -c 'yaa --model=\"sonnet[1]\"'"

-- ── App Keybinds ──────────────────────────────────────────────

-- Quickshell Overview
hl.bind("SUPER + Space", hl.dsp.exec_cmd(quickShell))

-- Quick Apps
hl.bind("MOD3 + Space",       hl.dsp.exec_cmd(menu))
hl.bind("MOD3 + t",           hl.dsp.exec_cmd(terminal))
hl.bind("MOD3 + z",           hl.dsp.exec_cmd(zed))
hl.bind("MOD3 + period",      hl.dsp.exec_cmd(emojiPicker))
hl.bind("MOD3 + a",           hl.dsp.exec_cmd(audioManager))

-- Browsers + AI
hl.bind("MOD3 + b",           hl.dsp.exec_cmd(chrome))
hl.bind("MOD3 + g",           hl.dsp.exec_cmd(gemini_app))
hl.bind("MOD3 ALT + c",       hl.dsp.exec_cmd(claude_app))
hl.bind("MOD3 + c",           hl.dsp.exec_cmd(yaaFast))
hl.bind("MOD3 SHIFT + c",     hl.dsp.exec_cmd(yaa))
hl.bind("MOD3 + p",           hl.dsp.exec_cmd(vennon))
