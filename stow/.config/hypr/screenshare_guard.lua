-- ============================================================
--  SCREENSHARE GUARD — auto-DND + indicador visual
--
--  Quando você compartilha tela (Meet/Zoom/OBS), ativa:
--    - swaync-client DND on (mata notif que vazariam)
--    - bordas vermelhas pesadas (lembra que tá compartilhando)
--    - mute de Discord/Telegram notifs do sistema
--  Sai do screenshare → reverte tudo.
-- ============================================================

local _was_dnd = false
local _saved_border = "3"

local function ok_pcall(fn) local ok, err = pcall(fn); return ok, err end

ok_pcall(function()
    hl.on("screenshare.state", function(ev)
        -- ev pode ser { state = true/false } ou { active = true/false } ou similar
        local active = false
        if type(ev) == "table" then
            active = ev.state or ev.active or ev.sharing or false
        elseif type(ev) == "boolean" then
            active = ev
        end

        if active then
            -- entrando em screenshare
            hl.exec_cmd("swaync-client -d 2>/dev/null | grep -q true || swaync-client -d")
            _was_dnd = true
            hl.exec_cmd("hyprctl keyword general:border_size 6")
            hl.exec_cmd("hyprctl keyword general:col.active_border " ..
                "'rgba(ff0000ff) rgba(ff5500ff) 45deg'")
            hl.exec_cmd("notify-send -t 1500 -u critical " ..
                "'🔴 SCREENSHARE ATIVO' 'DND on, bordas vermelhas'")
        else
            -- saindo do screenshare
            if _was_dnd then
                hl.exec_cmd("swaync-client -d 2>/dev/null | grep -q true && swaync-client -d")
                _was_dnd = false
            end
            hl.exec_cmd("hyprctl keyword general:border_size " .. _saved_border)
            -- Recarrega generated-colors pra voltar ao gradient normal
            hl.exec_cmd("hyprctl reload")
            hl.exec_cmd("notify-send -t 1000 'Screenshare encerrado' -u low")
        end
    end)
end)
