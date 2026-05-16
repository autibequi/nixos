-- ============================================================
--  SUBMAPS — smart actions context-aware
--
--  Não usa submap nativo do Hyprland (volátil). Em vez disso,
--  define ações que olham o app focado e despacham o atalho
--  apropriado via `wtype` (Wayland XTest-like).
--
--  Bindings:
--    SUPER+SHIFT+s  → "save smart"  (Ctrl+S na maioria; varia por app)
--    SUPER+SHIFT+w  → "close smart" (Ctrl+W em browsers/Zed; killactive caso contrário)
--    SUPER+SHIFT+r  → "reload smart" (F5 em browsers; nop em outros)
-- ============================================================

local function focused_class()
    for _, c in ipairs(hl.get_clients() or {}) do
        if c.focused then return c.class or "" end
    end
    return ""
end

local SAVE_RULES = {
    -- class match → sequência wtype (cada item = uma chamada com -M/-k)
    ["zeditor"]              = { mods = "ctrl", key = "s" },
    ["dev.zed.Zed"]          = { mods = "ctrl", key = "s" },
    ["cursor"]               = { mods = "ctrl", key = "s" },
    ["Cursor"]               = { mods = "ctrl", key = "s" },
    ["obsidian"]             = { mods = "ctrl", key = "s" },
    ["org.gnome.Nautilus"]   = nil, -- nop
    ["google-chrome"]        = { mods = "ctrl", key = "s" },  -- save page
}

local CLOSE_RULES = {
    ["zeditor"]      = { mods = "ctrl", key = "w" },
    ["dev.zed.Zed"]  = { mods = "ctrl", key = "w" },
    ["cursor"]       = { mods = "ctrl", key = "w" },
    ["Cursor"]       = { mods = "ctrl", key = "w" },
    ["google-chrome"]= { mods = "ctrl", key = "w" },
    ["chromium"]     = { mods = "ctrl", key = "w" },
}

local RELOAD_RULES = {
    ["google-chrome"]= { mods = "ctrl", key = "r" },
    ["chromium"]     = { mods = "ctrl", key = "r" },
    ["vivaldi-stable"]={ mods = "ctrl", key = "r" },
}

local function dispatch(rule, fallback)
    if not rule then
        if fallback then fallback() end
        return
    end
    -- wtype: -M ctrl s -m ctrl  → press, key, release
    local mods = rule.mods or ""
    local key = rule.key
    if mods ~= "" then
        hl.exec_cmd(string.format("wtype -M %s -k %s -m %s", mods, key, mods))
    else
        hl.exec_cmd(string.format("wtype -k %s", key))
    end
end

function smart_save()
    local class = focused_class()
    dispatch(SAVE_RULES[class], function()
        hl.exec_cmd("notify-send -t 600 'smart_save' " ..
            "'sem rule pra " .. (class ~= "" and class or "?") .. "' -u low")
    end)
end

function smart_close()
    local class = focused_class()
    dispatch(CLOSE_RULES[class], function()
        hl.dispatch(hl.dsp.window.close())
    end)
end

function smart_reload()
    local class = focused_class()
    dispatch(RELOAD_RULES[class], function()
        hl.exec_cmd("notify-send -t 600 'smart_reload' " ..
            "'sem rule pra " .. (class ~= "" and class or "?") .. "' -u low")
    end)
end

hl.bind("SUPER + SHIFT + s", function() smart_save() end)
hl.bind("SUPER + SHIFT + w", function() smart_close() end)
hl.bind("SUPER + SHIFT + r", function() smart_reload() end)
