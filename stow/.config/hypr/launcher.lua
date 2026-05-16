-- ============================================================
--  LAUNCHER — wrapper unificado pra spawn de apps
--
--  Centraliza decoradores (uwsm app, gpu-offload, --class, --app=)
--  e permite kill-switches globais via env:
--    HYPR_NO_GPU=1   → desabilita gpu-offload em todos os builds
--    HYPR_NO_UWSM=1  → spawn direto, sem uwsm
-- ============================================================

local M = {}

local function env_truthy(name)
    local v = os.getenv(name)
    return v ~= nil and v ~= "" and v ~= "0"
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
    if not opts.raw and not env_truthy("HYPR_NO_UWSM") then
        pre = "uwsm app -- "
    end
    if opts.gpu == "offload" and not env_truthy("HYPR_NO_GPU") then
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
    return M.build("google-chrome-stable --ozone-platform=x11", opts)
end

-- term(inner, opts) → alacritty -e <inner>
function M.term(inner, opts)
    opts = opts or {}
    opts.gpu = opts.gpu or "offload"
    local extra = inner and (" -e " .. inner) or ""
    return M.build("alacritty" .. extra, opts)
end

return M
