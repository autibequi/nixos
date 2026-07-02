-- ============================================================
--  AUTO PROFILE — chaveia profiles.battery / profiles.default
--  conforme estado da fonte AC.
--
--  Fonte: /sys/class/power_supply/ADP0/online  (1 = AC plugged, 0 = bateria)
--  Poll: 10s (event-less; sysfs lê barato via io.open).
--
--  Opt-out runtime: tocar ~/.cache/hyprland/no_auto_profile
--    (esconde poll; útil pra forçar um profile via UI sem ser sobrescrito).
--
--  Estado interno persiste só durante a sessão.
-- ============================================================

local core = require("core.core")

local AC_PATH    = "/sys/class/power_supply/ADP0/online"
local OPT_OUT    = os.getenv("HOME") .. "/.cache/hyprland/no_auto_profile"
local POLL_MS    = 10000
local _last_ac   = nil  -- "1" | "0" | nil

local function read_first_line(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*l")
    f:close()
    return s
end

local function ac_state()
    return read_first_line(AC_PATH)  -- "1"=plugged, "0"=battery, nil=sem ADP0 (desktop)
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

local function tick()
    if file_exists(OPT_OUT) then return end
    local now = ac_state()
    if not now then return end  -- sem ADP0; nada a fazer
    if _last_ac == nil then
        _last_ac = now           -- snapshot inicial; não dispara apply
        return
    end
    if now == _last_ac then return end
    _last_ac = now

    local ok, profiles = pcall(require, "profiles")
    if not ok then return end

    if now == "0" then
        -- AC desconectado → battery
        profiles.apply("battery")
        core.notify("⚡ AC desconectado", "Profile → battery",
            { timeout = 1500, urgency = "low" })
    else
        -- AC reconectado → default
        profiles.apply("default")
        core.notify("🔌 AC conectado", "Profile → default",
            { timeout = 1500, urgency = "low" })
    end
end

local ok, err = pcall(function()
    hl.timer(tick, { timeout = POLL_MS, type = "repeat" })
end)
if not ok then
    hl.exec_cmd("logger -t hyprland-lua 'auto_profile timer falhou: " ..
        tostring(err) .. "'")
end
