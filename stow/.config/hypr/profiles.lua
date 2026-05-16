-- ============================================================
--  PROFILES — modos de uso (default/focus/meeting/battery)
--
--  Cada profile aplica diff de config via `hyprctl keyword`
--  e roda on_enter/on_exit (side effects: DND, mic, env).
--  State em memória + arquivo (persiste reload).
-- ============================================================

local M = {}

local STATE_FILE = os.getenv("HOME") .. "/.cache/hyprland/profile_state"

local profiles = {
    default = {
        keywords = {
            ["general:gaps_out"]      = "5",
            ["general:border_size"]   = "3",
            ["decoration:blur:enabled"] = "false",
            ["animations:enabled"]    = "true",
        },
        on_enter = function()
            hl.exec_cmd("notify-send -t 800 'Profile: default' -u low")
        end,
    },
    focus = {
        keywords = {
            ["general:gaps_out"]      = "0",
            ["general:border_size"]   = "1",
            ["decoration:blur:enabled"] = "false",
            ["animations:enabled"]    = "false",
        },
        on_enter = function()
            hl.exec_cmd("swaync-client -d")  -- DND
            hl.exec_cmd("notify-send -t 800 'Focus mode' 'DND on, sem animações' -u low")
        end,
    },
    meeting = {
        keywords = {
            ["general:gaps_out"]      = "12",
            ["general:border_size"]   = "4",
            ["decoration:blur:enabled"] = "true",
            ["animations:enabled"]    = "true",
        },
        on_enter = function()
            hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0")
            hl.exec_cmd("brightnessctl s 80%")
            hl.exec_cmd("notify-send -t 800 'Meeting mode' 'Mic on, brilho 80%' -u low")
        end,
    },
    battery = {
        keywords = {
            ["general:gaps_out"]      = "3",
            ["general:border_size"]   = "2",
            ["decoration:blur:enabled"] = "false",
            ["animations:enabled"]    = "false",
        },
        on_enter = function()
            -- Hint pra launcher.lua: novos spawns sem gpu-offload
            os.execute("touch " .. os.getenv("HOME") .. "/.cache/hyprland/no_gpu")
            hl.exec_cmd("notify-send -t 800 'Battery mode' 'GPU offload desabilitado' -u low")
        end,
        on_exit = function()
            os.execute("rm -f " .. os.getenv("HOME") .. "/.cache/hyprland/no_gpu")
        end,
    },
}

local ORDER = { "default", "focus", "meeting", "battery" }

local _current = "default"

local function load_state()
    local f = io.open(STATE_FILE, "r")
    if f then
        local s = f:read("*l")
        f:close()
        if s and profiles[s] then _current = s end
    end
end

local function save_state(name)
    os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hyprland")
    local f = io.open(STATE_FILE, "w")
    if f then f:write(name) f:close() end
end

function M.apply(name)
    local p = profiles[name]
    if not p then return end
    local prev = profiles[_current]
    if prev and prev.on_exit and _current ~= name then prev.on_exit() end

    for kw, val in pairs(p.keywords) do
        hl.exec_cmd("hyprctl keyword " .. kw .. " " .. val)
    end
    if p.on_enter then p.on_enter() end

    _current = name
    save_state(name)
end

function M.cycle()
    local idx = 1
    for i, n in ipairs(ORDER) do if n == _current then idx = i break end end
    local next_name = ORDER[(idx % #ORDER) + 1]
    M.apply(next_name)
end

function M.current() return _current end

load_state()

-- Bind global: SUPER+SHIFT+P (Profile) cycle.
-- Combo "P" não conflita: SUPER+p é hyprpicker; SHIFT diferencia.
hl.bind("SUPER + SHIFT + p", function() M.cycle() end)

return M
