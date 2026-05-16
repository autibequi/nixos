-- ============================================================
--  THEME WATCHER — auto-reload de cores quando vennon muda
--
--  Hoje theme.lua chama vennon-theme-apply manualmente. Quando
--  você rodar vennon-theme-apply via CLI (fora do bind), o Hyprland
--  não percebe. Este timer poll detecta e reaplica.
--
--  Marker file (criar via post-hook do vennon):
--    ~/.cache/vennon/last-applied
-- ============================================================

local MARKER = os.getenv("HOME") .. "/.cache/vennon/last-applied"
local POLL_MS = 1500
local _last_mtime = 0

local function mtime(path)
    local p = io.popen("stat -c %Y '" .. path .. "' 2>/dev/null")
    if not p then return 0 end
    local s = p:read("*l")
    p:close()
    return tonumber(s) or 0
end

local function poll()
    local t = mtime(MARKER)
    if t == 0 then return end
    if _last_mtime == 0 then
        _last_mtime = t
        return
    end
    if t > _last_mtime then
        _last_mtime = t
        -- Re-source generated-colors + reload mínimo
        hl.exec_cmd("hyprctl reload")
        hl.exec_cmd("notify-send -t 600 'Theme refreshed' '" ..
            os.date("%H:%M:%S") .. "' -u low")
    end
end

local ok, err = pcall(function()
    hl.timer(poll, { timeout = POLL_MS, type = "repeat" })
end)
if not ok then
    hl.exec_cmd("logger -t hyprland-lua 'theme_watcher timer falhou: " .. tostring(err) .. "'")
end
