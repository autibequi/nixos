-- ============================================================
--  POMODORO — focus timer integrado a profiles
--
--  SUPER+SHIFT+T cicla: idle → work(25m) → break(5m) → idle
--  Cada ciclo:
--    - work: aplica profile=focus, escreve status em ~/.cache/hyprland/pomodoro
--    - break: aplica profile=default, notif "break"
--  Waybar pode ler o arquivo de status pra render.
-- ============================================================

local core = require("core")

local STATUS = core.state_file("pomodoro")
local WORK_MS  = 25 * 60 * 1000
local BREAK_MS =  5 * 60 * 1000

local _state = "idle"   -- "idle" | "work" | "break"
local _started_at = 0
local _cycle_id = 0     -- invalida callbacks de ciclos anteriores

local function notify(title, body, urgency)
    core.notify(title, body, { timeout = 3000, urgency = urgency or "low" })
end

local function start_break(my_cycle)
    if my_cycle ~= _cycle_id then return end
    _state = "break"
    _started_at = os.time()
    STATUS.save("break:" .. _started_at)
    local ok = pcall(require, "profiles")
    if ok then require("profiles").apply("default") end
    notify("☕ Break", "5 min — levanta, alonga, bebe água", "normal")
    core.timer(BREAK_MS, function()
        if my_cycle ~= _cycle_id then return end
        _state = "idle"
        STATUS.save("idle")
        notify("✅ Pomodoro completo", "Pronto pra próximo ciclo (SUPER+SHIFT+T)", "normal")
    end)
end

local function start_work()
    _cycle_id = _cycle_id + 1
    local my_cycle = _cycle_id
    _state = "work"
    _started_at = os.time()
    STATUS.save("work:" .. _started_at)
    local ok = pcall(require, "profiles")
    if ok then require("profiles").apply("focus") end
    notify("🍅 Pomodoro iniciado", "25 min focus — DND on, sem animações", "normal")
    core.timer(WORK_MS, function() start_break(my_cycle) end)
end

local function cancel()
    _cycle_id = _cycle_id + 1  -- invalida callbacks pendentes
    _state = "idle"
    STATUS.save("idle")
    local ok = pcall(require, "profiles")
    if ok then require("profiles").apply("default") end
    notify("⏹ Pomodoro cancelado", "", "low")
end

function pomodoro_toggle()
    if _state == "idle" then
        start_work()
    else
        cancel()
    end
end

function pomodoro_status()
    if _state == "idle" then return "idle" end
    local elapsed = os.time() - _started_at
    local total = (_state == "work") and (WORK_MS / 1000) or (BREAK_MS / 1000)
    local left = math.max(0, total - elapsed)
    local m, s = math.floor(left / 60), left % 60
    return string.format("%s %02d:%02d", _state, m, s)
end

STATUS.save("idle")
hl.bind("SUPER + SHIFT + t", function() pomodoro_toggle() end)
