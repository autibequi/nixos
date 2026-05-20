-- ============================================================
--  LAUNCHER — wrapper unificado pra spawn de apps
--
--  Centraliza decoradores (uwsm app, gpu-offload, --class, --app=)
--  e permite kill-switches globais via env vars OU marker files:
--    HYPR_NO_GPU=1   ou  ~/.cache/hyprland/no_gpu   → sem gpu-offload
--    HYPR_NO_UWSM=1  ou  ~/.cache/hyprland/no_uwsm  → spawn direto
--
--  Os marker files permitem que outros módulos Lua (ex: profiles.lua
--  battery mode) alternem os flags sem precisar `os.setenv` (que não
--  existe em Lua puro).
-- ============================================================

local M = {}

local HOME      = os.getenv("HOME")
local CACHE_DIR = HOME .. "/.cache/hyprland"

local function env_truthy(name)
    local v = os.getenv(name)
    return v ~= nil and v ~= "" and v ~= "0"
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

local function disabled(env_name, marker_name)
    return env_truthy(env_name) or file_exists(CACHE_DIR .. "/" .. marker_name)
end

-- build(cmd, opts) → string pronta pra hl.dsp.exec_cmd
--
-- opts:
--   gpu     = "offload"  → prefixa `gpu-offload `
--   class   = "string"   → adiciona `--class='X,X'` (apps GTK/Chromium aceitam)
--   app_url = "https://..." → adiciona `--app=<url>` (Chromium PWA mode)
--   raw     = true       → não passa por uwsm app --
function M.build(cmd, opts)
    opts = opts or {}

    local pre = ""
    if not opts.raw and not disabled("HYPR_NO_UWSM", "no_uwsm") then
        pre = "uwsm app -- "
    end
    if opts.gpu == "offload" and not disabled("HYPR_NO_GPU", "no_gpu") then
        pre = pre .. "gpu-offload "
    end

    local suf = ""
    if opts.class then
        suf = suf .. " --class='" .. opts.class .. "," .. opts.class .. "'"
    end
    if opts.app_url then
        suf = suf .. " --app=" .. opts.app_url
    end

    return pre .. cmd .. suf
end

-- chrome(url, opts) → atalho para Chromium PWA com flags-padrão do setup
function M.chrome(url, opts)
    opts = opts or {}
    opts.gpu = opts.gpu or "offload"
    opts.app_url = url
    return M.build("google-chrome-stable", opts)
end

-- term(inner, opts) → alacritty -e <inner>
function M.term(inner, opts)
    opts = opts or {}
    opts.gpu = opts.gpu or "offload"
    local extra = inner and (" -e " .. inner) or ""
    return M.build("alacritty" .. extra, opts)
end

return M
