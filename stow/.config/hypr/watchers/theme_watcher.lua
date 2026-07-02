-- ============================================================
--  THEME WATCHER — auto-reload de cores quando vennon muda
--
--  Hoje theme.lua chama vennon-theme-apply manualmente. Quando
--  você rodar vennon-theme-apply via CLI (fora do bind), o Hyprland
--  não percebe. Este timer poll detecta e reaplica.
--
--  Marker file (criar via post-hook do vennon):
--    ~/.cache/vennon/last-applied  (conteúdo = timestamp/hash arbitrário)
--
--  Implementação: io.open() + read content (pseudo-fs / disk read direto;
--  NÃO io.popen). Comparação de conteúdo serve no lugar de mtime — vennon
--  só precisa escrever algo diferente a cada apply (date +%s já basta).
-- ============================================================

local core = require("core.core")

local MARKER  = os.getenv("HOME") .. "/.cache/vennon/last-applied"
local POLL_MS = 1500
local _last   = nil  -- nil = primeira leitura ainda não feita

local function read_marker()
    local f = io.open(MARKER, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local function poll()
    local now = read_marker()
    if not now then return end  -- marker não existe ainda
    if _last == nil then
        _last = now  -- snapshot inicial; não dispara reload no primeiro poll
        return
    end
    if now ~= _last then
        _last = now
        hl.exec_cmd("hyprctl reload")
        core.notify("Theme refreshed", os.date("%H:%M:%S"),
            { timeout = 600, urgency = "low" })
    end
end

local ok, err = pcall(function()
    hl.timer(poll, { timeout = POLL_MS, type = "repeat" })
end)
if not ok then
    hl.exec_cmd("logger -t hyprland-lua 'theme_watcher timer falhou: " ..
        tostring(err) .. "'")
end
